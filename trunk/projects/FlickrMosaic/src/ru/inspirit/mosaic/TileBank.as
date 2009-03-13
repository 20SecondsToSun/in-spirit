package ru.inspirit.mosaic
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	import flash.utils.Timer;
	import ru.inspirit.mosaic.events.TileBankEvent;
	import ru.inspirit.utils.ColorUtils;
	import ru.inspirit.utils.Random;

	/**
	* Image tiles loader and holder
	* 
	* @author Eugene Zatepyakin
	*/
	public class TileBank extends EventDispatcher
	{

		public static var tiles:Vector.<TileItem>;
		private static var dict:Dictionary;
		
		private var que:Array;
		private var lTimers:Array;
		private var busy:Vector.<int>;
		private var loaders:Vector.<Loader>;
		private var maxLoaders:int = 4;
		private var maxTimeOut:int = 10;
		
		private var _finishing:Boolean = false;
		private var finishCheck:Timer;

		public function TileBank()
		{
			dict = new Dictionary();
			tiles = new Vector.<TileItem>();
			que = new Array();
			loaders = new Vector.<Loader>(maxLoaders, true);
			busy = new Vector.<int>(maxLoaders, true);
			//
			finishCheck = new Timer(20);
			finishCheck.addEventListener(TimerEvent.TIMER, checkFinished);
			//
			var l:Loader;
			for (var i:int = 0; i < maxLoaders; i++) {
				l = new Loader();
				l.name = i.toString();
				l.contentLoaderInfo.addEventListener(Event.COMPLETE, onTileLoaded);
				l.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onTileError);
				l.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onTileError);
				l.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, updateLoadingTime);
				loaders[i] = l;
				//
				busy[i] = 0;
			}
		}
		
		private function checkFinished(e:TimerEvent):void 
		{
			var i:int;
			var t:int = getTimer();
			for (i = 0; i < maxLoaders; i++) {
				if (busy[i] != 0 && (t - busy[i]) > maxTimeOut * 1000) {
					loaders[i].unload();
					busy[i] = 0;
					nextQue();
					return;
				}
			}
		}
		
		public static function findTile(c:uint):TileItem
		{
			var i:int;
			var t:TileItem;
			var bestDistance:Number = 100000;
			var d:Number;
			var ind:int;
			if (dict[c] != null) {
				return tiles[dict[c]];
			}
			for (i = 0; i < tiles.length; i++) {
				t = tiles[i];
				if ( c == t._color ) {
					ind = i;
					break;
				}
				d = ColorUtils.getDistance(c, t._color);
				if (d < bestDistance) {
					bestDistance = d;
					ind = i;
				}
			}
			dict[c] = ind;
			return tiles[ind];
		}

		public function addTile(url:String, autoStart:Boolean = false):void
		{
			que.push(url);
			_finishing = false;
			if(autoStart) nextQue();
		}

		private function storeTile(obj:DisplayObject, url:String):void
		{
			var t:TileItem;
			var bmp:BitmapData = new BitmapData(obj.width, obj.height, false, 0xFFFFFF);
			bmp.draw(obj);
			//
			t = new TileItem( bmp, url );
			tiles.push( t );
			dispatchEvent(new TileBankEvent("TileLoaded", t));
			nextQue();
		}
		
		public function nextQue():void
		{
			var l:Loader;
			var u:URLRequest;
			var lc:LoaderContext;
			var i:int;
			var t:int = getTimer();
			if (que.length) {
				for (i = 0; i < maxLoaders; i++) {
					if (busy[i] == 0) {
						l = loaders[i];
						l.unload();
						//
						u = new URLRequest(que.shift());
						lc = new LoaderContext(true);
						l.load(u, lc);
						busy[i] = getTimer();
						//
						//if (que.length == 0) break;
					} else {
						if ((t - busy[i]) > maxTimeOut * 1000) {
							loaders[i].unload();
							busy[i] = 0;
							nextQue();
						}
					}
				}
			} else {
				if (!_finishing) {
					finishCheck.start();
					_finishing = true;
				}
				var b:int = 0;
				for (i = 0; i < maxLoaders; i++) {
					if (busy[i] == 0) {
						b++;
					}
				}
				if (b == maxLoaders - 1) {
					finishCheck.stop();
					finishCheck.reset();
					_finishing = false;
					dispatchEvent(new TileBankEvent("AllTilesLoaded"));
				}
			}
			//trace("loading: ", que.length);
		}
		
		public function clear():void
		{
			var i:int;
			var l:Loader;
			var t:TileItem;
			for (i = 0; i < maxLoaders; i++) {
				l = loaders[i];
				l.unload();
				busy[i] = 0;
			}
			//
			while (tiles.length) {
				t = tiles.pop();
				t.destroy();
				t = null;
			}
			//
			dict = new Dictionary();
		}

		private function onTileLoaded(e:Event):void
		{
			var l:LoaderInfo = e.currentTarget as LoaderInfo;
			busy[int(l.loader.name)] = 0;
			storeTile(l.content, l.url);
		}
		
		private function onTileError(e:IOErrorEvent):void
		{
			var l:LoaderInfo = e.currentTarget as LoaderInfo;
			busy[int(l.loader.name)] = 0;
			trace(e);
			nextQue();
		}
		
		private function updateLoadingTime(e:ProgressEvent):void 
		{
			var l:LoaderInfo = e.currentTarget as LoaderInfo;
			busy[int(l.loader.name)] = getTimer();
		}
		
	}

}