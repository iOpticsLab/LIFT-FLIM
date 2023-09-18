import time
import os
os.environ["CUDA_DEVICE_ORDER"] = "PCI_BUS_ID"
os.environ['CUDA_VISIBLE_DEVICES'] = '0'
import argparse
import matplotlib.pyplot as plt
import scipy.io as sio
import scipy.ndimage as ndimage
from skimage.util import montage
import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
from torch.optim import lr_scheduler
from torchvision import datasets, transforms, utils
# from tensorboardX import SummaryWriter
# from torch.utils.tensorboard import SummaryWriter
from utils import * 
from my_tools import *
from model import * 
import np_transforms
from PIL import Image

def ecc(im, im_ref, centralize=True):
    if centralize:
        im -= im.mean()
        im_ref -= im_ref.mean()
    corr = np.real(np.vdot(im, im_ref)) / np.sqrt((np.abs(im)**2).sum() * (np.abs(im_ref)**2).sum())
    return corr

parser = argparse.ArgumentParser()
# data I/O
parser.add_argument('-i', '--data_dir', type=str,
                    default='data', help='Location for the dataset')
parser.add_argument('-o', '--save_dir', type=str, default='models',
                    help='Location for parameter checkpoints and samples')
parser.add_argument('-d', '--dataset', type=str,
                    default='cifar', help='Can be either cifar|mnist')
parser.add_argument('-p', '--print_every', type=int, default=50,
                    help='how many iterations between print statements')
parser.add_argument('-t', '--save_interval', type=int, default=100,
                    help='Every how many epochs to write checkpoint/samples?')
parser.add_argument('-r', '--load_params', type=str, default=None,
                    help='Restore training from previous model checkpoint?')
# model
parser.add_argument('-q', '--nr_resnet', type=int, default=4,
                    help='Number of residual blocks per stage of the model')
parser.add_argument('-n', '--nr_filters', type=int, default=32,
                    help='Number of filters to use across the model. Higher = larger model.')
parser.add_argument('-s', '--n_scale', type=int, default=5,
                    help='Number of down-/up-sampl   ing stages. Higher = larger model.')
parser.add_argument('-m', '--nr_logistic_mix', type=int, default=10,
                    help='Number of logistic components in the mixture. Higher = more flexible model')
parser.add_argument('-l', '--lr', type=float,
                    default=0.0002, help='Base learning rate')
parser.add_argument('-e', '--lr_decay', type=float, default=0.999995,
                    help='Learning rate decay, applied every step of the optimization')
parser.add_argument('-b', '--batch_size', type=int, default=2,
                    help='Batch size during training per GPU')
parser.add_argument('-x', '--max_epochs', type=int,
                    default=5000, help='How many epochs to run in total?')
parser.add_argument('--seed', type=int, default=1,
                    help='Random seed to use')
args = parser.parse_args()

# reproducibility
torch.manual_seed(args.seed)
np.random.seed(args.seed)

# path = 'UNet_ep=2000_w=48_nb=6_LIFT+WF_corr'
path = 'pcnn_lr0.00010_nr-resnet4_nr-filters32-n_scale5'
model_name = "ckpt_best.pth"
path_model = 'models/'+path
path_output = 'outputs/'+path
os.makedirs(path_output, exist_ok=True)

DATA_PATH = './demo_data'
data_file = os.path.join(DATA_PATH, 'testingpair.mat')
data = sio.loadmat(data_file)
lift_input = data['lift_refocus_all'].astype('float32')  # [H, W, C=2(LIFT&WF), N]
lift_input /= np.percentile(lift_input, 99.5, axis=(0,1,2), keepdims=True)
lift_input = ndimage.zoom(lift_input, zoom=(256/270, 256/270,1,1))
gt = data['groundtruth_all'].astype('float32')
gt = np.expand_dims(gt, axis=2)  # [H, W, C=1, N]
gt /= np.percentile(gt, 99.5, axis=(0,1,2), keepdims=True)
gt = ndimage.zoom(gt, zoom=(256/270, 256/270,1,1))

mask = sio.loadmat("./demo_data/fovmask_l.mat")
mask = mask['fovmask_l'].astype('float32')
mask = np.expand_dims(mask, axis=(2,3))  # [H, W, C=1, N=1]
mask = ndimage.zoom(mask, zoom=(256/270, 256/270,1,1))
lift_input *= mask
gt *= mask

# load model
model = PixelCNN(nr_resnet=args.nr_resnet, nr_filters=args.nr_filters, 
            input_channels=2, output_channels=1)
model = model.cuda()
ckpt = torch.load(os.path.join(path_model, model_name))
model.load_state_dict(ckpt)
model.eval()

ecc_list = []
with torch.no_grad():
    for i in range(gt.shape[-1]):
        loss = 0
        xx, yy = lift_input[:,:,:,i], gt[:,:,:,i]
        
        # permute and to tensor
        xx = np.expand_dims(xx.transpose([2,0,1]), axis=0)
        yy = np.expand_dims(yy.transpose([2,0,1]), axis=0)
        xx = torch.from_numpy(xx).cuda()
        yy = torch.from_numpy(yy).cuda()

        im = model(xx)
        # (im_amp, im_ph), (yy_amp, yy_ph) = R2P(comp_field_norm(im)), R2P(comp_field_norm(yy))
        xx, yy, im = xx.cpu().numpy().squeeze(), yy.cpu().numpy().squeeze(), im.cpu().numpy().squeeze()
        ecc_list.append(ecc(im, yy))

        # save montage
        inp_lift = min_max_norm(xx[0,...])  # remove WF
        # inp_montage = montage(xx)
        inp_wf = min_max_norm(xx[1,...])  # WF
        out = min_max_norm(im, vmin=yy.min(), vmax=yy.max())
        tag = min_max_norm(yy, vmin=yy.min(), vmax=yy.max())
        # out_montage = montage(im)
        # tag_montage = montage(yy)

        plt.imsave(os.path.join(path_output, 'valid%d_WF_input.png'%i), inp_wf, cmap='gray')
        plt.imsave(os.path.join(path_output, 'valid%d_LIFT_input.png'%i), inp_lift, cmap='gray')
        plt.imsave(os.path.join(path_output, 'valid%d_WF_target.png'%i), yy, cmap='gray')
        plt.imsave(os.path.join(path_output, 'valid%d_output.png'%i), out, cmap='gray')
        # plt.imsave(os.path.join(path_output, 'valid%d_WF_input.png'%i), inp_wf, cmap='gray')
        # plt.imsave(os.path.join(args.output_dir, fname.replace('.mat','_input.jpg')), xx, cmap='gray')
        sio.savemat(os.path.join(path_output, 'valid%d.mat'%i), {'inputData':xx, 'outputData':im, 'targetData':yy})

print('Average ECC', np.mean(ecc_list))