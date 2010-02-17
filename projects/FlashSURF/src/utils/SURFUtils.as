package utils
{
	import ru.inspirit.surf.IPoint;

	import mx.utils.Base64Encoder;

	import flash.display.Bitmap;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.net.FileReference;
	import flash.utils.ByteArray;

	/**
	 * Different useful methods
	 *
	 * @author Eugene Zatepyakin
	 */
	public class SURFUtils
	{
		public static const BASE64_ENCODER:Base64Encoder = new Base64Encoder();

		private static var fileReference:FileReference = new FileReference();

		public static function drawMatches(gfx:Graphics, ipts:Vector.<Number>, scale:Number = 1, offset:Number = 0):void
		{
			var l:int = ipts.length;
			gfx.lineStyle(1, 0x0000FF);

			for(var i:int = 0; i < l; i+=4)
			{
				var x1:Number = ipts[i] * scale;
				var y1:Number = ipts[(i+1) | 0] * scale;
				var x2:Number = ipts[(i+2) | 0] + offset;
				var y2:Number = ipts[(i+3) | 0];

				gfx.moveTo(x2, y2);
				gfx.lineTo(x1, y1);
			}
		}

		public static function drawMotionVectors(gfx:Graphics, ipts:Vector.<Number>, scale:Number = 1):void
		{
			var l:int = ipts.length;
			gfx.lineStyle(1, 0xFFFFFF);

			for(var i:int = 0; i < l; i+=4)
			{
				var x1:Number = ipts[i] * scale;
				var y1:Number = ipts[(i+1) | 0] * scale;
				var x2:Number = ipts[(i+2) | 0] * scale;
				var y2:Number = ipts[(i+3) | 0] * scale;

				var dx:Number = x1 - x2;
				var dy:Number = y1 - y2;
				var speed:Number = Math.sqrt(dx*dx+dy*dy);
				if (speed > 5 && speed < 30)
				{
					drawArrow(gfx, x1, y1, dx, dy, speed*2);
				}
			}
		}

		public static function drawIPoints(gfx:Graphics, ipts:Vector.<IPoint>, scale:Number = 1):void
		{
			var l:int = ipts.length;
			var ip:IPoint;

			for(var i:int = 0; i < l; ++i)
			{
				ip = ipts[i];
				var s:Number = ip.scale * scale;
				var x1:Number = ip.x * scale;
				var y1:Number = ip.y * scale;
	            var x2:Number = s * Math.cos(ip.orientation) + x1;
	            var y2:Number = s * Math.sin(ip.orientation) + y1;

				if(ip.orientation) {
					gfx.lineStyle(1, 0x00FF00);
	            	gfx.moveTo(x1, y1);
	            	gfx.lineTo(x2, y2);
				} else {
					gfx.beginFill(0x00FF00);
					gfx.drawCircle(x1, y1, 1);
					gfx.endFill();
				}
				if(ip.laplacian > 0) {
					gfx.lineStyle(1, 0x0000FF);
					gfx.drawCircle(x1, y1, s);
				} else {
					gfx.lineStyle(1, 0xFF0000);
					gfx.drawCircle(x1, y1, s);
				}
			}
		}

		public static function drawArrow(graphics:Graphics, stx:Number, sty:Number, dirx:Number = -1, diry:Number = -1, length:Number = 50, arrowSize:int = 6, angle:Number = -1):void
		{
			var endx:Number;
			var endy:Number;
			if(dirx == -1 && diry == -1){
				endx = stx + Math.cos(angle) * length;
				endy = sty + Math.sin(angle) * length;
			} else {
				var mag:Number = 1 / Math.sqrt(dirx * dirx + diry * diry);
				endx = dirx * mag * length + stx;
				endy = diry * mag * length + sty;
			}

			graphics.moveTo(stx, sty);
			graphics.lineTo(endx, endy);

			var diffx:Number = endx - stx;
			var diffy:Number = endy - sty;
			var ln:Number = Math.sqrt(diffx * diffx + diffy * diffy);

			if (ln <= 0) return;

			diffx = diffx / ln;
			diffy = diffy / ln;
			graphics.moveTo(endx, endy);
			graphics.lineTo(endx - arrowSize * diffx - arrowSize * -diffy, endy - arrowSize * diffy - arrowSize * diffx);
			graphics.moveTo(endx, endy);
			graphics.lineTo(endx - arrowSize * diffx + arrowSize * -diffy, endy - arrowSize * diffy + arrowSize * diffx);
		}

		public static function savePointsData(pointsCount:int, pointsData:ByteArray):void
		{
			var ba:ByteArray = new ByteArray();
			ba.writeBytes(pointsData);
			ba.compress();
			ba.position = 0;

			//BASE64_ENCODER.reset();
			//BASE64_ENCODER.encodeBytes(pointsData);

			//ba.clear();
			//ba.writeUTFBytes(BASE64_ENCODER.toString());

			fileReference.save(ba, 'points.surf');
		}

	}
}
