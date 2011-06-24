package demo.KLT
{
	import apparat.asm.__cint;
	import apparat.math.FastMath;
	import apparat.memory.Memory;
	import demo.pyrFlowLK.TrackPoint;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.BlurFilter;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.text.TextField;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.getTimer;
	import ru.inspirit.image.klt.KLTracker;
	import ru.inspirit.image.mem.MemImageMacro;
	import ru.inspirit.image.mem.MemImageUChar;




	/**
	 * @author Eugene Zatepyakin
	 */
	[SWF(width='640',height='590',frameRate='25',backgroundColor='0xFFFFFF')]
	public class DemoKLTracker extends Sprite
	{
		public static const GRAYSCALE_MATRIX:ColorMatrixFilter = new ColorMatrixFilter([
                        																0, 0, 0, 0, 0,
            																			0, 0, 0, 0, 0,
            																			.2989, .587, .114, 0, 0,
            																			0, 0, 0, 0, 0
																						]);
		public const ORIGIN:Point = new Point();
		public const blur2x2:BlurFilter = new BlurFilter(2, 2, 2);
		public const blur4x4:BlurFilter = new BlurFilter(4, 4, 2);
																						
		protected var myview:Sprite;
        public static var _txt:TextField;
        protected var camBmp:Bitmap;
        
        protected var _cam:Camera;
        protected var _video:Video;
        protected var _cambuff:BitmapData;
        protected var _buff:BitmapData;
        protected var _cambuff_rect:Rectangle;
        protected var _cam_mtx:Matrix;
        
        public const ram:ByteArray = new ByteArray();
        public const klt:KLTracker = new KLTracker();
        
        public var imgU640:MemImageUChar;
        public var imgU320:MemImageUChar;
        public var imgU160:MemImageUChar;
        public var imgU640_:MemImageUChar;
        public var imgU320_:MemImageUChar;
        public var imgU160_:MemImageUChar;
        
        public var trackPoints:Vector.<TrackPoint> = new Vector.<TrackPoint>();
        
        public var frame:int = 0;
        public var frame_prev:int = 0;
        public var frame_ms:int = 0;
        public var klt_prev:int = 0;
        public var klt_time:int = 0;
        public var klt_n:int = 0;
        
		public function DemoKLTracker()
		{
			if(stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		protected function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			//
			stage.scaleMode = StageScaleMode.NO_SCALE;

            myview = new Sprite();
            
            // debug test field
            _txt = new TextField();
            _txt.autoSize = 'left';
            _txt.width = 300;
            _txt.x = 5;
            _txt.y = 480;                   
            myview.addChild(_txt);
            
            // web camera initiation
            initCamera(640, 480, 25);
            camBmp = new Bitmap(_cambuff);                  
            myview.addChild(camBmp);
            
            var imgChunk1:int = 640*480;
            var imgChunk2:int = 320*240;
            var imgChunk3:int = 160*120;
			var imgChunk4:int = (640 * 480) << 2;
			var kltChunk:int = klt.calcRequiredChunkSize(21);
            
            ram.endian = Endian.LITTLE_ENDIAN;
			ram.length = imgChunk1*2 + imgChunk2*2 + imgChunk3*2 + imgChunk4*2 + kltChunk + 1024;
			ram.position = 0;
			Memory.select(ram);
			
			var offset:int = 1024;
			imgU640 = new MemImageUChar();
			imgU640.setup(offset, 640, 480);
			offset += imgChunk1;
			imgU320 = new MemImageUChar();
			imgU320.setup(offset, 320, 240);
			offset += imgChunk2;
            imgU160 = new MemImageUChar();
            imgU160.setup(offset, 160, 120);
			offset += imgChunk3;
			//
			imgU640_ = new MemImageUChar();
			imgU640_.setup(offset, 640, 480);
			offset += imgChunk1;
			imgU320_ = new MemImageUChar();
			imgU320_.setup(offset, 320, 240);
			offset += imgChunk2;
            imgU160_ = new MemImageUChar();
            imgU160_.setup(offset, 160, 120);
			offset += imgChunk3;
			//
			klt.setup( offset, 640, 480, 21 );
            
            addChild(myview);
            
			addEventListener(Event.ENTER_FRAME, render);
			stage.addEventListener(MouseEvent.CLICK, addPoint);
		}
		
		protected function render(e:Event = null):void
		{
			var t:int = getTimer();
			
			_cambuff.draw(_video, _cam_mtx);

            //t = getTimer();

			_buff.applyFilter( _cambuff, _cambuff_rect, ORIGIN, blur2x2 );
			_buff.applyFilter( _buff, _cambuff_rect, ORIGIN, GRAYSCALE_MATRIX );

			imgU640.fill( _buff.getVector( _cambuff_rect ) );
			var uptr1:int = imgU640.ptr;
			var uptr2:int = imgU320.ptr;
			var w2:int = 320;
			var h2:int = 240;
			MemImageMacro.pyrDown( uptr1, uptr2, w2, h2 );

            uptr1 = imgU160.ptr;
            w2 = 160;
            h2 = 120;
            MemImageMacro.pyrDown( uptr2, uptr1, w2, h2 );
			
			//imgU320.render(_cambuff);
			
			var n:int = trackPoints.length;
			var newPoints:Vector.<Number> = new Vector.<Number>(n<<1);
			var prevPoints:Vector.<Number> = new Vector.<Number>(n<<1);
			var status:Vector.<int> = new Vector.<int>(n);
			var pp:TrackPoint;
			var fx:Number, fy:Number;
			for(var i:int = 0; i < n; ++i)
			{
				pp = trackPoints[i];
				prevPoints[i<<1] = pp.x;
				prevPoints[__cint((i<<1)+1)] = pp.y;

				pp.tracked = false;
			}
			
			t = getTimer();
			
			klt.currImg = Vector.<int>([imgU640.ptr, imgU320.ptr, imgU160.ptr]);
			klt.prevImg = Vector.<int>([imgU640_.ptr, imgU320_.ptr, imgU160_.ptr]);
			
			klt.trackPoints(n, prevPoints, newPoints, status, 20, 0.01);
			
			klt_time += getTimer() - t;
            if(++klt_n == 10)
            {
                klt_prev = klt_time / 10 + 0.5;
                klt_time = klt_n = 0;
            }

            var filterdPoints:Vector.<TrackPoint> = new Vector.<TrackPoint>();
            t = 0;
			for(i = 0; i < n; ++i)
			{
				if(status[i] == 1)
				{
					fx = newPoints[i<<1];
					fy = newPoints[__cint((i<<1)+1)];
					pp = trackPoints[i];
					pp.x = fx;
					pp.y = fy;
					pp.tracked = true;
                    filterdPoints.push(pp);
                    t++;
				}
			}
            trackPoints = filterdPoints.concat();
            n = t;

			plotPoints(trackPoints, n);
			
			// swap images
			t = imgU640.ptr;
			imgU640.ptr = imgU640_.ptr;
			imgU640_.ptr = t;
			t = imgU320.ptr;
			imgU320.ptr = imgU320_.ptr;
			imgU320_.ptr = t;
            t = imgU160.ptr;
			imgU160.ptr = imgU160_.ptr;
			imgU160_.ptr = t;
			
			
			_txt.text = '3 Level Image Pyramid | 21px Patch Size | 20 Iterations per point | '+ n +' points\n';
			if(getTimer() - frame_ms >= 1000)
			{
				_txt.appendText( frame + '/25 fps' + '\nklt: ' + klt_prev + 'ms' );
				frame_prev = frame;
				frame_ms = getTimer();
				frame = 0;
			}
			else
			{
				frame++;
				
				_txt.appendText( frame_prev + '/25 fps' + '\nklt: ' + klt_prev + 'ms' );
			}
		}
		
		public function addPoint(e:Event = null):void
		{
			var n:int = trackPoints.length;
			var p:TrackPoint;
			var nx:Number = mouseX;
			var ny:Number = mouseY;
			for(var i:int = 0; i < n; ++i)
			{
				p = trackPoints[i];
				var dx:Number = p.x - nx;
				var dy:Number = p.y - ny;
				if(dx*dx + dy*dy < 100)
				{
					trackPoints.splice(i, 1);
					return;
				}
			}
			
			p = new TrackPoint();
			p.x = nx;
			p.y = ny;
			p.vx = p.vy = 0;
			trackPoints.push(p);
		}
		
		protected function plotPoints(pts:Vector.<TrackPoint>, n:int):void
		{
			var px:int, py:int;
			var col:uint = 0x00FF00;
			
			_cambuff.lock();
			
			for(var i:int = 0; i < n; ++i)
			{
				px = FastMath.rint(pts[i].x);
				py = FastMath.rint(pts[i].y);
				//col = pts[i].tracked ? 0x00FF00 : 0xFF0000;
				
				_cambuff.setPixel(px, py, col);
				_cambuff.setPixel(px+1, py, col);
				_cambuff.setPixel(px-1, py, col);
				_cambuff.setPixel(px, py+1, col);
				_cambuff.setPixel(px, py-1, col);
			}
			_cambuff.unlock( _cambuff_rect );
		}
		
		protected function initCamera(w:int = 640, h:int = 480, fps:int = 25):void
        {
            _cambuff = new BitmapData( w, h, false, 0x0 );
            _cam = Camera.getCamera();
            _cam.setMode( w, h, fps, true );

			_cambuff_rect = _cambuff.rect;
			_cam_mtx = new Matrix(-1, 0, 0, 1, w);
			
			_buff = _cambuff.clone();
            
            _video = new Video( _cam.width, _cam.height );
            _video.attachCamera( _cam );
        }
	}
}
