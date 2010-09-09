#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "AS3.h"

#include "libfast/fast.h"
#include "utils.h"
#include "homography.c"

unsigned char *img_orig;
unsigned char *img_prev;
unsigned char *img_blur;
unsigned char *img_mask;

double *integral;
double *descriptorsRef;
double *descriptorsCurr;
double *samplesCurr;
double *samplesPrev;
double *arcamera;

int *result_b;
int *currRefIndexes;

int iborder = 50;
int iwidth = 0;

int img_width = 320;
int img_height = 240;

int max_ref_points_pool = 5000;
int max_screen_points = 2000;
int max_points_pool = 500;
int max_objects_pool = 100;

IPoint *referencePoints;
IPoint *screenPoints;
IPoint *screenPointsPrev;
IPointMatch *frameMatches;
IPointMatch *refMatches;
RefObject *refObjectsMap;

int referencePointsCount = 0;
int referenceCount = 0;
int screenPointsCount = 0;
int prevFramePointsCount = 0;
int matchedPointsCount = 0;
int goodMatchedPointsCount = 0;
int foundReferenceCount = 0;

int screenPointsThresh = 10;
double screenPointsShitomasi = 70.0;
int useMask = 0;
int supressNeighbors = 0;
double supressDist = 15.0;

int DESCRIPTOR_SIZE = 36;
int PATCH_SIZE = 64;
int DETECT_PRECISION = 1;


// --------------------------------------------
// KDTREE STRUCTURE

#include "match_kdtree.c"

// --------------------------------------------
// Points Detectors and Descriptors

#include "detector_fast.c"
#include "descriptor_surf.c"

// --------------------------------------------
// 3D POSE ESTIMATION

double estimatePoseFromMatches(double *camera_info, IPointMatch *matches, double model_matrix[12], const int matchesCount, const int width, const int height);
double estimatePoseFromCorners(double *camera_info, RefObject *object);
double estimatePoseFromPoints(double *camera_info, double *scr_pts, double *ref_pts, double model_matrix[12], const int count, const int width, const int height);

// --------------------------------------------

// --------------------------------------------
// IMPORT / EXPORT OPERATIONS

#include "import_export.c"

// --------------------------------------------

/*static void * custom_memmove( void * destination, const void * source, size_t num ) {
 
  void *result;
  __asm__("%0 memmove(%1, %2, %3)\n" : "=r"(result) : "r"(destination), "r"(source), "r"(num));
  return result;
}*/
 
 
static void * custom_memcpy ( void * destination, const void * source, size_t num ) {
  void *result;
 
  __asm__("%0 memcpy(%1, %2, %3)\n" : "=r"(result) : "r"(destination), "r"(source), "r"(num));
  return result;
}
 
 
 
static void * custom_memset ( void * ptr, int value, size_t num ) {
  void *result;
  __asm__("%0 memset(%1, %2, %3)\n" : "=r"(result) : "r"(ptr), "r"(value), "r"(num));
  return result;
}
 
 
//#define memmove custom_memmove
#define memcpy custom_memcpy
#define memset custom_memset

// --------------------------------------------

AS3_Val setupGlobalBuffers(void* self, AS3_Val args)
{	
	AS3_ArrayValue(args, "IntType, IntType, IntType, IntType", &max_ref_points_pool, &max_objects_pool, &max_points_pool, &DETECT_PRECISION );
	
	DESCRIPTOR_SIZE = DETECT_PRECISION == 0 ? 64 : 36;
	
	if(referencePoints) free(referencePoints);
	if(frameMatches) free(frameMatches);
	if(refMatches) free(refMatches);
	if(refObjectsMap) free(refObjectsMap);
	if(descriptorsRef) free(descriptorsRef);
	if(samplesCurr) free(samplesCurr);
	if(arcamera) free(arcamera);
	if(result_b) free(result_b);
	if(currRefIndexes) free(currRefIndexes);
	
	referencePoints = (IPoint*)malloc( (max_ref_points_pool + max_screen_points + max_points_pool*2) * sizeof(IPoint) );
	screenPoints = referencePoints+max_ref_points_pool;
	screenPointsPrev = screenPoints+max_screen_points;
	frameMatches = (IPointMatch*)malloc( max_points_pool*2 * sizeof(IPointMatch) );
	refMatches = (IPointMatch*)malloc( max_objects_pool*max_points_pool * sizeof(IPointMatch) );
	
	refObjectsMap = (RefObject *)malloc( max_objects_pool * sizeof(RefObject) );
	
	descriptorsRef = (double*)malloc( ((DESCRIPTOR_SIZE * (max_ref_points_pool+max_points_pool)) ) * sizeof(double) );
	descriptorsCurr = descriptorsRef + (DESCRIPTOR_SIZE * max_ref_points_pool);
	
	samplesCurr = (double *)malloc( (PATCH_SIZE * max_screen_points * 2) * sizeof(double) );
	samplesPrev = samplesCurr + (PATCH_SIZE * max_screen_points);
	
	arcamera = (double*)malloc(4 * sizeof(double));
	
	memset(refObjectsMap, 0, max_objects_pool * sizeof(refObjectsMap));
	
	result_b = (int *)malloc((max_points_pool + 10) * sizeof(int));
	currRefIndexes = (int *)malloc(max_objects_pool * sizeof(int));

	return AS3_Ptr(result_b);
}

AS3_Val setupImageHolders(void* self, AS3_Val args)
{	
	AS3_ArrayValue(args, "IntType, IntType", &img_width, &img_height );
	
	if(img_orig) free(img_orig);
	
	int off = (img_width * img_height);
	
	img_orig = (unsigned char*)malloc( off * 4 );
	img_prev = img_orig+off;//(unsigned char*)malloc( img_width * img_height );
	img_blur = img_prev+off;//(unsigned char*)malloc( img_width * img_height );
	img_mask = img_blur+off;//(unsigned char*)malloc( img_width * img_height );	
	
	calcSampleWin(img_width);
	calcShiTomasiWin(img_width, 3);
	
	return AS3_Ptr(img_orig);
}

AS3_Val setupIntegral(void* self, AS3_Val args)
{	
	int iw = 320;
	int ih = 240;
	
	AS3_ArrayValue(args, "IntType, IntType", &iw, &ih );
	
	if(integral) free(integral);
	
	integral = (double*)malloc( ((iw+iborder*2) * (ih+iborder*2)) * sizeof(double) );
	
	iwidth = iw + iborder * 2;
	
	return AS3_Ptr(integral);
}

void calcIntegralData(register const unsigned char *image, int iw, int ih)
{
	const int iborder2 = 100;
	int i, j;
	double sum = 0.0;
	const double inv255 = (double)1.0 / (double)255.0;
	
	register double *ptr0 = integral+(iborder + iborder * iwidth);
	//register const unsigned char *ptr_b = image;
	for( j = 0; j < iw; j++ )
	{
		sum += (double)(*image++) * inv255;
		*(ptr0++) = sum;
	}

	//ptr_b = image+iw;
	ptr0 += iborder2;
	
	register double const *ptr1 = ptr0 - iwidth;

	for( i = 1; i < ih; i++ )
	{
		sum = 0.0;
		for( j = 0; j < iw; j++, image++, ptr0++, ptr1++ )
		{
			sum += (double)(*image) * inv255;
			*ptr0 = *ptr1 + sum;
		}
		ptr0 += iborder2;
		ptr1 += iborder2;
	}
}

AS3_Val createRefObject(void* self, AS3_Val args)
{
	int iw = 320;
	int ih = 240;
	
	AS3_ArrayValue(args, "IntType, IntType", &iw, &ih );
	
	RefObject obj;
	
	obj.index = referenceCount;
	obj.width = iw;
	obj.height = ih;
	obj.pointsCount = 0;
	obj.descriptors = descriptorsRef+(referencePointsCount*DESCRIPTOR_SIZE);
	obj.points = referencePoints+referencePointsCount;
	obj.matches = refMatches + ( referenceCount * max_points_pool );
	
	refObjectsMap[referenceCount] = obj;
	
	RefObject *obj_ptr = &refObjectsMap[referenceCount];
	
	foundReferenceCount = referenceCount++;
	
	AS3_Val pointers = AS3_Array("AS3ValType", NULL);
	
	AS3_Set(pointers, AS3_Int(0), AS3_Int(obj_ptr->index));
	AS3_Set(pointers, AS3_Int(1), AS3_Ptr(&obj_ptr->pointsCount));
	AS3_Set(pointers, AS3_Int(2), AS3_Ptr(&obj_ptr->matchedPointsCount));
	AS3_Set(pointers, AS3_Int(3), AS3_Ptr(&obj_ptr->poseError));
	AS3_Set(pointers, AS3_Int(4), AS3_Ptr(&*obj_ptr->homography));
	AS3_Set(pointers, AS3_Int(5), AS3_Ptr(&*obj_ptr->pose));
	
	return pointers;
}

AS3_Val pushDataToRefObject(void* self, AS3_Val args)
{
	int refID = 0;
	int refObjPointsCount = 0;
	AS3_Val src;
	FILE *input;
	int *iptr;
	double *dptr;
	
	AS3_ArrayValue( args, "IntType, IntType, AS3ValType", &refID, &refObjPointsCount, &src );
	
	RefObject *obj = &refObjectsMap[refID];
	
	input = funopen((void *)src, readba, writeba, seekba, closeba);
	
	int chunck_size = ( (DESCRIPTOR_SIZE * 8) + 40 );
	char out[chunck_size];
	
	int i, j;
	for(i = 0; i < refObjPointsCount; i++)
	{
		fread(out, 1, chunck_size, input);
		iptr = (int*)out;
		
		IPoint *ipt = obj->points + i;
			
		ipt->index = referencePointsCount;
		iptr++;
		ipt->refIndex = refID;
		iptr++;
		ipt->pos = *iptr++;
		ipt->x = *iptr++;
		ipt->y = *iptr++;
		ipt->scale = *iptr++;
		ipt->localIndex = i;
		
		dptr = (double*)(out+24);
			
		ipt->score = *dptr++;
		ipt->orientation = *dptr++;
		
		ipt->descriptor = descriptorsRef+(referencePointsCount*DESCRIPTOR_SIZE);
		
		j = DESCRIPTOR_SIZE;
		double *descr = ipt->descriptor;
		while( --j > -1 )
		{
			*descr++ = *dptr++;
		}
		
		referencePointsCount ++;
	}
	
	obj->pointsCount = refObjPointsCount;
	
	fclose( input );
	
	return 0;
}

AS3_Val pushImageToRefObject(void* self, AS3_Val args)
{
	int count;
	
	int refID = 0;
	int iw = 320;
	int ih = 240;
	int maxPoints = 300;
	double scale = 1.0;
	int i, j;
	IPoint *pts;
	
	AS3_ArrayValue(args, "IntType, IntType, IntType, IntType, DoubleType", &refID, &iw, &ih, &maxPoints, &scale );
	
	int dupl = 0;
	int ip_thresh = ((supressNeighbors == 0) ? 45 : 15);
	supressDist = (double)15.0 / scale;
	
	count = detectPointsFast(img_orig, iw, ih, referencePoints+referencePointsCount, ip_thresh, 70.0, maxPoints, 15, 0, &dupl);
	
	if(DESCRIPTOR_SIZE == 36)
	{
		if(DETECT_PRECISION == 1)
		{
			calcIntegralData(img_blur, iw, ih);
			calculateDescriptors_SURF36(referencePoints+referencePointsCount, count, integral, descriptorsRef+(referencePointsCount*DESCRIPTOR_SIZE));
		} else {
			fastSURFDescriptors( img_blur, iw, ih, referencePoints+referencePointsCount, count, descriptorsRef+(referencePointsCount*DESCRIPTOR_SIZE) );
		}
	}
	else
	{
		calcIntegralData(img_blur, iw, ih);
		calculateDescriptors_SURF64(referencePoints+referencePointsCount, count, integral, descriptorsRef+(referencePointsCount*DESCRIPTOR_SIZE));
	}
	
	pts = referencePoints+referencePointsCount;
	
	for(i = 0, j = referencePointsCount; i < count; i++, j++)
	{
		pts[i].mapScale = scale;
		pts[i].x *= scale;
		pts[i].y *= scale;
		pts[i].refIndex = refID;
		pts[i].index = j;
		pts[i].localIndex = i;
	}
	
	RefObject *obj_ptr = &refObjectsMap[refID];
	obj_ptr->pointsCount += count;	
	
	referencePointsCount += count;
	
	return 0;
}

AS3_Val clearReferenceObjects(void* self, AS3_Val args)
{
	int i;
	for(i = 0; i < referenceCount; i++)
	{
		if(refObjectsMap[i].kdf) vl_kdforest_delete(refObjectsMap[i].kdf);
	}
	memset(refObjectsMap, 0, max_objects_pool * sizeof(RefObject));
	
	referencePointsCount = 0;
	referenceCount = 0;
	
	return 0;
}

AS3_Val buildRefIndex(void* self, AS3_Val args)
{		
	int i;
	for(i=0; i<referenceCount; i++)
	{
		RefObject *obj = &refObjectsMap[i];
		obj->kdf = vl_kdforest_new ( DESCRIPTOR_SIZE, 5 );
		vl_kdforest_build (obj->kdf, obj->pointsCount, obj->descriptors);
		vl_kdforest_set_max_num_comparisons(obj->kdf, 81);
	}
	
	result_b[max_points_pool+3] = referencePointsCount;
	supressNeighbors = 0;
	
	return 0;
}

void relocateFeatures(IPointMatch *matches, const int count)
{	
	int i;
	
	const int num = count;
	
	for(i = 0; i < num; i++)
	{		
		memcpy(screenPointsPrev + i, matches[i].first, sizeof(IPoint));
		//memcpy(samplesCurr + i*PATCH_SIZE, matches[i].first->sample, PATCH_SIZE * sizeof(double));
		memcpy(samplesPrev + i*PATCH_SIZE, matches[i].first->sample, PATCH_SIZE * sizeof(unsigned char));		
		matches[i].first = &screenPointsPrev[i];
		matches[i].first->sample = samplesPrev + i*PATCH_SIZE;
	}
	
	prevFramePointsCount = num;
}

AS3_Val runTask(void* self, AS3_Val args)
{	
	int maxPoints = 300;
	int objID = 0;
	int options = 0;
	int count = 0;
	int skiped = 0;
	
	AS3_ArrayValue(args, "IntType, IntType, IntType, IntType", &maxPoints, &useMask, &objID, &options );
	
	if(screenPointsCount > maxPoints - 50 /*&& screenPointsThresh < 150*/)
	{
		if(screenPointsThresh < 150) screenPointsThresh += 1;
		if(screenPointsThresh >= 150 && screenPointsShitomasi < 150) screenPointsShitomasi += 1;
	}
	else if(screenPointsCount < 100 /*&& screenPointsThresh > 10*/)
	{
		//screenPointsThresh -= 5;
		if(screenPointsShitomasi <= 50 && screenPointsThresh > 10) screenPointsThresh -= 1;
		if(screenPointsShitomasi > 50) screenPointsShitomasi -= 1;
	}
	
	screenPointsCount = detectPointsFast(img_orig, img_width, img_height, screenPoints, screenPointsThresh, screenPointsShitomasi, maxPoints, 25, 1, &prevFramePointsCount);
	
	RefObject *obj = &refObjectsMap[objID];
	
	if(prevFramePointsCount < 15)
	{
	
		calculateDescriptors:
	
		if(DESCRIPTOR_SIZE == 36)
		{
			if(DETECT_PRECISION == 1)
			{
				calcIntegralData(img_blur, img_width, img_height);
				calculateDescriptors_SURF36(screenPoints, screenPointsCount, integral, descriptorsCurr);
			} 
			else 
			{
				fastSURFDescriptors( img_blur, img_width, img_height, screenPoints, screenPointsCount, descriptorsCurr );
			}
		}
		else
		{
			calcIntegralData(img_blur, img_width, img_height);
			calculateDescriptors_SURF64(screenPoints, screenPointsCount, integral, descriptorsCurr);
		}

		count = getMatchesByTree(obj, screenPoints, referencePoints, screenPointsCount, referencePointsCount, frameMatches, prevFramePointsCount, 0.7);

		result_b[max_points_pool] = screenPointsCount;
		result_b[max_points_pool+1] = count;
		result_b[max_points_pool+2] = prevFramePointsCount;
	
		count = filterOutliersByAngle(frameMatches, count);
		count = filterOutliersByLines(frameMatches, count);
		
		locatePlanarObject16(frameMatches, &count, &*obj->homography);
	}
	else
	{
		result_b[max_points_pool] = screenPointsCount;
		result_b[max_points_pool+1] = prevFramePointsCount;
		result_b[max_points_pool+2] = prevFramePointsCount;
		count = prevFramePointsCount;
		
		locatePlanarObject(frameMatches, &count, &*obj->homography);
		
		skiped = 1;
	}
	
	if(skiped == 1 && count < 8)
	{
		skiped = 0;
		prevFramePointsCount = count;
		goto calculateDescriptors;
	}
	
	obj->matchedPointsCount = count;
	goodMatchedPointsCount = count;
	
	if(options == 2 && count > 4)
	{
		//if(count < 16)
		//{
			obj->poseError = estimatePoseFromMatches(arcamera, frameMatches, &*obj->pose, count, obj->width, obj->height);
		/*}
		else
		{
			// this is optinal speed up
			IPointMatch perpMatches[8];
			perpendicularRegression(frameMatches, count, &*perpMatches);
			
			obj->poseError = estimatePoseFromMatches(arcamera, &*perpMatches, &*obj->pose, 8, obj->width, obj->height);
		}*/
	}	

	memcpy(img_prev, img_blur, img_width * img_height);
	
	result_b[max_points_pool+4] = count;
	
	relocateFeatures(frameMatches, count);
	
	return AS3_Int(count);
}

AS3_Val runTask2(void* self, AS3_Val args)
{	
	int maxPoints = 300;
	int objNum = 0;
	int options = 0;
	int i, count, skiped = 0;
	
	AS3_ArrayValue(args, "IntType, IntType, IntType", &maxPoints, &useMask, &options );
	
	if(screenPointsCount > maxPoints - 50 /*&& screenPointsThresh < 150*/)
	{
		if(screenPointsThresh < 150) screenPointsThresh += 1;
		if(screenPointsThresh >= 150 && screenPointsShitomasi < 150) screenPointsShitomasi += 1;
	}
	else if(screenPointsCount < 100 /*&& screenPointsThresh > 10*/)
	{
		//screenPointsThresh -= 5;
		if(screenPointsShitomasi <= 50 && screenPointsThresh > 10) screenPointsThresh -= 1;
		if(screenPointsShitomasi > 50) screenPointsShitomasi -= 1;
	}
	
	screenPointsCount = detectPointsFast(img_orig, img_width, img_height, screenPoints, screenPointsThresh, screenPointsShitomasi, maxPoints, 25, 1, &prevFramePointsCount);
	
	if(prevFramePointsCount < 15*foundReferenceCount)
	{
	
		calculateDescriptors:
	
		if(DESCRIPTOR_SIZE == 36)
		{
			if(DETECT_PRECISION == 1)
			{
				calcIntegralData(img_blur, img_width, img_height);
				calculateDescriptors_SURF36(screenPoints, screenPointsCount, integral, descriptorsCurr);
			}
			else
			{
				fastSURFDescriptors( img_blur, img_width, img_height, screenPoints, screenPointsCount, descriptorsCurr );
			}
		}
		else
		{
			calcIntegralData(img_blur, img_width, img_height);
			calculateDescriptors_SURF64(screenPoints, screenPointsCount, integral, descriptorsCurr);
		}
		
		//count = getMatchesByTree(screenPoints, referencePoints, screenPointsCount, referencePointsCount, frameMatches, prevFramePointsCount, 0.7);
		count = getMatchesByMultiTree(screenPoints, referencePoints, screenPointsCount, referencePointsCount, frameMatches, prevFramePointsCount, 0.7);
	
	} 
	else 
	{
		count = prevFramePointsCount;
		skiped = 1;
		sortMatchesByObjects(refObjectsMap, frameMatches, referenceCount, count);
	}
	
	result_b[max_points_pool] = screenPointsCount;
	result_b[max_points_pool+1] = count;
	result_b[max_points_pool+2] = prevFramePointsCount;
	
	foundReferenceCount = 0;
	
	IPointMatch filtMatches[count];
	int k = 0;
	
	for(i = 0; i < referenceCount; i++)
	{
	
		RefObject *obj = &refObjectsMap[ i ];
		
		if(obj->matchedPointsCount < 5) continue;
		
		currRefIndexes[objNum++] = i;
		
		obj->matchedPointsCount = filterOutliersByAngle(obj->matches, obj->matchedPointsCount);
		obj->matchedPointsCount = filterOutliersByLines(obj->matches, obj->matchedPointsCount);
		
		locatePlanarObject16(obj->matches, &obj->matchedPointsCount, &*obj->homography);
		
		if(skiped == 1 && obj->prevMatchedPointsCount >= 15 && obj->matchedPointsCount < 8)
		{
			skiped = 0;
			goto calculateDescriptors;
		}
		
		if(options == 2 && obj->matchedPointsCount > 4)
		{
			if(obj->matchedPointsCount <= 16)
			{
				obj->poseError = estimatePoseFromMatches(arcamera, obj->matches, &*obj->pose, obj->matchedPointsCount, obj->width, obj->height);
			}
			else
			{
				IPointMatch perpMatches[8];
				perpendicularRegression(obj->matches, obj->matchedPointsCount, &*perpMatches);
				
				obj->poseError = estimatePoseFromMatches(arcamera, &*perpMatches, &*obj->pose, 8, obj->width, obj->height);
			}
		}
		
		memcpy(&*(filtMatches + k), obj->matches, obj->matchedPointsCount * sizeof(IPointMatch));
		k += obj->matchedPointsCount;
		
		if(obj->matchedPointsCount >= 4) foundReferenceCount++;
	}
	
	if(foundReferenceCount == 0) foundReferenceCount = referenceCount;
	
	result_b[max_points_pool+4] = k;

	memcpy(img_prev, img_blur, img_width * img_height);
	relocateFeatures(filtMatches, k);
	
	return AS3_Int(objNum);
}

AS3_Val getDataPointers(void* self, AS3_Val args)
{
	AS3_Val pointers = AS3_Array("AS3ValType", NULL);
	
	AS3_Set(pointers, AS3_Int(0), AS3_Ptr(result_b));
	AS3_Set(pointers, AS3_Int(1), AS3_Ptr(img_blur));
	AS3_Set(pointers, AS3_Int(2), AS3_Ptr(img_mask));
	AS3_Set(pointers, AS3_Int(3), AS3_Ptr(img_orig));
	AS3_Set(pointers, AS3_Int(4), AS3_Ptr(arcamera));
	AS3_Set(pointers, AS3_Int(5), AS3_Ptr(currRefIndexes));
	AS3_Set(pointers, AS3_Int(6), AS3_Ptr(&supressNeighbors));
	
	return pointers;
}

AS3_Val clearBuffers(void* self, AS3_Val args)
{
	if(img_orig) free(img_orig);
	if(img_prev) free(img_prev);
	if(img_blur) free(img_blur);
	if(img_mask) free(img_mask);
	
	if(integral) free(integral);
	if(descriptorsRef) free(descriptorsRef);
	if(descriptorsCurr) free(descriptorsCurr);
	if(arcamera) free(arcamera);
	if(result_b) free(result_b);
	
	if(referencePoints) free(referencePoints);
	if(screenPoints) free(screenPoints);
	if(screenPointsPrev) free(screenPointsPrev);
	if(frameMatches) free(frameMatches);
	if(refMatches) free(refMatches);
	if(refObjectsMap) free(refObjectsMap);
	if(currRefIndexes) free(currRefIndexes);

	return 0;
}


int main() 
{
	AS3_Val setupGlobalBuffers_ = AS3_Function( NULL, setupGlobalBuffers );
	AS3_Val setupImageHolders_ = AS3_Function( NULL, setupImageHolders );
	AS3_Val setupIntegral_ = AS3_Function( NULL, setupIntegral );
	AS3_Val createRefObject_ = AS3_Function( NULL, createRefObject );
	AS3_Val pushImageToRefObject_ = AS3_Function( NULL, pushImageToRefObject );
	AS3_Val clearReferenceObjects_ = AS3_Function( NULL, clearReferenceObjects );
	AS3_Val buildRefIndex_ = AS3_Function( NULL, buildRefIndex );
	AS3_Val runTask_ = AS3_Function( NULL, runTask );
	AS3_Val runTask2_ = AS3_Function( NULL, runTask2 );
	AS3_Val getDataPointers_ = AS3_Function( NULL, getDataPointers );
	AS3_Val clearBuffers_ = AS3_Function( NULL, clearBuffers );
	AS3_Val exportReferencesData_ = AS3_Function( NULL, exportReferencesData );
	AS3_Val pushDataToRefObject_ = AS3_Function( NULL, pushDataToRefObject );


	AS3_Val result = AS3_Object("setupGlobalBuffers: AS3ValType, setupImageHolders: AS3ValType, setupIntegral: AS3ValType, createRefObject: AS3ValType, pushImageToRefObject: AS3ValType, clearReferenceObjects: AS3ValType, buildRefIndex: AS3ValType, runTask: AS3ValType, runTask2: AS3ValType, getDataPointers: AS3ValType, clearBuffers: AS3ValType, exportReferencesData: AS3ValType, pushDataToRefObject: AS3ValType",
	setupGlobalBuffers_, setupImageHolders_, setupIntegral_, createRefObject_, pushImageToRefObject_, clearReferenceObjects_, buildRefIndex_, runTask_, runTask2_, getDataPointers_, clearBuffers_, exportReferencesData_, pushDataToRefObject_);

	AS3_Release( setupGlobalBuffers_ );
	AS3_Release( setupImageHolders_ );
	AS3_Release( setupIntegral_ );
	AS3_Release( createRefObject_ );
	AS3_Release( pushImageToRefObject_ );
	AS3_Release( clearReferenceObjects_ );
	AS3_Release( buildRefIndex_ );
	AS3_Release( runTask_ );
	AS3_Release( runTask2_ );
	AS3_Release( getDataPointers_ );
	AS3_Release( clearBuffers_ );
	AS3_Release( exportReferencesData_ );
	AS3_Release( pushDataToRefObject_ );

	AS3_LibInit( result );
	
	return 0;
}
