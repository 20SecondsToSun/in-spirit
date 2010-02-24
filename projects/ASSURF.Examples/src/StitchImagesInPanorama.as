package  
{
	import ru.inspirit.surf.FlashSURF;
	import ru.inspirit.surf.IPointMatch;
	import ru.inspirit.surf.SURFOptions;
	import ru.inspirit.surf_example.FlashSURFExample;
	import ru.inspirit.surf_example.utils.DistortImage;

	import com.bit101.components.Label;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;

	/**
	 * Finding matches between two images
	 * Estimate Homography transform matrix
	 * Project second image to first using transformation matrix
	 * 
	 * @author Eugene Zatepyakin
	 */
	 
	[SWF(width='1040',height='574',frameRate='33',backgroundColor='0x000000')]
	
	public class StitchImagesInPanorama extends FlashSURFExample 
	{
		[Embed(source = '../assets/pan_a.jpg')] private var pan_a:Class;
		[Embed(source = '../assets/pan_b.jpg')] private var pan_b:Class;
		
		public var surf:FlashSURF;
		public var surfOptions:SURFOptions;
		
		protected var imageDistortion:DistortImage;
		
		protected var view:Sprite;
		protected var overlay:Shape;
		protected var screenBmp:Bitmap;
		protected var refBmp:Bitmap;
		
		protected var panoBase:BitmapData;
		protected var pa:BitmapData;
		protected var pb:BitmapData;
		
		protected var stat_txt:Label;
		
		public function StitchImagesInPanorama()
		{
			super();
			if(stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			stat_txt = new Label(p, 100, 5);
			
			view = new Sprite();
			view.y = 40;
			
			screenBmp = new Bitmap();
			view.addChild(screenBmp);
			
			refBmp = new Bitmap();
			refBmp.x = 640;
			view.addChild(refBmp);

			overlay = new Shape();
			view.addChild(overlay);
			
			imageDistortion = new DistortImage(640, 480, 20);
			
			panoBase = new BitmapData(640, 480, false, 0x00);
			pb = Bitmap(new pan_a()).bitmapData;
			pa = Bitmap(new pan_b()).bitmapData;
			
			panoBase.copyPixels(pa, pa.rect, new Point(20, (480-pa.height)*0.5));
			
			screenBmp.bitmapData = panoBase;
			refBmp.bitmapData = new BitmapData(pb.width, pa.height + pb.height, false, 0x0);
			refBmp.bitmapData.copyPixels(pb, pb.rect, new Point(0, 0));
			refBmp.bitmapData.copyPixels(pa, pa.rect, new Point(0, pb.height));
			
			surfOptions = new SURFOptions(640, 480, 600, 0.0003, true, 4, 4, 2);
			surf = new FlashSURF(surfOptions);
			
			var opt2:SURFOptions = new SURFOptions(pb.width, pb.height, 600, 0.0003, true, 4, 4, 2);
			
			var match:Vector.<IPointMatch> = surf.getMatchesBetweenImages(panoBase, pb, surfOptions, opt2, true, 4);
			
			if(surf.homographyFound)
			{				
				imageDistortion.setSize(pb.width, pb.height);
				
				imageDistortion.setTransform(overlay.graphics, pb, 
														surf.homography.projectPoint(new Point(0, 0)), 
														surf.homography.projectPoint(new Point(pb.width, 0)),
														surf.homography.projectPoint(new Point(pb.width, pb.height)), 
														surf.homography.projectPoint(new Point(0, pb.height)));

			}
			
			// Draw connections between Matched points
			
			var n:int = match.length;
			var pt:IPointMatch;
			var yoff:Number = (480-pa.height)*0.5;
			overlay.graphics.lineStyle(1, 0xFF0000);
			
			for(var i:int = 0; i < n; ++i)
			{
				pt = match[i];
				var x1:Number = pt.currX - 20 + 640;
				var y1:Number = pt.currY - yoff + pb.height;
				var x2:Number = pt.refX + 640;
				var y2:Number = pt.refY;
				
				overlay.graphics.moveTo(x2, y2);
				overlay.graphics.lineTo(x1, y1);
			}
			
			stat_txt.text = 'FOUND POINTS: ' + surf.currentPointsCount + '\nMATCHES: ' + surf.matchedPointsCount;
			
			addChild(view);
		}
	}
}
