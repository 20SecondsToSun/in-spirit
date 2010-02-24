package ru.inspirit.surf
{

	/**
	 * Interest Point
	 * 
	 * @author Eugene Zatepyakin
	 */
	public class IPoint 
	{
		public var x:Number;
		public var y:Number;
		public var dx:Number;
		public var dy:Number;
		public var scale:Number;
		public var orientation:Number = 0;
		public var laplacian:Number;
		
		public var clusterIndex:int = 0;
		public var clusterChilds:int = 0;
		
		public function IPoint()
		{
			//
		}
	}
}
