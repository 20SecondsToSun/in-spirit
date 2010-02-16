package ru.inspirit.surf 
{

	/**
	 * SURF Options
	 * 
	 * @author Eugene Zatepyakin
	 */
	public final class SURFOptions 
	{
		public static const OCTAVES_DEFAULT:uint = 3;
		public static const INTERVALS_DEFAULT:uint = 4;
		public static const SAMPLE_STEP_DEFAULT:uint = 2;
		public static const MAX_POINTS_DEFAULT:uint = 200;
		public static const THRESHOLD_DEFAULT:Number = 0.004;
		
		public var octaves:uint;
		public var intervals:uint;
		public var sampleStep:uint;
		public var maxPoints:uint;
		public var threshold:Number;
		public var width:uint;
		public var height:uint;
		public var useOrientation:uint;
		public var correctImageLevels:Boolean;
		
		/**
		 * @param width					width of the provided image source
		 * @param height				height of the provided image source
		 * @param maxPoints				max points allowed to be detected (this number is limited to 10000 inside C lib)
		 * @param threshold				blob strength threshold
		 * @param useOrientation		specify if you need orientation based descriptors (needed for different sources matching)
		 * @param correctImageLevels	specify if you want correct image levels using image histagram values
		 * @param octaves				number of octaves to calculate
		 * @param intervals				number of intervals per octave
		 * @param sampleStep			initial sampling step
		 */
		
		public function SURFOptions(width:uint, height:uint, maxPoints:uint = MAX_POINTS_DEFAULT, threshold:Number = THRESHOLD_DEFAULT, useOrientation:Boolean = true, correctImageLevels:Boolean = false, octaves:uint = OCTAVES_DEFAULT, intervals:uint = INTERVALS_DEFAULT, sampleStep:uint = SAMPLE_STEP_DEFAULT)
		{
			this.width = width;
			this.height = height;
			this.maxPoints = maxPoints;
			this.threshold = threshold;
			this.useOrientation = useOrientation ? 1 : 0;
			this.correctImageLevels = correctImageLevels;
			this.octaves = octaves;
			this.intervals = intervals;
			this.sampleStep = sampleStep;
		}
		
		public function compare(options:SURFOptions):Boolean
		{
			if(width != options.width) return false;
			if(height != options.height) return false;
			if(maxPoints != options.maxPoints) return false;
			if(threshold != options.threshold) return false;
			if(useOrientation != options.useOrientation) return false;
			if(correctImageLevels != options.correctImageLevels) return false;
			if(octaves != options.octaves) return false;
			if(intervals != options.intervals) return false;
			if(sampleStep != options.sampleStep) return false;
			
			return true;
		}
		
		public function toString():String 
		{
			return "SURFOptions{width:" + width + ', height:' + height + ', maxPoints:' + maxPoints + ', threshold:' + threshold + ', useOrientation:' + useOrientation + ', correctImageLevels:' + correctImageLevels + ', octaves:' + octaves + ', intervals:' + intervals + ', sampleStep:' + sampleStep + '}';
		}
	}
}
