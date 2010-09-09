package  
{
	import flash.utils.ByteArray;
	import ru.inspirit.surf_example.MatchElement;
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
	 * Multiple images searching demonstartion
	 * It uses simple write and match technique
	 * 
	 * @author Eugene Zatepyakin
	 */
	
	[SWF(width='840',height='520',frameRate='33',backgroundColor='0x000000')]
	
	public class CameraMatchMultipleReferences extends FlashSURFExample 
	{
		[Embed(source = '../assets/rocky_lane.jpg')] private static const a_rocky_lane:Class;
		[Embed(source = '../assets/boy.jpg')] private static const a_boy:Class;
		[Embed(source = '../assets/graffiti_400.png')] private static const a_graffiti:Class;
		
		public static const els_names:Vector.<String> = Vector.<String>(['ROCKY LANE', 'BOY', 'GRAFFITI']);
		public static const els_bmds:Vector.<BitmapData> = Vector.<BitmapData>([
																					Bitmap(new a_rocky_lane()).bitmapData,
																					Bitmap(new a_boy()).bitmapData,
																					Bitmap(new a_graffiti()).bitmapData
																				]);
		
		public static const SCALE:Number = 1.5;

		public static const SCALE_MAT:Matrix = new Matrix(1/SCALE, 0, 0, 1/SCALE, 0, 0);
		public static const ORIGIN:Point = new Point();
		
		public var surf:ASSURF;
		public var surfOptions:SURFOptions;
		public var quasimondoProcessor:QuasimondoImageProcessor;
		public var buffer:BitmapData;
		public var autoCorrect:Boolean = false;
		
		public var matchEls:Vector.<MatchElement>;
		
		protected var view:Sprite;
		protected var camera:CameraBitmap;
		protected var overlay:Shape;
		protected var screenBmp:Bitmap;
		protected var matchView:Sprite;
		
		protected var stat_txt:Label;
		
		public function CameraMatchMultipleReferences()
		{
			super();
			if(stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			stat_txt = new Label(p, 100, 5);
			
			var sl:HUISlider = new HUISlider(p, 430, 6, 'POINTS THRESHOLD', onThresholdChange);
			sl.setSliderParams(0.001, 0.01, 0.003);
			sl.labelPrecision = 4;
			sl.width = 250;
			
			sl = new HUISlider(p, 430, 19, 'MATCH FACTOR     ', onMatchFactorChange);
			sl.setSliderParams(0.3, 0.65, 0.55);
			sl.labelPrecision = 2;
			sl.width = 250;
			
			new CheckBox(p, 300, 11, 'CORRECT LEVELS', onCorrectLevels);
			
			view = new Sprite();
			view.y = 40;
			
			screenBmp = new Bitmap();
			view.addChild(screenBmp);
			
			matchView = new Sprite();
			matchView.x = 640;
			view.addChild(matchView);

			overlay = new Shape();
			view.addChild(overlay);
			
			camera = new CameraBitmap(640, 480, 15, false);
			
			screenBmp.bitmapData = camera.bitmapData;
			
			surfOptions = new SURFOptions(int(640 / SCALE), int(480 / SCALE), 200, 0.003, true, 4, 4, 2);
			surf = new ASSURF(surfOptions);
			
			surf.pointMatchFactor = 0.55;
			
			buffer = new BitmapData(surfOptions.width, surfOptions.height, false, 0x00);
			buffer.lock();
			
			quasimondoProcessor = new QuasimondoImageProcessor(buffer.rect);

			addChild(view);
			
			initMatchElements();
			
			camera.addEventListener(Event.RENDER, render);
		}
		
		protected function render( e:Event ) : void
		{
			var gfx:Graphics = overlay.graphics;
			gfx.clear();
			
			buffer.draw(camera.bitmapData, SCALE_MAT);
			
			var ipts:Vector.<IPoint> = surf.getInterestPoints(buffer);
			SURFUtils.drawIPoints(gfx, ipts, SCALE);
			
			// Lets look if we can find any of our images
			
			var matched:Vector.<MatchElement> = new Vector.<MatchElement>();
			var matchedStr:Vector.<String> = new Vector.<String>();
			var n:int = 3;
			var i:int;
			var el:MatchElement;
			
			for( i = 0; i < n; ++i )
			{
				el = matchEls[i];
				
				el.matchCount = surf.getMatchesToPointsData(el.pointsCount, el.pointsData).length;
				
				if(el.matchCount >= 4) 
				{
					matched.push( el );
					matchedStr.push(els_names[i] +'-' + el.matchCount);
				}
			}
			
			SURFUtils.drawMatchedBitmaps(matched, matchView);
			
			stat_txt.text = 'FOUND POINTS: ' + surf.currentPointsCount + '\n';
			stat_txt.text += 'MATCHED: ' + ( matchedStr.length ? matchedStr.join(', ') : 'NONE' );
		}

		protected function initMatchElements():void
		{
			var n:int = 3;
			var i:int;
			var el:MatchElement;
			
			// This is the simpliest possible version of multi-reference match
			// but it is good for educational purpose to learn how methods work
			// I will show more efficient ways in next examples
			
			var matchOptions:SURFOptions = new SURFOptions(320, 240, 200, 0.004, true, 4, 4, 2);
			
			matchEls = new Vector.<MatchElement>(n, true);
			
			for( i = 0; i < n; ++i )
			{
				el = new MatchElement();
				el.id = i;
				el.bitmap = els_bmds[i];
				el.pointsData = new ByteArray();
				
				matchOptions.width = el.bitmap.width;
				matchOptions.height = el.bitmap.height;
				surf.changeSurfOptions(matchOptions);
				
				el.pointsCount = surf.getInterestPointsByteArray(el.bitmap, el.pointsData);
				
				matchEls[i] = el;
			}
			
			surf.changeSurfOptions(surfOptions);
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
		
		protected function onMatchFactorChange(e:Event):void
		{
			surf.pointMatchFactor = HUISlider(e.currentTarget).value;
		}
	}
}
