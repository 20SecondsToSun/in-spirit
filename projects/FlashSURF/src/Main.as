package
{
	import ru.inspirit.surf.FlashSURF;
	import ru.inspirit.surf.IPoint;
	import ru.inspirit.surf.SURFOptions;

	import com.bit101.components.Label;
	import com.bit101.components.Panel;
	import com.bit101.components.Style;
	import com.quasimondo.bitmapdata.CameraBitmap;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;

	/**
	 * FlashSURF sample usage examples
	 *
	 * @author Eugene Zatepyakin
	 * @link http://blog.inspirit.ru
	 * @link http://code.google.com/p/in-spirit/source/browse/#svn/trunk/projects/FlashSURF
	 */

	[SWF(width='1040',height='520',frameRate='33',backgroundColor='0x000000')]

	public class Main extends Sprite
	{
		protected const COLOURS:Vector.<uint> = Vector.<uint>(
									[ 0x0000FF, 0x00FF00,
                                    0xFF0000, 0x00FFFF,
                                    0xFFFF00, 0xFF00FF,
                                    0xFFFFFF, 0x000000] );

		protected static const SCALE:Number = 1.5;

		protected static const SCALE_MAT:Matrix = new Matrix(1/SCALE, 0, 0, 1/SCALE, 0, 0);
		protected static const ORIGIN:Point = new Point();

		[Embed(source = '../assets/graffiti_400.png')] private var defImg:Class;

		[Embed(source = '../assets/pan_a.jpg')] private var pan_a:Class;
		[Embed(source = '../assets/pan_b.jpg')] private var pan_b:Class;

		protected var screenBmp:Bitmap;
		protected var overlayScreenBmp:Bitmap;
		protected var refBmp:Bitmap;

		protected var bmp:BitmapData;

		protected var panoBase:BitmapData;
		protected var pa:BitmapData;
		protected var pb:BitmapData;
		protected var pc:BitmapData;

		protected var view:Sprite;
		protected var camera:CameraBitmap;
		protected var overlay:Shape;
		protected var cameraGfx:Sprite;

		protected var km:KMeans = new KMeans(); // not used in current version
		protected var maxClusterRadius:Number;
		protected var performClustering:Boolean = false;

		protected var p:Panel;
		protected var _timer:uint;
		protected var _fps:uint;
		protected var _ms:uint;
		protected var _ms_prev:uint;
		protected var procc_t:uint;
		protected var procc_n:uint;

		protected var surf:FlashSURF;
		protected var surfOptions:SURFOptions;
		protected var buffer:BitmapData;
		protected var imageDistortion:DistortImage;

		public function Main()
		{
			if(stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}

		private function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			initStage();

			view = new Sprite();
			view.y = 40;

			maxClusterRadius = 640 / 2;
			performClustering = false;

			refBmp = new Bitmap();
			refBmp.x = 640;
			refBmp.visible = false;
			view.addChild( refBmp );

			screenBmp = new Bitmap();
			view.addChild(screenBmp);

			overlay = new Shape();
			cameraGfx = new Sprite();
			view.addChild(overlay);
			view.addChild(cameraGfx);

			addChild(view);

			// Image distortion class to map images to each over
			imageDistortion = new DistortImage(640, 480, 20);

			// test video frames processing
			//setTimeout(prepareVideo, 1000);

			// test static images matching and stitching
			setTimeout(preparePano, 1000);

			//drawCamera(); // hope to be in next version ;)

			iniPanel();

			addEventListener(Event.ENTER_FRAME, countFrameTime);
		}

		protected function render( e:Event ) : void
		{
			var t:int = getTimer();

			var gfx:Graphics = overlay.graphics;
			gfx.clear();

			buffer.draw(camera.bitmapData, SCALE_MAT);

			// This is simple points extraction
			var ipts:Vector.<IPoint> = surf.getInterestPoints(buffer);
			drawIPoints(gfx, ipts);

			// Get matches to previously provided image [can be used for motion detecting]
			//var match:Vector.<Number> = surf.getMatchesToPreviousFrame(buffer);
			//drawMotionVectors(gfx, match);

			// Get matches to reference image, also trying to find Homography
			//var match:Vector.<Number> = surf.getMatchesToReference(buffer, true, 4);

			// Check if homography was detected
			// and draw reference image into detected bounds
			/*if(surf.homographyFound)
			{
				// as far as we scale down video source now we should scale homography
				// to feet our bounds
				surf.homography.scale(SCALE);
				imageDistortion.setTransform(gfx, refBmp.bitmapData,
												surf.homography.projectPoint(new Point(0, 0)),
												surf.homography.projectPoint(new Point(refBmp.bitmapData.width, 0)),
												surf.homography.projectPoint(new Point(refBmp.bitmapData.width, refBmp.bitmapData.height)),
												surf.homography.projectPoint(new Point(0, refBmp.bitmapData.height)));
			}
			drawMatches(gfx, match, SCALE, 640);
			*/

			procc_t += getTimer()-t;
			procc_n++;

			var lab:Label = Label(p.getChildByName('stat_txt'));
			lab.text = 'TOTAL POINTS: ' + surf.currentPointsCount + '\n';
			lab.text += 'MATCHED POINTS: ' + surf.matchedPointsCount;
		}

		protected function prepareVideo(e:Event = null):void
		{
			overlay.graphics.clear();

			camera = new CameraBitmap(640, 480, 15, false);

			var refb:BitmapData = Bitmap( new defImg() ).bitmapData;

			screenBmp.bitmapData = camera.bitmapData;
			refBmp.bitmapData = refb;
			refBmp.visible = true;
			imageDistortion.setSize(refb.width, refb.height);

			surfOptions = new SURFOptions(int(640 / SCALE), int(480 / SCALE), 100, 0.004, true, true, 4, 4, 2);
			surf = new FlashSURF(surfOptions);

			buffer = new BitmapData(refb.width, refb.height, false, 0x00);
			buffer.draw(refb);
			buffer.lock();

			surf.setReferenceImage(buffer, new SURFOptions(refb.width, refb.height, 200, 0.004, true, false, 4, 4, 2));

			buffer = new BitmapData(surfOptions.width, surfOptions.height, false, 0x00);
			buffer.lock();

			screenBmp.alpha = 1;
			camera.addEventListener(Event.RENDER, render);
		}

		protected function preparePano(e:Event = null):void
		{
			overlay.graphics.clear();

			panoBase = new BitmapData(640, 480, false, 0x00);
			pb = Bitmap(new pan_a()).bitmapData;
			pa = Bitmap(new pan_b()).bitmapData;

			panoBase.copyPixels(pa, pa.rect, new Point(20, (480-pa.height)*0.5));

			screenBmp.bitmapData = panoBase;
			refBmp.bitmapData = pb;
			screenBmp.visible = true;
			refBmp.visible = true;

			surfOptions = new SURFOptions(640, 480, 600, 0.0003);
			surf = new FlashSURF(surfOptions);

			var t:int = getTimer();

			var opt2:SURFOptions = new SURFOptions(pb.width, pb.height, 600, 0.0003);

			var mtch:Vector.<Number> = surf.getMatchesBetweenImages(panoBase, pb, surfOptions, opt2, true, 4);

			if(surf.homographyFound)
			{
				imageDistortion.setSize(pb.width, pb.height);

				imageDistortion.setTransform(overlay.graphics, pb,
														surf.homography.projectPoint(new Point(0, 0)),
														surf.homography.projectPoint(new Point(pb.width, 0)),
														surf.homography.projectPoint(new Point(pb.width, pb.height)),
														surf.homography.projectPoint(new Point(0, pb.height)));
			}

			drawMatches(overlay.graphics, mtch, 1, 640);

			var lab:Label = Label(p.getChildByName('stat_txt'));
			lab.text = 'TOTAL POINTS: ' + surf.currentPointsCount + '\tCOMPUTE TIME: '+ (getTimer()-t) +'ms\n';
			lab.text += 'MATCHED POINTS: ' + surf.matchedPointsCount;
		}

		protected function drawMatches(gfx:Graphics, ipts:Vector.<Number>, scale:Number = SCALE, offset:Number = 0):void
		{
			var l:int = ipts.length;
			gfx.lineStyle(1, 0x0000FF);

			for(var i:int = 0; i < l; i+=4)
			{
				var x1:Number = ipts[i] * scale;
				var y1:Number = ipts[int(i+1)] * scale;
				var x2:Number = ipts[int(i+2)] + offset;
				var y2:Number = ipts[int(i+3)];

				gfx.moveTo(x2, y2);
				gfx.lineTo(x1, y1);
			}
		}

		protected function drawMotionVectors(gfx:Graphics, ipts:Vector.<Number>, scale:Number = SCALE):void
		{
			var l:int = ipts.length;
			gfx.lineStyle(1, 0xFFFFFF);

			for(var i:int = 0; i < l; i+=4)
			{
				var x1:Number = ipts[i] * scale;
				var y1:Number = ipts[int(i+1)] * scale;
				var x2:Number = ipts[int(i+2)] * scale;
				var y2:Number = ipts[int(i+3)] * scale;

				var dx:Number = x1 - x2;
				var dy:Number = y1 - y2;
				var speed:Number = Math.sqrt(dx*dx+dy*dy);
				if (speed > 5 && speed < 30)
				{
					drawArrow(gfx, x1, y1, dx, dy, speed*2);
				}
			}
		}

		protected function drawIPoints(gfx:Graphics, ipts:Vector.<IPoint>, scale:Number = SCALE):void
		{
			var l:int = ipts.length;
			var ip:IPoint;

			for(var i:int = 0; i < l; ++i)
			{
				ip = ipts[i];
				var s:Number = ip.scale * scale;
				var x1:Number = ip.x * scale;
				var y1:Number = ip.y * scale;
	            var x2:Number = s * Math.cos(ip.orientation) + x1;
	            var y2:Number = s * Math.sin(ip.orientation) + y1;

				if(ip.orientation) {
					gfx.lineStyle(1, 0x00FF00);
	            	gfx.moveTo(x1, y1);
	            	gfx.lineTo(x2, y2);
				} else {
					gfx.beginFill(0x00FF00);
					gfx.drawCircle(x1, y1, 1);
					gfx.endFill();
				}
				if(ip.laplacian > 0) {
					gfx.lineStyle(1, 0x0000FF);
					gfx.drawCircle(x1, y1, s);
				} else {
					gfx.lineStyle(1, 0xFF0000);
					gfx.drawCircle(x1, y1, s);
				}
			}
		}

		protected function drawCamera():void
		{
			cameraGfx.graphics.clear();

			cameraGfx.graphics.lineStyle(2, 0x00FF00);
			cameraGfx.graphics.drawRect(-10, -10, 20, 20);

			var ray:Shape = new Shape();
			ray.graphics.lineStyle(2, 0x00ff00);
			ray.graphics.moveTo(0, 0);
			ray.graphics.lineTo(0, 60);

			ray.rotationX = 90;

			cameraGfx.addChild(ray);
		}

		protected function drawClusters(gfx:Graphics, clust:Vector.<IPoint>, pts:Vector.<IPoint>):void
		{
			var i:int;
			var ipt:IPoint;
			for(i = 0; i < clust.length; ++i)
			{
				ipt = clust[i];
				if(ipt.clusterChilds == 0) continue;
				gfx.beginFill(COLOURS[ ipt.clusterIndex%COLOURS.length ]);
				gfx.drawCircle(ipt.x, ipt.y, 3);
				gfx.endFill();
				gfx.lineStyle(2, COLOURS[ (ipt.clusterIndex+1)%COLOURS.length ]);
				gfx.drawCircle(ipt.x, ipt.y, 4);
			}
			gfx.lineStyle(1, 0xFFFFFF);
			for(i = 0; i < pts.length; ++i)
			{
				ipt = pts[i];
				if(ipt.clusterIndex == -1) continue;
				gfx.moveTo(ipt.x, ipt.y);
				gfx.lineTo(clust[ipt.clusterIndex].x, clust[ipt.clusterIndex].y);
			}
		}

		protected function iniPanel():void
		{
			p = new Panel(this);
			p.width = stage.stageWidth;
			p.height = 40;

			Style.PANEL = 0x333333;
			Style.BUTTON_FACE = 0x333333;
			Style.LABEL_TEXT = 0xF6F6F6;

			var lb:Label = new Label(p, 10, 5);
			lb.name = 'fps_txt';
			lb = new Label(p, 100, 5);
			lb.name = 'stat_txt';
		}

		protected function countFrameTime(e:Event = null):void
		{
			_timer = getTimer();
			var lab:Label = Label(p.getChildByName('fps_txt'));
			if( _timer - 1000 >= _ms_prev )
			{
				_ms_prev = _timer;

				lab.text = 'FPS: ' + _fps + ' / ' + stage.frameRate + '\nRENDER: ' + int(procc_t / procc_n + 0.5) + 'ms';

				_fps = procc_t = procc_n = 0;
			}

			_fps ++;
			_ms = _timer;
		}

		public function drawArrow(graphics:Graphics, stx:Number, sty:Number, dirx:Number = -1, diry:Number = -1, length:Number = 50, arrowSize:int = 6, angle:Number = -1):void
		{
			var endx:Number;
			var endy:Number;
			if(dirx == -1 && diry == -1){
				endx = stx + Math.cos(angle) * length;
				endy = sty + Math.sin(angle) * length;
			} else {
				var mag:Number = 1 / Math.sqrt(dirx * dirx + diry * diry);
				endx = dirx * mag * length + stx;
				endy = diry * mag * length + sty;
			}

			graphics.moveTo(stx, sty);
			graphics.lineTo(endx, endy);

			var diffx:Number = endx - stx;
			var diffy:Number = endy - sty;
			var ln:Number = Math.sqrt(diffx * diffx + diffy * diffy);

			if (ln <= 0) return;

			diffx = diffx / ln;
			diffy = diffy / ln;
			graphics.moveTo(endx, endy);
			graphics.lineTo(endx - arrowSize * diffx - arrowSize * -diffy, endy - arrowSize * diffy - arrowSize * diffx);
			graphics.moveTo(endx, endy);
			graphics.lineTo(endx - arrowSize * diffx + arrowSize * -diffy, endy - arrowSize * diffy + arrowSize * diffx);
		}

		protected function initStage():void
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
