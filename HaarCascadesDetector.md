# Haar Cascades Detector #

![http://farm5.static.flickr.com/4016/4474350420_58c3386fc1_o.png](http://farm5.static.flickr.com/4016/4474350420_58c3386fc1_o.png)

Simplified for the best performance implementation of [Viola-Jones object detection](http://en.wikipedia.org/wiki/Viola-Jones_object_detection_framework) using Adobe Flash.

Build using [Apparat project](http://code.google.com/p/apparat/)

### Features ###

  * Stump and Tree based cascades XML files
  * Built in Region of interest support
  * Optional start detection size, scale up speed and region analyzation step factor
  * Optional Edges Map to speed up process by skipping low-edged areas
  * Option to distribute computations between frames (u can divide each detection cycle to any amount of frames)


### Info ###

Please note:
  * you will need to use Apparat SWC libraries to compile the code
  * you will need to post-process your compiled SWF file with Apparat TDSI tool

[Source code and Demo App](http://code.google.com/p/in-spirit/source/browse/#svn%2Ftrunk%2Fprojects%2FHaarCascadesDetector)