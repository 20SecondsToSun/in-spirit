package  
{
	import ru.inspirit.surf.IPoint;
	
	/**
	 * Simple K-Means algorithm
	 * 
	 * @author Eugene Zatepyakin
	 */
	 
	public final class KMeans 
	{
		
		public var maxDist:Number;
		public var points:Vector.<IPoint>;
		public var clusters:Vector.<IPoint>;
		
		public function KMeans()
		{
			//
		}
		
		public function run(pts:Vector.<IPoint>, num:int, maxDist:Number):void
		{
			this.maxDist = maxDist;
			this.points = pts;
			this.clusters = new Vector.<IPoint>(num, true);
			var len:int = points.length;
			var pind:int;
			
			var nc:IPoint;
			for(var i:int; i < num; ++i) {
				nc = points[ (pind = int(Math.random()*len)) ];
				clusters[i] = nc;
				clusters[i].clusterIndex = i;
				clusters[i].clusterChilds = 0;
				points.splice(pind, 1);
				len--;
			}
			
			while(assignToClusters())
			{
				repositionClusters();
			}
		}
		
		protected function assignToClusters():Boolean
		{
			var Updated:Boolean = false;
			var i:int, j:int, oldIndex:int;
			var pl:int = points.length;
			var cl:int = clusters.length;
			var bestDist:Number, currentDist:Number;
			var cp:IPoint, np:IPoint;
			
			for( i = 0; i < pl; ++i ) 
			{
				bestDist = 100000000;
				cp = points[i];
				oldIndex = cp.clusterIndex;
				
				for( j = 0; j < cl; ++j )
				{
					np = clusters[j];
					var dx:Number = cp.x - np.x;
					var dy:Number = cp.y - np.y;
					currentDist = Math.sqrt(dx*dx + dy*dy);
					if (currentDist < bestDist && currentDist < maxDist) 
					{
						bestDist = currentDist;
						cp.clusterIndex = j;
					} else {
						cp.clusterIndex = -1;
					}
				}
				if(oldIndex != cp.clusterIndex) Updated = true;
			}
			
			return Updated;
		}
		
		protected function repositionClusters():void
		{
			var i:int, j:int, count:int;
			var x:Number, y:Number, dx:Number, dy:Number;
			var ip:IPoint;
			var pl:int = points.length;
			var cl:int = clusters.length;
			
			for(i = 0; i < cl; ++i)
			{
				x = y = dx = dy = 0;
				count = 1;
				for( j = 0; j < pl; ++j )
				{
					if (points[j].clusterIndex == i)
					{
						ip = points[j];
						x += ip.x;
						y += ip.y;
						dx += ip.dx;
						dy += ip.dy;
						++count;
					}
				}
				clusters[i].clusterChilds = count - 1;
				clusters[i].x = x/count;
				clusters[i].y = y/count;
				clusters[i].dx = dx/count;
				clusters[i].dy = dy/count;
			}
		}
	}
}
