package  
{
	import ru.inspirit.bitmapdata.CannyEdgeDetectorAlchemy;
	import com.bit101.components.CheckBox;
	import com.bit101.components.HUISlider;
	import com.bit101.components.Label;
	import com.bit101.components.Panel;
	import com.bit101.components.Style;
	import com.quasimondo.bitmapdata.CameraBitmap;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
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
	 
	[SWF(width='640',height='280',frameRate='100',backgroundColor='0x000000')]
	
	public class Main extends Sprite 
	{
		protected var CANNY:CannyEdgeDetectorAlchemy;
		
		private var view:Sprite;
		
		private var camera:CameraBitmap;
		private var edgesBmd:BitmapData;
		private var useBlur:Boolean = false;
		
		private var _timer:uint;
		private var _fps:uint;
		private var _ms:uint;
		private var _ms_prev:uint;
		private var alg_t:uint = 0;
		private var alg_n:uint = 0;
		
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
			
			CANNY = new CannyEdgeDetectorAlchemy(camera.bitmapData);
			CANNY.useTDSI = true;
			
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
			var tt:int = getTimer();
			
			CANNY.detectEdges(edgesBmd);
			
			alg_t += getTimer() - tt;
			alg_n ++;
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
			
			var sl:HUISlider = new HUISlider(p, 100, 5, 'LOW THRESHOLD', onLowThresChange);
			sl.setSliderParams(0.01, 1, 0.2);
			sl.labelPrecision = 3;
			sl.width = 250;
			
			sl = new HUISlider(p, 100, 18, 'HIGH THRESHOLD', onHighThresChange);
			sl.setSliderParams(0.1, 1, 0.9);
			sl.labelPrecision = 3;
			sl.width = 250;
			
			sl = new HUISlider(p, 440, 5, 'BLUR SIZE', onBlurSizeChange);
			sl.name = 'blur_slider';
			sl.setSliderParams(2, 10, 2);
			sl.labelPrecision = 0;
			sl.width = 200;
			
			var blde:CheckBox = new CheckBox(p, 360, 9, 'USE BLUR', onBoldChange);
			blde.selected = false;
			
			addEventListener(Event.ENTER_FRAME, countFrameTime);		
		}
		
		private function onLowThresChange(e:Event):void
		{
			CANNY.lowThreshold = HUISlider(e.currentTarget).value;
		}
		private function onHighThresChange(e:Event):void
		{
			CANNY.highThreshold = HUISlider(e.currentTarget).value;
		}
		private function onBlurSizeChange(e:Event):void
		{
			CANNY.blurSize = uint(HUISlider(e.currentTarget).value); 
		}

		private function onBoldChange(e:Event):void
		{
			useBlur = CheckBox(e.currentTarget).selected;
			if(useBlur) {
				CANNY.blurSize = uint(HUISlider(p.getChildByName('blur_slider')).value);
			} else {
				CANNY.blurSize = 0;
			}
		}
			
		private function countFrameTime(e:Event = null):void
		{
			_timer = getTimer();
			var lab:Label = Label(p.getChildByName('fps_txt'));
			if( _timer - 1000 >= _ms_prev )
			{
				_ms_prev = _timer;
				
				lab.text = 'FPS: ' + _fps + ' / ' + stage.frameRate + '\nRENDER TIME: ' + int(alg_t / alg_n + 0.5);
				
				_fps = alg_t = alg_n = 0;
			}
			
			_fps ++;
			_ms = _timer;
		}
		
		private function initStage():void
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			//stage.align = StageAlign.TOP_LEFT;
			
			var myContextMenu:ContextMenu = new ContextMenu();
			myContextMenu.hideBuiltInItems();
			
			
			var copyr:ContextMenuItem = new ContextMenuItem("© inspirit.ru", true, false);
			myContextMenu.customItems.push(copyr);
			
			contextMenu = myContextMenu;
		}
		
	}
}
