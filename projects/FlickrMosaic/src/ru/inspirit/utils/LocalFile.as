package ru.inspirit.utils
{

	import flash.display.BitmapData;
	import flash.net.FileReference;
	import flash.net.FileFilter;

	import flash.events.IOErrorEvent;
	import flash.events.Event;

	import flash.utils.ByteArray;
	
	import mx.graphics.codec.JPEGEncoder;
	
	import ru.inspirit.utils.PNGEnc;

	/**
	* Open/Save local files
	* @author Eugene Zatepyakin
	*/
	public class LocalFile
	{

		private static var fr:FileReference;
		private static var FILE_TYPES:Array = [new FileFilter("Image File", "*.jpeg;*.jpg;*.gif;*.png")];
		private static var onData:Function;
		private static var onOpenCancel:Function;
		
		private static const j_encoder : JPEGEncoder = new JPEGEncoder(100);

		public function LocalFile() { }

		public static function openFile(onOpen:Function, onSelectCancel:Function = null):void
		{
			fr = new FileReference();
			fr.addEventListener(Event.SELECT, onFileSelect);
			fr.addEventListener(Event.CANCEL, onCancel);
			//
			onData = onOpen;
			onOpenCancel = onSelectCancel;
			//
			fr.browse(FILE_TYPES);
		}

		public static function saveFile(data:*, name:String):void
		{
			fr = new FileReference();
			fr.addEventListener(Event.COMPLETE, onFileSave);
			fr.addEventListener(Event.CANCEL, onCancel);
			fr.addEventListener(IOErrorEvent.IO_ERROR, onSaveLoadError);

			fr.save(data, name);
		}
		
		public static function saveImage(data:BitmapData, name:String = "image", type:String = "png", opaque:int = 0):void
		{
			var ba : ByteArray;
			var fn:String = name + "." + type;
			if(type == "png"){
				ba = PNGEnc.encode(data, opaque);
			} else {
				ba = j_encoder.encode(data);
			}
			
			saveFile(ba, fn);
			ba = null;
		}

		private static function onFileSelect(e:Event):void
		{
			fr.addEventListener(Event.COMPLETE, onLoadComplete);
			fr.addEventListener(IOErrorEvent.IO_ERROR, onSaveLoadError);
			//
			fr.load();
		}

		private static function onCancel(e:Event):void
		{
			if (onOpenCancel != null) onOpenCancel.apply( null, [e] );
			onOpenCancel = null;
			fr = null;
		}

		private static function onLoadComplete(e:Event):void
		{
			var data:ByteArray = fr.data;
			onData.apply( null, [data]);
			onData = null;
			fr = null;
		}

		private static function onFileSave(e:Event):void
		{
			fr = null;
		}

		private static function onSaveLoadError(e:IOErrorEvent):void
		{
			trace("Error with file : " + e.text);
			fr = null;
		}

	}

}