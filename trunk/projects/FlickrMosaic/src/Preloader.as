package 
{
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.utils.getDefinitionByName;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.ui.ContextMenuBuiltInItems;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	
	public class Preloader extends MovieClip
	{
		
		public function Preloader() 
		{
			addEventListener(Event.ENTER_FRAME, checkFrame);
			
			initStage();
			
			graphics.beginFill(0x333333);
			graphics.drawRect(10, 10, 100, 10);
			graphics.endFill();
		}
		
		private function checkFrame(e:Event):void 
		{
			// update loader
			var pc:int = Math.round((this.loaderInfo.bytesLoaded / this.loaderInfo.bytesTotal) * 98);
			graphics.beginFill(0xDDDDDD);
			graphics.drawRect(11, 11, pc, 8);
			graphics.endFill();
			//
			if (currentFrame == totalFrames)
			{
				removeEventListener(Event.ENTER_FRAME, checkFrame);
				startup();
			}
		}
		
		private function startup():void 
		{
			// hide loader
			graphics.clear();
			var mainClass:Class = getDefinitionByName("Main") as Class;
			addChild(new mainClass() as DisplayObject);
		}
		
		private function initStage():void
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			var myContextMenu:ContextMenu = new ContextMenu();
			myContextMenu.hideBuiltInItems();
			
			var copyr:ContextMenuItem = new ContextMenuItem("© inspirit.ru", true, false);
			myContextMenu.customItems.push(copyr);
			
			contextMenu = myContextMenu;
		}
		
	}
	
}