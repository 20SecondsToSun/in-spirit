package  
{
	import ru.inspirit.surf.FlashSURF;
	import ru.inspirit.surf.IPoint;
	import ru.inspirit.surf.RegionOfInterest;
	import ru.inspirit.surf.SURFOptions;
	import ru.inspirit.surf_example.FlashSURFExample;
	import ru.inspirit.surf_example.utils.QuasimondoImageProcessor;
	import ru.inspirit.surf_example.utils.RegionSelector;
	import ru.inspirit.surf_example.utils.SURFUtils;

	import com.bit101.components.CheckBox;
	import com.bit101.components.HUISlider;
	import com.bit101.components.Label;
	import com.bit101.components.PushButton;
	import com.quasimondo.bitmapdata.CameraBitmap;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	/**
	 * @author Eugene Zatepyakin
	 */
	
	[SWF(width='640',height='520',frameRate='33',backgroundColor='0x000000')]
	
	public class CameraRegionOfInterest extends FlashSURFExample 
	{
		public static const SCALE:Number = 1.5;
		public static const INVSCALE:Number = 1 / SCALE;

		public static const SCALE_MAT:Matrix = new Matrix(1/SCALE, 0, 0, 1/SCALE, 0, 0);
		public static const ORIGIN:Point = new Point();
		
		public var surf:FlashSURF;
		public var surfOptions:SURFOptions;
		public var quasimondoProcessor:QuasimondoImageProcessor = new QuasimondoImageProcessor();
		public var buffer:BitmapData;
		public var autoCorrect:Boolean = false;
		
		public var regionSelect:RegionSelector;
		public var myROI:RegionOfInterest;
		
		public var moveRegion:Boolean = false;
		public var rvx:int = 7;
		public var rvy:int = 6;
		
		protected var view:Sprite;
		protected var camera:CameraBitmap;
		protected var overlay:Shape;
		protected var screenBmp:Bitmap;
		
		protected var stat_txt:Label;
		
		public function CameraRegionOfInterest()
		{
			super();
			if(stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			stat_txt = new Label(p, 100, 5);
			
			var sl:HUISlider = new HUISlider(p, 310, 7, 'POINTS THRESHOLD', onThresholdChange);
			sl.setSliderParams(0.001, 0.01, 0.003);
			sl.labelPrecision = 4;
			sl.width = 240;
			
			new CheckBox(p, 210, 11, 'CORRECT LEVELS', onCorrectLevels);
			
			var pb:PushButton;
			
			pb = new PushButton(p, 550, 5, 'SELECT REGION', onSelectRegion);
			pb.height = 16;
			pb.width = 80;
			pb = new PushButton(p, 550, 20, 'MOVING REGION', onMoveRegion);
			pb.height = 16;
			pb.width = 80;
			
			view = new Sprite();
			view.y = 40;
			
			screenBmp = new Bitmap();
			view.addChild(screenBmp);

			overlay = new Shape();
			view.addChild(overlay);
			
			regionSelect = new RegionSelector(new Rectangle(0, 0, 640, 480));
			view.addChild(regionSelect);
			
			camera = new CameraBitmap(640, 480, 15, false);
			
			screenBmp.bitmapData = camera.bitmapData;
			
			surfOptions = new SURFOptions(int(640 / SCALE), int(480 / SCALE), 200, 0.003, true, 4, 4, 2);
			surf = new FlashSURF(surfOptions);
			
			myROI = new RegionOfInterest(0, 0, surfOptions.width, surfOptions.height);
			
			buffer = new BitmapData(surfOptions.width, surfOptions.height, false, 0x00);
			buffer.lock();

			addChild(view);
			
			camera.addEventListener(Event.RENDER, render);
		}

		protected function render( e:Event ) : void
		{
			var gfx:Graphics = overlay.graphics;
			gfx.clear();
			
			buffer.draw(camera.bitmapData, SCALE_MAT);
			
			if(moveRegion) 
			{
				myROI.x += rvx;
				myROI.y += rvy;
				if(myROI.left < 0) 
				{
					myROI.x = 0;
					rvx *= -1;
				}
				if(myROI.top < 0) 
				{
					myROI.y = 0;
					rvy *= -1;
				}
				if(myROI.right > surfOptions.width) 
				{
					myROI.x = surfOptions.width - myROI.width;
					rvx *= -1;
				}
				if(myROI.bottom > surfOptions.height) 
				{
					myROI.y = surfOptions.height - myROI.height;
					rvy *= -1;
				}
				
				surf.updateROI(myROI);
			}
			
			if(myROI.width < buffer.width || myROI.height < buffer.height)
			{
				gfx.lineStyle(1, 0xFFFFFF, 0.8);
				gfx.beginFill(0x333333, 0.5);
				gfx.drawRect(myROI.x * SCALE, myROI.y * SCALE, myROI.width * SCALE, myROI.height * SCALE);
			}
			
			var ipts:Vector.<IPoint> = surf.getInterestPoints(buffer);
			SURFUtils.drawIPoints(gfx, ipts, SCALE);
			
			stat_txt.text = 'FOUND POINTS: ' + surf.currentPointsCount;
		}

		protected function onSelectRegion(e:Event = null):void
		{
			moveRegion = false;
			
			if(!regionSelect.visible)
			{
				regionSelect.init();
				camera.active = false;
				overlay.graphics.clear();
			} else
			{
				if(regionSelect.rect.width > 20 && regionSelect.rect.height > 20) 
				{
					myROI.x = regionSelect.rect.x * INVSCALE;
					myROI.y = regionSelect.rect.y * INVSCALE;
					myROI.width = regionSelect.rect.width * INVSCALE;
					myROI.height = regionSelect.rect.height * INVSCALE;
					
					surf.updateROI(myROI);
				}
				
				regionSelect.uninit();
				camera.active = true;
			}
		}
		
		protected function onMoveRegion(e:Event):void 
		{
			moveRegion = !moveRegion;
			if(moveRegion)
			{
				if(myROI.width == surfOptions.width) myROI.width = surfOptions.width * 0.2;
				if(myROI.height == surfOptions.height) myROI.height = surfOptions.height * 0.2;
			}
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
