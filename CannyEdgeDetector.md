# Canny Edge Detector Class #

![http://blog.inspirit.ru/wp-content/uploads/canny/canny_5.png](http://blog.inspirit.ru/wp-content/uploads/canny/canny_5.png)

[The Canny edge detection operator was developed by John F. Canny in 1986 and uses a multi-stage algorithm to detect a wide range of edges in images.](http://en.wikipedia.org/wiki/Canny_edge_detector)

**[Test demonstration application (pure AS3 version)](http://blog.inspirit.ru/?p=297)**

**[Small explanation of Alchemy version](http://blog.inspirit.ru/?p=336)**

### Usage info ###

```
// init Canny Detector instance
// i would recommend pre-init instance outside loops for better performance

var canny:CannyEdgeDetector = new CannyEdgeDetector();

// run Edges detection
// please note that source image should be GrayScaled before you run
// detection process. (only BLUE channel data is used)

// you also can control different detection options (via properties):
// lowThreshold - min edges threshold value to be processed
// highThreshold - max edges threshold value to be processed

/**
* @param imgPtr        mem offset to image data (uchar)
* @param edgPtr        mem offset to edges data (int)
*/
canny.detect(imgPtr, edgPtr, width, height);

```

### Download ###
**[Usage Demo Example](http://code.google.com/p/in-spirit/source/browse/trunk/classes/demo/DemoEdges.as)**

**[Pure AS3 Apparat version](http://code.google.com/p/in-spirit/source/browse/#svn%2Ftrunk%2Fclasses%2Fru%2Finspirit%2Fimage%2Fedges)**

**[Complete Alchemy source code](http://code.google.com/p/in-spirit/source/browse/#svn/trunk/projects/CannyEdgeDetector)**