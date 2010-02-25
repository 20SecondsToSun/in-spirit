package  
{
	import ru.inspirit.surf_example.AverageHomographyMatrix;
	import ru.inspirit.surf.ASSURF;
	import ru.inspirit.surf.IPointMatch;
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
	 * Searching for reference image in camera video stream
	 * If enough points try to estimate Homography transformation matrix
	 * 
	 * @author Eugene Zatepyakin
	 */
	 
	[SWF(width='1040',height='520',frameRate='33',backgroundColor='0x000000')]
	
	public class CameraMatchWithHomography extends FlashSURFExample 
	{
		[Embed(source = '../assets/graffiti_400.png')] private var defImg:Class;
		
		public static const SCALE:Number = 1.5;

		public static const SCALE_MAT:Matrix = new Matrix(1/SCALE, 0, 0, 1/SCALE, 0, 0);
		public static const ORIGIN:Point = new Point();
		
		public var surf:ASSURF;
		public var surfOptions:SURFOptions;
		public var quasimondoProcessor:QuasimondoImageProcessor;
		public var buffer:BitmapData;
		public var autoCorrect:Boolean = false;
		
		public var averageHomography:AverageHomographyMatrix;
		
		protected var view:Sprite;
		protected var camera:CameraBitmap;
		protected var overlay:Shape;
		protected var screenBmp:Bitmap;
		protected var refBmp:Bitmap;
		
		protected var stat_txt:Label;
		
		public function CameraMatchWithHomography()
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
			
			refBmp = new Bitmap();
			refBmp.x = 640;
			view.addChild(refBmp);

			overlay = new Shape();
			view.addChild(overlay);
			
			camera = new CameraBitmap(640, 480, 15, false);
			
			screenBmp.bitmapData = camera.bitmapData;
			
			surfOptions = new SURFOptions(int(640 / SCALE), int(480 / SCALE), 200, 0.003, true, 4, 4, 2);
			surf = new ASSURF(surfOptions);
			
			averageHomography = new AverageHomographyMatrix();
			
			var refb:BitmapData = Bitmap( new defImg() ).bitmapData;
			refBmp.bitmapData = refb;
			
			buffer = new BitmapData(refb.width, refb.height, false, 0x00);
			buffer.draw(refb);
			buffer.lock();
			
			surf.setReferenceImage(buffer, new SURFOptions(refb.width, refb.height, 200, 0.004, true, 4, 4, 2));
			
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
			
			// Get matches to reference image, also trying to find Homography
			
			var match:Vector.<IPointMatch> = surf.getMatchesToReference(buffer, true, 4);
			
			// Check if homography was detected
			// and draw detected bounds
			if(surf.homographyFound)
			{
				// we use average value of several homography matrices
				// to smooth visual representation
				averageHomography.addMatrix(surf.homography.clone());
				
				// as far as we scale down video source now we should scale homography
				// to feet our bounds
				averageHomography.scale(SCALE);
				
				var pt0:Point = averageHomography.projectPoint(new Point(0, 0));
				var pt1:Point = averageHomography.projectPoint(new Point(refBmp.bitmapData.width, 0));
				var pt2:Point = averageHomography.projectPoint(new Point(refBmp.bitmapData.width, refBmp.bitmapData.height));
				var pt3:Point = averageHomography.projectPoint(new Point(0, refBmp.bitmapData.height));
				
				gfx.lineStyle(2, 0x00FF00);
				gfx.moveTo(pt0.x, pt0.y);
				gfx.lineTo(pt1.x, pt1.y);
				gfx.lineTo(pt2.x, pt2.y);
				gfx.lineTo(pt3.x, pt3.y);
				gfx.lineTo(pt0.x, pt0.y);
			}
			
			SURFUtils.drawMatches(gfx, match, SCALE, 640);
			
			stat_txt.text = 'FOUND POINTS: ' + surf.currentPointsCount + '\nMATCHES: ' + surf.matchedPointsCount;
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
