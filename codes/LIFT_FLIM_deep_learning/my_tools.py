from os import error
import torch
import numpy as np
import torch
import scipy.io
import scipy.signal
from torch import get_file_path, tensor
import scipy.ndimage as ndimage
import torch.nn as nn
import torch.nn.functional as F
import PIL
# import h5py

import operator
from functools import reduce
from functools import partial

from multiprocessing.pool import ThreadPool
import time

z_positions_list = []


def min_max_norm(img, vmin=None, vmax=None):
    if vmin is None:
        vmin = img.min()
    if vmax is None:
        vmax = img.max()
    img = np.clip(img, vmin, vmax)
    return (img - vmin) / (vmax - vmin)

def patchify(img, patch_size):
    n, c, h, w = img.shape
    assert isinstance(patch_size, int), "Patch size must be integer"
    assert ((h//patch_size+1)*patch_size-h) % 2 == 0, "Pad size must be symmetric"
    if h % patch_size == 0 and w % patch_size == 0:
        pad_size = 0
    else:
        pad_size = [((h//patch_size+1)*patch_size-h)//2, ((w//patch_size+1)*patch_size-w)//2]
    
    xx = F.unfold(img, kernel_size=patch_size, padding=pad_size, stride=patch_size)  # pad to [2304, 2304]
    l = xx.shape[-1]
    img = xx.reshape([n, c, patch_size, patch_size, l]).permute([0,4,1,2,3]).reshape([n*l, c, patch_size, patch_size])
    
    return img

def unpatchify(img, output_size):
    n, c, patch_size, _ = img.shape
    if output_size % patch_size == 0:
        l = (output_size//patch_size) ** 2
        pad_size = 0
    else:
        l = (output_size//patch_size+1) ** 2
        pad_size = ((output_size//patch_size+1)*patch_size-output_size)//2
    xx = img.reshape([n//l, l, c, patch_size, patch_size]).permute([0,2,3,4,1]).reshape([n//l, c*patch_size**2, l])
    xx = F.fold(xx, output_size, kernel_size=patch_size, padding=pad_size, stride=patch_size)
    # img = xx[:,:,pad_size:-pad_size, pad_size:-pad_size]
    
    return xx


class LIFTDataset_slice(torch.utils.data.Dataset):
    def __init__(self, data_files, trans, wf=False, dpm=False, mask=False, train=True):
        self.data_files = data_files
        self.trans = trans
        self.wf = wf
        self.dpm = dpm
        if mask:
            mask = scipy.io.loadmat(r"./demo_data/fovmask_l_smaller.mat")
            self.mask = mask['fovmask_l'].astype('float32')
            # mask = np.expand_dims(mask, axis=(2,3))  # [H, W, 1, 1]

    def __len__(self):
        return len(self.data_files)
    
    def __getitem__(self, index):
        data_file = self.data_files[index]
        tmp = scipy.io.loadmat(data_file)
        inp, tag = tmp['lift_refocus'].astype('float32'), tmp['groundtruth'].astype('float32')  # [H, W, 1, 1]
        wf, dpm = tmp['wf'].astype('float32'), tmp['dpm'].astype('float32')  # [H, W, 1, 1]
        inp, tag = inp.squeeze(), tag.squeeze()  # [H, W]
        wf, dpm = wf.squeeze(), dpm.squeeze()  # [H, W]
        
        # mask
        if self.mask is not None:
            inp *= self.mask
            tag *= self.mask
        # normalization
        inp /= np.percentile(inp, 95)  # normalization
        tag /= np.percentile(tag, 95)  # normalization
        
        if self.wf:
            inp = np.stack((inp, wf), axis=-1)  # [H, W, C+1]
            tag = np.expand_dims(tag, axis=-1)  # [H, W, C]
        else:
            inp = np.expand_dims(inp, axis=-1)  # [H, W, C]
            tag = np.expand_dims(tag, axis=-1)  # [H, W, C]
        if self.dpm:
            dpm = np.expand_dims(dpm, axis=-1)
            inp = np.concatenate((inp, dpm), axis=-1)  # [H, W, C+1]
        
        c = inp.shape[-1]
        pair_t = self.trans(np.concatenate((inp, tag), axis=-1))
        inp, tag = pair_t[:c,...], pair_t[c:,...]
        return torch.Tensor(inp), torch.Tensor(tag)


class LIFTDataset_vol(torch.utils.data.Dataset):
    def __init__(self, data_files, trans, wf=False, dpm=False, mask=False, train=True):
        self.data_files = data_files
        nfov_per_file = []
        for f in data_files:  # summarize all FOVs
            tmp = scipy.io.loadmat(f)
            if tmp['lift_refocus'].ndim == 3:
                nfov_per_file.append(1)
            else:
                nfov_per_file.append(tmp['lift_refocus'].shape[-1])
        # cumsum
        self.nfov_cum_file = np.cumsum(nfov_per_file)
        
        self.wf = wf
        self.dpm = dpm
        self.trans = trans
        # self.mask = mask
        if mask:
            mask = scipy.io.loadmat(r"./demo_data/fovmask_l_smaller.mat")
            mask = mask['fovmask_l'].astype('float32')
            self.mask = np.expand_dims(mask, axis=(2,3))  # [H, W, 1, 1]

    def __len__(self):
        return self.nfov_cum_file[-1]
    
    def __getitem__(self, index):
        # get file index
        df_ind = np.searchsorted(self.nfov_cum_file, index, side='right')
        data_file = self.data_files[df_ind]
        if df_ind >= 1:
            fov_ind = index - self.nfov_cum_file[df_ind-1]
        else:  # df_ind == 0
            fov_ind = index
        tmp = scipy.io.loadmat(data_file)
        lift_input, gt = tmp['lift_refocus'].astype('float32'), tmp['groundtruth'].astype('float32')  # [H, W, D, N]
        # append dimension
        if lift_input.ndim == 3:  # N = 1
            lift_input = np.expand_dims(lift_input, axis=-1)
        if gt.ndim == 3:  # N = 1
            gt = np.expand_dims(gt, axis=-1)
        if self.mask is not None:  # mask out recon artifacts first
            lift_input *= self.mask
            gt *= self.mask
        lift_input /= np.percentile(lift_input, 95, axis=(0,1,2), keepdims=True)  # normalization
        gt /= np.percentile(gt, 95, axis=(0,1,2), keepdims=True)  # normalization
        
        n_heights = lift_input.shape[-2]
        h = np.random.randint(0, n_heights)
        inp = lift_input[..., h, fov_ind]
        tag = gt[..., h, fov_ind]
        if self.wf:
            wf = gt[..., n_heights//2, fov_ind]
            inp = np.stack((inp, wf), axis=-1)  # [H, W, C+1]
            tag = np.expand_dims(tag, axis=-1)  # [H, W, C]
        else:
            inp = np.expand_dims(inp, axis=-1)  # [H, W, C]
            tag = np.expand_dims(tag, axis=-1)  # [H, W, C]
        if self.dpm:
            dpm = np.ones_like(tag) * (h - n_heights//2)
            inp = np.concatenate((inp, dpm), axis=-1)  # [H, W, C+1]
        # inp, tag = self.trans(inp), self.trans(tag)
        c = inp.shape[-1]
        pair_t = self.trans(np.concatenate((inp, tag), axis=-1))
        inp, tag = pair_t[:c,...], pair_t[c:,...]
        return torch.Tensor(inp), torch.Tensor(tag)

