package  
{
	import com.bit101.components.HUISlider;
	import com.bit101.components.InputText;
	import com.bit101.components.Label;
	import com.bit101.components.Panel;
	import com.bit101.components.PushButton;
	import com.bit101.components.RadioButton;
	import com.bit101.components.RadioButtonGroup;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.StatusEvent;
	import flash.media.Video;
	import flash.media.Camera;
	import ru.inspirit.flickr.Flickr;
	
	/**
	* Control Panel.
	* I use Keith Peter's Miniml Components.
	* 
	* @author Eugene Zatepyakin
	*/
	public class Controls extends Sprite
	{
		
		private var _owner:Main;
		private var panel:Panel;
		private var openFileBtn:PushButton;
		private var captureImageBtn:PushButton;
		private var capturePanel:Panel;
		private var _video:Video;
		private var _cam:Camera;
		private var fader:Sprite;
		private var fPoolG:RadioButtonGroup;
		private var radio_pool_color:RadioButton;
		private var radio_pool_macro:RadioButton;
		private var radio_pool_urban:RadioButton;
		private var radio_pool_digits:RadioButton;
		private var radio_pool_interesting:RadioButton;
		private var tileNumberSlider:HUISlider;
		private var pixelSizeSlider:HUISlider;
		private var startBtn:PushButton;
		private var poolsBtn:PushButton;
		private var poolsPanel:Panel;
		private var fOptionsG:RadioButtonGroup;
		private var radio_flickr_options_pool:RadioButton;
		private var radio_flickr_options_tags:RadioButton;
		private var radio_flickr_options_user:RadioButton;
		private var _enabled:Boolean = true;
		
		private var tmp_data:Object = { };
		
		private var texture_bmp:BitmapData;
		
		[Embed(source = '../assets/line.png')] public var texture: Class;
		
		public function Controls(owner:Main) 
		{
			_owner = owner;
			//
			tmp_data.flickrMethod = Main.flickrMethod;
			tmp_data.flickrPool = Main.flickrPool;
			tmp_data.flickrTags = Main.flickrTags;
			tmp_data.flickrUser = Main.flickrUser;
			tmp_data.flickrUserID = Main.flickrUserID;
			//
			texture_bmp = (new texture() as Bitmap).bitmapData;
			//
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			//
			panel = new Panel(this, 0, 0);
			var p:Panel = panel;
			p.height = 55;
			//
			var alls:Sprite = new Sprite();
			alls.name = "all_controls";
			var g:Graphics = alls.graphics;
			//
			openFileBtn = new PushButton(alls, 10, 5, "OPEN IMAGE", _owner.onOpenImagePress);
			captureImageBtn = new PushButton(alls, 10, 30, "CAPTURE IMAGE", onCaptureImagePress);
			openFileBtn.width = captureImageBtn.width = 90;
			
			drawSep(g, 110);
			
			var lb:Label;
			poolsBtn = new PushButton(alls, 120, 5, "", showPoolSettings);
			poolsBtn.label = "FLICKR SETTINGS";
			poolsBtn.setSize(90, 45);
			//
			drawSep(g, 220);
			
			lb = new Label(alls, 230, 3, "TILE IMAGES SETTINGS");
			tileNumberSlider = new HUISlider(alls, 230, 18, "IMAGES TO LOAD", onTilesNumberChanged);
			pixelSizeSlider = new HUISlider(alls, 230, 33, "IMAGE TILE SIZE ", onPixelSizeChanged);
			tileNumberSlider.width = pixelSizeSlider.width = 250;
			tileNumberSlider.backClick = pixelSizeSlider.backClick = true;
			tileNumberSlider.setSliderParams(50, 500, 100);
			pixelSizeSlider.setSliderParams(10, 20, 10);
			tileNumberSlider.labelPrecision = 0;
			pixelSizeSlider.labelPrecision = 0;
			
			drawSep(g, 455);
			
			startBtn = new PushButton(alls, 465, 5, "LOAD & RENDER", onStartPress);
			startBtn.setSize(90, 20);
			var render_btn:PushButton = new PushButton(alls, 465, 30, "RENDER", onRenderPress);
			render_btn.name = "render_btn";
			render_btn.setSize(90, 20);
			
			var save_btn:PushButton = new PushButton(alls, 565, 5, "SAVE", onSavePoster);
			save_btn.name = "save_btn";
			save_btn.setSize(50, 45);
			//
			var txtr:Sprite = new Sprite();
			txtr.name = "txtr";
			txtr.blendMode = "multiply";
			txtr.alpha = .2;
			p.content.addChild(txtr);
			p.content.addChild(alls);
			//
			initStep(0);
			//
			stage.addEventListener(Event.RESIZE, onResize);
			onResize();
		}
		
		public function set enabled(val:Boolean):void
		{
			if (!val) {
				fader = new Sprite();
				fader.graphics.beginFill(0x000000, .5);
				fader.graphics.drawRect(0, 0, stage.stageWidth, panel.height);
				addChild(fader);
				panel.alpha = .5;
			} else {
				removeChild(fader);
				fader = null;
				panel.alpha = 1;
			}
			_enabled = val;
		}
		
		private function onSavePoster(e:Event):void
		{
			_owner.savePoster();
		}
		
		private function showPoolSettings(e:Event):void
		{
			fader = new Sprite();
			fader.graphics.beginFill(0x000000, .5);
			fader.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			addChild(fader);
			//
			var tx:Number = (stage.stageWidth - 400) / 2;
			var ty:Number = (stage.stageHeight - 200) / 2;
			poolsPanel = new Panel(this, tx, ty);
			var p:Panel = poolsPanel;
			p.setSize(400, 200);
			//
			var lb:Label;
			fOptionsG = new RadioButtonGroup();
			fPoolG = new RadioButtonGroup();
			radio_flickr_options_pool = new RadioButton(p.content, 10, 10, "TAKE FROM FLICKR POOL", Main.flickrMethod=="pool", onFlickrOptionsChanged, fOptionsG);
			radio_pool_color = new RadioButton(p.content, 25, 33, "COLOR FIELDS", Main.flickrPool==Flickr.pool_colorfields, onFlickrPoolChanged, fPoolG);
			radio_pool_macro = new RadioButton(p.content, 120, 33, "MACRO", Main.flickrPool==Flickr.pool_macro, onFlickrPoolChanged, fPoolG);
			radio_pool_urban = new RadioButton(p.content, 185, 33, "URBAN", Main.flickrPool==Flickr.pool_urban, onFlickrPoolChanged, fPoolG);
			radio_pool_digits = new RadioButton(p.content, 245, 33, "DIGITS", Main.flickrPool == Flickr.pool_digit, onFlickrPoolChanged, fPoolG);
			radio_pool_interesting = new RadioButton(p.content, 300, 33, "INTERESTING", Main.flickrPool=="interesting", onFlickrPoolChanged, fPoolG);
			//
			radio_flickr_options_tags = new RadioButton(p.content, 10, 60, "SEARCH FLICKR TAGS", Main.flickrMethod=="tags", onFlickrOptionsChanged, fOptionsG);
			var flickr_tags:InputText = new InputText(p.content, 25, 80, Main.flickrTags.split(",").join(", "), onFlickrTagsChanged);
			flickr_tags.name = "flickr_tags";
			flickr_tags.width = 350;
			//
			radio_flickr_options_user = new RadioButton(p.content, 10, 115, "FLICKR USER", Main.flickrMethod=="user", onFlickrOptionsChanged, fOptionsG);
			var flickr_user:InputText = new InputText(p.content, 25, 135, Main.flickrUser);
			flickr_user.name = "flickr_user";
			flickr_user.restrict = "^ ";
			flickr_user.width = 300;
			lb = new Label(p.content, 25, 150, "");
			lb.name = "user_info";
			var ucheck:PushButton = new PushButton(p.content, 330, 135, "SET", onFlickrUserCheck);
			ucheck.name = "check_btn";
			ucheck.setSize(45, 16);
			//
			var ok_btn:PushButton = new PushButton(p.content, 260, 170, "OK", onPoolSettingsOK);
			var close_btn:PushButton = new PushButton(p.content, 330, 170, "CLOSE", closePoolSettings);
			ok_btn.width = close_btn.width = 60;
			//
			onFlickrOptionsChanged();
		}
		
		private function closePoolSettings(e:Event = null):void
		{
			removeChild(poolsPanel);
			removeChild(fader);
			//
			poolsPanel = null;
			fader = null;
		}
		
		private function onPoolSettingsOK(e:Event):void
		{
			Main.flickrMethod = tmp_data.flickrMethod;
			Main.flickrPool = tmp_data.flickrPool;
			Main.flickrTags = tmp_data.flickrTags.split(" ").join("");
			Main.flickrUser = tmp_data.flickrUser;
			Main.flickrUserID = tmp_data.flickrUserID;
			closePoolSettings();
		}
		
		private function onFlickrUserCheck(e:Event):void
		{
			var fu:InputText = poolsPanel.content.getChildByName("flickr_user") as InputText;
			var lab:Label = poolsPanel.content.getChildByName("user_info") as Label;
			lab.text = "Checking user name...";
			_owner.checkFlickrUser(fu.text);
		}
		
		public function setUserInfo(inf:*):void
		{
			var lab:Label = poolsPanel.content.getChildByName("user_info") as Label;
			var fu:InputText = poolsPanel.content.getChildByName("flickr_user") as InputText;
			lab.text = "Found " + inf.photoCount + " photos by " + inf.username;
			tmp_data.flickrUser = (inf.photoCount > 0) ? fu.text : Main.flickrUser;
			tmp_data.flickrUserID = (inf.photoCount > 0) ? inf.nsid : Main.flickrUserID;
		}
		
		private function onFlickrTagsChanged(e:Event):void
		{
			var ft:InputText = poolsPanel.content.getChildByName("flickr_tags") as InputText;
			tmp_data.flickrTags = ft.text;
		}
		
		private function onFlickrOptionsChanged(e:Event = null):void
		{
			var method:String;
			if (radio_flickr_options_pool.selected) method = "pool";
			if (radio_flickr_options_tags.selected) method = "tags";
			if (radio_flickr_options_user.selected) method = "user";
			//
			var ft:InputText = poolsPanel.content.getChildByName("flickr_tags") as InputText;
			var fu:InputText = poolsPanel.content.getChildByName("flickr_user") as InputText;
			var uc:PushButton = poolsPanel.content.getChildByName("check_btn") as PushButton;
			ft.tf.type = fu.tf.type = "dynamic";
			ft.tf.selectable = fu.tf.selectable = false;
			uc.buttonMode = radio_pool_color.buttonMode = radio_pool_macro.buttonMode = radio_pool_urban.buttonMode = radio_pool_digits.buttonMode = radio_pool_interesting.buttonMode = false;
			uc.mouseEnabled = radio_pool_color.mouseEnabled = radio_pool_macro.mouseEnabled = radio_pool_urban.mouseEnabled = radio_pool_digits.mouseEnabled = radio_pool_interesting.mouseEnabled = false;
			uc.alpha = ft.alpha = fu.alpha = radio_pool_color.alpha = radio_pool_macro.alpha = radio_pool_urban.alpha = radio_pool_digits.alpha = radio_pool_interesting.alpha = .5;
			//
			switch(method) {
				case "pool":
					radio_pool_color.buttonMode = radio_pool_macro.buttonMode = radio_pool_urban.buttonMode = radio_pool_digits.buttonMode = radio_pool_interesting.buttonMode = true;
					radio_pool_color.mouseEnabled = radio_pool_macro.mouseEnabled = radio_pool_urban.mouseEnabled = radio_pool_digits.mouseEnabled = radio_pool_interesting.mouseEnabled = true;
					radio_pool_color.alpha = radio_pool_macro.alpha = radio_pool_urban.alpha = radio_pool_digits.alpha = radio_pool_interesting.alpha = 1;
					break;
				case "tags":
					ft.tf.type = "input";
					ft.tf.selectable = true;
					ft.alpha = 1;
					break;
				case "user":
					fu.tf.type = "input";
					fu.tf.selectable = true;
					uc.buttonMode = uc.mouseEnabled = true;
					fu.alpha = uc.alpha = 1;
					break;
			}
			//
			tmp_data.flickrMethod = method;
		}
		
		public function initStep(step:int):void
		{
			var rb:PushButton = (panel.content.getChildByName("all_controls") as Sprite).getChildByName("render_btn") as PushButton;
			var sb:PushButton = (panel.content.getChildByName("all_controls") as Sprite).getChildByName("save_btn") as PushButton;
			
			startBtn.buttonMode = rb.buttonMode = sb.buttonMode = false;
			startBtn.mouseEnabled = rb.mouseEnabled = sb.mouseEnabled = false;
			startBtn.alpha = rb.alpha = sb.alpha = .5;
			//
			switch(step) {
				case 1:
					startBtn.alpha = 1;
					startBtn.buttonMode = true;
					startBtn.mouseEnabled = true;
					break;
				case 2:
					startBtn.alpha = rb.alpha = 1;
					startBtn.buttonMode = rb.buttonMode = true;
					startBtn.mouseEnabled = rb.mouseEnabled = true;
					break;
				case 3:
					startBtn.alpha = rb.alpha = 1;
					startBtn.buttonMode = rb.buttonMode = true;
					startBtn.mouseEnabled = rb.mouseEnabled = true;
					sb.alpha = 1;
					sb.buttonMode = true;
					sb.mouseEnabled = true;
					break;
			}
		}
		
		private function onStartPress(e:Event):void
		{
			_owner.startRender(true);
		}
		
		private function onRenderPress(e:Event):void
		{
			_owner.startRender(false);
		}
		
		private function onPixelSizeChanged(e:Event):void
		{
			Main.pixelSize = pixelSizeSlider.value;
		}
		
		private function onTilesNumberChanged(e:Event):void
		{
			Main.totalTiles = tileNumberSlider.value;
		}
		
		private function onFlickrPoolChanged(e:Event):void
		{
			var pool:String;
			if (radio_pool_color.selected) pool = Flickr.pool_colorfields;
			if (radio_pool_macro.selected) pool = Flickr.pool_macro;
			if (radio_pool_urban.selected) pool = Flickr.pool_urban;
			if (radio_pool_digits.selected) pool = Flickr.pool_digit;
			if (radio_pool_interesting.selected) pool = 'interesting';
			//
			tmp_data.flickrPool = pool;
		}
		
		private function onCaptureImagePress(e:Event):void
		{
			try {
				_cam = Camera.getCamera();
				_cam.setMode(640, 480, 30);
				_cam.setQuality(0, 100);
				_video = new Video(640, 480);
				_video.attachCamera(_cam);
				//
				if(_cam.muted){
					_cam.addEventListener(StatusEvent.STATUS, CameraStatus);
				} else {
					initCameraModule();
				}
			} catch (e:*) {
				// no camera
				trace("no camera");
			}
		}
		
		private function CameraStatus(e:StatusEvent):void
		{
			if (e.code == "Camera.Unmuted")
			{
				_cam.removeEventListener(StatusEvent.STATUS, CameraStatus);
				initCameraModule();
			}
		}
		
		private function initCameraModule():void
		{
			fader = new Sprite();
			fader.graphics.beginFill(0x000000, .5);
			fader.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			addChild(fader);
			//
			capturePanel = new Panel(this, int((stage.stageWidth - 640)/2), int((stage.stageHeight-530)/2));
			capturePanel.setSize(640, 530);
			//
			var capBtn:PushButton = new PushButton(capturePanel.content, 205, 495, "CAPTURE", doCapture);
			var closeBtn:PushButton = new PushButton(capturePanel.content, 315, 495, "CLOSE", doCloseCapture);
			//
			capturePanel.content.addChild(_video);
		}
		
		private function doCloseCapture(e:Event = null):void
		{
			capturePanel.content.removeChild(_video);
			removeChild(capturePanel);
			removeChild(fader);
			//
			_video.attachCamera(null);
			//
			capturePanel = null;
			_cam = null;
			fader = null;
			_video = null;
		}
		
		private function doCapture(e:Event):void
		{
			var bmp:BitmapData = new BitmapData(_video.width, _video.height, false, 0xFFFFFF);
			bmp.draw(_video);
			//
			doCloseCapture();
			//
			_owner.onImageCaptured(bmp);
		}
		
		private function onResize(e:Event = null):void 
		{
			var w:Number = stage.stageWidth;
			var h:Number = stage.stageHeight;
			var alls:Sprite = panel.content.getChildByName("all_controls") as Sprite;
			panel.width = w;
			alls.x = int((w - 625) * .5);
			//
			var g:Graphics = (panel.content.getChildByName("txtr") as Sprite).graphics;
			g.clear();
			g.beginBitmapFill(texture_bmp);
			g.drawRect(0, 0, w, 55);
			g.endFill();
			//
			if (capturePanel != null) {
				capturePanel.x = int((w - capturePanel.width) / 2);
				capturePanel.y = int((h - capturePanel.height) / 2);
				fader.width = w;
				fader.height = h;
			} else if (poolsPanel != null) {
				poolsPanel.x = int((w - poolsPanel.width) / 2);
				poolsPanel.y = int((h - poolsPanel.height) / 2);
				fader.width = w;
				fader.height = h;
			}
			if (!_enabled) {
				fader.width = w;
				fader.height = panel.height;
			}
		}
		
		private function drawSep(g:Graphics, x:int):void
		{
			g.lineStyle(1, 0x999999, 1, true, "normal", "SQUARE");
			g.moveTo(x, 5);
			g.lineTo(x, 49);
			g.lineStyle(1, 0xFFFFFF, 1, true, "normal", "SQUARE");
			g.moveTo(x+1, 5);
			g.lineTo(x+1, 49);
		}
		
	}
	
}