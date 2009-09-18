package ru.inspirit.bitmapdata 
{
	import flash.utils.Endian;
	import cmodule.canny.CLibInit;
	import cmodule.canny.gstate;

	import com.joa_ebert.apparat.memory.Memory;

	import flash.display.BitmapData;
	import flash.filters.BlurFilter;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Point;
	import flash.utils.ByteArray;

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
	public final class CannyEdgeDetectorAlchemy 
	{
		protected const GRAYSCALE_MATRIX:ColorMatrixFilter = new ColorMatrixFilter([
			0, 0, 0, 0, 0,
            0, 0, 0, 0, 0,
            .2989, .587, .114, 0, 0,
            0, 0, 0, 0, 0
		]);
		
		protected const GAUSS_BLUR:BlurFilter = new BlurFilter( 2, 2, 2 );
		protected const ORIGIN:Point = new Point();
		
		protected const CANNY_LIB:Object = (new CLibInit()).init();
		
		protected var alchemyRAM:ByteArray;
		protected var imagePointer:uint;
		protected var edgesPointer:uint;
		
		protected var image:BitmapData;
		protected var buffer:BitmapData;
		protected var imageBytes:ByteArray;
		protected var width:int;
		protected var height:int;
		protected var area:int;
		protected var _lowThreshold:Number;
		protected var _highThreshold:Number;
		protected var _blurSize:uint = 0;
		
		public var useTDSI:Boolean = false;
		
		public function CannyEdgeDetectorAlchemy(image:BitmapData, lowThreshold:Number = 0.2, highThreshold:Number = 0.9)
		{	
			var ns:Namespace = new Namespace( "cmodule.canny" );
			alchemyRAM = (ns::gstate).ds;
			
			setupCanny(image, lowThreshold, highThreshold);
		}
		
		public function setupCanny(image:BitmapData, lowThreshold:Number = 0.2, highThreshold:Number = 0.9):void
		{
			this.image = image;
			this.lowThreshold = lowThreshold;
			this.highThreshold = highThreshold;
			
			destroyCanny();
			
			width = this.image.width;
			height = this.image.height;
			area = width * height;
			
			imageBytes = new ByteArray();
			imageBytes.endian = Endian.LITTLE_ENDIAN;
			imageBytes.length = area << 2;
			
			buffer = new BitmapData(width, height, false, 0x00);
			buffer.lock();
			
			CANNY_LIB.setupCanny(width, height, lowThreshold, highThreshold);
			imagePointer = CANNY_LIB.getImagePointer();
			edgesPointer = CANNY_LIB.getEdgesPointer();
		}
		
		public function detectEdges(edgesImage:BitmapData):void
		{
			buffer.applyFilter(image, buffer.rect, ORIGIN, GRAYSCALE_MATRIX);
			
			if(blurSize > 0)
			{
				buffer.applyFilter(buffer, buffer.rect, ORIGIN, GAUSS_BLUR);
			}
			
			var data:Vector.<uint> = buffer.getVector(buffer.rect);
			var pos:int = imagePointer;
			var i:int;
			
			if(useTDSI)
			{
				i = area;		
				while( --i > -1 )
				{
					Memory.writeInt(data[i]&0xFF, pos + (i<<2));
				}
			} 
			else 
			{
				imageBytes.position = 0;
				i = -1;
				while( ++i < area )
				{
					imageBytes.writeInt(data[i]&0xFF);
				}
				imageBytes.position = 0;
				alchemyRAM.position = pos;
				alchemyRAM.writeBytes(imageBytes);
			}
			
			CANNY_LIB.runCanny();
			
			edgesImage.lock();
			alchemyRAM.position = edgesPointer;
			edgesImage.setPixels( edgesImage.rect, alchemyRAM );
			edgesImage.unlock( edgesImage.rect );
		}
		
		public function set blurSize(value:uint):void
		{
			if(value > 0) 
			{
				_blurSize = nextPowOf2(value);
				GAUSS_BLUR.blurX = GAUSS_BLUR.blurY = _blurSize;
			} else {
				_blurSize = 0;
			}
		}
		public function get blurSize():uint 
		{
			return _blurSize;
		}

		public function set lowThreshold(value:Number):void
		{
			_lowThreshold = value;
			if(_lowThreshold > _highThreshold){
				value = _lowThreshold;
				_lowThreshold = _highThreshold;
				_highThreshold = value;
			}
			CANNY_LIB.setLowThreshold(_lowThreshold);
			CANNY_LIB.setHighThreshold(_highThreshold);
		}
		public function get lowThreshold():Number
		{
			return _lowThreshold;
		}

		public function set highThreshold(value:Number):void
		{
			_highThreshold = value;
			if(_lowThreshold > _highThreshold){
				value = _lowThreshold;
				_lowThreshold = _highThreshold;
				_highThreshold = value;
			}
			CANNY_LIB.setLowThreshold(_lowThreshold);
			CANNY_LIB.setHighThreshold(_highThreshold);
		}
		public function get highThreshold():Number
		{
			return _highThreshold;
		}
		
		public function destroyCanny():void
		{
			if(buffer) buffer.dispose();
			if(imageBytes) imageBytes.length = 0;
			CANNY_LIB.destroyCanny();
		}
		
		protected function nextPowOf2(value:uint):uint
        {
			--value;
			value |= value >>> 0x01;
			value |= value >>> 0x02;
			value |= value >>> 0x04;
			value |= value >>> 0x08;
			value |= value >>> 0x10;
			++value;
			
			return value;
        }
	}
}
