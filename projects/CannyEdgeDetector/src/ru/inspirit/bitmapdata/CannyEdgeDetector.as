package ru.inspirit.bitmapdata 
{
	import flash.display.BitmapData;
	import flash.display.Shader;
	import flash.display.ShaderJob;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	/**
	 * released under MIT License (X11)
	 * http://www.opensource.org/licenses/mit-license.php
	 * 
	 * This class provides a configurable implementation of the Canny edge
	 * detection algorithm. This classic algorithm has a number of shortcomings,
	 * but remains an effective tool in many scenarios.
	 * 
	 * @author Eugene Zatepyakin
	 * @see http://blog.inspirit.ru
	 */
	public final class CannyEdgeDetector 
	{
		[Embed("../../../../pbj/Gray.pbj", mimeType="application/octet-stream")] private var Gray:Class;
		[Embed("../../../../pbj/GaussBlur.pbj", mimeType="application/octet-stream")] private var GaussBlur:Class;
		[Embed("../../../../pbj/EdgeDiff.pbj", mimeType="application/octet-stream")] private var EdgeDiff:Class;
		[Embed("../../../../pbj/EdgeMagnitude.pbj", mimeType="application/octet-stream")] private var EdgeMagnitude:Class;
		[Embed("../../../../pbj/BytesToBitmap.pbj", mimeType="application/octet-stream")] private var BytesToBitmap:Class;
		[Embed("../../../../pbj/Hysteresis.pbj", mimeType="application/octet-stream")] private var Hysteresis:Class;
		
		protected var Gray_shader:Shader;
		protected var Gray_job:ShaderJob;
		
		protected var GaussBlur_shader:Shader;
		protected var GaussBlur_job:ShaderJob;
		
		protected var EdgeDiff_shader:Shader;
		protected var EdgeDiff_job:ShaderJob;
		
		protected var EdgeMagnitude_shader:Shader;
		protected var EdgeMagnitude_job:ShaderJob;
		
		protected var BytesToBitmap_shader:Shader;
		protected var BytesToBitmap_job:ShaderJob;
		
		protected var Hysteresis_shader:Shader;
		protected var Hysteresis_job:ShaderJob;
		
		protected var imgGrayResult:ByteArray;
		protected var imgBlurResult:ByteArray;
		protected var edgeDiffResult:ByteArray;
		protected var edgeMagResult:ByteArray;
		
		protected var image:BitmapData;
		protected var dataBmd:BitmapData;
		
		protected var width:int;
		protected var height:int;
		protected var size:int;
		protected var rect:Rectangle;
		protected var contrastMult:Number;
		
		protected var _lowThreshold:Number;
		protected var _highThreshold:Number;
		protected var _doNormalizeContrast:Boolean = false;
		
		public var data:Vector.<uint>;
		public var magnitude:Vector.<uint>;
		
		public function CannyEdgeDetector(image:BitmapData, lowThreshold:Number = 0.01, highThreshold:Number = 0.1)
		{
			this.image = image;
			this.width = image.width;
			this.height = image.height;
			this.size = width * height;
			this.rect = new Rectangle(0, 0, width, height);
			this.contrastMult = 255 / size;
			
			this._highThreshold = highThreshold;
			this._lowThreshold = lowThreshold;
			
			this.data = new Vector.<uint>(size, true);
			
			this.dataBmd = new BitmapData(width, height, false, 0x00);
			this.dataBmd.lock();
			
			initShaders();
			initKernels();
		}
		
		public function detectEdges(targetBmd:BitmapData, binary:Boolean = true):void
		{			
			if(_doNormalizeContrast)
			{
				Gray_job = new ShaderJob(Gray_shader, dataBmd, width, height);
				Gray_job.start(true);
				
				dataBmd.setVector(rect, normalizeContrast(dataBmd.getVector(rect)));
			} else {
				Gray_job = new ShaderJob(Gray_shader, imgGrayResult, width, height);
				Gray_job.start(true);
			}
			
			GaussBlur_job = new ShaderJob(GaussBlur_shader, imgBlurResult, width, height);
			GaussBlur_job.start(true);
			
			EdgeDiff_job = new ShaderJob(EdgeDiff_shader, edgeDiffResult, width, height);
			EdgeDiff_job.start(true);
			
			EdgeMagnitude_job = new ShaderJob(EdgeMagnitude_shader, edgeMagResult, width, height);
			EdgeMagnitude_job.start(true);
			
			if(binary)
			{
				BytesToBitmap_job = new ShaderJob(BytesToBitmap_shader, dataBmd, width, height);
				BytesToBitmap_job.start(true);
				
				magnitude = _doNormalizeContrast ? normalizeContrast(dataBmd.getVector(rect)) : dataBmd.getVector(rect);
			
				var max:uint = 0;
				var b:uint;
				var i:int = size;
				while( --i > -1 )
				{
					data[i] = 0;
					b = magnitude[i] & 0xFF;
					magnitude[i] = b;
					if(b > max) max = b;
				}
				
				var low:int = max * _lowThreshold;
				var high:int = max * _highThreshold;
				
				if(low < 1) low = 1;
				if(high < 1) high = 1;
				
				i = 0;
				for (var y:int = 0; y < height; ++y)
				{
					for (var x:int = 0; x < width; ++x, ++i) 
					{
						if (data[i] == 0 && magnitude[i] >= high) 
						{
							hysteresisFollow(data, magnitude, width, height, x, y, i, low);
						}
					}
				}
				
				targetBmd.lock();
				targetBmd.setVector(rect, data);
				targetBmd.unlock();
			} else {
				targetBmd.lock(); // not sure we really need it
				BytesToBitmap_job = new ShaderJob(BytesToBitmap_shader, targetBmd, width, height);
				BytesToBitmap_job.start(true);
				targetBmd.unlock();
			}
		}
		
		public function detectEdgesBold(targetBmd:BitmapData):void
		{
			if(_doNormalizeContrast)
			{
				Gray_job = new ShaderJob(Gray_shader, dataBmd, width, height);
				Gray_job.start(true);
				
				dataBmd.setVector(rect, normalizeContrast(dataBmd.getVector(rect)));
				
			} else {
				Gray_job = new ShaderJob(Gray_shader, imgGrayResult, width, height);
				Gray_job.start(true);
			}
			
			GaussBlur_job = new ShaderJob(GaussBlur_shader, imgBlurResult, width, height);
			GaussBlur_job.start(true);
			
			EdgeDiff_job = new ShaderJob(EdgeDiff_shader, edgeDiffResult, width, height);
			EdgeDiff_job.start(true);
			
			EdgeMagnitude_job = new ShaderJob(EdgeMagnitude_shader, edgeMagResult, width, height);
			EdgeMagnitude_job.start(true);
			
			targetBmd.lock(); // not sure we really need it
			Hysteresis_job = new ShaderJob(Hysteresis_shader, targetBmd, width, height);
			Hysteresis_job.start(true);	
			targetBmd.unlock();
		}
		
		public function set lowThreshold(value:Number):void
		{
			_lowThreshold = value;
			if(_lowThreshold > _highThreshold){
				value = _lowThreshold;
				_lowThreshold = _highThreshold;
				_highThreshold = value;
			}
			
			Hysteresis_shader.data.low.value = [ _lowThreshold ];
			Hysteresis_shader.data.high.value = [ _highThreshold ];
		}
		
		public function set highThreshold(value:Number):void
		{
			_highThreshold = value;
			if(_lowThreshold > _highThreshold){
				value = _lowThreshold;
				_lowThreshold = _highThreshold;
				_highThreshold = value;
			}
			
			Hysteresis_shader.data.low.value = [ _lowThreshold ];
			Hysteresis_shader.data.high.value = [ _highThreshold ];
		}
		
		public function set doNormalizeContrast(value:Boolean):void
		{
			_doNormalizeContrast = value;
			if(_doNormalizeContrast){
				GaussBlur_shader.data.src.input = dataBmd;
			} else {
				GaussBlur_shader.data.src.input = imgGrayResult;
			}
		}
		
		public function get lowThreshold():Number
		{
			return _lowThreshold;
		}
		
		public function get highThreshold():Number
		{
			return _highThreshold;
		}
		
		public function get doNormalizeContrast():Boolean
		{
			return _doNormalizeContrast;
		}
		
		protected function hysteresisFollow(data:Vector.<uint>, magnitude:Vector.<uint>, width:int, height:int, x1:int, y1:int, i1:int, threshold:int):void
		{
			var x0:int = x1 == 0 ? x1 : x1 - 1;
			var x2:int = x1 == width - 1 ? x1 : x1 + 1;
			var y0:int = y1 == 0 ? y1 : y1 - 1;
			var y2:int = y1 == height -1 ? y1 : y1 + 1;
			var i2:int;
			var x:int, y:int;
			
			data[i1] = 0xFFFFFF;
			for (y = y0; y <= y2; ++y)
			{
				i2 = int(x0 + y * width);
				for (x = x0; x <= x2; ++x, ++i2)
				{
					if ((y != y1 || x != x1)
						&& data[i2] == 0 
						&& magnitude[i2] >= threshold) {
						hysteresisFollow(data, magnitude, width, height, x, y, i2, threshold);
						return;
					}
				}
			}
		}
		
		protected function initShaders():void
		{
			// init shaders result holders
			imgGrayResult = new ByteArray();
			imgBlurResult = new ByteArray();
			edgeDiffResult = new ByteArray();
			edgeMagResult = new ByteArray();
			imgGrayResult.endian = imgBlurResult.endian = edgeDiffResult.endian = edgeMagResult.endian = Endian.LITTLE_ENDIAN;
			
			// init shaders
			Gray_shader = new Shader(new Gray() as ByteArray);
			Gray_shader.data.src.width = width;
			Gray_shader.data.src.height = height;
			Gray_shader.data.src.input = image;
			
			GaussBlur_shader = new Shader(new GaussBlur() as ByteArray);
			GaussBlur_shader.data.src.width = width;
			GaussBlur_shader.data.src.height = height;
			GaussBlur_shader.data.src.input = imgGrayResult;
			
			EdgeDiff_shader = new Shader(new EdgeDiff() as ByteArray);
			EdgeDiff_shader.data.src.width = width;
			EdgeDiff_shader.data.src.height = height;
			EdgeDiff_shader.data.src.input = imgBlurResult;
			
			EdgeMagnitude_shader = new Shader(new EdgeMagnitude() as ByteArray);
			EdgeMagnitude_shader.data.src.width = width;
			EdgeMagnitude_shader.data.src.height = height;
			EdgeMagnitude_shader.data.src.input = edgeDiffResult;
			
			BytesToBitmap_shader = new Shader(new BytesToBitmap() as ByteArray);
			BytesToBitmap_shader.data.src.width = width;
			BytesToBitmap_shader.data.src.height = height;
			BytesToBitmap_shader.data.src.input = edgeMagResult;
			
			// this one could be used if you want to get bold edges
			Hysteresis_shader = new Shader(new Hysteresis() as ByteArray);
			Hysteresis_shader.data.src.width = width;
			Hysteresis_shader.data.src.height = height;
			Hysteresis_shader.data.src.input = edgeMagResult;
		}
		
		protected function normalizeContrast(data:Vector.<uint>):Vector.<uint>
		{
			var p:int, a:int, b:int;
			var T1:int = 0.05 * size;
			var T2:int = 0.95 * size;
			var histogram:Vector.<int> = new Vector.<int>(256, true);
			var i:int = 256;
			
			while( --i > -1 ) 
			{
				histogram[i] = 0;
			}
			
			i = size;
			while( --i > -1 ) 
			{
				p = data[i] & 0xFF;
				data[i] = p;
				histogram[ p ]++;
			}			
			
			var sum:int = 0;
			for( i = 0; i < 256; ++i )
			{
				sum += histogram[i];
				if(sum >= T1)
				{
					a = i;
					break;
				}
			}
			
			i++;
			for( ; i < 256; ++i )
			{
				sum += histogram[i];
				if(sum >= T2)
				{
					b = i;
					break;
				}
			}
			
			var scale:Number = 255 / (b - a);
			for( i = 0; i < size; ++i )
			{
				p = int( (data[i] - a) * scale + .5 );
				if(p < 0) p = 0;
				if(p > 255) p = 255;
				data[i] = p << 16 | p << 8 | p;
			}
			
			return data;
		}
		
		protected function initKernels(gaussianKernelRadius:Number = 2, gaussianKernelWidth:int = 10):void
		{
			const CUT_OFF:Number = 0.005;
			var kernel:Vector.<Number> = new Vector.<Number>(gaussianKernelWidth, true);
			var diffKernel:Vector.<Number> = new Vector.<Number>(gaussianKernelWidth, true);
			var kwidth:int;
			for (kwidth = 0; kwidth < gaussianKernelWidth; ++kwidth)
			{
				var g1:Number = gaussian(kwidth, gaussianKernelRadius);
				if (g1 <= CUT_OFF && kwidth >= 2) break;
				var g2:Number = gaussian(kwidth - 0.5, gaussianKernelRadius);
				var g3:Number = gaussian(kwidth + 0.5, gaussianKernelRadius);
				kernel[kwidth] = (g1 + g2 + g3) / 3 / (6.283185 * gaussianKernelRadius * gaussianKernelRadius);
				diffKernel[kwidth] = g3 - g2;
			}
			
			GaussBlur_shader.data.weight0.value = [ kernel[0] ];
			GaussBlur_shader.data.weight1.value = [ kernel[1] ];
			GaussBlur_shader.data.weight2.value = [ kernel[2] ];
			GaussBlur_shader.data.weight3.value = [ kernel[3] ];
			GaussBlur_shader.data.weight4.value = [ kernel[4] ];
			GaussBlur_shader.data.weight5.value = [ kernel[5] ];
			GaussBlur_shader.data.weight6.value = [ kernel[6] ];
			
			//EdgeDiff_shader.data.weight0.value = [ diffKernel[0] ]; // this one is 0, so no use
			EdgeDiff_shader.data.weight1.value = [ diffKernel[1] ];
			EdgeDiff_shader.data.weight2.value = [ diffKernel[2] ];
			EdgeDiff_shader.data.weight3.value = [ diffKernel[3] ];
			EdgeDiff_shader.data.weight4.value = [ diffKernel[4] ];
			EdgeDiff_shader.data.weight5.value = [ diffKernel[5] ];
			EdgeDiff_shader.data.weight6.value = [ diffKernel[6] ];
		}
		
		protected function gaussian(x:Number, sigma:Number):Number
		{
			return Math.exp(-(x * x) / (2 * sigma * sigma));
		}
	}
}
