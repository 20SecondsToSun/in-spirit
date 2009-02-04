
/**
* Flickr Mosaic Engine
* 
* Released under MIT license:
* http://www.opensource.org/licenses/mit-license.php
* 
* @author Eugene Zatepyakin
* @see http://www.inspirit.ru/exchange/mosaic/
* @version 1.0
*/

package 
{
	import com.adobe.webapis.flickr.Photo;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.system.Security;
	import flash.utils.ByteArray;
	import ru.inspirit.flickr.events.FlickrEvent;
	import ru.inspirit.flickr.Flickr;
	import ru.inspirit.mosaic.Canvas;
	import ru.inspirit.mosaic.events.TileBankEvent;
	import ru.inspirit.mosaic.TileBank;
	import ru.inspirit.ui.MacMouseWheel;
	import ru.inspirit.utils.LocalFile;
	
	public class Main extends Sprite
	{
		
		private var flickr:Flickr;
		private var tiles:TileBank;
		private var canvas:Canvas;
		private var controls:Controls;
		private var tilesPan:TilesPanel;
		
		public static var flickrMethod:String = "tags";
		public static var flickrPool:String = 'interesting';
		public static var flickrTags:String = "portrait,face,famous";
		public static var flickrUser:String = "";
		public static var flickrUserID:String = "";
		public static var pixelSize:int = 10;
		public static var totalTiles:int = 100;
		public static var totalFoundTiles:int;
		
		public function Main():void
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			MacMouseWheel.setup(root.stage);
			
			tiles = new TileBank();
			tiles.addEventListener("TileLoaded", onTileLoaded);
			tiles.addEventListener("AllTilesLoaded", onTilesFinish);
			
			flickr = new Flickr();
			flickr.addEventListener("GET_PHOTOS", loadPhotos);
			flickr.addEventListener("FIND_USER", onUserFind);
			flickr.addEventListener("FlickrError", onFlickrError);
			
			canvas = new Canvas(this);
			canvas.y = 55;
			tilesPan = new TilesPanel();
			controls = new Controls(this);
			
			addChild(canvas);
			addChild(tilesPan);
			addChild(controls);
		}
		
		private function loadPhotos(e:FlickrEvent):void 
		{
			var photo:Photo;
			var t:int = e.photoList.photos.length;
			var i:int;
			for (i = 0; i < t; i++) {
				photo = e.photoList.photos[i];
				tiles.addTile(Flickr.getFlickrPhotoUrl(photo));
			}
			totalFoundTiles = t;
			tiles.nextQue();
			tilesPan.show();
		}
		
		public function startRender(reLoad:Boolean):void
		{
			tilesPan.clear();
			canvas.clear();
			canvas.setPixelSize(pixelSize);
			controls.initStep(TileBank.tiles.length == 0 ? 1 : 2);
			//
			if (reLoad) {
				tiles.clear();
				if (flickrMethod == "pool") {
					if (flickrPool == 'interesting') {
						flickr.getInterestingnessList(null, "", totalTiles);
					} else {
						flickr.getPoolPhotos(flickrPool, totalTiles);
					}
				} else if(flickrMethod == "tags"){
					flickr.getPhotos("", flickrTags, "all", totalTiles);
				} else if (flickrMethod == "user") {
					flickr.getPublicPhotos(flickrUserID, totalTiles);
				}
			} else {
				if (TileBank.tiles.length == 0) return;
				canvas.startTiling();
			}
		}
		
		private function onTileLoaded(e:TileBankEvent):void 
		{
			tilesPan.putTile(e.tile);
		}
		
		private function onTilesFinish(e:Event):void 
		{
			tilesPan.hide();
			if (TileBank.tiles.length == 0) return;
			canvas.startTiling();
		}
		
		public function onTilingFinished():void
		{
			controls.initStep(3);
		}
		
		public function savePoster():void
		{
			canvas.savePoster();
		}
		
		public function onOpenImagePress(e:Event):void
		{
			LocalFile.openFile(onFileSelected);
		}
		
		public function onFileSelected(data:ByteArray):void
		{
			canvas.loadImage(data);
			if(TileBank.tiles.length > 0){
				controls.initStep(2);
			} else {
				controls.initStep(1);
			}
		}
		
		public function onImageCaptured(bmp:BitmapData):void
		{
			canvas.setImage(bmp);
			if(TileBank.tiles.length > 0){
				controls.initStep(2);
			} else {
				controls.initStep(1);
			}
		}
		
		public function checkFlickrUser(un:String):void
		{
			flickr.getUserByName(un);
		}
		
		private function onUserFind(e:FlickrEvent):void 
		{
			controls.setUserInfo(e.user);
		}
		
		private function onFlickrError(e:FlickrEvent):void 
		{
			trace(e);
		}
	}
}