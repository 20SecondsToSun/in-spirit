package {
	import flash.utils.ByteArray;
	import ru.inspirit.surf.FlashSURF;
	import ru.inspirit.surf.IPoint;
	import ru.inspirit.surf.SURFOptions;
	import ru.inspirit.surf_example.FlashSURFExample;
	import ru.inspirit.surf_example.MatchElement;
	import ru.inspirit.surf_example.MatchList;
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
	 * Dynamicly add selected region as match reference
	 * with ability to save current MatchList as local file
	 * and also to load that file as MatchList
	 *  
	 * @author Eugene Zatepyakin
	 */
	 
	[SWF(width='840',height='520',frameRate='33',backgroundColor='0x000000')]
	
	public class DynamicMatchesWithSaveAndLoadRefs extends FlashSURFExample 
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
		
		public var matchList:MatchList;
		public var regionSelect:RegionSelector;
		
		protected var view:Sprite;
		protected var camera:CameraBitmap;
		protected var overlay:Shape;
		protected var screenBmp:Bitmap;
		protected var matchView:Sprite;
		
		protected var stat_txt:Label;
		
		public function DynamicMatchesWithSaveAndLoadRefs() 
		{
			super();
			if(stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			stat_txt = new Label(p, 100, 5);
			
			var sl:HUISlider = new HUISlider(p, 340, 7, 'POINTS THRESHOLD', onThresholdChange);
			sl.setSliderParams(0.001, 0.01, 0.003);
			sl.labelPrecision = 4;
			sl.width = 250;
			
			new CheckBox(p, 230, 11, 'CORRECT LEVELS', onCorrectLevels);
			
			var pb:PushButton;
			
			pb = new PushButton(p, 590, 6, 'SELECT REGION', onSelectRegion);
			pb.height = 16;
			pb = new PushButton(p, 590, 21, 'CLEAR MATCHES', onClearList);
			pb.height = 16;
			
			pb = new PushButton(p, 700, 6, 'SAVE MATCHES', onSaveList);
			pb.height = 16;
			pb = new PushButton(p, 700, 21, 'LOAD MATCHES', onLoadList);
			pb.height = 16;
			
			view = new Sprite();
			view.y = 40;
			
			screenBmp = new Bitmap();
			view.addChild(screenBmp);
			
			matchView = new Sprite();
			matchView.x = 640;
			view.addChild(matchView);

			overlay = new Shape();
			view.addChild(overlay);
			
			regionSelect = new RegionSelector(new Rectangle(0, 0, 640, 480));
			view.addChild(regionSelect);
			
			camera = new CameraBitmap(640, 480, 15, false);
			
			screenBmp.bitmapData = camera.bitmapData;
			
			surfOptions = new SURFOptions(int(640 / SCALE), int(480 / SCALE), 200, 0.003, true, 4, 4, 2);
			surf = new FlashSURF(surfOptions);
			
			buffer = new BitmapData(surfOptions.width, surfOptions.height, false, 0x00);
			buffer.lock();

			addChild(view);
			
			matchList = new MatchList(surf);
			
			camera.addEventListener(Event.RENDER, render);
		}

		protected function onSaveList(e:Event):void 
		{
			SURFUtils.savePointsData( matchList.saveListToByteArray() );
		}

		protected function onLoadList(e:Event):void 
		{
			SURFUtils.openPointsDataFile(loadPointsDone);
		}
		
		protected function loadPointsDone(data:ByteArray):void 
		{
			matchList.initListFromByteArray(data);
		}

		protected function render( e:Event ) : void
		{
			var gfx:Graphics = overlay.graphics;
			gfx.clear();
			
			buffer.draw(camera.bitmapData, SCALE_MAT);
			
			var ipts:Vector.<IPoint> = surf.getInterestPoints(buffer);
			gfx.clear();
			SURFUtils.drawIPoints(gfx, ipts, SCALE);
			
			var matched:Vector.<MatchElement> = matchList.getMatches();
			
			SURFUtils.drawMatchedBitmaps(matched, matchView);
			
			stat_txt.text = 'FOUND POINTS: ' + surf.currentPointsCount + '\nPOINTS TO MATCH: ' + matchList.pointsCount;
		}

		protected function onSelectRegion(e:Event = null):void
		{
			if(!regionSelect.visible)
			{
				regionSelect.init();
				camera.active = false;
				PushButton(e.currentTarget).label = 'ADD REGION';
				PushButton(e.currentTarget).draw();
			} else
			{
				if(regionSelect.rect.width > 20 && regionSelect.rect.height > 20)
				{
					var bmp:BitmapData = new BitmapData(regionSelect.rect.width, regionSelect.rect.height, false, 0x00);
					bmp.copyPixels(camera.bitmapData, regionSelect.rect, new Point(0, 0));
					
					regionSelect.rect.x *= INVSCALE;
					regionSelect.rect.y *= INVSCALE;
					regionSelect.rect.width *= INVSCALE;
					regionSelect.rect.height *= INVSCALE;
					
					matchList.addRegionAsMatch(regionSelect.rect, bmp);
				}
				
				regionSelect.uninit();
				camera.active = true;
				PushButton(e.currentTarget).label = 'SELECT REGION';
			}
		}
		
		protected function onClearList(e:Event):void 
		{
			matchList.clear();
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
