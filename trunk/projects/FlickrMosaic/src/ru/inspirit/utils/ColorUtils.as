package ru.inspirit.utils
{

	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.utils.ByteArray;

	/**
	* Varios color functions
	* 
	* @author Eugene Zatepyakin
	*/
	public class ColorUtils
	{

		public function ColorUtils() {}

		public static function averageColor(source_bmp:BitmapData, scale:Boolean = false):uint
		{
			var a:uint = 0;
			var r:uint = 0;
			var g:uint = 0;
			var b:uint = 0;
			var s:int = 1;
			var c:int;
			var i:int;
			var _bmp:BitmapData = source_bmp;
			var tmp_bmp1:BitmapData;
			var tmp_bmp2:BitmapData;

			if(scale){
				s = Math.round(Math.max(_bmp.width / 100, _bmp.height / 100));
				tmp_bmp1 = new BitmapData(int(_bmp.width/s + .5), int(_bmp.height/s + .5), false, 0x000000);
				tmp_bmp2 = new BitmapData(_bmp.width, _bmp.height, false, 0x000000);
				tmp_bmp1.draw(_bmp, new Matrix(1/s, 0, 0, 1/s, 0, 0));
				tmp_bmp2.draw(tmp_bmp1, new Matrix(s, 0, 0, s, 0, 0));
				_bmp = tmp_bmp2;
			}
			
			var bArray:ByteArray = _bmp.getPixels( _bmp.rect );
			var L:int = bArray.length;
			for ( i = 0; i < L ; i+=4 )
			{
				
				a += bArray[ i ];
				r += bArray[ i + 1 ];
				g += bArray[ i + 2 ];
				b += bArray[ i + 3 ];
				
			}
			
			var div:Number =  1 / ( _bmp.width * _bmp.height );
			a = ( a * div ) << 24; 
			r = ( r * div ) << 16;
			g = ( g * div ) << 8;
			b = b * div;
			
			//c = a | r | g | b;
			c = r | g | b;
			
			if(scale){
				tmp_bmp1.dispose();
				tmp_bmp2.dispose();
			}
			//
			return ( c );
		}

		public static function blend( a:uint, b:uint, f:Number ):uint
		{
			return mix(a >>> 24, b >>> 24, f) << 24
				| mix((a >> 16) & 0xff, (b >> 16) & 0xff, f) << 16
				| mix((a >> 8) & 0xff, (b >> 8) & 0xff, f) << 8
				| mix(a & 0xff, b & 0xff, f);
		}

		public static function similar( c1:uint, c2:uint, tolerance:Number = 0.01 ):Boolean
		{
			tolerance = tolerance * ( 0xFF * 0xFF * 3 ) << 0;

			var distance:Number = getDistance(c1, c2);

			return distance <= tolerance;
		}

		public static function getDistance(c1:uint, c2:uint):Number
		{
			var RGB1:Object = {r:(c1 >> 16 & 0xff), g:(c1 >> 8 & 0xff), b:(c1 & 0xff)};
			var RGB2:Object = { r:(c2 >> 16 & 0xff), g:(c2 >> 8 & 0xff), b:(c2 & 0xff) };

			var distance:Number = 0;

			distance += Math.pow( RGB1.r - RGB2.r, 2 );
			distance += Math.pow( RGB1.g - RGB2.g, 2 );
			distance += Math.pow( RGB1.b - RGB2.b, 2 );

			return distance;
		}

		private static function mix(a:Number, b:Number, f:Number):Number
		{
			return (a + (b - a) * f);
		}

	}

}