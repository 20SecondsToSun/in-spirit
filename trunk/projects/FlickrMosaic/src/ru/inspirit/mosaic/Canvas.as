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
		public var tileSprite:Sprite;
		
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
			tileSprite = new Sprite();
			//
			imageLoader = new Loader();
			imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImageLoaded);
			
			layers.addChild(img);
			layers.addChild(pixelImage);
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
			
			pixelImage.blendMode = "screen";
			tileSprite.blendMode = "multiply";
			
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
			buildTileHolder();
			//
			tilingInfo.visible = true;
			//
			tileTimer.reset();
			tileTimer.start();
			//
			addEventListener(MouseEvent.MOUSE_MOVE, scrollLayer);
			addEventListener(MouseEvent.MOUSE_WHEEL, mouseZoom);
		}
		
		/**
		* This workaround was made to allow resizing result mosaic at the maximum size
		* we cant draw all tiles in one Bitmap cause of size restrictions.
		*/
		private function buildTileHolder():void
		{
			var w:Number = source.width * maxZoom;
			var h:Number = source.height * maxZoom;
			var px:int = Math.floor(source.width / Main.pixelSize);
			var py:int = Math.floor(source.height / Main.pixelSize);
			var halfW:int = Math.ceil(px / 2);
			var halfH:int = Math.ceil(py / 2);
			var tl_w:Number = halfW * 75;
			var tr_w:Number = w - tl_w;
			var tl_h:Number = halfH * 75;
			var bl_h:Number = h - tl_h;
			//
			var r_tl:BitmapData = new BitmapData(tl_w, tl_h, true, 0x00FFFFFF);
			var r_tr:BitmapData = new BitmapData(tr_w, tl_h, true, 0x00FFFFFF);
			var r_bl:BitmapData = new BitmapData(tl_w, bl_h, true, 0x00FFFFFF);
			var r_br:BitmapData = new BitmapData(tr_w, bl_h, true, 0x00FFFFFF);
			//
			tile_TL = new Bitmap(r_tl);
			tile_TR = new Bitmap(r_tr);
			tile_BL = new Bitmap(r_bl);
			tile_BR = new Bitmap(r_br);
			//
			tile_TR.x = tile_BR.x = tl_w;
			tile_BL.y = tile_BR.y = tl_h;
			//
			tileSprite.addChild(tile_TL);
			tileSprite.addChild(tile_TR);
			tileSprite.addChild(tile_BL);
			tileSprite.addChild(tile_BR);
			//
			tileSprite.width = img.width;
			tileSprite.height = img.height;
		}
		
		private function setTilePlace(ind:int):void
		{
			var p:Object = tileQue[ind];
			var c:uint = source.getPixel32(p.x*Main.pixelSize + 1, p.y*Main.pixelSize + 1);
			var t:TileItem;
			var bmp:BitmapData;
			var tx:int;
			var ty:int;
			var ts:int = 75;
			t = TileBank.findTile(c);
			if (t != null) {
			//	var bmp:BitmapData = new BitmapData(t._bmp.width, t._bmp.height, true, c);
			//	var k:Number = .4;
			//	var ct:ColorTransform = new ColorTransform(1, 1, 1, 1, (c >> 16 & 0xff)*k, (c >> 8 & 0xff)*k, (c & 0xff)*k, 0);
			//	bmp.draw(t._bmp, null, ct);
				tx = p.x * ts;
				ty = p.y * ts;
				if ((tx + ts) <= tile_TL.width && (ty + ts) <= tile_TL.height) {
					bmp = tile_TL.bitmapData;
				} else if ((tx + ts) <= tile_TL.width && (ty + ts) > tile_TL.height) {
					bmp = tile_BL.bitmapData;
					ty -= tile_TL.height;
				} else if ((tx + ts) > tile_TL.width && (ty + ts) <= tile_TL.height) {
					bmp = tile_TR.bitmapData;
					tx -= tile_TL.width;
				} else if ((tx + ts) > tile_TL.width && (ty + ts) > tile_TL.height) {
					bmp = tile_BR.bitmapData;
					tx -= tile_TL.width;
					ty -= tile_TL.height;
				}
				bmp.copyPixels(t._bmp, t._bmp.rect, new Point(tx, ty));
			}
			tileQue.splice(ind, 1);
			//
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
			// resize to exact dimensions
			img.width = pixelImage.width = w;
			img.height = pixelImage.height = h;
			tileSprite.scaleX = tileSprite.scaleY = 1;
			layers.scrollRect = null;
			
			var bmp1:BitmapData = new BitmapData(tile_TL.width, tile_TL.height, false, 0x000000);
			var bmp2:BitmapData = new BitmapData(tile_TR.width, tile_TR.height, false, 0x000000);
			var bmp3:BitmapData = new BitmapData(tile_BL.width, tile_BL.height, false, 0x000000);
			var bmp4:BitmapData = new BitmapData(tile_BR.width, tile_BR.height, false, 0x000000);
			bmp1.draw(layers, new Matrix(1, 0, 0, 1, 0, 0), null, null, bmp1.rect);
			bmp2.draw(layers, new Matrix(1, 0, 0, 1, -tile_TL.width, 0)), null, null, bmp2.rect;
			bmp3.draw(layers, new Matrix(1, 0, 0, 1, 0, -tile_TL.height), null, null, bmp3.rect);
			bmp4.draw(layers, new Matrix(1, 0, 0, 1, -tile_BL.width, -tile_TR.height), null, null, bmp4.rect);
			
			// resize back
			img.scaleX = img.scaleY = z;
			pixelImage.scaleX = pixelImage.scaleY = z;
			tileSprite.width = img.width;
			tileSprite.height = img.height;
			layers.scrollRect = scrollR;
			//
			if (Main.pixelSize < 10) {
				je.PixelsPerIteration = 64;
			} else {
				je.PixelsPerIteration = 128;
			}
			je.encodeMultiToOne([
								[bmp1, bmp2],
								[bmp3, bmp4]
								]);
			tilingInfo.visible = true;
			_owner.enableControls = false;
		}
		
		private function onEncodingComplete(e:Event):void 
		{
			(tilingInfo.getChildByName("_txt") as TextField).text = 'ENCODING POSTER COMPLETE\nCLICK HERE TO SAVE IT';
			tilingInfo.buttonMode = true;
			tilingInfo.addEventListener(MouseEvent.CLICK, processSave);
		}
		
		private function processSave(e:MouseEvent):void 
		{
			LocalFile.saveFile(je.ImageData, 'mosaic.jpg');
			
			je.cleanUp();
			
			tilingInfo.buttonMode = false;
			tilingInfo.removeEventListener(MouseEvent.CLICK, processSave);
			tilingInfo.visible = false;
			
			_owner.enableControls = true;
		}
		
		private function onEncodingProgress(e:ProgressEvent):void 
		{
			(tilingInfo.getChildByName("_txt") as TextField).text = 'ENCODING POSTER\nPROGRESS: ' + Math.round(e.bytesLoaded/e.bytesTotal * 100) + '%';
		}
		
		private function zoomCanvas(delta:Number = 0):void
		{
			var z:Number = pixelImage.scaleX;
			z += delta;
			z = Math.max(z, 1);
			z = Math.min(z, maxZoom);
			//
			pixelImage.scaleX = pixelImage.scaleY = z;
			//img.scaleX = img.scaleY = z;
			img.width = pixelImage.width;
			img.height = pixelImage.height;
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
			var b:Bitmap;
			while (tileSprite.numChildren) {
				b = tileSprite.removeChildAt(0) as Bitmap;
				b.bitmapData.dispose();
			}
		}
		
		public function clear():void
		{
			tileTimer.stop();
			if (source != null) source.dispose();
			//
			clearTiles();
			img.scaleX = img.scaleY = pixelImage.scaleX = pixelImage.scaleY = tileSprite.scaleX = tileSprite.scaleY = 1;
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