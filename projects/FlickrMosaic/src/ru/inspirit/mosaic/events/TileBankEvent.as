package ru.inspirit.mosaic.events 
{
	import flash.events.Event;
	import ru.inspirit.mosaic.TileItem;
	
	/**
	* Simple event container
	* @author Eugene Zatepyakin
	*/
	public class TileBankEvent extends Event
	{
		
		public var tile:TileItem;
		
		public function TileBankEvent(type:String, t:TileItem = null) 
		{
			super(type);
			this.tile = t;
		}
		
	}
	
}