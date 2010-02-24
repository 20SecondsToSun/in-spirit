package ru.inspirit.surf_example.utils 
{
	import ru.inspirit.surf.ImageProcessor;

	import com.quasimondo.geom.ColorMatrix;

	import flash.display.BitmapData;

	/**
	 * @author Eugene Zatepyakin
	 */
	public class QuasimondoImageProcessor extends ImageProcessor 
	{
		public var cm:ColorMatrix = new ColorMatrix();
		
		override public function preProcess(input:BitmapData, output:BitmapData):void
		{
			output.copyPixels(input, input.rect, ORIGIN);
			
			cm.reset();
			cm.autoDesaturate(output, false, true);
			cm.applyFilter(output);
		}
	}
}
