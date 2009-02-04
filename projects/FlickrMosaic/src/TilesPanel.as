package  
{
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import ru.inspirit.mosaic.TileBank;
	import ru.inspirit.mosaic.TileItem;
	import flash.text.TextField;
	
	/**
	* Tiles Panel class is using to display loading Flickr tiles
	* 
	* @author Eugene Zatepyakin
	*/
	public class TilesPanel extends Sprite
	{
		private const H:int = 300;
		private const tileSize:int = 75;
		
		private var bg:Sprite;
		private var infoSp:Sprite;
		private var thumbsSprite:Sprite;
		private var scrollR:Rectangle;
		private var col:int = 0;
		private var row:int = 0;
		private var thumbs:Array;
		
		private var isVisible:Boolean = false;
		
		public function TilesPanel() 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			//
			bg = new Sprite();
			addChild(bg);
			//
			thumbsSprite = new Sprite();
			addChild(thumbsSprite);
			//
			scrollR = new Rectangle(0, 0, stage.stageWidth, H);
			thumbsSprite.scrollRect = scrollRect;
			//
			infoSp = new Sprite();
			infoSp.graphics.beginFill(0x000000, .8);
			infoSp.graphics.drawRoundRect(0, 0, 250, 50, 10);
			infoSp.graphics.endFill();
			//
			var txt:TextField = new TextField();
			txt.name = "_txt";
			txt.defaultTextFormat = new flash.text.TextFormat("_sans", 12, 0xFFFFFF, false, false, false, null, null, "center");
			txt.text = "LOADING TILES";
			txt.width = 250;
			txt.selectable = false;
			txt.y = 15;
			infoSp.addChild(txt);
			addChild(infoSp);
			//
			thumbs = new Array();
			//
			visible = false;
			stage.addEventListener(Event.RESIZE, onResize);
			onResize();
		}
		
		public function putTile(t:TileItem):void
		{
			var b:Bitmap = new Bitmap( t._bmp, "always");
			b.x = col * tileSize;
			b.y = row * tileSize;
			//
			thumbsSprite.addChild(b);
			thumbs.push(b);
			if(!this.hitTestPoint(parent.mouseX, parent.mouseY)) scrollContent(null, stage.stageWidth);
			//
			(infoSp.getChildByName("_txt") as TextField).text = "LOADING TILES " + Main.totalFoundTiles + " / " + thumbs.length;
			//
			row ++;
			if (row >= H / tileSize) {
				row = 0;
				col++;
			}
		}
		
		public function show():void
		{
			if (!isVisible) {
				this.y = int((stage.stageHeight - H) * .5);
				visible = true;
				isVisible = true;
				//
				addEventListener(MouseEvent.MOUSE_MOVE, scrollContent);
			}
		}
		
		private function scrollContent(e:MouseEvent = null, mx:Number = -1):void 
		{
			var w:Number = col * tileSize;
			if (w > stage.stageWidth) {
				var pc:Number = (mx == -1 ? mouseX : mx) / stage.stageWidth;
				var diff:Number = w - stage.stageWidth;
				scrollR.x = pc * diff;
				thumbsSprite.scrollRect = scrollR;
			}
		}
		public function hide():void
		{
			if (isVisible) {
				this.y = (stage.stageHeight + H);
				visible = false;
				isVisible = false;
				removeEventListener(MouseEvent.MOUSE_MOVE, scrollContent);
			}
		}
		
		public function clear():void
		{
			var b:Bitmap;
			while (thumbs.length) {
				b = thumbs.pop();
				thumbsSprite.removeChild(b);
				b = null;
			}
			scrollR.x = 0;
			thumbsSprite.scrollRect = scrollR;
			//
			row = 0;
			col = 0;
		}
		
		private function onResize(e:Event = null):void 
		{
			bg.graphics.clear();
			bg.graphics.beginFill(0x000000, .5);
			bg.graphics.drawRect(0, 0, stage.stageWidth, H);
			bg.graphics.endFill();
			//
			if (isVisible) this.y = int((stage.stageHeight - H) * .5);
			infoSp.x = int((stage.stageWidth - infoSp.width) * .5);
			infoSp.y = int((H - 50) * .5);
			//
			scrollR.x = 0;
			scrollR.width = stage.stageWidth;
			thumbsSprite.scrollRect = scrollR;
		}
		
	}
	
}