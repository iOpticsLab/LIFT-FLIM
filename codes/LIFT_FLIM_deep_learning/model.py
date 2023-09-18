import pdb
import torch 
import torch.nn as nn
import torch.nn.functional as F
from torch.autograd import Variable
from layers import * 
from utils import * 
import numpy as np

class PixelCNNLayer_up(nn.Module):
    def __init__(self, nr_resnet, nr_filters, resnet_nonlinearity):
        super(PixelCNNLayer_up, self).__init__()
        self.nr_resnet = nr_resnet
        # stream from pixels above
        self.u_stream = nn.ModuleList([gated_resnet(nr_filters, down_shifted_conv2d, 
                                        resnet_nonlinearity, skip_connection=0) 
                                            for _ in range(nr_resnet)])
        
        # stream from pixels above and to thes left
        self.ul_stream = nn.ModuleList([gated_resnet(nr_filters, down_right_shifted_conv2d, 
                                        resnet_nonlinearity, skip_connection=1) 
                                            for _ in range(nr_resnet)])

    def forward(self, u, ul):
        u_list, ul_list = [], []
        
        for i in range(self.nr_resnet):
            u  = self.u_stream[i](u)
            ul = self.ul_stream[i](ul, a=u)
            u_list  += [u]
            ul_list += [ul]

        return u_list, ul_list


class PixelCNNLayer_down(nn.Module):
    def __init__(self, nr_resnet, nr_filters, resnet_nonlinearity):
        super(PixelCNNLayer_down, self).__init__()
        self.nr_resnet = nr_resnet
        # stream from pixels above
        self.u_stream  = nn.ModuleList([gated_resnet(nr_filters, down_shifted_conv2d, 
                                        resnet_nonlinearity, skip_connection=1) 
                                            for _ in range(nr_resnet)])
        
        # stream from pixels above and to thes left
        self.ul_stream = nn.ModuleList([gated_resnet(nr_filters, down_right_shifted_conv2d, 
                                        resnet_nonlinearity, skip_connection=2) 
                                            for _ in range(nr_resnet)])

    def forward(self, u, ul, u_list, ul_list):
        for i in range(self.nr_resnet):
            u  = self.u_stream[i](u, a=u_list.pop())
            ul = self.ul_stream[i](ul, a=torch.cat((u, ul_list.pop()), 1))
        
        return u, ul


# PixelCNN++ for small FOVs
class PixelCNN(nn.Module):
    def __init__(self, nr_resnet=5, nr_filters=80, n_scale=3, input_channels=3, output_channels=3, 
                    resnet_nonlinearity='concat_elu'):
        super(PixelCNN, self).__init__()
        if resnet_nonlinearity == 'concat_elu' : 
            # self.resnet_nonlinearity = lambda x : concat_elu(x)
            self.resnet_nonlinearity = resnet_nonlinearity
        else : 
            raise Exception('right now only concat elu is supported as resnet nonlinearity.')

        self.nr_filters = nr_filters
        self.n_scale = n_scale
        self.input_channels = input_channels
        self.output_channels = output_channels
        self.right_shift_pad = nn.ZeroPad2d((1, 0, 0, 0))
        self.down_shift_pad  = nn.ZeroPad2d((0, 0, 1, 0))

        down_nr_resnet = [nr_resnet] + [nr_resnet + 1] * 2
        self.down_layers = nn.ModuleList([PixelCNNLayer_down(down_nr_resnet[i], nr_filters, 
                                                self.resnet_nonlinearity) for i in range(n_scale)])

        self.up_layers   = nn.ModuleList([PixelCNNLayer_up(nr_resnet, nr_filters, 
                                                self.resnet_nonlinearity) for _ in range(n_scale)])

        self.downsize_u_stream  = nn.ModuleList([down_shifted_conv2d(nr_filters, nr_filters, 
                                                    stride=(2,2)) for _ in range(n_scale-1)])

        self.downsize_ul_stream = nn.ModuleList([down_right_shifted_conv2d(nr_filters, 
                                                    nr_filters, stride=(2,2)) for _ in range(n_scale-1)])
        
        self.upsize_u_stream  = nn.ModuleList([down_shifted_deconv2d(nr_filters, nr_filters, 
                                                    stride=(2,2)) for _ in range(n_scale-1)])
             
        self.upsize_ul_stream = nn.ModuleList([down_right_shifted_deconv2d(nr_filters, 
                                                    nr_filters, stride=(2,2)) for _ in range(n_scale-1)])
        
        self.u_init = down_shifted_conv2d(input_channels + 1, nr_filters, filter_size=(2,3), 
                        shift_output_down=True)

        self.ul_init = nn.ModuleList([down_shifted_conv2d(input_channels + 1, nr_filters, 
                                            filter_size=(1,3), shift_output_down=True), 
                                       down_right_shifted_conv2d(input_channels + 1, nr_filters, 
                                            filter_size=(2,1), shift_output_right=True)])
    
        # num_mix = 3 if self.input_channels == 1 else 10
        self.nin_out = nin(nr_filters, output_channels)
        self.init_padding = None


    def forward(self, x, sample=False):
        # similar as done in the tf repo :  
        if self.init_padding is None and not sample: 
            xs = [int(y) for y in x.size()]
            padding = Variable(torch.ones(xs[0], 1, xs[2], xs[3]), requires_grad=False)
            self.init_padding = padding.cuda() if x.is_cuda else padding
        
        if sample : 
            xs = [int(y) for y in x.size()]
            padding = Variable(torch.ones(xs[0], 1, xs[2], xs[3]), requires_grad=False)
            padding = padding.cuda() if x.is_cuda else padding
            x = torch.cat((x, padding), 1)

        ###      UP PASS    ###
        x = x if sample else torch.cat((x, self.init_padding), 1)
        u_list  = [self.u_init(x)]
        ul_list = [self.ul_init[0](x) + self.ul_init[1](x)]
        for i in range(self.n_scale):
            # resnet block
            u_out, ul_out = self.up_layers[i](u_list[-1], ul_list[-1])
            u_list  += u_out
            ul_list += ul_out

            if i != self.n_scale-1: 
                # downscale (only twice)
                u_list  += [self.downsize_u_stream[i](u_list[-1])]
                ul_list += [self.downsize_ul_stream[i](ul_list[-1])]                                                                                           

        ###    DOWN PASS    ###
        u  = u_list.pop()
        ul = ul_list.pop()
        
        for i in range(self.n_scale):
            # resnet block
            u, ul = self.down_layers[i](u, ul, u_list, ul_list)

            # upscale (only twice)
            if i != self.n_scale-1:
                u  = self.upsize_u_stream[i](u)
                ul = self.upsize_ul_stream[i](ul)

        x_out = self.nin_out(F.elu(ul))

        assert len(u_list) == len(ul_list) == 0, pdb.set_trace()

        return x_out
        

# PixelCNN++ for large FOVs      
class PixelCNN_L(nn.Module):
    def __init__(self, nr_resnet=5, nr_filters=80, n_scale=3, input_channels=3, output_channels=3, 
                    resnet_nonlinearity='concat_elu'):
        super(PixelCNN_L, self).__init__()
        if resnet_nonlinearity == 'concat_elu' : 
            self.resnet_nonlinearity = resnet_nonlinearity
        else : 
            raise Exception('right now only concat elu is supported as resnet nonlinearity.')

        self.nr_filters = nr_filters
        self.n_scale = n_scale
        self.input_channels = input_channels
        self.output_channels = output_channels
        self.right_shift_pad = nn.ZeroPad2d((1, 0, 0, 0))
        self.down_shift_pad  = nn.ZeroPad2d((0, 0, 1, 0))

        down_nr_resnet = [nr_resnet] + [nr_resnet + 1] * 2
        self.down_layers = nn.ModuleList([PixelCNNLayer_down(down_nr_resnet[i], nr_filters, 
                                                self.resnet_nonlinearity) for i in range(n_scale)])

        self.up_layers   = nn.ModuleList([PixelCNNLayer_up(nr_resnet, nr_filters, 
                                                self.resnet_nonlinearity) for _ in range(n_scale)])

        self.downsize_u_stream  = nn.ModuleList([down_shifted_conv2d(nr_filters, nr_filters, 
                                                    stride=(2,2)) for _ in range(n_scale-1)])

        self.downsize_ul_stream = nn.ModuleList([down_right_shifted_conv2d(nr_filters, 
                                                    nr_filters, stride=(2,2)) for _ in range(n_scale-1)])
        
        self.upsize_u_stream  = nn.ModuleList([down_shifted_deconv2d(nr_filters, nr_filters, 
                                                    stride=(2,2)) for _ in range(n_scale-1)])
             
        self.upsize_ul_stream = nn.ModuleList([down_right_shifted_deconv2d(nr_filters, 
                                                    nr_filters, stride=(2,2)) for _ in range(n_scale-1)])
        
        # input downsampling
        self.stem = nn.Conv2d(input_channels + 1, nr_filters, kernel_size=4, stride=4)
        
        self.u_init = down_shifted_conv2d(nr_filters, nr_filters, filter_size=(2,3), 
                        shift_output_down=True)
        
        self.ul_init = nn.ModuleList([down_shifted_conv2d(nr_filters, nr_filters, 
                                            filter_size=(1,3), shift_output_down=True), 
                                       down_right_shifted_conv2d(nr_filters, nr_filters, 
                                            filter_size=(2,1), shift_output_right=True)])
    
        # output upsampling
        self.pix_shuffle = nn.PixelShuffle(upscale_factor=4)
        self.nin_out = nin(nr_filters//16, output_channels)
        self.init_padding = None


    def forward(self, x, sample=False):
        # similar as done in the tf repo :  
        if self.init_padding is None and not sample: 
            xs = [int(y) for y in x.size()]
            padding = Variable(torch.ones(xs[0], 1, xs[2], xs[3]), requires_grad=False)
            self.init_padding = padding.cuda() if x.is_cuda else padding
        
        if sample : 
            xs = [int(y) for y in x.size()]
            padding = Variable(torch.ones(xs[0], 1, xs[2], xs[3]), requires_grad=False)
            padding = padding.cuda() if x.is_cuda else padding
            x = torch.cat((x, padding), 1)

        ###      UP PASS    ###
        x = x if sample else torch.cat((x, self.init_padding), 1)
        x = self.stem(x)
        u_list  = [self.u_init(x)]
        ul_list = [self.ul_init[0](x) + self.ul_init[1](x)]
        for i in range(self.n_scale):
            # resnet block
            u_out, ul_out = self.up_layers[i](u_list[-1], ul_list[-1])
            u_list  += u_out
            ul_list += ul_out

            if i != self.n_scale-1: 
                # downscale (only twice)
                u_list  += [self.downsize_u_stream[i](u_list[-1])]
                ul_list += [self.downsize_ul_stream[i](ul_list[-1])]                                                                                           

        ###    DOWN PASS    ###
        u  = u_list.pop()
        ul = ul_list.pop()
        
        for i in range(self.n_scale):
            # resnet block
            u, ul = self.down_layers[i](u, ul, u_list, ul_list)

            # upscale (only twice)
            if i != self.n_scale-1:
                u  = self.upsize_u_stream[i](u)
                ul = self.upsize_ul_stream[i](ul)

        x_out = self.pix_shuffle(F.elu(ul))
        x_out = self.nin_out(x_out)

        assert len(u_list) == len(ul_list) == 0, pdb.set_trace()

        return x_out
     