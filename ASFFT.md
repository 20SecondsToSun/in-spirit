#summary Fast Fourier Transform for Flash.
#labels Featured

# ASFFT #

![http://farm5.static.flickr.com/4065/4419633556_3deaf1e791_o.png](http://farm5.static.flickr.com/4065/4419633556_3deaf1e791_o.png)

A [Fast Fourier transform (FFT)](http://en.wikipedia.org/wiki/Fast_Fourier_transform) is an efficient algorithm to compute the discrete Fourier transform (DFT) and its inverse.

The lib consists of 2 classes _FFT2D_ and _FFT_. First one is to work with two dimensional data mostly presented as images. The second one is for streaming (or not) one dimensional data. Usually used in sound signal manipulations/transformation.

### Features ###

  * Forward and Inverse transforms
  * Magnitude of Real and Imaginary parts calculation
  * FFT Sound Spectrum analyzer class
  * Phase of Real and Imaginary parts calculation
  * 2 and 1 dimensional data handling (images/sound)
  * RGB and Single Channel (BLUE) data manipulation in images
  * Output/input as ByteArray, Vector and BitmapData objects

### Usage info ###

```
//
// Example of FFT and FFTSpectrumAnalyzer usage
//

var fft:FFT = new FFT();

// init fft instance with required length of data
// and specify number of channels

fft.init(2048, 2);

// init FFT Spectrum helper instance
// you should provide FFT instance to work with and desired sample Rate

var fftHelp:FFTSpectrumAnalyzer = new FFTSpectrumAnalyzer(fft, 44100);

// lets init Logarithmic Average mode to get more visually correct spectrum
// you should provide min bandwidth to include and number of bands
// you want to divide each octave to

fftHelp.initLogarithmicAverages(22, 3);

// create buffer to handle sound data before/after FFT analysis
// please note that all data that come to/from FFT Lib is LITTLE_ENDIAN
var buffer:ByteArray = new ByteArray();
buffer.endian = Endian.LITTLE_ENDIAN;

// now we create new sound object and add SAMPLE_DATA event

sound = new Sound();
sound.addEventListener( SampleDataEvent.SAMPLE_DATA, onSampleData);
sound.play();

// here is actual analysis take place

function sampleData( event:SampleDataEvent ):void
{
    // imagine that you extract data from loaded MP3 sound object
    // into out playing sound

    var read:int = mp3.extract( buffer, 2048 );

    // now we send our data to FFT instance

    buffer.position = 0;
    fft.setStereoRAWDataByteArray(buffer);

    // perform forward FFT to calculate Real and Imaginary parts
    // after forward we can analyze sound spectrum

    fft.forwardFFT();
    
    // as far as we set to work with averages
    // this method call will return average spectrum data

    var spectr_data:ByteArray = fftHelp.analyzeSpectrum();
    var spectrLength:int = spectr_data.length >> 2;

    // now we can draw the result spectrum the way
    // you do it with built in Sound Spectrum

    for(var i:int = 0; i < spectrLength; ++i)
    {
        var spectrBand:Number = spectr_data.readFloat();
        // draw it
    }

    // now we should put data into our playing sound
    // we have to perform inverse FFT to get original data

    fft.inverseFFT();

    buffer.position = 0;
    buffer.writeBytes(fft.getStereoRAWDataByteArray());
    buffer.position = 0;
    for(i = 0; i < 2048; ++i)
    {
        event.data.writeFloat(buffer.readFloat());
        event.data.writeFloat(buffer.readFloat());
    }
}
```

---

```
//
// Example of FFT2D usage
//

var fft2d:FFT2D = new FFT2D();

// firt we should init some data in lib
fft2d.initFromRGBBitmap(ImageBitmapData);

// you also can initiate without any bitmap
// see sources for the arguments info
// fft2d.init(width, height, 3);

// calculate FFT Real and Imaginary parts
fft2d.forwardFFT();

// extract Real part
var data_real:ByteArray = fft2d.getDataByteArray(FFT2D.REAL_FFT_DATA);

// allocate object for manipulation result
var out:ByteArray = new ByteArray();
out.endian = Endian.LITTLE_ENDIAN;

// FFT works only with data dimensions of power of 2
// so if image size for example is 320x440
// in FFT it will be presented with dimensions of next power of 2
// in this particular example 512x512

var w2:int = MemoryMath.nextPow2(ImageBitmapData.width);
var h2:int = MemoryMath.nextPow2(ImageBitmapData.height);

// here is the most interesting part
// due to data format (r, g, b, r, g, b floats)
// we can pass that ByteArray object directly to Pixel Bender
lowPassFilter_shader.data.src.input = data_real;
_shaderJob = new ShaderJob(lowPassFilter_shader, out, w2, h2);
_shaderJob.start(true);

// and now we can set result data back to FFT instance
fft2d.setDataByteArray(out, FFT2D.REAL_FFT_DATA);

// the same operations can be done with any of presented data
// after you finish all manipulations
// you can see the result image by applying inverse transform
fft2d.inverseFFT();

// and plot original image to BitmapData
fft2d.draw(FFT2D.REAL_RAW_DATA, transformedImageBitmapData, false, false);

```

I recommend to use compiled ASFFT.swc as far as the Lib is build using Alchemy and TDSI to optimize performance. And if you don't want to process you project with TDSI every compilation simply include ASFFT.swc in your source path.

[ASFFT SWC Lib project sources](http://code.google.com/p/in-spirit/source/browse/#svn/trunk/projects/ASFFT)<br>
<a href='http://in-spirit.googlecode.com/files/ASFFT.swc.zip'>ASFFT.swc download</a>