These algorithms were developed by [David McCarthy](//davidmccarthy.me.uk) during a research into a measurement system for monitoring dynamic tests of civil engineering structures using long exposure motion blurred images, named LEMBI monitoring.

### Introduction

Photogrammetry has in the past been used to monitor the static properties of laboratory samples and full-scale structures using multiple image sensors. Detecting vibrations during dynamic structural tests conventionally depends on high-speed cameras, often resulting in lower image resolutions and reduced accuracy. To overcome this limitation, a novel and radically different approach was developed to take measurements from blurred images in long-exposure photos. The motion of the structure is captured in an individual motion-blurred image, alleviating the dependence on imaging speed.

The bespoke algorithms contained herein were devised to determine the motion amplitude and direction of a circular target at each measurement point.

### Development Chapter

The code was originally written in Matlab and utilised Matlab's own Image Processing Toolbox. This project will translate the code into Python and use OpenCV, making performance improvements along the way. The intention is that the code will be published here with a demonstation dataset.
