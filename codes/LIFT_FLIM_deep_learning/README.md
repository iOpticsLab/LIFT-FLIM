## LIFT-FLIM

This repository is for LIFT-FLIM reconstruction reported in the paper: [Light-field tomographic fluorescence lifetime imaging microscopy](https://doi.org/10.21203/rs.3.rs-2883279/v1) by Yayao Ma et al. 

Main code taken from the [PixelCNN++.](https://arxiv.org/pdf/1701.05517.pdf)

One pre-trained model and demo data are available under `models` and `demo_data` folders.


### Environment

All codes were implemented and tested on the environment below:
- Windows 10 22H2
- Intel(R) Xeon(R) W-2195 CPU
- NVIDIA GeForce RTX 2080 Ti GPU
- 256 GB RAM
- Python 3.9.16
- PyTorch 1.13.1+cu117

Other necessary packages can be found in `requirements.txt`.


### Running the code

First set up parameters and training data path (see TODOs in `train.py`). The data should be organized in the following format:
- training data saved in `.mat` format
- each file contains
    * one slice of LIFT image `lift_refocus` (at certain z position)
    * corresponding WF image `wf` (at z=0)
    * ground truth WF image (at the same z position)
    * a digital propagation matrix `dpm`
- `dpm` may not be necessary for autofocusing tasks

To start training, simply run
```
python train.py
```


### Testing

To test, download the pre-trained model and demo data, and run
```
python test.py
```
The results will be saved under `outputs` folder.

The demo data demonstrates the autofocusing task presented in the paper. LIFT and WF images were captured on a tumor sample. The defocused range is from 0um to +30um. Objective: 20x, NA = 0.8

