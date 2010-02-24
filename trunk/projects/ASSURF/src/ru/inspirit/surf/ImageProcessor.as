package ru.inspirit.surf 
{
	import flash.display.BitmapData;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Point;

	/**
	 * @author Eugene Zatepyakin
	 */
	public class ImageProcessor 
	{
		public static const GRAYSCALE_MATRIX:ColorMatrixFilter = new ColorMatrixFilter([
			0, 0, 0, 0, 0,
            0, 0, 0, 0, 0,
            .2989, .587, .114, 0, 0,
            0, 0, 0, 0, 0
		]);
		
		public static const ORIGIN:Point = new Point();
		
		public function preProcess(input:BitmapData, output:BitmapData):void
		{
			output.applyFilter(input, input.rect, ORIGIN, GRAYSCALE_MATRIX);
		}
	}
}
