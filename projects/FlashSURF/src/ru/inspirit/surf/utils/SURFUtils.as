package ru.inspirit.surf.utils  
{
	import ru.inspirit.surf.IPoint;

	import test.MatchElement;

	import flash.display.Bitmap;
	import flash.display.Graphics;
	import flash.display.Sprite;

	/**
	 * @author Eugene Zatepyakin
	 */
	public class SURFUtils 
	{
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
		
		public static function drawMatchedBitmaps(matches:Vector.<MatchElement>, sp:Sprite):void
		{
			var n:int = matches.length;
			var w:int = 200;
			var h:int = 0;
			
			while(sp.numChildren)
			{
				sp.removeChildAt(0);
			}
			
			sp.scaleX = sp.scaleY = 1;
			
			for(var i:int = 0; i < n; ++i)
			{
				var b:Bitmap = new Bitmap(matches[i].bitmap);
				b.width = w;
				b.scaleY = b.scaleX;
				b.y = h + 10;
				
				h += b.height + 10;
				 
				sp.addChild(b);
			}
			
			if(sp.height + 10 > 490)
			{
				sp.height = 480;
				sp.scaleX = sp.scaleY;
			}
		}
		
		public static function sortMatchedElements(a:Vector.<MatchElement>, n:int):void
		{
			var i:int = 0, j:int = 0, k:int = 0, t:int;
			var m:int = n * .125;
			var l:Vector.<int> = new Vector.<int>(m, true);
			var anmin:int = a[0].matchCount;
			var nmax:int  = 0;
			var nmove:int = 0;

			for (i = 1; i < n; ++i)
			{
				if ( (t = a[i].matchCount) < anmin) anmin = t;
				if (t > a[nmax].matchCount) nmax = i;
			}

			if (anmin == a[nmax].matchCount) return;

			var c1:Number = (m - 1) / (a[nmax].matchCount - anmin);

			for (i = 0; i < n; ++i)
			{
				//k = (c1 * (a[i].matchCount - anmin));
				//++l[k];
				l[ (c1 * (a[i].matchCount - anmin)) | 0 ] ++;
			}

        	for (k = 1, t = 0; k < m; ++k, ++t)
			{
				l[k] += l[t];
			}

			var hold:MatchElement = a[nmax];
			a[nmax] = a[0];
			a[0] = hold;

			var flash:MatchElement;
			j = 0;
			k = int(m - 1);
			i = int(n - 1);

			while (nmove < i)
			{
				while (j > (l[k]-1))
				{
					k = (c1 * (a[ int(++j) ].matchCount - anmin));
				}

				flash = a[j];

				while (!(j == l[k]))
				{
					k = (c1 * (flash.matchCount - anmin));
					hold = a[ (t = int(l[k]-1)) ];
					a[ t ] = flash;
					flash = hold;
					--l[k];
					++nmove;
				}
			}

			for(j = 1; j < n; ++j)
	        {
	            hold = a[j];
	            i = (j - 1);
	            while(i >= 0 && a[i].matchCount > hold.matchCount)
	                a[(i+1) | 0] = a[ int(i--) ];
	            a[(i+1) | 0] = hold;
	        }
		}
		
		public static function sortMatchedElementsThresh(a:Vector.<MatchElement>, n:int):void
		{
			var i:int = 0, j:int = 0, k:int = 0, t:int;
			var m:int = n * .125;
			var l:Vector.<int> = new Vector.<int>(m, true);
			var anmin:int = a[0].sortThreshold;
			var nmax:int  = 0;
			var nmove:int = 0;

			for (i = 1; i < n; ++i)
			{
				if ( (t = a[i].sortThreshold) < anmin) anmin = t;
				if (t > a[nmax].sortThreshold) nmax = i;
			}

			if (anmin == a[nmax].sortThreshold) return;

			var c1:Number = (m - 1) / (a[nmax].sortThreshold - anmin);

			for (i = 0; i < n; ++i)
			{
				//k = (c1 * (a[i].matchCount - anmin));
				//++l[k];
				l[ (c1 * (a[i].sortThreshold - anmin)) | 0 ] ++;
			}

        	for (k = 1, t = 0; k < m; ++k, ++t)
			{
				l[k] += l[t];
			}

			var hold:MatchElement = a[nmax];
			a[nmax] = a[0];
			a[0] = hold;

			var flash:MatchElement;
			j = 0;
			k = int(m - 1);
			i = int(n - 1);

			while (nmove < i)
			{
				while (j > (l[k]-1))
				{
					k = (c1 * (a[ int(++j) ].sortThreshold - anmin));
				}

				flash = a[j];

				while (!(j == l[k]))
				{
					k = (c1 * (flash.sortThreshold - anmin));
					hold = a[ (t = int(l[k]-1)) ];
					a[ t ] = flash;
					flash = hold;
					--l[k];
					++nmove;
				}
			}

			for(j = 1; j < n; ++j)
	        {
	            hold = a[j];
	            i = (j - 1);
	            while(i >= 0 && a[i].sortThreshold > hold.sortThreshold)
	                a[(i+1) | 0] = a[ int(i--) ];
	            a[(i+1) | 0] = hold;
	        }
		}
		
		public static function sortMatchedElementsInsert(a:Vector.<MatchElement>, n:int):void
		{
			var i:int, j:int;
			var hold:MatchElement;
			
			for(j = 1; j < n; ++j)
	        {
	            hold = a[j];
	            i = (j - 1);
	            while(i >= 0 && a[i].matchCount > hold.matchCount)
	                a[(i+1) | 0] = a[ int(i--) ];
	            a[(i+1) | 0] = hold;
	        }
		}
		
		public static function sortMatchedElementsThreshInsert(a:Vector.<MatchElement>, n:int):void
		{
			var i:int, j:int;
			var hold:MatchElement;
			
			for(j = 1; j < n; ++j)
	        {
	            hold = a[j];
	            i = (j - 1);
	            while(i >= 0 && a[i].sortThreshold > hold.sortThreshold)
	                a[(i+1) | 0] = a[ int(i--) ];
	            a[(i+1) | 0] = hold;
	        }
		}
		
	}
}
