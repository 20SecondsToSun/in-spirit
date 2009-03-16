package ru.inspirit.mosaic 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	import flash.utils.Timer;
	import flash.text.TextField;
	import ru.inspirit.ui.KeyboardShortcut;
	import ru.inspirit.utils.JPGEncoder;
	import ru.inspirit.utils.LocalFile;
	import ru.inspirit.utils.Random;
	
	/**
	* Main photo canvas.
	* All tiling processes displaying hear.
	* 
	* @author Eugene Zatepyakin
	*/
	public class Canvas extends Sprite
	{
		
		private const maxImageWidth:int = 800;
		private const maxImageHeight:int = 550;
		private const maxBitmap:int = 4000;
		
		private var maxZoom:Number;
		
		public var layers:Sprite;
		public var img:Bitmap;
		public var pixelImage:Bitmap;
		public var tileSprite:TileLayer;
		
		public var renderedImage:Sprite;
		
		private var tile_TL:Bitmap;
		private var tile_TR:Bitmap;
		private var tile_BL:Bitmap;
		private var tile_BR:Bitmap;
		
		public var scrollR:Rectangle;
		
		public static var source:BitmapData;
		
		private var imageLoader:Loader;
		
		private var tileTimer:Timer;
		private var tileQue:Array;
		private var row:int = 0;
		private var col:int = 0;
		private var tilingInfo:Sprite;
		private var totalTiles:int;
		
		private var _owner:Main;
		private var je:JPGEncoder;
		private var originalImage:BitmapData;
		
		public function Canvas(own:Main) 
		{
			_owner = own;
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			layers = new Sprite();
			img = new Bitmap();
			pixelImage = new Bitmap();
			tileSprite = new TileLayer();
			//
			imageLoader = new Loader();
			imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImageLoaded);
			
			layers.addChild(img);
			//layers.addChild(pixelImage); // there is no need to show this layer
			layers.addChild(tileSprite);
			addChild(layers);
			
			tilingInfo = new Sprite();
			tilingInfo.graphics.beginFill(0x000000, .8);
			tilingInfo.graphics.drawRoundRect(0, 0, 200, 50, 10);
			tilingInfo.graphics.endFill();
			
			var txt:TextField = new TextField();
			txt.name = "_txt";
			txt.defaultTextFormat = new flash.text.TextFormat("_sans", 12, 0xFFFFFF, false, false, false, null, null, "center");
			txt.text = "TILING";
			txt.width = 200;
			txt.height = 42;
			txt.selectable = false;
			txt.y = 8;
			tilingInfo.addChild(txt);
			
			var emptyBtn:Sprite = new Sprite();
			emptyBtn.graphics.beginFill(0x000000, 0);
			emptyBtn.graphics.drawRoundRect(0, 0, 200, 50, 10);
			emptyBtn.graphics.endFill();
			tilingInfo.addChild(emptyBtn);
			
			tilingInfo.visible = false;
			addChild(tilingInfo);
			
			scrollR = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight - y);
			layers.scrollRect = scrollR;
			
			tileTimer = new Timer(10);
			tileTimer.addEventListener(TimerEvent.TIMER, tileTick);
			
			je = new JPGEncoder(90);
			je.addEventListener(ProgressEvent.PROGRESS, onEncodingProgress);
			je.addEventListener(Event.COMPLETE, onEncodingComplete);
			
			root.stage.addEventListener(Event.RESIZE, onResize);
			
			// Keyboard shortcuts for zooming
			KeyboardShortcut.createInstance(root.stage);
			KeyboardShortcut.getInstance().addShortcut(zoomCanvas, [Keyboard.CONTROL, 187], .5);
			KeyboardShortcut.getInstance().addShortcut(zoomCanvas, [Keyboard.CONTROL, 189], -.5);
		}
		
		public function setPixelSize(s:int):void
		{
			if (source != null) source.dispose();
			var tmp_bmp:BitmapData = new BitmapData(int(img.width/s - .5), int(img.height/s - .5), false, 0xFFFFFF);
			tmp_bmp.draw(img.bitmapData, new Matrix(1 / s, 0, 0, 1 / s, 0, 0));
			
			source = new BitmapData(tmp_bmp.width*s, tmp_bmp.height*s, false, 0xFFFFFF);
			source.draw(tmp_bmp, new Matrix(s, 0, 0, s, 0, 0));
			
			var newImg:BitmapData = source.clone();
			var k:Number = Math.max(source.width/originalImage.width, source.height/originalImage.height);
			newImg.draw(originalImage, new Matrix(k, 0, 0, k, 0, 0));
			
			tmp_bmp.dispose();
			tmp_bmp = null;
			pixelImage.bitmapData = source;
			img.bitmapData = newImg;
			//
			maxZoom = 75 / s;
			//
			onResize();
		}
		
		public function startTiling():void
		{
			tileQue = new Array();
			totalTiles = 0;
			var r:int = 0;
			var c:int = 0;
			for (var i:int = 0; i < source.width; i += Main.pixelSize) {
				for (var j:int = 0; j < source.height; j += Main.pixelSize) {
					tileQue.push( { x:c, y:r } );
					r ++;
					totalTiles ++;
				}
				c ++;
				r = 0;
			}
			//
			tileSprite.buildLayer(source.width, source.height, maxZoom);
			tileSprite.width = img.width;
			tileSprite.height = img.height;
			//
			tilingInfo.visible = true;
			//
			tileTimer.reset();
			tileTimer.start();
			//
			addEventListener(MouseEvent.MOUSE_MOVE, scrollLayer);
			addEventListener(MouseEvent.MOUSE_WHEEL, mouseZoom);
		}
		
		private function setTilePlace(ind:int):void
		{
			var p:Object = tileQue[ind];
			var c:uint = source.getPixel32(p.x*Main.pixelSize + 1, p.y*Main.pixelSize + 1);
			var t:TileItem;
			var ts:int = 75;
			
			t = TileBank.findTile(c);
			
			if (t != null) {
				tileSprite.placeTile(p.x * ts, p.y * ts, t, c, img.bitmapData);
			}
			
			tileQue.splice(ind, 1);
			
			(tilingInfo.getChildByName("_txt") as TextField).text = "TILING " + (totalTiles) + " / " + (totalTiles - tileQue.length) + "\nuse scroll wheel to zoom in/out";
		}
		
		private function tileTick(e:TimerEvent):void 
		{
			var ind:int = Random.integer(0, tileQue.length);
			for (var i:int = 0; i < 4; i++) {
				ind = Random.integer(0, tileQue.length);				
				if (tileQue.length) {
					setTilePlace(ind);
				} else {
					break;
				}
			}
			if (tileQue.length == 0) {
				tilingInfo.visible = false;
				tileTimer.stop();
				_owner.onTilingFinished();
			}
		}
		
		public function savePoster():void 
		{
			var w:Number = int(source.width * maxZoom);
			var h:Number = int(source.height * maxZoom);
			var z:Number = img.scaleY;
			
			var arr:Array = tileSprite.getEncodeArray();
			var e_arr:Array = [];
			var b:Bitmap;
			for (var i:uint = 0; i < arr.length; i++) {
				e_arr[i] = [];
				for (var j:uint = 0; j < arr[i].length; j++) {
					b = Bitmap(arr[i][j]);
					e_arr[i][j] = b.bitmapData;
				}
			}
			
			if (Main.pixelSize < 10) {
				je.PixelsPerIteration = 96;
			} else {
				je.PixelsPerIteration = 128;
			}
			
			je.encodeMultiToOne(e_arr);
			
			tilingInfo.visible = true;
			_owner.enableControls = false;
		}
		
		private function onEncodingComplete(e:Event):void 
		{
			(tilingInfo.getChildByName("_txt") as TextField).text = 'ENCODING POSTER COMPLETE\nCLICK HERE TO SAVE IT';
			tilingInfo.buttonMode = true;
			tilingInfo.addEventListener(MouseEvent.CLICK, processSave);
			tilingInfo.addEventListener(MouseEvent.MOUSE_OVER, onSaveBtnOver);
			tilingInfo.addEventListener(MouseEvent.MOUSE_OUT, onSaveBtnOut);
		}
		
		private function onSaveBtnOver(e:MouseEvent):void
		{
			tilingInfo.graphics.clear();
			tilingInfo.graphics.beginFill(0xFFFFFF, .8);
			tilingInfo.graphics.drawRoundRect(0, 0, 200, 50, 10);
			tilingInfo.graphics.endFill();
			(tilingInfo.getChildByName("_txt") as TextField).textColor = 0x000000;
		}
		
		private function onSaveBtnOut(e:MouseEvent = null):void
		{
			tilingInfo.graphics.clear();
			tilingInfo.graphics.beginFill(0x000000, .8);
			tilingInfo.graphics.drawRoundRect(0, 0, 200, 50, 10);
			tilingInfo.graphics.endFill();
			(tilingInfo.getChildByName("_txt") as TextField).textColor = 0xFFFFFF;
		}
		
		private function processSave(e:MouseEvent):void 
		{
			LocalFile.saveFile(je.ImageData, 'mosaic.jpg');
			
			je.cleanUp();
			
			onSaveBtnOut();
			tilingInfo.buttonMode = false;
			tilingInfo.removeEventListener(MouseEvent.CLICK, processSave);
			tilingInfo.removeEventListener(MouseEvent.MOUSE_OVER, onSaveBtnOver);
			tilingInfo.removeEventListener(MouseEvent.MOUSE_OUT, onSaveBtnOut);
			tilingInfo.visible = false;
			
			_owner.enableControls = true;
		}
		
		private function onEncodingProgress(e:ProgressEvent):void 
		{
			(tilingInfo.getChildByName("_txt") as TextField).text = 'ENCODING POSTER\nCOMPLETED: ' + Math.round(e.bytesLoaded/e.bytesTotal * 100) + '%';
		}
		
		private function zoomCanvas(delta:Number = 0):void
		{
			var z:Number = img.scaleX;
			z += delta;
			z = Math.max(z, 1);
			z = Math.min(z, maxZoom);
			
			img.scaleX = img.scaleY = z;
			tileSprite.width = img.width;
			tileSprite.height = img.height;
			onResize();
			scrollLayer();
		}
		
		private function mouseZoom(e:MouseEvent):void 
		{
			zoomCanvas(e.delta * .2);
		}
		
		private function scrollLayer(e:MouseEvent = null):void 
		{
			var w:Number = img.width;
			var h:Number = img.height;
			var sw:Number = stage.stageWidth;
			var sh:Number = stage.stageHeight - y;
			var pc:Number;
			var diff:Number;
			if(w > sw || h > sh){
				if (w > sw) {
					pc = mouseX / sw;
					diff = w - sw;
					scrollR.x = pc * diff;
				} else {
					scrollR.x = 0;
				}
				if (h > sh) {
					pc = mouseY / sh;
					diff = h - sh;
					scrollR.y = pc * diff;
				} else {
					scrollR.y = 0;
				}
				layers.scrollRect = scrollR;
			}
		}
		
		public function setImage(bmp:BitmapData):void
		{
			img.bitmapData = fitImage(bmp);
			originalImage = img.bitmapData.clone();
			clear();
			onResize();
		}
		
		public function loadImage(data:ByteArray):void
		{
			imageLoader.unload();
			imageLoader.loadBytes(data);
		}
		
		private function onImageLoaded(e:Event):void 
		{
			var w:Number = imageLoader.width;
			var h:Number = imageLoader.height;
			var bmp:BitmapData = new BitmapData(w, h, true, 0x00FFFFFF);
			bmp.draw(imageLoader);
			
			setImage(bmp);
			
			imageLoader.unload();
		}
		
		private function fitImage(bmp:BitmapData):BitmapData
		{
			var w:Number = bmp.width;
			var h:Number = bmp.height; 
			var _bmp:BitmapData;
			var k:Number;
			if(w > maxImageWidth || h > maxImageHeight){
				if ((w/maxImageWidth)<(h/maxImageHeight)) {
					k = (maxImageHeight / h);
				} else {
					k = (maxImageWidth / w);
				}
				_bmp = new BitmapData(int(w * k + .5), int(h * k + .5), true, 0x00FFFFFF);
				_bmp.draw(bmp, new Matrix(1 * k, 0, 0, 1 * k, 0, 0));
			} else {
				_bmp = new BitmapData(w, h, true, 0x00FFFFFF);
				_bmp.draw(bmp);
			}
			return _bmp;
		}
		
		public function clearTiles():void
		{
			tileSprite.destroy();
		}
		
		public function clear():void
		{
			tileTimer.stop();
			if (source != null) source.dispose();
			
			clearTiles();
			
			img.scaleX = img.scaleY = 1;
			tileSprite.scaleX = tileSprite.scaleY = 1;
			tilingInfo.visible = false;
		}
		
		private function onResize(e:Event = null):void 
		{
			var w:Number = img.width;
			var h:Number = img.height;
			var sw:Number = stage.stageWidth;
			var sh:Number = stage.stageHeight - y;
			//
			tilingInfo.x = int((sw - tilingInfo.width) * .5);
			tilingInfo.y = int((sh - tilingInfo.height) * .5);
			//
			scrollR.width = sw;
			scrollR.height = sh;
			if (w > sw || h > sh) {
				if (w <= sw) {
					scrollR.x = 0;
					layers.x = (sw - w) / 2;
				} else {
					layers.x = 0;
				}
				if (h <= sh) {
					scrollR.y = 0;
					layers.y = (sh - h) / 2;
				} else {
					layers.y = 0;
				}
			} else {
				scrollR.x = scrollR.y = 0;
				layers.x = (sw - w) / 2;
				layers.y = (sh - h) / 2;
			}
			layers.scrollRect = scrollR;
		}
		
	}
	
}