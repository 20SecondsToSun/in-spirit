# PNG Encoder #

This package allows you asynchronously encode and merge several/single BitmapData objects into single PNG image.
It is a very easy task until you need to save a really large/huge image file (for print purpose or whatever). As far as Flash don’t have ability to compress/deflate ByteArrays in append way or simply partly we surely will crash flash player while compressing image data for image larger then 10.000×10.000 px. I've compiled custom ZLIB library using Alchemy to be able to compress image data asynchronously during encoding.
Along with asynchronous methods the package also allows you encode PNG files in normal way like default Adobe encoder but bringing more power to this operations with custom ZLIB compression levels and PNG Filters.

### Features ###

  * Synch and Asynchronous encoding
  * Merging several BitmapData objects into single PNG image file
  * Custom compression level via ZLIB
  * Custom processing PNG Filters

### Usage info ###

```
var png:PNGEncoder = new PNGEncoder();
png.addEventListener(Event.COMPLETE, onEncoded);
png.addEventListener(ProgressEvent.PROGRESS, onEncodeProgress);
 
// filter options are available via static properties
// PNGEncoder.FILTER_NONE
// PNGEncoder.FILTER_SUB
// PNGEncoder.FILTER_UP
// PNGEncoder.FILTER_AVERAGE
// PNGEncoder.FILTER_PAETH
 
// we can encode in various ways
// Simple static synch encode
 
PNGEncoder.encode(source:BitmapData, opaque:Boolean = false, comressLevel:int = -1, filter:int = 0):ByteArray;
 
// Asynch encode
// you should provide listeners to catch encoding progress and result
 
png.encodeAsync(source:BitmapData, opaque:Boolean = false, comressLevel:int = -1, filter:int = 0);
 
// Merging multiple Bitmapdata objects into single PNG image file asynchronously
// you should provide listeners to catch encoding progress and result
// you also should provide callback function for returning Bitmapdata objects for each row
 
var currInfo:PNGEncoderInfo = new PNGEncoderInfo(
						resultImageWidth:uint, resultImageHeight:uint,
						numberOfColumns:uint, numberOfRows:uint,
						getNextBitmapsRow:Function, opaque:Boolean,
						compressLevel:int, filter:int);
png.encodeMultiToOne(currInfo);
 
function getNextBitmapsRow(info:PNGEncoderInfo, yi:uint):Vector.<BitmapData>
{
	var currBitmapsRow:Vector.<BitmapData> = new Vector.<BitmapData>();
	// yi argument is current row index
	// info.xn - is number of BitmapData objects in image row
	for (var j:int = 0; j < info.xn; ++j) 
	{
		currBitmapsRow[j] = new BitmapData(800, 600, false, int(Math.random() * 0xFFFFFF));
	}
 
	return currBitmapsRow;
}
 
function onEncoded(e:Event = null):void 
{
	// here is our encoded PNG file ByteArray
	var data:ByteArray = PNGEncoder.encodedPNGData;
}
function onEncodeProgress(e:ProgressEvent):void 
{
	trace('ENCODING PNG: ' + String( Math.round(e.bytesLoaded / e.bytesTotal * 100) ) + '%');
}
```

### Download ###

[PNGEncoder.swc download](http://in-spirit.googlecode.com/files/PNGEncoder.swc.zip)