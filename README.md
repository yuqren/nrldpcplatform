# 5G-NR LDPC Decoding
Codes for paper "Edge-Spreading Raptor-Like LDPC Codes for 6G Wireless Systems, " arXiv preprint arXiv:2410.16875 (2024) [[paper]](https://arxiv.org/abs/2410.16875) to ensure consistency in baseline performance.

If you find them useful, we would sincerely appreciate it if you could cite:
```
@article{ren2024edge,
  title={Edge-Spreading Raptor-Like LDPC Codes for 6G Wireless Systems},
  author={Ren, Yuqing and Zhang, Leyu and Shen, Yifei and Song, Wenqing and Boutillon, Emmanuel and Balatsoukas-Stimming, Alexios and Burg, Andreas},
  journal={arXiv preprint arXiv:2410.16875},
  year={2024}
}
```

We have the following directories:
* [common](common): general files
* [decoding](decoding): layered normalized min-sum (L-NMS) decoding
* [nr_ldpc_platform.m](nr_ldpc_platform.m): main file

Please run nr_ldpc_platform.m to start the simulation.

Here are some optional configurations for 5G-NR LDPC decoding. The settings align with C_{5G}^{I} in [[paper]](https://arxiv.org/abs/2410.16875), which adopts a multi-core architecture.
```
NR-LDPC (R=0.87)
TxRx.bgn         = 1;                 
TxRx.Z           = 384;               
TxRx.CR          = 0.863;              
TxRx.punc        = 2;                 
TxRx.core        = 10;                
TxRx.norm        = 3/4;               
TxRx.SNR         = 1;                 
TxRx.SNRrange    = 4.25:0.05:5.15;      
TxRx.maxIteras   = 5;                 
TxRx.ToolboxFlag = 0;


NR-LDPC (R=0.8)
TxRx.bgn         = 1;                 
TxRx.Z           = 384;               
TxRx.CR          = 0.8;              
TxRx.punc        = 2;                 
TxRx.core        = 10;                
TxRx.norm        = 3/4;               
TxRx.SNR         = 1;                 
TxRx.SNRrange    = 3.65:0.05:4.7;      
TxRx.maxIteras   = 5;                 
TxRx.ToolboxFlag = 0;


NR-LDPC (R=0.72)
TxRx.bgn         = 1;                 
TxRx.Z           = 384;               
TxRx.CR          = 0.718;              
TxRx.punc        = 2;                 
TxRx.core        = 10;                
TxRx.norm        = 3/4;               
TxRx.SNR         = 1;                 
TxRx.SNRrange    = 3.15:0.05:4;      
TxRx.maxIteras   = 5;                 
TxRx.ToolboxFlag = 0;


NR-LDPC (R=0.63)
TxRx.bgn         = 1;                 
TxRx.Z           = 384;               
TxRx.CR          = 0.625;              
TxRx.punc        = 2;                 
TxRx.core        = 10;                
TxRx.norm        = 3/4;               
TxRx.SNR         = 1;                 
TxRx.SNRrange    = 2.85:0.05:3.75;      
TxRx.maxIteras   = 5;                 
TxRx.ToolboxFlag = 0;


NR-LDPC (R=0.52)
TxRx.bgn         = 1;                 
TxRx.Z           = 384;               
TxRx.CR          = 0.515;              
TxRx.punc        = 2;                 
TxRx.core        = 10;                
TxRx.norm        = 3/4;               
TxRx.SNR         = 1;                 
TxRx.SNRrange    = 2.45:0.05:3.45;      
TxRx.maxIteras   = 5;                 
TxRx.ToolboxFlag = 0;


NR-LDPC (R=0.34)
TxRx.bgn         = 1;                 
TxRx.Z           = 384;               
TxRx.CR          = 0.342;              
TxRx.punc        = 2;                 
TxRx.core        = 10;                
TxRx.norm        = 3/4;               
TxRx.SNR         = 1;                 
TxRx.SNRrange    = 2:0.05:2.8;      
TxRx.maxIteras   = 5;                 
TxRx.ToolboxFlag = 0;
```

