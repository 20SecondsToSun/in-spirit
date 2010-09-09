package ru.inspirit.surf 
{
	import flash.geom.Rectangle;

	/**
	 * Region of interest describing the area to be processed
	 * for interest points data 
	 * 
	 * @author Eugene Zatepyakin
	 */
	public class RegionOfInterest extends Rectangle
	{
		
		public function RegionOfInterest(x:int = 0, y:int = 0, width:int = 0, height:int = 0)
		{
			super(x, y, width, height);
		}
		
		public static function fromRectangle(rect:Rectangle):RegionOfInterest
		{
			return new RegionOfInterest(rect.x, rect.y, rect.width, rect.height); 
		}
	}
}
