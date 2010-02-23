package ru.inspirit.surf
{
	import cmodule.surf.CLibInit;

	import com.joa_ebert.apparat.memory.Memory;

	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;

	/***********************************************************
	*  FlashSURF
	*
	*  SURF feature extraction library written in C and Flash
	*  using Adobe Alchemy.
	*
	*  Wikipedia: http://en.wikipedia.org/wiki/SURF
	*
	*  I've used lot of resources for this lib such as
	*  OpenCV, OpenSURF, libmv SURF, Dlib and JavaSurf
	*
	*  released under MIT License (X11)
	*  http://www.opensource.org/licenses/mit-license.php
	*
	*  Eugene Zatepyakin
	*  http://blog.inspirit.ru
	*  http://code.google.com/p/in-spirit/source/browse/#svn/trunk/projects/FlashSURF
	*
	************************************************************/

	public final class FlashSURF
	{
		protected const SURF_LIB:Object = (new CLibInit()).init();

		protected const iborder:int = 100;
		protected const iborder2:int = 200;
		protected const colorScale:Number = 0.00392156862745098; // actually 1 / 255
		protected const defaultImageProcessor:ImageProcessor = new ImageProcessor();

		protected var alchemyRAM:ByteArray;
		protected var integralDataPointer:int;
		protected var currentPointsPointer:int;
		protected var referencePointsPointer:int;
		protected var matchedPointsPointer:int;
		protected var prevFramePointsPointer:int;
		protected var currentPointsCountPointer:int;
		protected var prevPointsCountPointer:int;
		protected var referencePointsCountPointer:int;
		protected var matchedPointsCountPointer:int;
		protected var homographyStatusPointer:int;
		protected var homographyPointer:int;
		protected var roiXPointer:int;
		protected var roiYPointer:int;
		protected var roiWidthPointer:int;
		protected var roiHeightPointer:int;
		protected var determinantPointer:int;

		protected var integralData:Vector.<Number>;
		public var buffer:BitmapData;
		protected var ipoints:Vector.<IPoint>;
		protected var matchedPoints:Vector.<IPointMatch>;

		protected var options:SURFOptions;
		protected var imageProc:ImageProcessor;
		protected var imageROI:RegionOfInterest = new RegionOfInterest();

		public var homography:HomographyMatrix = new HomographyMatrix();

		public var currentPointsCount:int = 0;
		public var referencePointsCount:int = 0;
		public var matchedPointsCount:int = 0;
		public var homographyFound:Boolean = false;

		public function FlashSURF(options:SURFOptions)
		{
			var ns:Namespace = new Namespace( "cmodule.surf" );
			alchemyRAM = (ns::gstate).ds;
			
			this.options = options;
			this.imageProc = this.options.imageProcessor || defaultImageProcessor;

			buffer = new BitmapData(options.width, options.height, false, 0x00);
			buffer.lock();

			integralData = new Vector.<Number>(options.width*options.height, true);

			SURF_LIB.setThreshold(options.threshold);
			SURF_LIB.setMaxPoints(options.maxPoints);
			SURF_LIB.setupSURF(options.width, options.height, options.octaves, options.intervals, options.sampleStep);

			updateDataPointers();
			updateROI(options.imageROI);
			allocatePointsVector();
		}
		
		/**
		 * Simply extract all found Interest Points from image
		 * 
		 * @param bmp	source image to analize [dimesions should match provided in options object]
		 */
		public function getInterestPoints(bmp:BitmapData):Vector.<IPoint>
		{			
			writeIntegralImageData(options.width, options.height, bmp);

			SURF_LIB.runSURFTasks( options.useOrientation, 1 );

			currentPointsCount = Memory.readInt(currentPointsCountPointer);
			var i:int = currentPointsCount;
			var address:int = currentPointsPointer;
			var step:int = 69 << 3;
			var ip:IPoint;

			while( --i > -1 )
			{
				ip = ipoints[i];
				ip.x = Memory.readDouble(address + 0);
				ip.y = Memory.readDouble(address + 8);
				ip.scale = ((9.0 / 1.2) * Memory.readDouble(address + 16)) / 3.0;
				ip.orientation = Memory.readDouble(address + 24);
				ip.laplacian = Memory.readDouble(address + 32);
				address += step;
			}

			return ipoints.slice(0, currentPointsCount);
		}
		
		/**
		 * Silently calculate/find Interest points inside Alchemy memory
		 * 
		 * @param bmp	source image to analize [dimesions should match provided in options object]
		 */
		public function calculateInterestPoints(bmp:BitmapData):void
		{
			writeIntegralImageData(options.width, options.height, bmp);
			
			SURF_LIB.runSURFTasks( options.useOrientation, 1 );
			
			currentPointsCount = Memory.readInt(currentPointsCountPointer);
		}
		
		/**
		 * Search for Interest points that are inside provided Rectangle
		 * and write their data to provided ByteArray
		 * 
		 * @param rect	Rectangle to search in
		 * @param ba	output ByteArray object
		 * @return		number of available points
		 */
		public function getInterestPointsRegionByteArray(rect:Rectangle, ba:ByteArray):int
		{
			var i:int = currentPointsCount;
			var address:int = currentPointsPointer;
			var step:int = 69 << 3;
			var cnt:int = 0;

			while( --i > -1 )
			{
				if(rect.contains(Memory.readDouble(address + 0), Memory.readDouble(address + 8)))
				{
					ba.writeBytes(alchemyRAM, address, step);
					cnt++;
				}
				
				address += step;
			}
			
			return cnt;
		}
		
		/**
		 * Calculate Interest points data and write it to provided ByteArray object
		 * 
		 * @param bmp	source image to analize [dimesions should match provided in options object]
		 * @param ba	output ByteArray object
		 * @return		number of available points
		 */
		public function getInterestPointsByteArray(bmp:BitmapData, ba:ByteArray):int
		{
			writeIntegralImageData(options.width, options.height, bmp);

			SURF_LIB.runSURFTasks( options.useOrientation, 1 );

			currentPointsCount = Memory.readInt(currentPointsCountPointer);
			var step:int = 69 << 3;
						
			ba.writeBytes(alchemyRAM, currentPointsPointer, step * currentPointsCount);
			
			return currentPointsCount;
		}
		
		/**
		 * Read current Interest points data into provided ByteArray object
		 * 
		 * @param ba	output ByteArray object
		 * @return		number of available points
		 */
		public function readCurrentInterestPointsToByteArray(ba:ByteArray):int
		{
			currentPointsCount = Memory.readInt(currentPointsCountPointer);
			var step:int = 69 << 3;
						
			ba.writeBytes(alchemyRAM, currentPointsPointer, step * currentPointsCount);
			
			return currentPointsCount;
		}

		/**
		 * Find matched points between source image and reference [you should set reference image first]
		 * 
		 * @param bmp						source image
		 * @param findHomography			if TRUE will try to find Homography between source and reference
		 * @param minPointsForHomography	min number of points to start finding Homography
		 * @return Vector.<IPointMatch>		matched points vector
		 */
		public function getMatchesToReference(bmp:BitmapData, findHomography:Boolean = false, minPointsForHomography:int = 4):Vector.<IPointMatch>
		{
			writeIntegralImageData(options.width, options.height, bmp);

			SURF_LIB.runSURFTasks( options.useOrientation, (findHomography ? 3 : 2), minPointsForHomography );

			currentPointsCount = Memory.readInt(currentPointsCountPointer);
			matchedPointsCount = Memory.readInt(matchedPointsCountPointer);
			var i:int = matchedPointsCount;
			var address:int = matchedPointsPointer;
			var step:int = 6 << 3;			
			var mp:IPointMatch;

			while( --i > -1 )
			{
				mp = matchedPoints[i];
				mp.currID = Memory.readDouble(address);
				mp.refID = Memory.readDouble(address + 8);
				mp.currX = Memory.readDouble(address + 16);
				mp.currY = Memory.readDouble(address + 24);
				mp.refX = Memory.readDouble(address + 32);
				mp.refY = Memory.readDouble(address + 40);
				
				address += step;
			}

			if(findHomography)
			{
				updateHomography();
			}

			return matchedPoints.slice(0, matchedPointsCount);
		}
		
		/**
		 * Write provided Interest points data into Alchemy memory as reference data
		 * 
		 * @param pointsCount	number of points
		 * @param pointsData	points data ByteArray
		 */
		public function writePointsDataToReference(pointsCount:int, pointsData:ByteArray):void
		{
			alchemyRAM.position = referencePointsPointer;
			pointsData.position = 0;
			alchemyRAM.writeBytes(pointsData);
			
			Memory.writeInt(pointsCount, referencePointsCountPointer);
		}
		
		/**
		 * Find matches between currently computed points data and provided one
		 * 
		 * @param pointsCount		number of provided points
		 * @param pointsData		points data ByteArray
		 * @param updatePointsData	specify if data should be written as reference (it may be already done and you dont want to write it again)
		 * @return					matched points Vector
		 */
		public function getMatchesToPointsData(pointsCount:int, pointsData:ByteArray, updatePointsData:Boolean = true):Vector.<IPointMatch>
		{
			if(updatePointsData)
			{
				alchemyRAM.position = referencePointsPointer;
				pointsData.position = 0;
				alchemyRAM.writeBytes(pointsData);
			}
			
			SURF_LIB.findReferenceMatches(pointsCount);
			
			matchedPointsCount = Memory.readInt(matchedPointsCountPointer);
			
			var mp:IPointMatch;			
			var i:int = matchedPointsCount;
			var address:int = matchedPointsPointer;
			var step:int = 6 << 3;
			
			while( --i > -1 )
			{
				mp = matchedPoints[i];
				mp.currID = Memory.readDouble(address);
				mp.refID = Memory.readDouble(address + 8);
				mp.currX = Memory.readDouble(address + 16);
				mp.currY = Memory.readDouble(address + 24);
				mp.refX = Memory.readDouble(address + 32);
				mp.refY = Memory.readDouble(address + 40);
				
				address += step;
			}
			
			return matchedPoints.slice(0, matchedPointsCount);
		}

		/**
		 * Find matched points between 2 provided image sources
		 * 
		 * @param image1					first image source
		 * @param image2					second image source
		 * @param image1Options				options for first image analizing
		 * @param image2Options				options for second image analizing
		 * @param findHomography			if TRUE will try to find Homography between source and reference
		 * @param minPointsForHomography	min number of points to start finding Homography
		 * @return 							matched points Vector
		 */
		public function getMatchesBetweenImages(image1:BitmapData, image2:BitmapData, image1Options:SURFOptions, image2Options:SURFOptions, findHomography:Boolean = false, minPointsForHomography:int = 4):Vector.<IPointMatch>
		{
			setReferenceImage(image2, image2Options);

			var result:Vector.<IPointMatch>;

			if(!options.compare(image1Options))
			{
				var oldOptions:SURFOptions = options;
				changeSurfOptions(image1Options);
				result = getMatchesToReference(image1, findHomography, minPointsForHomography);
				changeSurfOptions(oldOptions);
			} else {
				result = getMatchesToReference(image1, findHomography, minPointsForHomography);
			}

			return result;
		}

		/**
		 * Find matched points between source image and pevious provided one
		 * 
		 * @param bmp	source image 
		 * @return 		matched points
		 */
		public function getMatchesToPreviousFrame(bmp:BitmapData):Vector.<IPointMatch>
		{
			writeIntegralImageData(options.width, options.height, bmp);

			SURF_LIB.runSURFTasks( options.useOrientation, 4 );

			currentPointsCount = Memory.readInt(currentPointsCountPointer);
			matchedPointsCount = Memory.readInt(matchedPointsCountPointer);
			var i:int = matchedPointsCount;
			var address:int = matchedPointsPointer;
			var step:int = 6 << 3;
			var mp:IPointMatch;

			while( --i > -1 )
			{
				mp = matchedPoints[i];
				mp.currID = Memory.readDouble(address);
				mp.refID = Memory.readDouble(address + 8);
				mp.currX = Memory.readDouble(address + 16);
				mp.currY = Memory.readDouble(address + 24);
				mp.refX = Memory.readDouble(address + 32);
				mp.refY = Memory.readDouble(address + 40);
				
				address += step;
			}

			return matchedPoints.slice(0, matchedPointsCount);
		}

		/**
		 * Update default SURF options
		 * 
		 * @param options	SURF options object to apply
		 */
		public function changeSurfOptions(options:SURFOptions):void
		{
			this.options = options;
			this.imageProc = this.options.imageProcessor || defaultImageProcessor;

			SURF_LIB.setThreshold(options.threshold);
			SURF_LIB.setMaxPoints(options.maxPoints);

			SURF_LIB.resizeDataHolders(options.width, options.height, options.octaves, options.intervals, options.sampleStep);
			updateDataPointers();
			
			updateROI(this.options.imageROI);
			
			buffer.dispose();
			buffer = new BitmapData(options.width, options.height, false, 0x00);			
			buffer.lock();

			integralData = new Vector.<Number>(options.width*options.height, true);
		}

		/**
		 * Set reference image for future matches finding
		 * 
		 * @param image					reference image source
		 * @param referenceOptions		SURF options to analize image
		 */
		public function setReferenceImage(image:BitmapData, referenceOptions:SURFOptions):void
		{
			var oldOptions:SURFOptions = options;

			if(!options.compare(referenceOptions)) {
				changeSurfOptions(referenceOptions);
			}

			writeIntegralImageData(options.width, options.height, image);

			SURF_LIB.updateReferencePointsData(options.useOrientation);

			if(!oldOptions.compare(options)) {
				changeSurfOptions(oldOptions);
			}
		}

		public function set pointsThreshold(value:Number):void
		{
			options.threshold = value;
			SURF_LIB.setThreshold(value);
		}
		public function get pointsThreshold():Number
		{
			return options.threshold;
		}

		public function set maximumPoints(value:uint):void
		{
			options.maxPoints = value;
			SURF_LIB.setMaxPoints(value);
			updateDataPointers();
		}

		public function get maximumPoints():uint
		{
			return options.maxPoints;
		}
		
		public function set imageProcessor(obj:ImageProcessor):void
		{
			this.imageProc = options.imageProcessor = obj || defaultImageProcessor;
		}

		public function get imageProcessor():ImageProcessor
		{
			return options.imageProcessor;
		}
		
		public function set regionOfInterest(region:RegionOfInterest):void
		{
			updateROI(region);
		}

		public function get regionOfInterest():RegionOfInterest
		{
			return options.imageROI;
		}
		
		public function updateROI(region:RegionOfInterest):void
		{
			this.imageROI = options.imageROI = region;
			
			Memory.writeInt(region.x, roiXPointer);
			Memory.writeInt(region.y, roiYPointer);
			Memory.writeInt(region.width, roiWidthPointer);
			Memory.writeInt(region.height, roiHeightPointer);
		}
		
		/**
		 * Clears all memory inside C library
		 * after calling this method there is no way to use this instance 
		 */
		public function destroy():void
		{
			SURF_LIB.disposeSURF();
			ipoints = null;
			matchedPoints = null;
			homography = null;
			integralData = null;
			buffer.dispose();
		}

		protected function updateHomography():void
		{
			homographyFound = Memory.readInt(homographyStatusPointer) == 1;
			if(homographyFound)
			{
				homography.m11 = Memory.readDouble(homographyPointer + 0);
				homography.m12 = Memory.readDouble(homographyPointer + 8);
				homography.m13 = Memory.readDouble(homographyPointer + 16);
				homography.m21 = Memory.readDouble(homographyPointer + 24);
				homography.m22 = Memory.readDouble(homographyPointer + 32);
				homography.m23 = Memory.readDouble(homographyPointer + 40);
				homography.m31 = Memory.readDouble(homographyPointer + 48);
				homography.m32 = Memory.readDouble(homographyPointer + 56);
				homography.m33 = Memory.readDouble(homographyPointer + 64);
			}
		}

		protected function updateDataPointers():void
		{
			var pps:Array = SURF_LIB.getDataPointers();

			integralDataPointer = int(pps[0]);
			currentPointsPointer = int(pps[1]);
			referencePointsPointer = int(pps[2]);
			prevFramePointsPointer = int(pps[3]);
			matchedPointsPointer = int(pps[4]);
			currentPointsCountPointer = int(pps[5]);
			referencePointsCountPointer = int(pps[6]);
			prevPointsCountPointer = int(pps[7]);
			matchedPointsCountPointer = int(pps[8]);
			homographyStatusPointer = int(pps[9]);
			homographyPointer = int(pps[10]);
			roiXPointer = int(pps[11]);
			roiYPointer = int(pps[12]);
			roiWidthPointer = int(pps[13]);
			roiHeightPointer = int(pps[14]);
			determinantPointer = int(pps[15]);
		}

		protected function allocatePointsVector():void
		{
			var n:uint = options.maxPoints;

			ipoints = new Vector.<IPoint>(n, true);
			matchedPoints = new Vector.<IPointMatch>(n << 4, true);

			for(var i:int = 0; i < n; ++i)
			{
				ipoints[i] = new IPoint();
			}
			
			n <<= 4;
			for( i = 0; i < n; ++i )
			{
				matchedPoints[i] = new IPointMatch();
			}
		}

		protected function writeIntegralImageData(width:int, height:int, bmp:BitmapData):void
		{
			imageProc.preProcess(bmp, buffer);
			
			var data:Vector.<uint> = buffer.getVector(buffer.rect);
			//var data:Vector.<uint> = buffer.getVector(imageROI); // works incorrect while using only ROI integral
			
			var integral:Vector.<Number> = integralData;

			var i:int, j:int, ind:int, ind2:int;
			var sum:Number = 0;
			var v:Number;
			var pos:int = integralDataPointer;
			var nw:int = width + iborder2;
			//var roi_w:int = imageROI.width;
			//var roi_h:int = imageROI.height;
			//var diff_w:int = (width - (imageROI.x + roi_w)) + imageROI.x;

			//i = imageROI.x + iborder + ((iborder + imageROI.y) * nw);
			i = iborder + iborder * nw;
			//for( j = 0; j < roi_w; ++j, ++i )
			for( j = 0; j < width; ++j, ++i )
			{
				sum += (data[j] & 0xFF) * colorScale;
				integral[j] = sum;
				Memory.writeDouble(sum, pos + (i<<3));
			}

			//ind = roi_w;
			//ind2 = imageROI.x + iborder + ((iborder + imageROI.y + 1) * nw);
			ind = width;
			ind2 = i + iborder2;
			
			//for( i = 1; i < roi_h; ++i )
			for( i = 1; i < height; ++i ) 
			{
				sum = 0;
				//for( j = 0; j < roi_w; ++j, ++ind, ++ind2 )
				for( j = 0; j < width; ++j, ++ind, ++ind2 ) 
				{
					sum += (data[ind] & 0xFF) * colorScale;
					integral[ind] = (v = sum + integral[(ind - width) | 0]);
					Memory.writeDouble(v, pos + (ind2<<3));
				}
				//ind2 += iborder2 + diff_w;
				ind2 += iborder2;
			}
		}
	}
}
