package ru.inspirit.surf_example.utils 
{
	import flash.geom.Rectangle;
	import ru.inspirit.surf.ImageProcessor;

	import com.quasimondo.geom.ColorMatrix;

	import flash.display.BitmapData;

	/**
	 * @author Eugene Zatepyakin
	 */
	public class QuasimondoImageProcessor extends ImageProcessor 
	{
		public var cm:ColorMatrix = new ColorMatrix();
		public var imageRect:Rectangle;
		
		public function QuasimondoImageProcessor(rect:Rectangle)
		{
			imageRect = rect;
		}

		override public function preProcess(input:BitmapData, output:BitmapData):void
		{
			output.copyPixels(input, imageRect, ORIGIN);
			
			cm.reset();
			cm.autoDesaturate(output, imageRect, false, true);
			cm.applyFilter(output);
		}
	}
}
