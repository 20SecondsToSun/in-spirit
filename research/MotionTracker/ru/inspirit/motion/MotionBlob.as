package ru.inspirit.motion 
{
	import flash.geom.Matrix;
	import flash.geom.Point;

	/**
	 * @author Eugene Zatepyakin
	 */
	public class MotionBlob 
	{		
		public const HALF_PI:Number = 1.57079632;
		public const PI:Number = 3.14159265;
		public const TWO_PI:Number = 6.2831853;
		public const FOURTH_PI:Number = 0.7853981;
		public const IDENTITY:Matrix = new Matrix();
		
		public var cx:Number;
		public var cy:Number;
		
		public var tl:Point = new Point();
		public var br:Point = new Point();
		public var tr:Point = new Point();
		public var bl:Point = new Point();
		
		public var width:Number = 0;
		public var height:Number = 0;
		public var area:int;
		
		public var angle:Number = 0;
		public var vel:Point = new Point();
		
		public function MotionBlob(x:Number, y:Number, invM00:Number, mu20:Number, mu11:Number, mu02:Number, n00:int):void
		{
			cx = x;
			cy = y;
			
			updateDimensions(x, y, invM00, mu20, mu11, mu02, n00);
			/*cx = x;
			cy = y;
			
			var a:Number = mu20 * invM00;
			var b:Number = mu11 * invM00;
			var c:Number = mu02 * invM00;
			var e:Number = Math.sqrt((4 * b * b) + ((a - c) * (a - c)));
			var na:Number = Math.atan2( 2*b, a - c + e );
			
			var cs:Number = Math.cos( na );
			var sn:Number = Math.sin( na );
			
			var rotate_a:Number = cs * cs * mu20 + 2 * cs * sn * mu11 + sn * sn * mu02;
			var rotate_c:Number = sn * sn * mu20 - 2 * cs * sn * mu11 + cs * cs * mu02;
			var nw:Number = Math.sqrt( rotate_a * invM00 ) * 4;
			var nl:Number = Math.sqrt( rotate_c * invM00 ) * 4;
			
			if( nw < nl )
  			{
  				var t:Number = nl;
  				nl = nw;
  				nw = t;
  				na = HALF_PI - na;
  			}
			
			width = nw;
			height = nl;
			angle = na;*/
		}
		
		public function updateDimensions(x:Number, y:Number, invM00:Number, mu20:Number, mu11:Number, mu02:Number, n00:int):void
		{
			var dx:Number = (x - cx);
			var dy:Number = (y - cy);
			 
			vel.x += (dx - vel.x) * .25;
			vel.y += (dy - vel.y) * .25;
			
			cx += dx * .5;
			cy += dy * .5;
			
			var a:Number = mu20 * invM00;
			var b:Number = mu11 * invM00;
			var c:Number = mu02 * invM00;
			var e:Number = Math.sqrt((4 * b * b) + ((a - c) * (a - c)));
			var na:Number = Math.atan2( 2*b, a - c + e );
			
			var cs:Number = Math.cos( na );
			var sn:Number = Math.sin( na );
			
			var rotate_a:Number = cs * cs * mu20 + 2 * cs * sn * mu11 + sn * sn * mu02;
			var rotate_c:Number = sn * sn * mu20 - 2 * cs * sn * mu11 + cs * cs * mu02;
			var nw:Number = Math.sqrt( rotate_a * invM00 ) * 4;
			var nl:Number = Math.sqrt( rotate_c * invM00 ) * 4;
			
			if( nw < nl )
  			{
  				var t:Number = nl;
  				nl = nw;
  				nw = t;
  				na = HALF_PI - na;
  				//t = cs;
  				//cs = sn;
  				//sn = t;
  			}
			
			width += (nw - width) * .5;
			height += (nl - height) * .5;
			
			//var ccs:Number = Math.cos(angle);
			//var csn:Number = Math.sin(angle);
			
			//var diff:Number = Math.atan2(ccs * sn - csn * cs, csn * sn + ccs * cs);
			//var diff:Number = (na - angle) % TWO_PI;
			//if (diff != diff % PI) {
				//diff = (diff < 0) ? diff + TWO_PI : diff - TWO_PI;
			//}
			angle = na;//+= diff * .5;
			area = n00;
						
			updateRectangle();
		}
		
		public function mergeBlob(blob:MotionBlob):Boolean
		{
			var dx:Number = blob.cx - cx;
			var dy:Number = blob.cy - cy;
			var da:Number = (blob.angle - angle) % TWO_PI;
			if( da != da % PI ) {
				da = da < 0 ? da + TWO_PI : da - TWO_PI;
			}
			var ada:Number = da < 0 ? -da : da;
			
			var dist:Number = ( dx * dx + dy * dy );
			var ds:int = Math.max(area, blob.area);
			
			if(dist < ds && ada < HALF_PI)
			{
				angle += da * .5;
				cx += dx * .5;
				cy += dy * .5;
				if(area > blob.area){
					width += blob.width * .5;
					height += blob.height * .5;
					area += blob.area >> 1;
				} else {
					width = blob.width + width*.5;
					height = blob.height + height*.5;
					area = blob.area + (area >> 1);
					vel.x += (blob.vel.x - vel.x) * .5;
					vel.y += (blob.vel.y - vel.y) * .5;
				}
				updateRectangle();
				
			/*	tl.x = Math.min(tl.x, blob.tl.x);
				tl.y = Math.min(tl.y, blob.tl.y);
				tr.x = Math.max(tr.x, blob.tr.x);
				tr.y = Math.min(tr.y, blob.tr.y);
				bl.x = Math.min(bl.x, blob.bl.x);
				bl.y = Math.max(bl.y, blob.bl.y);
				br.x = Math.max(br.x, blob.br.x);
				br.y = Math.max(br.y, blob.br.y);
				
				width = br.x - tl.x;
				height = br.y - tl.y;
				cx = (br.x + tl.x) * .5;
				cy = (tl.y + br.y) * .5;*/
				
				return true;
			}
			return false;		
		}
		
		protected function updateRectangle():void
		{
			var hw:Number = width * .5;
			var hh:Number = height * .5;
			
			updateRectPoint(tl, angle, cx - hw, cy - hh, cx, cy);
			updateRectPoint(br, angle, cx + hw, cy + hh, cx, cy);
			updateRectPoint(tr, angle, cx + hw, cy - hh, cx, cy);
			updateRectPoint(bl, angle, cx - hw, cy + hh, cx, cy);
		}
		
		protected function updateRectPoint( p:Point, angle:Number, x:Number, y:Number, cx:Number, cy:Number):void
		{			
			IDENTITY.identity();
			IDENTITY.tx = x - cx;
			IDENTITY.ty = y - cy;
			IDENTITY.rotate(angle);
			
			p.x = IDENTITY.tx + cx;
			p.y = IDENTITY.ty + cy;
		}
		
		public function dump():Boolean
		{
			vel.x *= .4;
			vel.y *= .4;
			
			cx += vel.x;
			cy += vel.y;
			
			tl.x += vel.x;
			tl.y += vel.y;
			tr.x += vel.x;
			tr.y += vel.y;
			bl.x += vel.x;
			bl.y += vel.y;
			br.x += vel.x;
			br.y += vel.y;
			
			var len:Number = Math.sqrt(vel.x * vel.x + vel.y * vel.y);
			
			return (len > 1);
		}
	}
}
