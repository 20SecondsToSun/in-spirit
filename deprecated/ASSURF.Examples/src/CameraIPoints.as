package  
{
	import ru.inspirit.surf.ASSURF;
	import ru.inspirit.surf.IPoint;
	import ru.inspirit.surf.SURFOptions;
	import ru.inspirit.surf_example.FlashSURFExample;
	import ru.inspirit.surf_example.utils.QuasimondoImageProcessor;
	import ru.inspirit.surf_example.utils.SURFUtils;

	import com.bit101.components.CheckBox;
	import com.bit101.components.HUISlider;
	import com.bit101.components.Label;
	import com.quasimondo.bitmapdata.CameraBitmap;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;

	/**
	 * Simple interest points extraction example
	 * 
	 * @author Eugene Zatepyakin
	 */
	 
	[SWF(width='640',height='520',frameRate='33',backgroundColor='0x000000')]
	
	public class CameraIPoints extends FlashSURFExample 
	{
		public static const SCALE:Number = 1.5;

		public static const SCALE_MAT:Matrix = new Matrix(1/SCALE, 0, 0, 1/SCALE, 0, 0);
		public static const ORIGIN:Point = new Point();
		
		public var surf:ASSURF;
		public var surfOptions:SURFOptions;
		public var quasimondoProcessor:QuasimondoImageProcessor;
		public var buffer:BitmapData;
		public var autoCorrect:Boolean = false;
		
		protected var view:Sprite;
		protected var camera:CameraBitmap;
		protected var overlay:Shape;
		protected var screenBmp:Bitmap;
		
		protected var stat_txt:Label;
		
		protected var maxPts:int = 0;
		protected var maxPtsT:int = 200;
		
		public function CameraIPoints()
		{
			super();
			
			if(stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			stat_txt = new Label(p, 100, 5);
			
			var sl:HUISlider = new HUISlider(p, 380, 7, 'POINTS THRESHOLD', onThresholdChange);
			sl.setSliderParams(0.001, 0.01, 0.003);
			sl.labelPrecision = 4;
			sl.width = 250;
			
			new CheckBox(p, 250, 11, 'CORRECT LEVELS', onCorrectLevels);
			
			view = new Sprite();
			view.y = 40;
			
			screenBmp = new Bitmap();
			view.addChild(screenBmp);

			overlay = new Shape();
			view.addChild(overlay);
			
			camera = new CameraBitmap(640, 480, 15, false);
			
			screenBmp.bitmapData = camera.bitmapData;
			
			surfOptions = new SURFOptions(int(640 / SCALE), int(480 / SCALE), 200, 0.003, true, 4, 4, 2);
			surf = new ASSURF(surfOptions);
			
			buffer = new BitmapData(surfOptions.width, surfOptions.height, false, 0x00);
			buffer.lock();
			
			quasimondoProcessor = new QuasimondoImageProcessor(buffer.rect);

			addChild(view);
			
			camera.addEventListener(Event.RENDER, render);
		}
		
		protected function render( e:Event ) : void
		{
			var gfx:Graphics = overlay.graphics;
			gfx.clear();
			
			buffer.draw(camera.bitmapData, SCALE_MAT);
			
			//var t:int = getTimer();
			
			// This is simple points extraction
			var ipts:Vector.<IPoint> = surf.getInterestPoints(buffer);
			
			//var tt:int = getTimer() - t;
			
			SURFUtils.drawIPoints(gfx, ipts, SCALE);
			
			stat_txt.text = 'FOUND POINTS: ' + surf.currentPointsCount;
			/*t = surf.currentPointsCount;
			if(t > maxPts) 
			{
				maxPts = surf.currentPointsCount;
				maxPtsT = tt;
			} else if(t == maxPts) 
			{
				maxPtsT = (maxPtsT + tt) * 0.5;
			}
			
			stat_txt.text = 'MAX PROCESSED IN: ' + maxPtsT;
			stat_txt.text += '\nMAX FOUND POINTS: ' + maxPts;*/
		}

		protected function onCorrectLevels(e:Event):void
		{
			autoCorrect = CheckBox(e.currentTarget).selected;
			surf.imageProcessor = autoCorrect ? quasimondoProcessor : null;
		}
		
		protected function onThresholdChange(e:Event):void
		{
			surf.pointsThreshold = HUISlider(e.currentTarget).value;
		}
	}
}
