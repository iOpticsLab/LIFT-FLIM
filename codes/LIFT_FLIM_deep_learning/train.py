import time
import os
os.environ["CUDA_DEVICE_ORDER"] = "PCI_BUS_ID"
os.environ['CUDA_VISIBLE_DEVICES'] = '0'
import argparse
import matplotlib.pyplot as plt
import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
from torch.optim import lr_scheduler
from torchvision import datasets, transforms, utils
from tensorboardX import SummaryWriter
# from torch.utils.tensorboard import SummaryWriter
import glob
from utils import * 
from my_tools import *
from model import * 
import np_transforms
from PIL import Image

parser = argparse.ArgumentParser()
# data I/O
parser.add_argument('-i', '--data_dir', type=str,
                    default='data', help='Location for the dataset')
parser.add_argument('-o', '--save_dir', type=str, default='models',
                    help='Location for parameter checkpoints and samples')
parser.add_argument('-p', '--print_every', type=int, default=50,
                    help='how many iterations between print statements')
parser.add_argument('-t', '--save_interval', type=int, default=10,
                    help='Every how many epochs to write checkpoint/samples?')
parser.add_argument('-r', '--load_params', type=str, default=None,
                    help='Restore training from previous model checkpoint?')
# model
parser.add_argument('-n', '--nr_resnet', type=int, default=4,
                    help='Number of residual blocks per stage of the model')
parser.add_argument('-f', '--nr_filters', type=int, default=32,
                    help='Number of filters to use across the model. Higher = larger model.')
parser.add_argument('-s', '--n_scale', type=int, default=5,
                    help='Number of down-/up-sampl   ing stages. Higher = larger model.')
parser.add_argument('-m', '--nr_logistic_mix', type=int, default=10,
                    help='Number of logistic components in the mixture. Higher = more flexible model')
parser.add_argument('-l', '--lr', type=float,
                    default=0.0002, help='Base learning rate')
parser.add_argument('-e', '--lr_decay', type=float, default=0.999995,
                    help='Learning rate decay, applied every step of the optimization')
parser.add_argument('-b', '--batch_size', type=int, default=1,
                    help='Batch size during training per GPU')
parser.add_argument('-x', '--max_epochs', type=int,
                    default=5000, help='How many epochs to run in total?')
parser.add_argument('--seed', type=int, default=1,
                    help='Random seed to use')
args = parser.parse_args()

# reproducibility
torch.manual_seed(args.seed)
np.random.seed(args.seed)

model_name = 'pcnn_lr{:.5f}_nr-resnet{}_nr-filters{}-n_scale{}'.format(args.lr, args.nr_resnet, args.nr_filters, args.n_scale)
# assert not os.path.exists(os.path.join('runs', model_name)), '{} already exists!'.format(model_name)
os.makedirs(os.path.join('models', model_name), exist_ok=True)
os.makedirs(os.path.join('runs', model_name), exist_ok=True)
writer = SummaryWriter(log_dir=os.path.join('runs', model_name))

sample_batch_size = 25
# obs = (1, 28, 28) if 'mnist' in args.dataset else (3, 32, 32)
# input_channels = obs[0]
rescaling     = lambda x : (x - .5) * 2.
rescaling_inv = lambda x : .5 * x  + .5
kwargs = {'num_workers':1, 'pin_memory':True, 'drop_last':True}
ds_transforms = transforms.Compose([transforms.ToTensor(), rescaling])


# TODO: set your own data path here
train_file = glob.glob(os.path.join(r"", '*.mat'))  
valid_file = glob.glob(os.path.join(r"", '*.mat'))
train_dataset = LIFTDataset_slice(train_file, np_transforms.Compose([np_transforms.RectCrop([100, 100, 1900, 1900]),  # TODO: set your own crop and scale size here
                                                                    np_transforms.Scale((1024, 1024)),
                                                                    np_transforms.ToTensor()
                                                                    ]), wf=True, dpm=True, mask=True
                )
train_loader = torch.utils.data.DataLoader(train_dataset, batch_size=args.batch_size, shuffle=True, drop_last=True)
valid_dataset = LIFTDataset_vol(valid_file, np_transforms.Compose([np_transforms.RectCrop([100, 100, 1900, 1900]),  # TODO: set your own crop and scale size here
                                                                    np_transforms.Scale((1024, 1024)),
                                                                    np_transforms.ToTensor()
                                                                    ]), wf=True, dpm=True, mask=True, train=False
                )
valid_loader = torch.utils.data.DataLoader(valid_dataset, batch_size=args.batch_size, shuffle=True, drop_last=False)
test_dataset = valid_dataset
# loss_op   = lambda real, fake : discretized_mix_logistic_loss(real, fake)
# loss_op = nn.L1Loss()
sample_op = lambda x : sample_from_discretized_mix_logistic(x, args.nr_logistic_mix)

# define loss operator
maeloss = nn.L1Loss()
mseloss = nn.MSELoss()
pcploss = PerceptualLoss([0,1,2], [0.5,0.15,0.1], torch.device("cuda" if torch.cuda.is_available() else "cpu")).cuda()
def loss_op(yy, im):
    # extract saliency map
    a_q = 1.25
    im_q, yy_q = F.sigmoid(100*(im - a_q)), F.sigmoid(100*(yy - a_q))
    loss = maeloss(torch.fft.fft2(im), torch.fft.fft2(yy))*0.1 + pcploss(im, yy)*0.1 + mseloss(im, yy)*20.0  # TODO: set your own loss weights here
    loss += mseloss(im_q*im, yy_q*yy)*20.0
    return loss

# TODO: set 'input_channel' according to your task
model = PixelCNN_L(nr_resnet=args.nr_resnet, nr_filters=args.nr_filters, 
            input_channels=3, output_channels=1)
model = model.cuda()

optimizer = optim.Adam(model.parameters(), lr=args.lr)
scheduler = lr_scheduler.StepLR(optimizer, step_size=1, gamma=args.lr_decay)

start_epoch = 0
if args.load_params:
    # load_part_of_model(model, args.load_params)
    ckpt = torch.load(os.path.join('models', model_name, args.load_params))
    model.load_state_dict(ckpt['model'])
    optimizer.load_state_dict(ckpt['optimizer'])
    scheduler.load_state_dict(ckpt['scheduler'])
    start_epoch = ckpt['epoch']
    print('model parameters loaded')


print('starting training')
writes = 0
min_val_loss = 1000000
for epoch in range(start_epoch, args.max_epochs):
    model.train(True)
    # torch.cuda.synchronize()
    train_loss = 0.
    time_ = time.time()
    model.train()
    for batch_idx, (input, target) in enumerate(train_loader):
        if batch_idx >= 1000:
            break
        
        input = input.cuda()
        target = target.cuda()
        # input = Variable(input)
        output = model(input)
        loss = loss_op(target, output)
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
        train_loss += loss
        # train_loss += loss.data[0]
        # deno = args.print_every * args.batch_size * np.prod(obs) * np.log(2.)
        writer.add_scalar('train/loss', (train_loss / (batch_idx+1)), writes)
        print('epoch : {}, loss : {:.4f}, time : {:.4f}'.format(
            epoch,
            (train_loss / (batch_idx+1)), 
            (time.time() - time_)))
        train_loss = 0.
        writes += 1
        time_ = time.time()
            

    # decrease learning rate
    scheduler.step()                                                                                                                                                                                                                        
    
    # torch.cuda.synchronize()
    model.eval()
    test_loss = 0.
    xx_list = []
    yy_list = []
    im_list = []
    with torch.no_grad():
        for batch_idx, (input, target) in enumerate(valid_loader):            
            input = input.cuda()
            target = target.cuda()
            # input_var = Variable(input)
            output = model(input, sample=True)
            loss = mseloss(target, output)
            # test_loss += loss.data[0]
            test_loss += loss
            # del loss, output
            xx_list.append(input.cpu().numpy())
            im_list.append(output.cpu().numpy())
            yy_list.append(target.cpu().numpy())

    xx = np.vstack(xx_list).reshape((-1,)+input.shape[1:])
    yy = np.vstack(yy_list).reshape((-1,)+target.shape[1:])
    im = np.vstack(im_list).reshape((-1,)+output.shape[1:])

    # deno = batch_idx * args.batch_size * np.prod(obs) * np.log(2.)
    writer.add_scalar('test/loss', (test_loss / (batch_idx+1)), writes)
    print('epoch : {}, test loss : {:.4f}'.format(epoch, test_loss / (batch_idx+1)))
    writer.add_images('input_LIFT', np.clip(xx[:,0:1,...],0,1), epoch, dataformats='NCHW')
    writer.add_images('output', np.clip((im-yy.min())/(yy.max()-yy.min()),0,1), epoch, dataformats='NCHW')
    writer.add_images('target_WF', (yy-yy.min())/(yy.max()-yy.min()), epoch, dataformats='NCHW')

    if test_loss < min_val_loss:
        torch.save({'model': model.state_dict(),
                    'epoch': epoch,
                    'optimizer': optimizer.state_dict(),
                    'scheduler': scheduler.state_dict()},
                   'models/{}/ckpt_best.pth'.format(model_name))
        min_val_loss = test_loss
    if (epoch + 1) % args.save_interval == 0: 
        torch.save({'model': model.state_dict(),
                    'epoch': epoch,
                    'optimizer': optimizer.state_dict(),
                    'scheduler': scheduler.state_dict()},
                   'models/{}/ckpt_{}.pth'.format(model_name, epoch))

