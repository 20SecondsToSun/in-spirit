package ru.inspirit.mosaic 
{
	import flash.display.BitmapData;
	import ru.inspirit.utils.ColorUtils;
	
	/**
	* Tile container.
	* 
	* @author Eugene Zatepyakin
	*/
	public class TileItem 
	{
		
		public var _bmp:BitmapData;
		public var _url:String;
		public var _color:uint;
		
		public function TileItem(bmp:BitmapData, url:String) 
		{
			this._bmp = bmp;
			this._url = url;
			this._color = ColorUtils.averageColor(bmp);
		}
		
		public function destroy():void
		{
			this._bmp.dispose();
			this._bmp = null;
			this._url = null;
		}
	}
	
}