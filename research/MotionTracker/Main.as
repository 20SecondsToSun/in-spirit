package  
{
	import ru.inspirit.motion.MotionBlob;
	import ru.inspirit.motion.MotionTracker;

	import com.bit101.components.HUISlider;
	import com.bit101.components.Label;
	import com.bit101.components.Panel;
	import com.bit101.components.Style;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageScaleMode;
	import flash.events.AsyncErrorEvent;
	import flash.events.Event;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.utils.Timer;
	import flash.utils.getTimer;

	/**
	 * @author Eugene Zatepyakin
	 */
	public class Main extends Sprite 
	{
		private var view:Sprite;
		private var tracker:MotionTracker;
		
		private var camera:CameraBitmap;
		private var _vid:Video;
		private var videoURL:String = "track.mov";
        private var connection:NetConnection;
        private var stream:NetStream;
        
        private const VID_W:int = 352;
        private const VID_H:int = 288;
        
		private var currFrame:BitmapData;
		private var prevFrame:BitmapData;
		private var edgeFrame:BitmapData;
		private var scaleFactor:uint = 2;
		private var w:int = 640;
		private var h:int = 480;
		
		private var oldVelocity:Vector.<Point>;

		private var canvas:Shape;
		private var panel:Panel;
		
		private var detectMode:int = 0;
		
		private var _timer : uint;
		private var _fps : uint;
		private var _ms : uint;
		private var _ms_prev : uint;

		public function Main()
		{
			if(stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}

		private function init(e:Event = null):void
		{
			initStage();
			
			view = new Sprite();
			
			camera = new CameraBitmap(w, h, 15, true);
			camera.addEventListener(Event.RENDER, renderCamera);
			view.addChild(new Bitmap(camera.bitmapData));
			
			//initFlv();
			
			tracker = new MotionTracker(w, h, scaleFactor, 20);
			
			currFrame = new BitmapData(int(w / scaleFactor + .5), int(h / scaleFactor + .5), false, 0x00);
			prevFrame = currFrame.clone();
			edgeFrame = currFrame.clone();
			
			var b:Bitmap = new Bitmap(currFrame);
			b.scaleX = b.scaleY = scaleFactor;
			b.x = 320;
			//view.addChild(b);
			
			b = new Bitmap(prevFrame);
			b.scaleX = b.scaleY = scaleFactor;
			b.y = 240;
			//view.addChild(b);
			
			b = new Bitmap(edgeFrame);
			b.scaleX = b.scaleY = scaleFactor;
			b.x = 320;
			b.y = 240;
			//view.addChild(b);

			addChild(view);
			
			canvas = new Shape();
			addChild(canvas);
			
			canvas.y = view.y = 40;
			
			initControls();
			
			//stage.addEventListener(MouseEvent.CLICK, nextMode);
		}
		
		private function initControls():void
		{
			Style.PANEL = 0x333333;
			Style.BUTTON_FACE = 0x333333;
			Style.LABEL_TEXT = 0xF6F6F6;
			
			panel = new Panel(this);
			panel.width = 640;
			panel.height = 40;
			
			var lb:Label = new Label(panel, 10, 5);
			lb.name = 'fps_txt';
			
			var sl:HUISlider = new HUISlider(panel, 90, 5, 'MAX BLOBS', onMaxBlobChange);
			sl.setSliderParams(1, 50, 10);
			sl.labelPrecision = 0;
			sl.width = 200;
			
			sl = new HUISlider(panel, 90, 18, 'SENSITIVITY', onThresholdChange);
			sl.setSliderParams(5, 70, 50);
			sl.labelPrecision = 0;
			sl.width = 200;
			
			sl = new HUISlider(panel, 280, 5, 'MIN  BLOB SIZE', onMinBlobSizeChange);
			sl.setSliderParams(.01, 0.1, 0.015);
			sl.labelPrecision = 3;
			sl.width = 230;
			
			sl = new HUISlider(panel, 280, 18, 'MAX BLOB SIZE', onMaxBlobSizeChange);
			sl.setSliderParams(0.1, 1.0, 0.3);
			sl.labelPrecision = 3;
			sl.width = 230;
			
			addEventListener(Event.ENTER_FRAME, countFrameTime);	
		}
		
		private function onMaxBlobChange(e:Event):void
		{
			tracker.maxBlobs = HUISlider(e.currentTarget).value;
		}
		
		private function onThresholdChange(e:Event):void
		{
			tracker.thresholdValue = 70 - HUISlider(e.currentTarget).value;
		}
		private function onMinBlobSizeChange(e:Event):void
		{
			tracker.minBlobSize = tracker.frameSize * HUISlider(e.currentTarget).value;
		}
		private function onMaxBlobSizeChange(e:Event):void
		{
			tracker.maxBlobSize = tracker.frameSize * HUISlider(e.currentTarget).value;
		}

		private function renderCamera(e:Event = null):void
		{
			//var tt:int = getTimer();
			tracker.trackFrame(camera.bitmapData);
			//tracker.drawPreviousFrame(prevFrame);
			//tracker.drawCurrentFrame(currFrame);
			//tracker.detectEdges(edgeFrame);
			
			if(detectMode == 0)
			{
				drawBlobs2();
			} 
			else if(detectMode == 1)
			{
				drawRects(tracker.getBlobs());
			}
			//trace(getTimer() - tt);
		}
		
		private function renderVideo(e:Event = null):void
		{
			currFrame.draw(_vid);
			tracker.trackFrame(currFrame);
			//tracker.drawCurrentFrame(prevFrame);
			//tracker.drawPreviousFrame(prevFrame);
			//tracker.drawCurrentFrame(currFrame);
			
			if(detectMode == 0)
			{
				drawBlobs2();
			} 
			else if(detectMode == 1)
			{
				drawRects(tracker.getBlobs());
			}
		}
		
		private function drawBlobs2():void
		{
			canvas.graphics.clear();
			canvas.graphics.lineStyle(1, 0xFFFF00);
			
			tracker.getBlobs(true);
			var t:int = tracker._blobs.length;
			var mb:MotionBlob;
			var cp:Point = new Point();
			var dir:Point = new Point();
			for(var i:int = 0; i < t; ++i)
			{
				mb = tracker._blobs[i];
				cp.x = mb.cx * scaleFactor;
				cp.y = mb.cy * scaleFactor;
				/*var w:Number = mb.width * scaleFactor;
				var h:Number = mb.height * scaleFactor;
				var rect:Rectangle = new Rectangle(cp.x - w * .5, cp.y - h * .5, w, h);
				var angle:Number = mb.angle;
				var tl:Point = getRotatedRectPoint(angle, rect.topLeft, cp);
				var br:Point = getRotatedRectPoint(angle, rect.bottomRight, cp);
				var tr:Point = getRotatedRectPoint(angle, new Point(rect.right, rect.top), cp);
				var bl:Point = getRotatedRectPoint(angle, new Point(rect.left, rect.bottom), cp);*/
				canvas.graphics.moveTo(mb.tl.x * scaleFactor, mb.tl.y * scaleFactor);
				canvas.graphics.lineTo(mb.tr.x * scaleFactor, mb.tr.y * scaleFactor);
				canvas.graphics.lineTo(mb.br.x * scaleFactor, mb.br.y * scaleFactor);
				canvas.graphics.lineTo(mb.bl.x * scaleFactor, mb.bl.y * scaleFactor);
				canvas.graphics.lineTo(mb.tl.x * scaleFactor, mb.tl.y * scaleFactor);
				//canvas.graphics.drawRect(cp.x - w * .5, cp.y - h * .5, w, h);
				dir.x = mb.vel.x;
				dir.y = mb.vel.y;
				//dir.normalize(5);
				if(dir.x == 0 && dir.y == 0) continue;
				drawArrow(canvas.graphics, cp, dir, dir.length*10, 7);
			}
		}
		
		public function getRotatedRectPoint( angle:Number, point:Point, rotationPoint:Point = null):Point
		{
			var ix:Number = (rotationPoint) ? rotationPoint.x : 0;
			var iy:Number = (rotationPoint) ? rotationPoint.y : 0;
			
			var m:Matrix = new Matrix( 1,0,0,1, point.x - ix, point.y - iy);
			m.rotate(angle);
			return new Point( m.tx + ix, m.ty + iy);
		}

		private function drawRects(rects:Vector.<Rectangle> = null):void
		{
			canvas.graphics.clear();
			
			if (rects) {
				var rc:Rectangle;
				var i:int;
				var j:int;
				/*for (i = 0;i < rects.length - 1; ++i) {
					for (j = i + 1;j < rects.length; ++j) {
						if (rects[i].containsRect(rects[j])) {
							rects = rects.splice(j, 1);
							j--;
						} 
						else if (rects[j].containsRect(rects[i])) {
							rects[i] = rects[j].clone();
							rects = rects.splice(j, 1);
							j--;
						}
						else if (intersects(rects[i], rects[j])) {
							rects[i] = rects[i].union(rects[j]);
							rects = rects.splice(j, 1);
							j--;
							//j = i + 1;
						}
					}
				}*/
				
				canvas.graphics.lineStyle(1, 0xFFFF00);
				
				var currf:Point;
				var prevf:Point;
				var ind:int;
				var n:int;
				var cx:Number, cy:Number;
				var mw:Number, mh:Number;
				var vx:Number, vy:Number;
				var avx:Number, avy:Number;
				
				for(i = 0; i < rects.length; ++i){
					rc = rects[i];
					//currf = tracker.getAreaForce(rc.x, rc.y, rc.width, rc.height);
					currf = tracker.force(rc.x, rc.y, rc.width, rc.height);
					if(currf.x == 0 && currf.y == 0) continue;
					
					mw = rc.width * .5;
					mh = rc.height * .5;
					cx = rc.x + mw;
					cy = rc.y + mh;
					avx = 0;
					avy = 0;
					var sx:int = int(cx - mw * .5);
					var sy:int = int(cy - mh * .5);
					var ex:int = int(sx + mw);
					var ey:int = Math.min(int(sy + mh), tracker.frameHeight);
					for(j = sy; j < ey; ++j)
					{
						ind = int(sx + tracker.frameWidth * j);
						for(n = sx; n < ex; ++n)
						{
							
							prevf = oldVelocity[ind];
					
							vx = prevf.x + (currf.x - prevf.x) * .5;
							vy = prevf.y + (currf.y - prevf.y) * .5;
							
							prevf.x = vx;
							prevf.y = vy;
							oldVelocity[ind] = prevf;
							
							avx += vx;
							avy += vy;
							
							++ind;
						}
					}
					ind = mw * mh;
					avx /= ind;
					avy /= ind;
					if(avx == 0 && avy == 0) continue;
					//avx = currf.x;
					//avy = currf.y;
					currf.normalize(1);
					
					canvas.graphics.drawRect(rc.x * scaleFactor, rc.y * scaleFactor, rc.width * scaleFactor, rc.height * scaleFactor);
					drawArrow(canvas.graphics, new Point(cx * scaleFactor, cy * scaleFactor), new Point(avx, avy), currf.length*50, 7);
				}
				dumpVectors();
			}
		}
		
		private function dumpVectors():void
		{
			var i:int = oldVelocity.length;
			while( --i > -1 ){
				oldVelocity[i].x *= .9;
				oldVelocity[i].y *= .9;
			}
		}

		public function drawArrow(graphics:Graphics, start:Point, direction:Point = null, length:Number = 50, arrowSize:int = 8, angle:Number = -1):void
		{
			var endx:Number;
			var endy:Number;
			if(direction){
				var dirx:Number = direction.x;
				var diry:Number = direction.y;
				var mag:Number = 1 / Math.sqrt(dirx * dirx + diry * diry);
				endx = dirx * mag * length + start.x;
				endy = diry * mag * length + start.y;
			} else {
				endx = start.x + Math.cos(angle) * length;
				endy = start.y + Math.sin(angle) * length;
			}
            
			graphics.moveTo(start.x, start.y);
			graphics.lineTo(endx, endy);
            
			var diffx:Number = endx - start.x;
			var diffy:Number = endy - start.y;
			var ln:Number = Math.sqrt(diffx * diffx + diffy * diffy);
			
			if (ln <= 0) return;
			
			diffx = diffx / ln;
			diffy = diffy / ln;
			graphics.moveTo(endx, endy);
			graphics.lineTo(endx - arrowSize * diffx - arrowSize * -diffy, endy - arrowSize * diffy - arrowSize * diffx);
			graphics.moveTo(endx, endy);
			graphics.lineTo(endx - arrowSize * diffx + arrowSize * -diffy, endy - arrowSize * diffy + arrowSize * diffx);
		}

		public function intersects(rect1:Rectangle, rect2:Rectangle):Boolean
		{
			
			if(!((rect1.right < rect2.left) || (rect1.left > rect2.right)))
				if(!((rect1.bottom < rect2.top) || (rect1.top > rect2.bottom)))
					return true; 
					
			return false; 
		}

		private function getGroupBounds(group:Array):Object 
		{
			var minx:Number = Number.POSITIVE_INFINITY;
			var miny:Number = Number.POSITIVE_INFINITY;
			var maxx:Number = Number.NEGATIVE_INFINITY;
			var maxy:Number = Number.NEGATIVE_INFINITY;
			var rc:Rectangle;
			var i:int = group.length;
			while (--i > -1) {
				rc = group[i];
				minx = Math.min(minx, rc.left);
				miny = Math.min(miny, rc.top);
				maxx = Math.max(maxx, rc.right);
				maxy = Math.max(maxy, rc.bottom);
			}
			return {minx:minx, miny:miny, maxx:maxx, maxy:maxy};
		}
		
		private function initFlv():void
		{
			w = VID_W;
			h = VID_H;
			connection = new NetConnection();
            connection.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
            connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
            connection.connect(null);
		}
		private function netStatusHandler(event:NetStatusEvent):void {
            switch (event.info.code) {
                case "NetConnection.Connect.Success":
                    connectStream();
                    break;
				case "NetStream.Play.Stop":
					stream.seek(0);
					stream.resume();
					break;
                case "NetStream.Play.StreamNotFound":
                    trace("Unable to locate video: " + videoURL);
                    break;
            }
        }

        private function connectStream():void {
            stream = new NetStream(connection);
            stream.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
            stream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);
            _vid = new Video(VID_W, VID_H);
            _vid.attachNetStream(stream);
            stream.play(videoURL);
            view.addChild(_vid);
            
            var vt:Timer = new Timer(150);
            vt.addEventListener(TimerEvent.TIMER, renderVideo);
            vt.start();
        }
        
        private function securityErrorHandler(event:SecurityErrorEvent):void {
            trace("securityErrorHandler: " + event);
        }

        private function asyncErrorHandler(event:AsyncErrorEvent):void {
            // ignore AsyncErrorEvent events.
        }
        
        private function countFrameTime(e:Event = null):void
		{
			_timer = getTimer();
			var lab:Label = Label(panel.getChildByName('fps_txt'));
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
			//stage.align = StageAlign.TOP_LEFT;
			
			var myContextMenu:ContextMenu = new ContextMenu();
			myContextMenu.hideBuiltInItems();
			
			
			var copyr:ContextMenuItem = new ContextMenuItem("© inspirit.ru", true, false);
			myContextMenu.customItems.push(copyr);
			
			contextMenu = myContextMenu;
		}
		
	}
}
