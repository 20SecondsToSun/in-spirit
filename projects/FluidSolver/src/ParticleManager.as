package  
{
	import ru.inspirit.utils.ColorUtils;
	import ru.inspirit.utils.NumberUtils;
	import ru.inspirit.utils.Random;

	import flash.display.BitmapData;

	/**
	 * Particle manager implementing simple LinkedList
	 * @author Eugene Zatepyakin
	 */
	public class ParticleManager 
	{
		public static const MAX_PARTICLES:uint = 5000;
		public static const VMAX:Number = 0.013;
		public static const VMAX2:Number = VMAX * VMAX;
		
		
		public var head:Particle;
		public var tail:Particle;
		
		public function ParticleManager() 
		{
			reset();
		}
		
		public function update(bmp:BitmapData, lines:Boolean):void
		{
			var p:Particle = head;			
			
			var a:int;
			var c:uint;
			
			var vxNorm:Number;
			var vyNorm:Number;
			var satInc:Number;
			var v2:Number;
			var m:Number;
			var rgb:Object;
			
			while (p)
			{
				if (p.alpha > 0) 
				{
					p.update();
					
					a = int(p.alpha * 0xFF + .5);
					
					if(Main.drawFluid){
						c = a << 24 | a << 16 | a << 8 | a;
					} else {
						vxNorm = p.vx * Main.isw;
		                vyNorm = p.vy * Main.ish;
		                v2 = vxNorm * vxNorm + vyNorm * vyNorm;
						
						if(v2 > VMAX2) v2 = VMAX2;
						
						m = p.mass;
						satInc = m > 0.5 ? m * m * m : 0;
						satInc *= satInc * satInc * satInc;
						
						rgb = ColorUtils.HSB2GRB(0, NumberUtils.map(v2, 0, VMAX2, 0, 1) + satInc, NumberUtils.interpolate(m, 0.5, 1) * p.alpha);
						c = a << 24 | (rgb.r * 0xFF) << 16 | (rgb.g * 0xFF) << 8 | rgb.b * 0xFF;
					}
					
					if (lines) {
						drawLine(bmp, int(p.px - Main.mx + .5), int(p.py - Main.my + .5), int(p.x + .5), int(p.y + .5), c);
					} else {
						drawLine(bmp, int(p.x - p.vx + .5), int(p.y - p.vy + .5), int(p.x + .5), int(p.y + .5), c);
					}
				}
				p = p.next;
			}
		}
		
		public function reset():void
		{
			var p:Particle = new Particle();
			
			head = tail = p;
			
			var k:int = MAX_PARTICLES;
			
			for (var i:int = 1; i < k; i++)
			{
				p = new Particle();
				tail.next = p;
				tail = p;
			}
		}
		
		public function addParticles(x:Number, y:Number, n:int):void
		{
			while ( --n > -1) {
				addParticle(x + Random.float(-15, 15), y + Random.float(-15, 15));
			}
		}
		
		public function addParticle(x:Number, y:Number):void
		{
			var p:Particle = head;
			
			head = head.next;
			tail.next = p;
			p.next = null;
			tail = p;
			
			tail.init(x, y);
		}
		
		public static function drawLine(bmp:BitmapData, x0:int, y0:int, x1:int, y1:int, color:uint):void
		{
			var ay:int = y1 - y0;
			ay = (ay ^ (ay >> 31)) - (ay >> 31);//abs
			var ax:int = x1 - x0;
			ax = (ax ^ (ax >> 31)) - (ax >> 31);
			var steep:Boolean = Boolean(ay > ax);
			if (steep) {
				x0 ^= y0;
				y0 ^= x0;
				x0 ^= y0;
				
				x1 ^= y1;
				y1 ^= x1;
				x1 ^= y1;
			}
			if (x0 > x1) {
				x0 ^= x1;
				x1 ^= x0;
				x0 ^= x1;
				
				y0 ^= y1;
				y1 ^= y0;
				y0 ^= y1;
			}
			var deltax:int = x1 - x0;
			var deltay:int = y1 - y0;
			deltay = (deltay ^ (deltay >> 31)) - (deltay >> 31);
			
			var error:int = deltax >> 1;
			var ystep:int;
			var y:int = y0;
			if (y0 < y1) {
				ystep = 1;
			} else {
				ystep = -1;
			}
			for (var x:int = x0; x <= x1; ++x) {
				if (steep) {
					bmp.setPixel32(y, x, color);
				} else {
					bmp.setPixel32(x, y, color);
				}
				error = error - deltay;
				if (error < 0) {
					y = y + ystep;
					error = error + deltax;
				}
			}
		}
		
	}
	
}