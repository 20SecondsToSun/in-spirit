## Usage ##

```
var bmp1:BitmapData = new BitmapData(2800, 2800, false, 0xFF0000);
var bmp2:BitmapData = new BitmapData(2800, 2800, false, 0x00FF00);
var bmp3:BitmapData = new BitmapData(2800, 2800, false, 0x0000FF);
var bmp4:BitmapData = new BitmapData(2800, 2800, false, 0xFFFF00);
var bmp5:BitmapData = new BitmapData(2800, 2800, false, 0xFF00FF);
var bmp6:BitmapData = new BitmapData(2800, 2800, false, 0x00FFFF);
 
//
// Simple one call encoding
//

// I recommend to pre-init instance for example at class initiation
// and then just use "encode" method. It would be way faster
var je:JPGEncoder = new JPGEncoder(90);
var jpgFileBA:ByteArray = je.encode(bmp1);

//
// Async encoding
//
var je_async:JPGAsyncEncoder = new JPGAsyncEncoder(90);
je_async.addEventListener(Event.COMPLETE, onEncoded);
je_async.addEventListener(ProgressEvent.PROGRESS, onEncodeProgress);
 
//
je_async.blocksPerIteration = 196;

//
// Simple Async encoding
//
je_async.encodeAsync(bmp1);

//
// Merging multiple BitmapData to single JPG file
//
je_async.encodeMultiToOne(
				[
				[bmp1, bmp2, bmp3],
				[bmp4, bmp5, bmp6]
				]);
 
function onEncoded(e:Event = null):void 
{
	trace('JPG ENCODED');
	// here is our JPG file ByteArray data
	// je_async.encodedImageData
}
 
function onEncodeProgress(e:ProgressEvent):void 
{
	trace('Encoding JPG: ' + String( Math.round(e.bytesLoaded / e.bytesTotal * 100) ) + '%');
}
```

## Download ##
[Download SWC lib](http://in-spirit.googlecode.com/files/jpgencoder.zip)