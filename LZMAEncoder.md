# LZMA Encoder #

### Usage info ###

```
// init LZMAEncoder instance

var lzma_enc:LZMAEncoder = new LZMAEncoder();

// single call interface
lzma_enc.encode(input_data:ByteArray, output_data:ByteArray);

// -----------------
// Async usage
// -----------------

lzma_enc.addEventListener(Event.COMPLETE, onAsyncEnd);
lzma_enc.addEventListener(ProgressEvent.PROGRESS, onAsyncProgress);

lzma_enc.encodeAsync(input_data:ByteArray, output_data:ByteArray);

function onAsyncProgress(e:ProgressEvent):void
{
    //'PROGRESS: ' + String(int(e.bytesLoaded / e.bytesTotal * 100 + 0.5));
}

function onAsyncEnd(e:Event):void
{
    // use your output ByteArray object
}

// You can also break async process
lzma_enc.stopAsync();

```


### Download ###
**[Compiled SWC Lib](http://in-spirit.googlecode.com/files/LZMAEncoder.zip)**