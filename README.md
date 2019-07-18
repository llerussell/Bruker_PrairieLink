# Bruker_PrairieLink
Stream data from PrairieView into MATLAB to allow online analysis

To increase speed of data analysis immediately prior to an experiment raw acquisition samples are streamed from the microscope to custom software (via PrairieLink, Bruker). This raw stream is used to process pixel samples, construct imaging frames and perform online registration. The acquired data is directly output to a custom file format making it immediately available for analysis. 

This repository contains software to interface with PrairieView and acquire data as well as utilites to read and write to the custom (binary) file format.

Online image registration added by [Henry Dalgeliesh](https://github.com/hwpdalgleish/) using [Suite2p](https://github.com/cortex-lab/Suite2P) functions.


## Interface
![screenshot](https://i.imgur.com/QuaGNjK.png)
