package ru.inspirit.mosaic 
{
	import com.gskinner.geom.ColorMatrix;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import ru.inspirit.utils.ColorUtils;
	
	/**
	 * This workaround was made to allow creating mosaic at original size
	 * we cant draw all tiles in one Bitmap cause of size restrictions.
	 * @author Eugene Zatepyakin
	 */
	public class TileLayer extends Sprite
	{
		private const maxBitmapWidth:uint = 4000;
		private const maxBitmapHeight:uint = 4000;
		private const origin:Point = new Point();
		
		public static var DRAW_STYLE:String = 'blend';
		
		private var _data:Array;
		private var _cm:ColorMatrix;
		
		public function TileLayer() 
		{
			_data = new Array();
			_cm = new ColorMatrix();
		}
		
		public function placeTile(tx:uint, ty:uint, t:TileItem, c:uint, img:BitmapData):void
		{
			var b:Bitmap;
			var w:uint;
			var h:uint;
			for (var i:uint = 0; i < _data.length; i++) {				
				for (var j:uint = 0; j < _data[i].length; j++) {
					b = Bitmap(_data[i][j]);
					w = b.x + b.width;
					h = b.y + b.height;
					if ( w >= tx + 75 && h >= ty + 75) {
						if ( DRAW_STYLE == 'blend' ) {
							var c_bmp:BitmapData = new BitmapData(75, 75, false, c);
							var i_bmp:BitmapData = new BitmapData(Main.pixelSize, Main.pixelSize, false, c);
							i_bmp.copyPixels(img, new Rectangle(tx / 75 * Main.pixelSize, ty / 75 * Main.pixelSize, i_bmp.width, i_bmp.height), new Point(0, 0));
							b.bitmapData.draw(i_bmp, new Matrix(75/Main.pixelSize, 0, 0, 75/Main.pixelSize, tx - b.x, ty - b.y));
							b.bitmapData.draw(c_bmp, new Matrix(1, 0, 0, 1, tx - b.x, ty - b.y), null, 'screen');
							b.bitmapData.draw(t._bmp, new Matrix(1, 0, 0, 1, tx - b.x, ty - b.y), null, 'multiply');
						} else if ( DRAW_STYLE == 'colorize' ) {
							var bmp:BitmapData = colorize(t._bmp, c, t._color);
							b.bitmapData.copyPixels(bmp, bmp.rect, new Point(tx - b.x, ty - b.y));
						} else if ( DRAW_STYLE == 'clear' ) {
							b.bitmapData.copyPixels(t._bmp, t._bmp.rect, new Point(tx - b.x, ty - b.y));
						}
						return;
					}
				}
			}
		}
		
		public function buildLayer(sw:uint, sh:uint, z:Number):void
		{
			destroy();
			
			var w:Number = sw * z;
			var h:Number = sh * z;
			
			var xn:uint = Math.ceil(w / maxBitmapWidth);
			var yn:uint = Math.ceil(h / maxBitmapHeight);
			
			var px:int = Math.floor(sw / Main.pixelSize);
			var py:int = Math.floor(sh / Main.pixelSize);
			
			var ow:uint = Math.ceil(px / xn);
			var oh:uint = Math.ceil(py / yn);
			
			var bw:uint, bh:uint;
			var b:Bitmap;
			for (var i:uint = 0; i < yn; i++) {
				_data[i] = [];
				if ( i < yn - 1 ) {
					bh = oh * 75;
				} else {
					bh = h - ( (oh * 75) * (yn - 1) );
				}
				for (var j:uint = 0; j < xn; j++) {
					if ( j < xn - 1 ) {
						bw = ow * 75;
					} else {
						bw = w - ( (ow * 75) * (xn - 1) );
					}
					b = new Bitmap(new BitmapData(bw, bh, true, 0x00FFFFFF));
					b.x = (ow * 75) * j;
					b.y = (oh * 75) * i;
					addChild(b);
					_data[i][j] = b;
				}
			}
		}
		
		public function getEncodeArray():Array
		{
			return _data;
		}
		
		public function destroy():void
		{
			var b:Bitmap;
			while (numChildren) {
				b = Bitmap(getChildAt(0));
				removeChild(b);
				b.bitmapData.dispose();
				b = null;
			}
			_data = [];
		}
		
		private function colorize(bmp:BitmapData, c1:uint, c2:uint):BitmapData
		{
			var d:uint = ( 0xFF * 0xFF * 3 );
			var k:Number = ColorUtils.getDistance(c1, c2) / d * 10;
			var ct:ColorTransform = new ColorTransform(1, 1, 1, 1, (c1 >> 16 & 0xFF) * k, (c1 >> 8 & 0xFF) * k, (c1 & 0xFF) * k, 0);
			var b:BitmapData = bmp.clone();
			
			b.colorTransform( b.rect, ct );
			
			// additional color adjustments
			_cm.reset();
			_cm.adjustContrast(100 * k);
			if (c1 < 0xFFFFFFFF * .5) {
				_cm.adjustBrightness(100 * k);
			} else {
				_cm.adjustBrightness(-100 * k);
			}
			var cmf:ColorMatrixFilter = new ColorMatrixFilter(_cm);
			b.applyFilter(b, b.rect, origin, cmf);
			
			return b;
		}
		
	}
	
}