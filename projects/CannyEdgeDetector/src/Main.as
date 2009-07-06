package  
{
	import ru.inspirit.bitmapdata.CannyEdgeDetector;

	import com.bit101.components.CheckBox;
	import com.bit101.components.HUISlider;
	import com.bit101.components.Label;
	import com.bit101.components.Panel;
	import com.bit101.components.Style;
	import com.quasimondo.bitmapdata.CameraBitmap;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.utils.getTimer;

	/**
	 * Canny Edge Detector Demo Application
	 * 
	 * @author Eugene Zatepyakin
	 * @see http://blog.inspirit.ru
	 */
	public class Main extends Sprite 
	{
		private var view:Sprite;
		
		private var camera:CameraBitmap;
		private var edgesBmd:BitmapData;
		
		private var cannyEdgesDetect:CannyEdgeDetector;
		private var _boldEdges:Boolean = false;
		
		private var _timer : uint;
		private var _fps : uint;
		private var _ms : uint;
		private var _ms_prev : uint;
		
		private var p:Panel;
		
		public var w:int = 320;
		public var h:int = 240;

		public function Main()
		{
			if(stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}

		private function init(e:Event = null):void
		{
			initStage();
			
			view = new Sprite();
			
			camera = new CameraBitmap(w, h, 25, true);
			camera.addEventListener(Event.RENDER, renderCamera);
			view.addChild(new Bitmap(camera.bitmapData));
			
			cannyEdgesDetect = new CannyEdgeDetector(camera.bitmapData);
			cannyEdgesDetect.lowThreshold = 0.03;
			cannyEdgesDetect.highThreshold = 0.18;
			
			edgesBmd = new BitmapData(w, h, false, 0x00);
			
			var b:Bitmap = new Bitmap(edgesBmd);
			b.x = 320;
			view.addChild(b);
			
			view.y = 40;
			addChild(view);
			
			initControls();
		}

		private function renderCamera(e:Event = null):void
		{
			//var tt:int = getTimer();
			
			if(_boldEdges){
				cannyEdgesDetect.detectEdgesBold(edgesBmd);
			} else {
				cannyEdgesDetect.detectEdges(edgesBmd);
			}
			
			//trace('process time:', getTimer() - tt);
		}
		
		private function initControls():void
		{
			Style.PANEL = 0x333333;
			Style.BUTTON_FACE = 0x333333;
			Style.LABEL_TEXT = 0xF6F6F6;
			
			p = new Panel(this);
			p.width = 640;
			p.height = 40;
			
			var lb:Label = new Label(p, 10, 5);
			lb.name = 'fps_txt';
			
			var sl:HUISlider = new HUISlider(p, 90, 5, 'LOW THRESHOLD', onLowThresChange);
			sl.setSliderParams(.01, .9, .03);
			sl.labelPrecision = 3;
			sl.width = 250;
			
			sl = new HUISlider(p, 90, 18, 'HIGH THRESHOLD', onHighThresChange);
			sl.setSliderParams(.01, 1.0, .18);
			sl.labelPrecision = 3;
			sl.width = 250;
			
			var blde:CheckBox = new CheckBox(p, 350, 22, 'GET BOLD EDGES', onBoldChange);
			blde.selected = false;
			
			blde = new CheckBox(p, 350, 9, 'NORMALIZE CONTRAST', onNormContrastChange);
			blde.selected = false;
			
			addEventListener(Event.ENTER_FRAME, countFrameTime);		
		}
		
		private function onLowThresChange(e:Event):void
		{
			cannyEdgesDetect.lowThreshold = HUISlider(e.currentTarget).value;
		}
		private function onHighThresChange(e:Event):void
		{
			cannyEdgesDetect.highThreshold = HUISlider(e.currentTarget).value;
		}
		private function onBoldChange(e:Event):void
		{
			_boldEdges = CheckBox(e.currentTarget).selected;
		}
		private function onNormContrastChange(e:Event):void
		{
			cannyEdgesDetect.doNormalizeContrast = CheckBox(e.currentTarget).selected;
		}
		
		private function countFrameTime(e:Event = null):void
		{
			_timer = getTimer();
			var lab:Label = Label(p.getChildByName('fps_txt'));
			if( _timer - 1000 >= _ms_prev )
			{
				_ms_prev = _timer;
				
				lab.text = 'FPS: ' + _fps + ' / ' + stage.frameRate + '\nMS:';
				
				_fps = 0;
			}
			
			_fps ++;
			lab.text = lab.text.split('MS:')[0] + 'MS: ' + (_timer - _ms);
			_ms = _timer;
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
