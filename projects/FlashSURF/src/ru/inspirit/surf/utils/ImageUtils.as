package ru.inspirit.surf.utils 
{
	import flash.display.BitmapData;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Point;

	/**
	 * @author Eugene Zatepyakin
	 */
	public class ImageUtils 
	{
		public static const GRAYSCALE_MATRIX:ColorMatrixFilter = new ColorMatrixFilter([
			0, 0, 0, 0, 0,
            0, 0, 0, 0, 0,
            .2989, .587, .114, 0, 0,
            0, 0, 0, 0, 0
		]);
		public static const GRAYSCALE_RGB_MATRIX:ColorMatrixFilter = new ColorMatrixFilter([
			.2989, .587, .114, 0, 0,
            .2989, .587, .114, 0, 0,
            .2989, .587, .114, 0, 0,
            0, 0, 0, 0, 0
		]);
		
		public static const ORIGIN:Point = new Point();
		public static const LUTR:Array = new Array(256);
		public static const LUTG:Array = new Array(256);
		public static const LUTB:Array = new Array(256);
		
		public static function grayScaleAndCorrect(bitmap:BitmapData):void
		{
			bitmap.applyFilter(bitmap, bitmap.rect, ORIGIN, GRAYSCALE_MATRIX);
			
			var histogram:Vector.<Vector.<Number>> = bitmap.histogram(bitmap.rect);
			var from:Vector.<int> = stretchChannelHistogram(histogram[2], 0, 256);
			
			var from_b:int = from[0];
			var to_b:int = from[1];
			var diff_b:Number = 1 / (to_b - from_b) * 255;
			
			var lut:Array = LUTR;
            var val:int;
            var i:int = -1;
            
            if (from_b != to_b)
			{
				while(++i < 256)
				{
	                val = ((i - from_b) * diff_b) + 0.5;
	                if (val > 255) val = 255;
	                if (val < 0) val = 0;
	                
					lut[i] = val;
				}
            }
            else
			{
                while(++i < 256)
				{
	                val = (i - from_b) * 255 + 0.5;
	                if (val > 255) val = 255;
	                if (val < 0) val = 0;
	                
					lut[i] = val;
				}
            }
            
			bitmap.paletteMap(bitmap, bitmap.rect, ORIGIN, null, null, lut, null);
		}
		
		public static function correctAndGrayscale(bitmap:BitmapData):void
		{			
			var histogram:Vector.<Vector.<Number>> = bitmap.histogram(bitmap.rect);
			var vals:Vector.<int> = stretchBLUEHistogram(histogram, 0, 256);
			
			var from:int = vals[0];
			var to:int = vals[1];
			var scale:Number = 1 / (to - from) * 255;
			
			var LUTr:Array = LUTR;
			var LUTg:Array = LUTG;
			var LUTb:Array = LUTB;
            var val:int;
            var i:int = -1;
            
            if (from != to)
			{
				while(++i < 256)
				{
	                val = ((i - from) * scale) + 0.5;
	                if (val > 255) val = 255;
	                if (val < 0) val = 0;
	                
					LUTr[i] = val << 16;
					LUTg[i] = val << 8;
					LUTb[i] = val;
				}
            }
            else
			{
                while(++i < 256)
				{
	                val = (i - from) * 255 + 0.5;
	                if (val > 255) val = 255;
	                if (val < 0) val = 0;
	                
					LUTr[i] = val << 16;
					LUTg[i] = val << 8;
					LUTb[i] = val;
				}
            }
            
			bitmap.paletteMap(bitmap, bitmap.rect, ORIGIN, LUTr, LUTg, LUTb);
			bitmap.applyFilter(bitmap, bitmap.rect, ORIGIN, GRAYSCALE_MATRIX);
		}
		
		public static function correctLevels(bitmap:BitmapData):void
		{
			var histogram:Vector.<Vector.<Number>> = bitmap.histogram(bitmap.rect);
			var from:Vector.<int> = Vector.<int>([0, 0, 0]);
			var to:Vector.<int> = Vector.<int>([256, 256, 256]);
			
			var LUTr:Array = LUTR;
			var LUTg:Array = LUTG;
			var LUTb:Array = LUTB;
			
			var i:int = -1;
			
			stretchHistogram(histogram, from, to);
			
			var from_r:int = from[0];
			var from_g:int = from[1];
			var from_b:int = from[2];
			
			var to_r:int = to[0];
			var to_g:int = to[1];
			var to_b:int = to[2];
			
			var diff_r:Number = 1 / (to_r - from_r);
			var diff_g:Number = 1 / (to_g - from_g);
			var diff_b:Number = 1 / (to_b - from_b);
			
			var fr:Number;
            var val:int;
			
			while(++i < 256)
			{
				if (from_r != to_r)
				{
					fr = (i - from_r) * diff_r;
                }
                else
				{
                    fr = i - from_r;
                }
                
                val = fr * 255 + 0.5;
                if (val > 255) val = 255;
                if (val < 0) val = 0;
                
				LUTr[i] = val << 16;
				
				//
				
				if (from_g != to_g)
				{
                        fr = (i - from_g) * diff_g;
                }
                else
				{
                    fr = i - from_g;
                }
                
                val = fr * 255 + 0.5;
                if (val > 255) val = 255;
                if (val < 0) val = 0;
                
				LUTg[i] = val << 8;
				
				//
				
				if (from_b != to_b)
				{
					fr = (i - from_b) * diff_b;
                }
                else
				{
                    fr = i - from_b;
                }
                
                val = fr * 255 + 0.5;
                if (val > 255) val = 255;
                if (val < 0) val = 0;
                
				LUTb[i] = val;
			}
			
			bitmap.paletteMap(bitmap, bitmap.rect, ORIGIN, LUTr, LUTg, LUTb);
		}

		public static function adjustContrast(bitmap:BitmapData, contrast:Number = 1.2):void
		{
			//
		}
		
		public static function adjustGamma(bitmap:BitmapData, gamma:Number = 2.2):void
		{
			var LUTr:Array = LUTR;
			var LUTg:Array = LUTG;
			var LUTb:Array = LUTB;
			var i:int = -1;
			var invGamma:Number = 1 / gamma;
			var g:int;
			while(++i < 256)
			{
				g = Math.pow( i / 255, invGamma) * 255 + 0.5;
				if (g > 255)
				{
					g = 255;
				}
				LUTr[i] = g << 16;
				LUTg[i] = g << 8;
				LUTb[i] = g;
			}
			bitmap.paletteMap(bitmap, bitmap.rect, ORIGIN, LUTr, LUTg, LUTb);
		}
		
		public static function adjustBrightness(bitmap:BitmapData, brightness:int):void
		{
			var LUTr:Array = LUTR;
			var LUTg:Array = LUTG;
			var LUTb:Array = LUTB;
			var i:int = -1;
			var b:int;
			
			while(++i < 256)
			{
				b = i + brightness;
				if (b > 255) b = 255;
				if (b < 0) b = 0;
				LUTr[i] = b << 16;
				LUTg[i] = b << 8;
				LUTb[i] = b;
			}
			bitmap.paletteMap(bitmap, bitmap.rect, ORIGIN, LUTr, LUTg, LUTb);
		}
		
		public static function stretchHistogram(histogram:Vector.<Vector.<Number>>, from:Vector.<int>, to:Vector.<int>):void 
		{
            var count:int;
            var invcount:Number;
            var binSum:int;
            var minH:Number;
            var maxH:Number;
            var i:int = -1, j:int, k:int;
            var channel:Vector.<Number>;
            var from_v:int, to_v:int;
            
            while (++i < 3)
            {
                
                from_v = from[i];
                to_v = to[i];
				count = 0;
	            
	            // count
	            channel = histogram[0];
                k = from_v - 1;
                while (++k < to_v)
                {
                    
                    count += channel[k];
                }
                channel = histogram[1];
                k = from_v - 1;
                while (++k < to_v)
                {
                    
                    count += channel[k];
                }
                channel = histogram[2];
                k = from_v - 1;
                while (++k < to_v)
                {
                    
                    count += channel[k];
                }
                //
	            
                if (count == 0)
                {
                    from[i] = 0;
                    to[i] = 0;
                }
                else
                {
                	channel = histogram[i];                	
                	invcount = 1 / count;
                	
					binSum = 0;
                    j = -1;
                    while (++j < 255)
                    {
                        
                        binSum += channel[j];
                        minH = binSum * invcount - 0.006;
                        maxH = (binSum + channel[(j + 1) | 0]) * invcount - 0.006;
                        if(minH < 0) minH = -minH;
                        if(maxH < 0) maxH = -maxH;
                        if (minH < maxH)
                        {
                            from[i] = j + 1;
                            break;
                        }
                    }
                    
                    binSum = 0;
                    j = 256;
                    while (--j > 0)
                    {
                        
                        binSum += channel[j];
                        minH = binSum * invcount - 0.006;
                        maxH = (binSum + channel[(j - 1) | 0]) * invcount - 0.006;
                        if(minH < 0) minH = -minH;
                        if(maxH < 0) maxH = -maxH;
                        if (minH < maxH)
                        {
                            to[i] = j - 1;
                            break;
                        }
                    }
                }
            }
        }
        
        public static function stretchChannelHistogram(channel:Vector.<Number>, from:int, to:int):Vector.<int> 
		{
            var count:int;
            var invcount:Number;
            var binSum:int;
            var minH:Number;
            var maxH:Number;
            var k:int;
            
			count = 0;
			
			k = from - 1;
		    while (++k < to)
		    {
		        
		        count += channel[k];
		    }
			
			if (count == 0)
			{
			    return Vector.<int>([0, 0]);
			}
			else
			{				
				invcount = 1 / count;
				binSum = 0;
			    k = -1;
			    while (++k < 255)
			    {
			        
			        binSum += channel[k];
			        minH = binSum * invcount - 0.006;
			        maxH = (binSum + channel[(k + 1) | 0]) * invcount - 0.006;
			        if(minH < 0) minH = -minH;
			        if(maxH < 0) maxH = -maxH;
			        if (minH < maxH)
			        {
			            from = k + 1;
			            break;
			        }
			    }
			    binSum = 0;
			    k = 256;
			    while (--k > 0)
			    {
			        
			        binSum += channel[k];
			        minH = binSum * invcount - 0.006;
			        maxH = (binSum + channel[(k - 1) | 0]) * invcount - 0.006;
			        if(minH < 0) minH = -minH;
			        if(maxH < 0) maxH = -maxH;
			        if (minH < maxH)
			        {
			            to = k - 1;
			            break;
			        }
			    }
			}
			return Vector.<int>([from, to]);
        }
        
         public static function stretchBLUEHistogram(histogram:Vector.<Vector.<Number>>, from:int, to:int):Vector.<int> 
		{
            var count:int;
            var invcount:Number;
            var binSum:int;
            var minH:Number;
            var maxH:Number;
            var k:int;
            var channel:Vector.<Number>;
            
			count = 0;
		    
			// count
			channel = histogram[0];
			k = from - 1;
			while (++k < to)
			{
			    
			    count += channel[k];
			}
			channel = histogram[1];
			k = from - 1;
			while (++k < to)
			{
			    
			    count += channel[k];
			}
			channel = histogram[2];
			k = from - 1;
			while (++k < to)
			{
			    
			    count += channel[k];
			}
			//
			
			if (count == 0)
			{
			    return Vector.<int>([0, 0]);
			}
			else
			{				
				invcount = 1 / count;
				binSum = 0;
			    k = -1;
			    while (++k < 255)
			    {
			        
			        binSum += channel[k];
			        minH = binSum * invcount - 0.006;
			        maxH = (binSum + channel[(k + 1) | 0]) * invcount - 0.006;
			        if(minH < 0) minH = -minH;
			        if(maxH < 0) maxH = -maxH;
			        if (minH < maxH)
			        {
			            from = k + 1;
			            break;
			        }
			    }
			    binSum = 0;
			    k = 256;
			    while (--k > 0)
			    {
			        
			        binSum += channel[k];
			        minH = binSum * invcount - 0.006;
			        maxH = (binSum + channel[(k - 1) | 0]) * invcount - 0.006;
			        if(minH < 0) minH = -minH;
			        if(maxH < 0) maxH = -maxH;
			        if (minH < maxH)
			        {
			            to = k - 1;
			            break;
			        }
			    }
			}
			return Vector.<int>([from, to]);
        }
        
        public static function getMeanValue(bitmap:BitmapData):int
        {
        	var val:int = 0;
        	
        	var data:Vector.<uint> = bitmap.getVector(bitmap.rect);
			var sz:int = bitmap.width * bitmap.height;
			var i:int = sz;
			while( --i > -1 )
			{
				val += data[i] & 0xFF;
			}
			
			return val / sz;
        }
	}
}
