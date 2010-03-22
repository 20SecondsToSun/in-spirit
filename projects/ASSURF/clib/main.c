/*********************************************************** 
*  ASSURF
*                                                          
*  SURF feature extraction library written in C and Flash  
*  using Adobe Alchemy.
*
*  Wikipedia: http://en.wikipedia.org/wiki/SURF
*
*  This version based on OpenCV and OpenSURF
*  implementations of SURF mostly
*
*  released under MIT License (X11)
*  http://www.opensource.org/licenses/mit-license.php
*                                                          
*  Eugene Zatepyakin
*  http://blog.inspirit.ru
*  http://code.google.com/p/in-spirit/wiki/ASSURF
*                                                          
************************************************************/


#include <math.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "AS3.h"

#include "utils.h"
#include "homography.c"


double *referencePointsData;
double *currentPointsData;
double *prevFramePointsData;

double *matchedPointsData;

double *integral;
double *determinant;
double *homography;

int width = 0;
int height = 0;
int iborder = 100;
int iwidth = 0;
int area = 0;
int area2 = 0;
int currentPointsCount = 0;
int prevFramePointsCount = 0;
int referencePointsCount = 0;
int matchedPointsCount = 0;
int homographyIsGood = 0;
int numberOfInliers = 0;

// Region Of Interest
int roi_x = 0;
int roi_y = 0;
int roi_width = 0;
int roi_height = 0;

int octaves = OCTAVES;
int intervals = INTERVALS;
int sample_step = INIT_SAMPLE;
double threshold = THRESHOLD;
int max_points = MAXPOINTS;
double point_match_factor = POINT_MATCH_FACTOR;

// ----------------------------------------------

#include "hessian.c"
#include "surf.c"

// ----------------------------------------------

int locateObject(const int minPointsForHomography)
{
	if(matchedPointsCount < minPointsForHomography) 
	{
		numberOfInliers = 0;
		return 0;
	}
	
	if(matchedPointsCount >= 4 && matchedPointsCount <= 10)
	{
		const int np2 = matchedPointsCount << 1;

		int i;
		
		double corners1[np2];
		double corners2[np2];
		double points_idx[np2];
		
		register double *cnp1, *cnp2, *mp, *pti;
		
		cnp1 = corners1;
		cnp2 = corners2;
		mp = matchedPointsData;
		pti = points_idx;
		
		for(i = 0; i < matchedPointsCount; ++i)
		{
			*(pti++) = *(mp++);
			*(pti++) = *(mp++);
			*(cnp1++) = *(mp++);
			*(cnp1++) = *(mp++);
			*(cnp2++) = *(mp++);
			*(cnp2++) = *(mp++);
		}
		
		if(findHomography(matchedPointsCount, corners1, corners2, homography))
		{
			numberOfInliers = 0;
			return 0;
		}
		
		double image1_coord[np2];
		double image2_coord[np2];
		double invH[9];
		
		invert3x3(homography, &*invH);
		
		projectPoints(homography, corners2, &*image1_coord, matchedPointsCount);
		projectPoints(invH, corners1, &*image2_coord, matchedPointsCount);
		
		int num_inliers = 0;
		mp = image1_coord;
		cnp1 = corners1;
		cnp2 = matchedPointsData;
		for( i = 0; i < matchedPointsCount; ++i )
		{
			const double distance = dSquare(*(mp++) - *(cnp1++)) + dSquare(*(mp++) - *(cnp1++)) 
									+ dSquare(image2_coord[i<<1] - corners2[i<<1]) + dSquare(image2_coord[(i<<1) + 1] - corners2[(i<<1) + 1]);
			
			if( distance < INLIER_THRESHOLD_SQ )
			{
				*(cnp2++) = points_idx[i<<1];
				*(cnp2++) = points_idx[(i<<1)+1];
				*(cnp2++) = *(cnp1-2);
				*(cnp2++) = *(cnp1-1);
				*(cnp2++) = corners2[i<<1];
				*(cnp2++) = corners2[(i<<1)+1];
				num_inliers++;
			}
		}
		
		numberOfInliers = matchedPointsCount = num_inliers;
		
		if(num_inliers < 4) return 0;
		
	} else if(matchedPointsCount > 10)
	{
		double corners1[matchedPointsCount*2];
		double corners2[matchedPointsCount*2];		
		double points_idx[matchedPointsCount*2];
		int best_inlier_ids[matchedPointsCount];
		
		int number_of_inliers, i, j;
		
		register double *cnp1, *cnp2, *mp, *pti;
		
		cnp1 = corners1;
		cnp2 = corners2;
		mp = matchedPointsData;
		pti = points_idx;
		
		for(i = 0; i < matchedPointsCount; ++i)
		{
			*(pti++)  = *(mp++);
			*(pti++)  = *(mp++);
			*(cnp1++) = *(mp++);
			*(cnp1++) = *(mp++);
			*(cnp2++) = *(mp++);
			*(cnp2++) = *(mp++);
		}
		
		ransac(corners1, corners2, matchedPointsCount, &*best_inlier_ids, &number_of_inliers, homography);
		
		if(number_of_inliers < 4) return 0;
		mp = matchedPointsData;
		
		for( i = 0; i < number_of_inliers; ++i )
		{
			j = best_inlier_ids[i] << 1;
			*(mp++) = points_idx[ j ];
			*(mp++) = points_idx[ j + 1 ];
			*(mp++) = corners1[ j ];
			*(mp++) = corners1[ j + 1 ];
			*(mp++) = corners2[ j ];
			*(mp++) = corners2[ j + 1 ];
		}
		
		matchedPointsCount = number_of_inliers;
		numberOfInliers = number_of_inliers;
		
		//refineHomography(homography, best_inlier_set1, best_inlier_set2, number_of_inliers);
		
	} else 
	{
		numberOfInliers = 0;
		return 0;
	}
	return 1;
}

void findMatches(double *set1, double *set2, const int num1, const int num2)
{
	double dist, d1, d2, lap;
	int ind1 = 5, ind2, match_idx;
	int i, j, k;
	register double *mpr, *desc1, *desc2;

	mpr = matchedPointsData;
	matchedPointsCount = 0;

	for(i = 0; i < num1; i++)
	{
		d1 = d2 = 1000000.0;
		ind2 = 5;
		lap = set1[ind1 - 1];
		desc2 = set2+4;

		for(j = 0; j < num2; j++)
		{
			if(lap != *(desc2++)) // check laplacian
			{
				ind2 += 69;
				desc2 += 68;
				continue;
			}
			
			dist = 0;
			desc1 = set1+ind1;
			
			for( k = 0; k < 64; k++ )
			{
				dist += dSquare(*(desc1++) - *(desc2++));
			}

			if(dist<d1) // if this feature matches better than current best
			{
				d2 = d1;
				d1 = dist;
				match_idx = ind2;
			}
			else if(dist<d2) // this feature matches better than second best
			{
				d2 = dist;
			}
			ind2 += 69;
			desc2 += 4;
		}

		// If match has a d1:d2 ratio < 0.6 || 0.65 || 0.5 ipoints are a match
		if(d1 < point_match_factor * d2)
		{
			*(mpr++) = i;
			*(mpr++) = (match_idx - 5) / 69;
			*(mpr++) = set1[ind1 - 5];
			*(mpr++) = set1[ind1 - 4];
			*(mpr++) = set2[match_idx - 5];
			*(mpr++) = set2[match_idx - 4];
			
			matchedPointsCount++;
		}
		ind1 += 69;
	}
}

void clearDataHolders()
{
	if(currentPointsData) free( currentPointsData );
	if(prevFramePointsData) free( prevFramePointsData );
	if(referencePointsData) free( referencePointsData );
	if(matchedPointsData) free( matchedPointsData );
	if(homography) free( homography );
	if(integral) free( integral );
	if(determinant) free( determinant );
	if(laplacian) free(laplacian);
	if(respMap) free(respMap);
}

AS3_Val setupSURF(void* self, AS3_Val args)
{
	// clear all data
	clearDataHolders();
	
	AS3_ArrayValue(args, "IntType, IntType, IntType, IntType, IntType", &width, &height, &octaves, &intervals, &sample_step );

	area = width * height;
	iwidth = width + iborder*2;
	area2 = iwidth * (height + iborder*2);

	currentPointsData =		(double*)malloc( (POINTS_POOL*POINT_DATA_LENGTH)* sizeof(double) );
	referencePointsData =	(double*)malloc( (POINTS_POOL*POINT_DATA_LENGTH)* sizeof(double) );
	prevFramePointsData =	(double*)malloc( (POINTS_POOL*POINT_DATA_LENGTH)* sizeof(double) );
	matchedPointsData =		(double*)malloc( (POINTS_POOL*6)* sizeof(double) );
	
	integral = (double*)malloc( area2 * sizeof(double) );
	
	homography = (double*)malloc(9 * sizeof(double));
	
	memset(integral, 0, area2 * sizeof(double));
	memset(homography, 0, 9 * sizeof(double));
	
	buildResponseMap();

	return 0;
}

AS3_Val resizeDataHolders(void* self, AS3_Val args)
{
	AS3_ArrayValue(args, "IntType, IntType, IntType, IntType, IntType", &width, &height, &octaves, &intervals, &sample_step );

	area = width * height;
	iwidth = width + iborder*2;
	area2 = iwidth * (height + iborder*2);

	free(integral);
	free(determinant);
	free(laplacian);
	free(respMap);

	integral = (double*)malloc( area2 * sizeof(double) );
	
	memset(integral, 0, area2 * sizeof(double));
	
	buildResponseMap();

	return 0;
}

AS3_Val getDataPointers(void* self, AS3_Val args)
{
	AS3_Val pointers = AS3_Array("AS3ValType", NULL);
	
	AS3_Set(pointers, AS3_Int(0), AS3_Ptr(&integral));
	AS3_Set(pointers, AS3_Int(1), AS3_Ptr(currentPointsData));
	AS3_Set(pointers, AS3_Int(2), AS3_Ptr(referencePointsData));
	AS3_Set(pointers, AS3_Int(3), AS3_Ptr(prevFramePointsData));
	AS3_Set(pointers, AS3_Int(4), AS3_Ptr(matchedPointsData));
	AS3_Set(pointers, AS3_Int(5), AS3_Ptr(&currentPointsCount));
	AS3_Set(pointers, AS3_Int(6), AS3_Ptr(&referencePointsCount));
	AS3_Set(pointers, AS3_Int(7), AS3_Ptr(&prevFramePointsCount));
	AS3_Set(pointers, AS3_Int(8), AS3_Ptr(&matchedPointsCount));
	AS3_Set(pointers, AS3_Int(9), AS3_Ptr(&homographyIsGood));
	AS3_Set(pointers, AS3_Int(10), AS3_Ptr(homography));
	AS3_Set(pointers, AS3_Int(11), AS3_Ptr(&roi_x));
	AS3_Set(pointers, AS3_Int(12), AS3_Ptr(&roi_y));
	AS3_Set(pointers, AS3_Int(13), AS3_Ptr(&roi_width));
	AS3_Set(pointers, AS3_Int(14), AS3_Ptr(&roi_height));
	AS3_Set(pointers, AS3_Int(15), AS3_Ptr(&point_match_factor));
	AS3_Set(pointers, AS3_Int(16), AS3_Ptr(&numberOfInliers));
	return pointers;
}


AS3_Val setThreshold(void* self, AS3_Val args)
{
	AS3_ArrayValue(args, "DoubleType", &threshold );
	return 0;
}
AS3_Val setMaxPoints(void* self, AS3_Val args)
{
	AS3_ArrayValue(args, "IntType", &max_points );
	return 0;
}

AS3_Val updateReferencePointsData(void* self, AS3_Val args)
{
	int useOrientation;

	AS3_ArrayValue(args, "IntType", &useOrientation);

	currentPointsCount = 0;	
	updateResponseMap(integral);
	getIpoints(referencePointsData, max_points);
	
	referencePointsCount = currentPointsCount;

	writePointsResult(useOrientation, referencePointsCount, referencePointsData);

	return 0;
}

AS3_Val runSURFTasks(void* self, AS3_Val args)
{
	int useOrientation;
	int options;
	int minPointsForHomography;
	AS3_ArrayValue(args, "IntType, IntType, IntType", &useOrientation, &options, &minPointsForHomography);

	if(options == 4)
	{
		prevFramePointsCount = currentPointsCount;
		memcpy(prevFramePointsData, currentPointsData, (currentPointsCount*POINT_DATA_LENGTH) * sizeof(double));
	}
	
	currentPointsCount = 0;
	updateResponseMap(integral);
	getIpoints(currentPointsData, max_points);

	writePointsResult(useOrientation, currentPointsCount, currentPointsData);

	if(options == 2) {
		findMatches(currentPointsData, referencePointsData, currentPointsCount, referencePointsCount);
	} 
	else if(options == 3) 
	{
		findMatches(currentPointsData, referencePointsData, currentPointsCount, referencePointsCount);
		homographyIsGood = locateObject(minPointsForHomography);
	} 
	else if(options == 4) 
	{
		findMatches(currentPointsData, prevFramePointsData, currentPointsCount, prevFramePointsCount);
	}

	return 0;
}

AS3_Val findReferenceMatches(void* self, AS3_Val args)
{
	int estimateHomography = 0;
	int minPointsForHomography = 4;
	
	AS3_ArrayValue(args, "IntType, IntType, IntType", &referencePointsCount, &estimateHomography, &minPointsForHomography);
	
	findMatches(currentPointsData, referencePointsData, currentPointsCount, referencePointsCount);
	
	if(estimateHomography == 1)
	{
		homographyIsGood = locateObject(minPointsForHomography);
	}
	
	return 0;
}

AS3_Val disposeSURF(void* self, AS3_Val args)
{
	clearDataHolders();
	return 0;
}


int main()
{
	AS3_Val setupSURFMethod = AS3_Function( NULL, setupSURF );
	AS3_Val setThresholdMethod = AS3_Function( NULL, setThreshold );
	AS3_Val setMaxPointsMethod = AS3_Function( NULL, setMaxPoints );
	AS3_Val disposeSURFMethod = AS3_Function( NULL, disposeSURF );
	AS3_Val updateReferencePointsDataMethod = AS3_Function( NULL, updateReferencePointsData );
	AS3_Val resizeDataHoldersMethod = AS3_Function( NULL, resizeDataHolders );
	AS3_Val runSURFTasksMethod = AS3_Function( NULL, runSURFTasks );
	AS3_Val getDataPointers_m = AS3_Function( NULL, getDataPointers );
	AS3_Val findReferenceMatches_m = AS3_Function( NULL, findReferenceMatches );


	AS3_Val result = AS3_Object("setupSURF: AS3ValType, setThreshold: AS3ValType, setMaxPoints: AS3ValType, disposeSURF: AS3ValType, updateReferencePointsData: AS3ValType, resizeDataHolders: AS3ValType, runSURFTasks: AS3ValType, getDataPointers: AS3ValType, findReferenceMatches: AS3ValType",
	setupSURFMethod, setThresholdMethod, setMaxPointsMethod, disposeSURFMethod, updateReferencePointsDataMethod, 
	resizeDataHoldersMethod, runSURFTasksMethod, getDataPointers_m, findReferenceMatches_m);

	AS3_Release( setupSURFMethod );
	AS3_Release( setThresholdMethod );
	AS3_Release( setMaxPointsMethod );
	AS3_Release( disposeSURFMethod );
	AS3_Release( updateReferencePointsDataMethod );
	AS3_Release( resizeDataHoldersMethod );
	AS3_Release( runSURFTasksMethod );
	AS3_Release( getDataPointers_m );
	AS3_Release( findReferenceMatches_m );

	AS3_LibInit( result );

	return 0;
}