# Line Segment Detector #

![http://blog.inspirit.ru/wp-content/uploads/aslsd/aslsd.jpg](http://blog.inspirit.ru/wp-content/uploads/aslsd/aslsd.jpg)

[Original implementation.](http://www.ipol.im/pub/algo/gjmr_line_segment_detector)

**[Test demonstration application](http://blog.inspirit.ru/?p=432)**

### Usage info ###

```
// init ASLSD instance
// you can change source Image at anytime using "source" property
// there are lots of different options available and I set the recommended by default
// please see source code to learn what each options is responsible for

var lsd:ASLSD = new ASLSD();
lsd.source = bitmapDataObject;

var res:Vector.<int> = lsd.getLineSegments();
var i:int = lsd.segmentsCount;
var j:int = -1;
			
while( --i > -1 )
{
    var x1:int = res[++j];
    var y1:int = res[++j];
    var x2:int = res[++j];
    var y2:int = res[++j];
    drawLine(x1, y1, x2, y2);
}

// always clear instance memory usage if you don't plan to use it any more

lsd.dispose();
```

### Async usage ###
```

var lsd:ASLSD = new ASLSD();
lsd.source = bitmapDataObject;

lsd.addEventListener(Event.COMPLETE, onAsyncEnd);
lsd.addEventListener(ProgressEvent.PROGRESS, onAsyncProgress);

lsd.getLineSegmentsAsync();

function onAsyncProgress(e:ProgressEvent):void
{
    //'PROGRESS: ' + String(int(e.bytesLoaded / e.bytesTotal * 100 + 0.5));
}

function onAsyncEnd(e:Event):void
{
    var res:Vector.<int> = lsd.lineSegments;
    var i:int = lsd.segmentsCount;
    var j:int = -1;
			
    while( --i > -1 )
    {
        var x1:int = res[++j];
        var y1:int = res[++j];
        var x2:int = res[++j];
        var y2:int = res[++j];
        drawLine(x1, y1, x2, y2);
    }
}
```

### Download ###
**[Compiled SWC Lib](http://in-spirit.googlecode.com/files/ASLSD.zip)**

**[Complete source code](http://code.google.com/p/in-spirit/source/browse/#svn/trunk/projects/ASLSD)**