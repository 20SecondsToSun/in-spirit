package ru.inspirit.motion 
{
	import flash.display.BitmapData;
	import flash.filters.BlurFilter;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	/**
	 * @author Eugene Zatepyakin
	 */
	public class MotionTracker 
	{
		private static const ORIGIN:Point = new Point();
		
		// Blur
		private static const BLUR:BlurFilter = new BlurFilter(2, 2, 2);
		
		// Grayscale Filter
		private static const GRAYSCALE_MATRIX:ColorMatrixFilter = new ColorMatrixFilter([
			0.212671, 0.715160, 0.072169, 0, 0,
			0.212671, 0.715160, 0.072169, 0, 0,
			0.212671, 0.715160, 0.072169, 0, 0,
			0, 0, 0, 1, 0
		]);
		
		private static const FLOOD_FILL_COLOR:uint = 0xFF0000;
		private static const PROCESSED_COLOR:uint = 0x0000FF;
		
		// Pixelate Filter
		private var _pixelSize:uint = 8;
		private var _lowMatrix:Matrix;
		
		// Threshold Filter
		private var _thresholdValue:uint = 15;
		
		private var _old:BitmapData;
		private var _new:BitmapData;
		private var _ow:int;
		private var _oh:int;
		private var _sw:int;
		private var _sh:int;
		private var _pixelsChanged:int;
		private var _prevFrameDifference:Vector.<uint>;
		private var _currentFrameThreshold:Vector.<uint>;
		private var _currentFrameDilatated:Vector.<uint>;
		private var _currentFrameData:Vector.<uint>;
		private var _frameSize:int;
		private var _tempCurr:BitmapData;
		
		public var maxBlobs:int = 10;
		public var minBlobSize:int = 10;
		public var maxBlobSize:int = 100; 
		public var minWidth:int = 40;
		public var minHeight:int = 30;
		public var maxWidth:int = 320;
		public var maxHeight:int = 240;
		
		public var _blobs:Vector.<MotionBlob>;

		public function MotionTracker(width:int = 320, height:int = 240, pixelateSize:uint = 8, thresholdValue:uint = 15)
		{
			_pixelSize = pixelateSize;
			_lowMatrix = new Matrix( 1 / _pixelSize, 0, 0, 1 / _pixelSize, 0, 0 );
			
			_ow = width;
			_oh = height;
			
			_sw = int(_ow / _pixelSize + .5);
			_sh = int(_oh / _pixelSize + .5);
			
			_new = new BitmapData(_sw, _sh, false, 0x00);
			_old = new BitmapData(_sw, _sh, false, 0x00);
			_tempCurr = new BitmapData(_sw, _sh, false, 0x00);
			_new.lock();
			_old.lock();
			_tempCurr.lock();
			
			_frameSize = _sw * _sh;
			
			minBlobSize = _frameSize * .015;
			maxBlobSize = _frameSize * .3;
			
			_prevFrameDifference = new Vector.<uint>(_frameSize, true);
			_currentFrameData = new Vector.<uint>(_frameSize, true);
			_currentFrameThreshold = new Vector.<uint>(_frameSize, true);
			_currentFrameDilatated = new Vector.<uint>(_frameSize, true);
			
			_blobs = new Vector.<MotionBlob>();
			
			_thresholdValue = thresholdValue;
		}
		
		public function trackFrame(bmp:BitmapData):void
		{
			_prevFrameDifference = _currentFrameDilatated.concat();
			_old.copyPixels(_new, _new.rect, ORIGIN);
			preProcess(bmp, _new);
			
			_pixelsChanged = 0;
			
			var c1:uint;
			var c2:uint;
			var x:int;
			var y:int;
			var v:int;
			var index:int = 0;
			
			// apply difference and threshold
			for(y = 0; y < _sh; ++y)
			{
				for(x = 0; x < _sw; ++x, ++index)
				{
					c1 = _old.getPixel(x, y) & 0xFF;
					c2 = _new.getPixel(x, y) & 0xFF;
					
					v = c2 - c1;
					if (v < 0) v = -v;
					
					if(v >= _thresholdValue) {
						v = 0xFF;
						_pixelsChanged++;
					} else {
						v = 0;
					}
					
					_currentFrameThreshold[index] = v;
					_currentFrameData[index] = c2;
				}
			}
			
			extendBorders();
		}
		
		public function force(x:int, y:int, w:int, h:int):Point
		{
			var ty:int = y + h;
			var tx:int = x + w;
			var ind:int;
			var pc:uint;
			var cc:uint;
			var m00:int, m10:int, m01:int;
			var n00:int, n10:int, n01:int;
			m00 = n00 = m01 = n01 = m10 = n10 = 0;
			for(var i:int = y; i < ty; ++i)
			{
				ind = int(i * _sw + x);
				for(var j:int = x; j < tx; ++j)
				{
					pc = _prevFrameDifference[ind];
					cc = _currentFrameDilatated[ind];
					
					if(pc > 0x00){
						m00 ++;
						m01 += i;
						m10 += j;
					}
					
					if(cc > 0x00){
						n00 ++;
						n01 += i;
						n10 += j;
					}
					
					++ind;
				}
			}
			
			if(n00 == 0 || m00 == 0) return ORIGIN;
			
			var invM00:Number = 1 / m00;
			var invN00:Number = 1 / n00;
			var xc1:Number = m10 * invM00;
			var yc1:Number = m01 * invM00;
			var xc2:Number = n10 * invN00;
			var yc2:Number = n01 * invN00;
			
			return new Point(xc2 - xc1, yc2 - yc1);
		}
		
		public function getBlobs(intern:Boolean = false):Vector.<Rectangle>
		{			
			var i:int = 0;
			var j:int;
			var n:int;
			var mainRect:Rectangle;
			var blobRect:Rectangle;
			var rects:Vector.<Rectangle> = new Vector.<Rectangle>();
			var sizes:Array = [];
			
			_tempCurr.setVector(_tempCurr.rect, _currentFrameDilatated);
			
			//while ( i < maxBlobs )
			while ( true ) 
			{
				mainRect = _tempCurr.getColorBoundsRect(0xFFFFFF, 0xFFFFFF);
				if (mainRect.isEmpty()) break;
				var x:int = mainRect.x;
				var ty:int = mainRect.y + mainRect.height;
				for (var y:int = mainRect.y; y < ty; ++y)
				{
					if (_tempCurr.getPixel(x, y) == 0xFFFFFF)
					{
						_tempCurr.floodFill(x, y, FLOOD_FILL_COLOR);
						// get the bounds of the filled area - this is the blob
						blobRect = _tempCurr.getColorBoundsRect(0xFFFFFF, FLOOD_FILL_COLOR);
						// check if it meets the min and max width and height
						n = blobRect.width * blobRect.height;
						//if (blobRect.width > minWidth && blobRect.width < maxWidth && blobRect.height > minHeight && blobRect.height < maxHeight)
						if (n > minBlobSize && n < maxBlobSize) 
						{
							rects.push(blobRect);
							sizes[i] = n;
							i++;
						}
						// mark blob as processed with some other color
						//_tempCurr.floodFill(x, y, PROCESSED_COLOR);
						_tempCurr.fillRect(blobRect, PROCESSED_COLOR);
					}
				}
				//i++;
			}
			
			if( i > maxBlobs)
			{
				sizes = sizes.sort(Array.NUMERIC | Array.DESCENDING | Array.RETURNINDEXEDARRAY);
				var frects:Vector.<Rectangle> = new Vector.<Rectangle>();
				for( j = 0; j < maxBlobs; ++j)
				{
					frects[j] = rects[ sizes[j] ];
				}
				rects = frects.concat();
			}
			
			if(intern)
			{
				var newBlobs:Vector.<MotionBlob> = new Vector.<MotionBlob>();
				var mb:MotionBlob;
				for( i = 0; i < rects.length; ++i )
				{
					blobRect = rects[i];
					newBlobs[i] = assignBlob(blobRect.x, blobRect.y, blobRect.width, blobRect.height);
				}
				n = _blobs.length;
				for( i = 0; i < n; ++i )
				{
					mb = _blobs[i];
					if(mb.dump()){
						newBlobs.push(mb);
					}
				}
				
				n = newBlobs.length;
				for (i = 0; i < n - 1; ++i) 
				{
					mb = newBlobs[i];
					for (j = i + 1; j < n; ++j) 
					{
						if(mb.mergeBlob(newBlobs[j]))
						{
							newBlobs.splice(j, 1);
							n--;
							//i = 0;
							//break;
							j--;
						}
					}
				}
				
				if(n > maxBlobs)
				{
					newBlobs.sort(blobSorter);
					newBlobs = newBlobs.slice(0, maxBlobs);
				}
				
				_blobs = newBlobs.concat();
			}
			
			return rects;
		}
		
		protected function blobSorter(a:MotionBlob, b:MotionBlob):Number
		{
			var aa:int = a.area;
			var ba:int = b.area;
			if(aa < ba) return 1;
			if(aa > ba) return -1;
			return 0;
		}
		
		private function intersects(rect1:Rectangle, rect2:Rectangle):Boolean
		{
			
			if(!((rect1.right < rect2.left) || (rect1.left > rect2.right)))
				if(!((rect1.bottom < rect2.top) || (rect1.top > rect2.bottom)))
					return true; 
					
			return false; 
		}
		
		private function assignBlob(x:int, y:int, w:int, h:int):MotionBlob
		{
			var ty:int = y + h;
			var tx:int = x + w;
			var ind:int;
			var pc:uint;
			var cc:uint;
			var m00:int, m10:int, m01:int;
			var n00:int, n10:int, n01:int, n11:int, n02:int, n20:int;
			m00 = n00 = m01 = n01 = m10 = n10 = 0;
			for(var i:int = y; i < ty; ++i)
			{
				ind = int(i * _sw + x);
				for(var j:int = x; j < tx; ++j)
				{
					pc = _prevFrameDifference[ind];
					cc = _currentFrameDilatated[ind];
					
					if(pc > 0x00){
						m00 ++;
						m01 += i;
						m10 += j;
					}
					
					if(cc > 0x00){
						n00 ++;
						n01 += i;
						n10 += j;
						n11 += j * i;
						n02 += i * i;
						n20 += j * j;
					}
					
					++ind;
				}
			}
			
			var invM00:Number = 1 / m00;
			var invN00:Number = 1 / n00;
			var xc1:Number = m10 * invM00;
			var yc1:Number = m01 * invM00;
			var xc2:Number = n10 * invN00;
			var yc2:Number = n01 * invN00;
			
			var mu20:Number = n20 - n10 * xc2;
			var mu02:Number = n02 - n01 * yc2;
			var mu11:Number = n11 - n01 * xc2;
			
			var mb:MotionBlob;
			if(_blobs.length){
				var min:Number = 0xFFFFFF;
				j = _blobs.length;
				for(i = 0; i < j; ++i){
					mb = _blobs[i];
					var dx:Number = xc1 - mb.cx;
					var dy:Number = yc1 - mb.cy;
					var dist:Number = Math.sqrt( dx * dx + dy * dy );
					if( dist < min ){
						min = dist;
						ind = i;
					}
				}
				if(min < Math.min(w, h))
				{
					mb = _blobs[ind];
					mb.updateDimensions(xc2, yc2, invN00, mu20, mu11, mu02, n00);
					_blobs.splice(ind, 1);
					return mb;
				}
			}
			
			mb = new MotionBlob(xc2, yc2, invN00, mu20, mu11, mu02, n00);
			if(n00 != 0 && m00 != 0) {
				mb.vel.x = xc2 - xc1;
				mb.vel.y = yc2 - yc1;
			}
			
			return mb;
		}
		
		public function drawCurrentFrame(dst:BitmapData):void
		{
			dst.lock();
			dst.setVector( dst.rect, _currentFrameDilatated );
			dst.unlock();
		}
		
		public function drawPreviousFrame(dst:BitmapData):void
		{
			dst.lock();
			dst.copyPixels(_old, _old.rect, ORIGIN);
			dst.unlock();
		}
		
		public function get motionVector():Vector.<uint>
		{
			return _currentFrameDilatated;
		}

		public function get motionLevel():Number
		{
			return _pixelsChanged / ( _sw * _sh );
		}
		
		public function get frameWidth():int
		{
			return _sw;
		}
		
		public function get frameHeight():int
		{
			return _sh;
		}
		
		public function get frameSize():int
		{
			return _frameSize;
		}
		
		public function set thresholdValue(value:uint):void
		{
			_thresholdValue = value;
		}

		private function preProcess(bmp:BitmapData, dst:BitmapData):void
		{			
			if(_pixelSize > 1)
			{				
				dst.draw(bmp, _lowMatrix, null, "normal", null, true);
				dst.applyFilter(dst, dst.rect, ORIGIN, GRAYSCALE_MATRIX);
			} else {
				dst.applyFilter(bmp, dst.rect, ORIGIN, GRAYSCALE_MATRIX);
			}
			dst.applyFilter(dst, dst.rect, ORIGIN, BLUR);
		}
		
		public function detectEdges(dst:BitmapData):void
		{
			var swm1:int = _sw - 1;
			var shm1:int = _sh - 1;
			var swp1:int = _sw + 1;
			var edgeThresh:int = 0xFF >> 1;
			
			var i:int, j:int, k:int = 0;
			var v:uint;
			var gx:int, gy:int;
			var pv0:uint, pv45:uint, pv90:uint, pv135:uint, pv180:uint;
			var pv225:uint, pv270:uint, pv315:uint;
			
			dst.lock();
			dst.fillRect(dst.rect, 0x00);
			
			for( i = 1; i < shm1; ++i )
			{
				k = int(i * _sw + 1);
				for( j = 1; j < swm1; ++j, ++k )
				{
					//pv0 = pv45 = pv90 = pv135 = pv180 = pv225 = pv270 = pv315 = 0;  
					// left pixels
					//if ( j > 0 )
					//{
						pv270 = _currentFrameData[int(k - 1)];

						//if ( i > 0 )
						//{
							pv315 = _currentFrameData[int(k - swp1)];
						//}
						//if ( i < shm1 )
						//{
							pv225 = _currentFrameData[int(k + swm1)];
						//}
					//}
					// right pixels
					//if ( j < swm1 )
					//{
						pv90 = _currentFrameData[int(k + 1)];

						//if ( i > 0 )
						//{
							pv45 = _currentFrameData[int(k - swm1)];
						//}
						//if ( i < shm1 )
						//{
							pv135 = _currentFrameData[int(k + swp1)];
						//}
					//}
					// top pixel
					//if ( i > 0 )
					//{
						pv0 = _currentFrameData[int(k - _sw)];
					//}
					// bottom pixel
					//if ( i < shm1 )
					//{
						pv180 = _currentFrameData[int(k + _sw)];
					//}
					
					gx = (pv45 + (pv90 << 1) + pv135) - (pv315 + (pv270 << 1) + pv225);
					gy = (pv315 + (pv0 << 1) + pv45) - (pv225 + (pv180 << 1 ) + pv135);
					
					if(gx < 0) gx = -gx;
					if(gy < 0) gy = -gy;
					
					v = gx + gy;
					//v >>= 2;
					
					//if(v > 255) v = 255;
					
					if(v > edgeThresh) dst.setPixel(j, i, 0xFFFFFF);
				}
			}
			
			dst.unlock();
		}
		
		protected function extendBorders():void
		{
			// dilatation analogue for borders extending
			// it can be skipped
			var swm1:int = _sw - 1;
			var shm1:int = _sh - 1;
			var swp1:int = _sw + 1;
			
			var i:int, j:int, k:int;
			var v:uint;
			
			k = 0;
			for ( i = 0; i < _sh; ++i )
			{
				for ( j = 0; j < _sw; ++j, ++k )
				{
					v = _currentFrameThreshold[k];

					// left pixels
					if ( j > 0 )
					{
						v += _currentFrameThreshold[int(k - 1)];

						if ( i > 0 )
						{
							v += _currentFrameThreshold[int(k - swp1)];
						}
						if ( i < shm1 )
						{
							v += _currentFrameThreshold[int(k + swm1)];
						}
					}
					// right pixels
					if ( j < swm1 )
					{
						v += _currentFrameThreshold[int(k + 1)];

						if ( i > 0 )
						{
							v += _currentFrameThreshold[int(k - swm1)];
						}
						if ( i < shm1 )
						{
							v += _currentFrameThreshold[int(k + swp1)];
						}
					}
					// top pixel
					if ( i > 0 )
					{
						v += _currentFrameThreshold[int(k - _sw)];
					}
					// bottom pixel
					if ( i < shm1 )
					{
						v += _currentFrameThreshold[int(k + _sw)];
					}
					
					_currentFrameDilatated[k] = (v != 0) ? 0xFFFFFF : 0x00;
				}
			}
		}
	}
}
