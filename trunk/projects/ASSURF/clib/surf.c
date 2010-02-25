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
*                                                          
************************************************************/


#include <math.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "AS3.h"

static const double pi = 3.14159;
static const double two_pi = 6.28318;
static const double pi_on_three = 1.04719667;

inline int IMIN(register int a, register int b)
{
	return (((a) < (b)) ? (a) : (b));
}

inline double FMAX(register double a, register double b)
{
	return (((a) < (b)) ? (b) : (a));
}

inline double IGAUSSIAN(register int x, const int y, register double sig)
{
	return (1.0 / (two_pi*sig*sig) * exp( -(x*x+y*y) / (2.0*sig*sig)));
}
inline double FGAUSSIAN(register double x, register double y, register double sig)
{
	return (1.0 / (two_pi*sig*sig) * exp( -(x*x+y*y) / (2.0*sig*sig)));
}

inline double ANGLE(register double X, register double Y)
{
	if(X > 0 && Y >= 0) return atan(Y/X);

	if(X < 0 && Y >= 0) return pi - atan(-Y/X);

	if(X < 0 && Y < 0) return pi + atan(Y/X);

	if(X > 0 && Y < 0) return two_pi - atan(-Y/X);

	return 0.0;
}

#include "ransac.c"

int PseudoInverse(register double *inv, register double *matx, const int M, const int N);
void MultiplyMat(register double *m1, register double *m2, register double *res, const int M1, const int N1, const int M2, const int N2);
void ransac(register double *corners1, register double *corners2, int npoints, register double *best_inlier_set1, 
			register double *best_inlier_set2, int *number_of_inliers, register double *bestH);
int findHomography(const int np, register double *obj, register double *img, register double *mat);
void refineHomography(double *ransac_H, double *inlier_set1, double *inlier_set2, int number_of_inliers);


static const int gauss25ID[13] = {6,5,4,3,2,1,0,1,2,3,4,5,6};
static const double gauss25 [7][7] = {
	{0.02350693969273,0.01849121369071,0.01239503121241,0.00708015417522,0.00344628101733,0.00142945847484,0.00050524879060},
	{0.02169964028389,0.01706954162243,0.01144205592615,0.00653580605408,0.00318131834134,0.00131955648461,0.00046640341759},
	{0.01706954162243,0.01342737701584,0.00900063997939,0.00514124713667,0.00250251364222,0.00103799989504,0.00036688592278},
	{0.01144205592615,0.00900063997939,0.00603330940534,0.00344628101733,0.00167748505986,0.00069579213743,0.00024593098864},
	{0.00653580605408,0.00514124713667,0.00344628101733,0.00196854695367,0.00095819467066,0.00039744277546,0.00014047800980},
	{0.00318131834134,0.00250251364222,0.00167748505986,0.00095819467066,0.00046640341759,0.00019345616757,0.00006837798818},
	{0.00131955648461,0.00103799989504,0.00069579213743,0.00039744277546,0.00019345616757,0.00008024231247,0.00002836202103}
};

static const double gauss33 [11][11] = {
	{0.014614763,0.013958917,0.012162744,0.00966788,0.00701053,0.004637568,0.002798657,0.001540738,0.000773799,0.000354525,0.000148179},
	{0.013958917,0.013332502,0.011616933,0.009234028,0.006695928,0.004429455,0.002673066,0.001471597,0.000739074,0.000338616,0.000141529},
	{0.012162744,0.011616933,0.010122116,0.008045833,0.005834325,0.003859491,0.002329107,0.001282238,0.000643973,0.000295044,0.000123318},
	{0.00966788,0.009234028,0.008045833,0.006395444,0.004637568,0.003067819,0.001851353,0.001019221,0.000511879,0.000234524,9.80224E-05},
	{0.00701053,0.006695928,0.005834325,0.004637568,0.003362869,0.002224587,0.001342483,0.000739074,0.000371182,0.000170062,7.10796E-05},
	{0.004637568,0.004429455,0.003859491,0.003067819,0.002224587,0.001471597,0.000888072,0.000488908,0.000245542,0.000112498,4.70202E-05},
	{0.002798657,0.002673066,0.002329107,0.001851353,0.001342483,0.000888072,0.000535929,0.000295044,0.000148179,6.78899E-05,2.83755E-05},
	{0.001540738,0.001471597,0.001282238,0.001019221,0.000739074,0.000488908,0.000295044,0.00016243,8.15765E-05,3.73753E-05,1.56215E-05},
	{0.000773799,0.000739074,0.000643973,0.000511879,0.000371182,0.000245542,0.000148179,8.15765E-05,4.09698E-05,1.87708E-05,7.84553E-06},
	{0.000354525,0.000338616,0.000295044,0.000234524,0.000170062,0.000112498,6.78899E-05,3.73753E-05,1.87708E-05,8.60008E-06,3.59452E-06},
	{0.000148179,0.000141529,0.000123318,9.80224E-05,7.10796E-05,4.70202E-05,2.83755E-05,1.56215E-05,7.84553E-06,3.59452E-06,1.50238E-06}
};

// pre calculated lobe sizes
static const int lobe_cache [16] = {3,5,7,9,5,9,13,17,9,17,25,33,17,33,49,65};
static const int lobe_map [16] = {0,1,2,3,1,3,4,5,3,5,6,7,5,7,8,9};
static const int border_cache [4] = {14,26,50,98};


#define OCTAVES 4
#define INTERVALS 4
#define INIT_SAMPLE 2
#define THRESHOLD 0.004
#define MAXPOINTS 200
#define POINTS_POOL 30000
#define POINT_DATA_LENGTH 69


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


static void buildDeterminant(register double *integralData, register double *determData)
{
	int hmb, wmb, l, w, b, border, step, ind, lap_sign;
	int ind11, ind12, cc1, cc2;
	int rw, r1, r2, r3, r4, l2, l_2;
	int o, i, r, c;
	//double dxx1, dxx2, dxx3, dxx4;
	double Dxx, Dyy, Dxy, inverse_area;

	for(o = 0; o < octaves; ++o)
	{
		step = (int)(sample_step * pow(2, o));
		border = border_cache[o];
		//hmb = height - border;
		//wmb = width - border;
		
		hmb = roi_y + roi_height - border;
		wmb = roi_x + roi_width - border;

		for(i = 0; i < intervals; ++i)
		{
			ind = o*intervals + i;
			l = lobe_cache[ind];
			l2 = (l<<1);
			l_2 = (l>>1);
			w = 3 * l;
			b = (w>>1);
			inverse_area = 1.0 / (w * w);
			ind *= area;

			for(r = roi_y + border; r < hmb; r += step)
			{
				rw = r * width + ind;
				r1 = r - l + iborder;
				r2 = r - b - 1 + iborder;
				r3 = r - l_2 - 1 + iborder;
				r4 = r - l - 1 + iborder;
				for(c = roi_x + border; c < wmb; c += step)
				{
					//rr1 = r1;
					//cc1 = c-b - 1 + iborder;
					//rr2 = rr1 + l2 - 1;
					//cc2 = cc1 + w;

					//ind11 = rr1 * iwidth;
					//ind12 = rr2 * iwidth;

					//dxx1 = integralData[(ind11 + cc1)] - integralData[(ind11 + cc2)] - integralData[(ind12 + cc1)] + integralData[(ind12 + cc2)];
					//dxx1 = *(integralData+(r1)*iwidth+c-b-1+iborder) - *(integralData+(r1)*iwidth+c-b-1+iborder+w) - *(integralData+(r1+l2-1)*iwidth+c-b-1+iborder) + *(integralData+(r1+l2-1)*iwidth+c-b-1+iborder+w);

					//cc1 = c - l_2 - 1 + iborder;
					//cc2 = cc1 + l;

					//dxx2 = integralData[(ind11 + cc1)] - integralData[(ind11 + cc2)] - integralData[(ind12 + cc1)] + integralData[(ind12 + cc2)];
					//dxx2 = *(integralData+(r1)*iwidth+c-l_2-1+iborder) - *(integralData+(r1)*iwidth+c-l_2-1+iborder+l) - *(integralData+(r1+l2-1)*iwidth+c-l_2-1+iborder) + *(integralData+(r1+l2-1)*iwidth+c-l_2-1+iborder+l);

					Dxx = (double)(FMAX(0.0, integralData[(ind11=r1*iwidth)+(cc1=c-b-1+iborder)] - integralData[ind11+(cc2=cc1+w)] - integralData[(ind12=(r1+l2-1)*iwidth)+cc1] + integralData[ind12+cc2])
					- FMAX(0.0, (integralData[ind11+(cc1=c-l_2-1+iborder)] - integralData[ind11+(cc2=cc1+l)] - integralData[ind12+cc1] + integralData[ind12+cc2])) * 3);

					// DYY

					/*rr1 = r2;
					cc1 = c - l + iborder;
					rr2 = rr1 + w;
					cc2 = cc1 + l2 - 1;

					ind11 = rr1 * iwidth;
					ind12 = rr2 * iwidth;

					dxx1 = integralData[(ind11 + cc1)] - integralData[(ind11 + cc2)] - integralData[(ind12 + cc1)] + integralData[(ind12 + cc2)];*/
					//dxx1 = *(integralData+(r2)*iwidth+c-l+iborder) - *(integralData+(r2)*iwidth+c-l+iborder+l2-1) - *(integralData+(r2+w)*iwidth+c-l+iborder) + *(integralData+(r2+w)*iwidth+c-l+iborder+l2-1);

					//rr1 = r3;
					//rr2 = rr1 + l;

					//ind11 = rr1 * iwidth;
					//ind12 = rr2 * iwidth;

					//dxx2 = integralData[(ind11 + cc1)] - integralData[(ind11 + cc2)] - integralData[(ind12 + cc1)] + integralData[(ind12 + cc2)];
					//dxx2 = *(integralData+(r3)*iwidth+c-l+iborder) - *(integralData+(r3)*iwidth+c-l+iborder+l2-1) - *(integralData+(r3+l)*iwidth+c-l+iborder) + *(integralData+(r3+l)*iwidth+c-l+iborder+l2-1);

					Dyy = (double)(FMAX(0.0, (*(integralData+(ind11=(r2)*iwidth)+(cc1=c-l+iborder)) - *(integralData+ind11+(cc2=cc1+l2-1)) - *(integralData+(ind12=(r2+w)*iwidth)+cc1) + *(integralData+ind12+cc2)))
					- FMAX(0.0, (*(integralData+(ind11=(r3)*iwidth)+cc1) - *(integralData+ind11+cc2) - *(integralData+(ind12=(r3+l)*iwidth)+cc1) + *(integralData+ind12+cc2))) * 3);

					// DXY

					//rr1 = r4;
					//cc1 = c + iborder;
					//rr2 = rr1 + l;
					//cc2 = cc1 + l;

					//ind11 = rr1 * iwidth;
					//ind12 = rr2 * iwidth;

					//dxx1 = integralData[(ind11 + cc1)] - integralData[(ind11 + cc2)] - integralData[(ind12 + cc1)] + integralData[(ind12 + cc2)];
					//dxx1 = *(integralData+(r4)*iwidth+c+iborder) - *(integralData+(r4)*iwidth+c+iborder+l) - *(integralData+(r4+l)*iwidth+c+iborder) + *(integralData+(r4+l)*iwidth+c+iborder+l);

					//cc1 = c - l - 1 + iborder;
					//cc2 = cc1 + l;

					//dxx3 = integralData[(ind11 + cc1)] - integralData[(ind11 + cc2)] - integralData[(ind12 + cc1)] + integralData[(ind12 + cc2)];
					//dxx3 = *(integralData+(r4)*iwidth+c-l-1+iborder) - *(integralData+(r4)*iwidth+c-1+iborder) - *(integralData+(r4+l)*iwidth+c-l-1+iborder) + *(integralData+(r4+l)*iwidth+c-1+iborder);

					//rr1 = r + iborder;
					//rr2 = rr1 + l;

					//ind11 = rr1 * iwidth;
					//ind12 = rr2 * iwidth;

					//dxx2 = integralData[(ind11 + cc1)] - integralData[(ind11 + cc2)] - integralData[(ind12 + cc1)] + integralData[(ind12 + cc2)];
					//dxx2 = *(integralData+(r+iborder)*iwidth+c-l-1+iborder) - *(integralData+(r+iborder)*iwidth+c-1+iborder) - *(integralData+(r+iborder+l)*iwidth+c-l-1+iborder) + *(integralData+(r+iborder+l)*iwidth+c-1+iborder);

					//cc1 = c + iborder;
					//cc2 = cc1 + l;

					//dxx4 = integralData[(ind11 + cc1)] - integralData[(ind11 + cc2)] - integralData[(ind12 + cc1)] + integralData[(ind12 + cc2)];
					//dxx4 = *(integralData+(r+iborder)*iwidth+c+iborder) - *(integralData+(r+iborder)*iwidth+c+iborder+l) - *(integralData+(r+iborder+l)*iwidth+c+iborder) + *(integralData+(r+iborder+l)*iwidth+c+iborder+l);

					Dxy = (double)(FMAX(0.0, (*(integralData+(ind11=(r4)*iwidth)+(cc1=c+iborder)) - *(integralData+ind11+(cc2=cc1+l)) - *(integralData+(ind12=(r4+l)*iwidth)+cc1) + *(integralData+ind12+cc2)))
					+ FMAX(0.0, (*(integralData+(ind11=(r+iborder)*iwidth)+(cc1=c-l-1+iborder)) - *(integralData+ind11+(cc2=cc1+l)) - *(integralData+(ind12=(r+iborder+l)*iwidth)+cc1) + *(integralData+ind12+cc2)))
					- FMAX(0.0, (*(integralData+(ind11=(r4)*iwidth)+cc1) - *(integralData+ind11+cc2) - *(integralData+(ind12=(r4+l)*iwidth)+cc1) + *(integralData+ind12+cc2)))
					- FMAX(0.0, (*(integralData+(ind11=(r+iborder)*iwidth)+(cc1=c+iborder)) - *(integralData+ind11+(cc2=cc1+l)) - *(integralData+(ind12=(r+iborder+l)*iwidth)+cc1) + *(integralData+ind12+cc2))));

					// Normalise the filter responses with respect to their size
					Dxx *= inverse_area;
					Dyy *= inverse_area;
					Dxy *= inverse_area;

					// Get the sign of the laplacian
					lap_sign = (Dxx+Dyy >= 0 ? 1 : -1);

					// Get the determinant of hessian response
					//float det = (Dxx*Dyy - 0.81f*Dxy*Dxy);
					//if(det < 0) det = FMAX(0, det);

					determData[ rw + c ] = (double)( lap_sign * FMAX(0.0, (Dxx*Dyy - 0.81*Dxy*Dxy)) );
				}
			}
		}
	}
}

static int isExtremum(register double *determData, const int step, const double val, const int octave, const int interval, const int c, const int r)
{
	// Bounds check
	if (interval - 1 < 0 || interval + 1 > intervals - 1
			|| c - step < 0 || c + step > width
			|| r - step < 0 || r + step > height)
	{
		return 0;
	}

	int ii, cc, rr;
	int ind1 = octave * intervals;

	// Check for maximum
	for( ii = interval-1; ii <= interval+1; ++ii )
	{
		for( cc = c - step; cc <= c + step; cc+=step )
		{
			for( rr = r - step; rr <= r + step; rr+=step )
			{
				if (ii != 0 || cc != 0 || rr != 0)
				{
					if( fabs(determData[ (ind1 + ii) * (area) + (rr * width + cc) ]) > val )
					{
						return 0;
					}
				}
			}
		}
	}

	return 1;
}

static int interpolateExtremum(register double *determData, double *pointsData, const int step, const double val, const int octv, const int intvl, const int r, const int c)
{
	double xi, xr, xc;
	double _dx, _dy, _ds, dxx, dyy, dss, dxy, dxs, dys, v1, v2;
	int ind = (octv * intervals + intvl) * area + (r * width + c);
	int sw = step * width;

	v1 = fabs(determData[ ind + step ]);
	v2 = fabs(determData[ ind - step ]);

	_dx = (v1 - v2) * 0.5;
	dxx = (v1 + v2) - 2 * val;

	v1 = fabs(determData[ ind + sw ]);
	v2 = fabs(determData[ ind - sw ]);

	_dy = (v1 - v2) * 0.5;
	dyy = (v1 + v2) - 2 * val;

	v1 = fabs(determData[ ind + area ]);
	v2 = fabs(determData[ ind - area ]);

	_ds = (v1 - v2) * 0.5;
	dss = (v1 + v2) - 2 * val;

	// Hessian 3D

	dxy = (fabs(determData[ ind + step + sw ]) - fabs(determData[ ind - step + sw ]) - fabs(determData[ ind + step - sw ]) + fabs(determData[ ind - step - sw ])) * 0.25;

	dxs = (fabs(determData[ ind + area + step ]) - fabs(determData[ ind + area - step ]) - fabs(determData[ ind - area + step ]) + fabs(determData[ ind - area - step ])) * 0.25;

	dys = (fabs(determData[ ind + area + sw ]) - fabs(determData[ ind + area - sw ]) - fabs(determData[ ind - area + sw ]) + fabs(determData[ ind - area - sw ])) * 0.25;

	double det = -1.0 / ( dxx * ( dyy*dss-dys*dys) - dxy * (dxy*dss-dxs*dys) + dxs * (dxy*dys-dxs*dyy) );

	xc = det * ( _dx * ( dyy*dss-dys*dys ) + _dy * ( dxs*dys-dss*dxy ) + _ds * ( dxy*dys-dyy*dxs ) );
	xr = det * ( _dx * ( dys*dxs-dss*dxy ) + _dy * ( dxx*dss-dxs*dxs ) + _ds * ( dxs*dxy-dys*dxx ) );
	xi = det * ( _dx * ( dxy*dys-dxs*dyy ) + _dy * ( dxy*dxs-dxx*dys ) + _ds * ( dxx*dyy-dxy*dxy ) );

	if(fabs(xi) < 0.5 && fabs(xr) < 0.5 && fabs(xc) < 0.5)
	{
		//ipoint *ipt = &pointsData[currentPointsCount++];
		
		/*ipt->x = (double)(c + step * xc);
		ipt->y = (double)(r + step * xr);
		ipt->scale = (double)((1.2/9.0) * (3*(pow(2, octv+1) * (intvl+xi+1)+1)));
		ipt->score = val;
		ipt->orientation = 0.0;
		ipt->laplacian = (double)(determData[ind] < 0 ? -1.0 : 1.0);*/
		register double *ptr = pointsData;
		*(ptr++) = (double)(c + step * xc);
		*(ptr++) = (double)(r + step * xr);
		*(ptr++) = (double)(0.1333 * (3*(pow(2, octv+1) * (intvl+xi+1)+1)));
		*(ptr++) = 0.0;
		*(ptr++) = (double)(determData[ind] < 0 ? -1.0 : 1.0);
		
		return 1;
	}
	return 0;
}

static int getInterestPoints(register double *determData, register double *pointsData)
{
	int o, i, r, c, ii, rr, cc;
	int hmb, wmb, step, s2, border, ie, re, ce, oint, rw;
	int im1 = intervals - 1;
	double val;

	for(o = 0; o < octaves; ++o)
	{
		step = (int)(sample_step * pow(2, o));
		s2 = (step<<1);
		border = border_cache[o];
		
		//hmb = height - border - step;
		//wmb = width - border - step;
		hmb = roi_y + roi_height - border - step;
		wmb = roi_x + roi_width - border - step;
		
		oint = o * intervals;

		for(i = 1; i < im1; i += 2)
		{
			ie = IMIN(im1, i + 2);
			for(r = roi_y + border+step; r < hmb; r += s2)
			{
				re = IMIN(hmb, r + s2);
				for(c = roi_x + border+step; c < wmb; c += s2)
				{
					int i_max = -1, r_max = -1, c_max = -1;
					double max_val = 0;

					ce = IMIN(wmb, c + s2);
					for (ii = i; ii < ie; ++ii)
					{
						for (rr = r; rr < re; rr += step)
						{
							rw = rr * width;
							for (cc = c; cc < ce; cc += step)
							{
								val = fabs(determData[((oint + ii) * (area) + (rw + cc))]);

								if (val > max_val)
								{
									max_val = val;
									i_max = ii;
									r_max = rr;
									c_max = cc;
								}
							}
						}
					}

					// Check the block extremum is an extremum across boundaries.
					if (max_val > threshold && isExtremum(determData, step, max_val, o, i_max, c_max, r_max)
						&& interpolateExtremum(determData, pointsData, step, max_val, o, i_max, r_max, c_max))
					{
						//if(){
							currentPointsCount ++;
							if(currentPointsCount == max_points) return 1;
							pointsData += POINT_DATA_LENGTH;
						//}
					}
				}
			}
		}
	}
	return 0;
}

static double resX[109];
static double resY[109];
static double Ang[109];
static double getPointOrientation(const int c, const int r, const double scale, register double *integralData)
{
	int i, j, cc, rr;
	int ind11, ind12, cc1, cc2;
	//double dxx1, dxx2;
	double gauss, _resx, _resy, nmax;
	int s = (int)(scale+0.5);
	int s4 = (s<<2);
	int s2 = (s4>>1);

	int idx = 0;
	register double *rxp = resX;
	register double *ryp = resY;
	register double *anp = Ang;

	for (i = -6; i <= 6; ++i)
	{
		cc = c + i * s + iborder;
		for (j = -6; j <= 6; ++j)
		{
			if (i * i + j * j < 36)
			{
				rr = r + j * s + iborder;
				gauss = gauss25[gauss25ID[i+6]][gauss25ID[j+6]];

				// HAAR X / Y //

				//rr1 = rr - s2;
				//cc1 = cc;
				//rr2 = rr1 + s4;
				//cc2 = cc1 + s2;

				//ind11 = rr1 * iwidth;
				//ind12 = rr2 * iwidth;

				//dxx1 = integralData[(ind11 + cc1)] - integralData[(ind11 + cc2)] - integralData[(ind12 + cc1)] + integralData[(ind12 + cc2)];
				//dxx1 = *(integralData+(rr-s2)*iwidth+cc) - *(integralData+(rr-s2)*iwidth+cc+s2) - *(integralData+(rr-s2+s4)*iwidth+cc) + *(integralData+(rr-s2+s4)*iwidth+cc+s2);

				//cc1 = cc - s2;
				//cc2 = cc1 + s2;

				//dxx2 = integralData[(ind11 + cc1)] - integralData[(ind11 + cc2)] - integralData[(ind12 + cc1)] + integralData[(ind12 + cc2)];
				//dxx2 = *(integralData+(rr-s2)*iwidth+cc-s2) - *(integralData+(rr-s2)*iwidth+cc) - *(integralData+(rr-s2+s4)*iwidth+cc-s2) + *(integralData+(rr-s2+s4)*iwidth+cc);

				_resx = gauss * (FMAX(0.0, (*(integralData+(ind11=(rr-s2)*iwidth)+cc) - *(integralData+ind11+(cc2=cc+s2)) - *(integralData+(ind12=(rr-s2+s4)*iwidth)+cc) + *(integralData+ind12+cc2)))
				- 1*FMAX(0.0, (*(integralData+ind11+(cc1=cc-s2)) - *(integralData+ind11+cc) - *(integralData+ind12+cc1) + *(integralData+ind12+cc))));

				// Y

				//rr1 = rr;
				//cc1 = cc - s2;
				//rr2 = rr1 + s2;
				//cc2 = cc1 + s4;

				//ind11 = rr1 * iwidth;
				//ind12 = rr2 * iwidth;
				//dxx1 = integralData[(ind11 + cc1)] - integralData[(ind11 + cc2)] - integralData[(ind12 + cc1)] + integralData[(ind12 + cc2)];
				//dxx1 = *(integralData+(rr)*iwidth+cc-s2) - *(integralData+(rr)*iwidth+cc-s2+s4) - *(integralData+(rr+s2)*iwidth+cc-s2) + *(integralData+(rr+s2)*iwidth+cc-s2+s4);

				//rr1 = rr - s2;
				//rr2 = rr1 + s2;

				//ind11 = rr1 * iwidth;
				//ind12 = rr2 * iwidth;
				//dxx2 = integralData[(ind11 + cc1)] - integralData[(ind11 + cc2)] - integralData[(ind12 + cc1)] + integralData[(ind12 + cc2)];
				//dxx2 = *(integralData+(rr-s2)*iwidth+cc-s2) - *(integralData+(rr-s2)*iwidth+cc-s2+s4) - *(integralData+(rr)*iwidth+cc-s2) + *(integralData+(rr)*iwidth+cc-s2+s4);

				_resy = gauss * (FMAX(0.0, (*(integralData+(ind11=(rr)*iwidth)+(cc1=cc-s2)) - *(integralData+ind11+(cc2=cc1+s4)) - *(integralData+(ind12=(rr+s2)*iwidth)+cc1) + *(integralData+ind12+cc2)))
				- 1*FMAX(0.0, (*(integralData+(ind12=(rr-s2)*iwidth)+cc1) - *(integralData+ind12+cc2) - *(integralData+ind11+cc1) + *(integralData+ind11+cc2))));


				*(rxp++) = _resx;
				*(ryp++) = _resy;
				*(anp++) = ANGLE(_resx, _resy);
				++idx;
			}
		}
	}

	// calculate the dominant direction
	double *end_a = Ang+idx;
	double max = 0, orientation = 0;
	double ang1 = 0, ang2 = 0, ang;

	// loop slides pi/3 window around feature point
	for(ang1 = 0; ang1 < two_pi;  ang1 += 0.15)
	{
		ang2 = ( ang1+pi_on_three > two_pi ? ang1-5.0*pi_on_three : ang1+pi_on_three);
		_resx = _resy = 0;
		
		for(anp = Ang, rxp=resX, ryp=resY; anp < end_a;)
		{
			ang = *(anp++);

			// determine whether the point is within the window
			if ( ang1 < ang2 && ang1 < ang && ang < ang2 )
			{
				_resx += *(rxp++);
				_resy += *(ryp++);
			}
			else if (ang2 < ang1 &&
					((ang > 0 && ang < ang2) || (ang > ang1 && ang < two_pi) ))
			{
				_resx += *(rxp++);
				_resy += *(ryp++);
			} else {
				rxp++;
				ryp++;
			}
		}

		// if the vector produced from this window is longer than all
		// previous vectors then this forms the new dominant direction
		nmax = _resx*_resx + _resy*_resy;
		if (nmax > max)
		{
			max = nmax;
			orientation = ANGLE(_resx, _resy);
		}
	}

	return orientation;
}

static void getDescriptor(	const int x, const int y, const double scale, const double co, const double si, 
							register double *integralData, register double *start, register double *end
						)
{
	int ind11, ind12, cc1, cc2;
	int sample_x, sample_y, k, l;
	int i, ix=0, j, jx=0, xs=0, ys=0;
	double scale25, dx, dy, mdx, mdy;
	double gauss_s1=0, gauss_s2=0;
	double rx=0.0, ry=0.0, rrx=0.0, rry=0.0, len=0.0;
	double cx = -0.5, cy = 0.0; //Subregion centers for the 4x4 IGAUSSIAN weighting

	scale25 = 2.5 * scale;
	int s2 = ((int)(scale+0.5)<<1);
	int s22 = (s2>>1);

	register double *data_ptr = start;

	//Calculate descriptor for this interest point
	for( i = -8; i < 12; i+=9 )
	{
		i = i-4;

		cx += 1.0;
		cy = -0.5;

		for( j = -8; j < 12; j+=9 )
		{
			dx=dy=mdx=mdy=0;
			cy += 1.0;

			j = j - 4;

			ix = i + 5;
			jx = j + 5;

			xs = (int)(x + ( -jx*scale*si + ix*scale*co) + 0.5);
			ys = (int)(y + ( jx*scale*co + ix*scale*si) + 0.5);

			for (k = i; k < i + 9; ++k)
			{
				for (l = j; l < j + 9; ++l)
				{
					//Get coords of sample point on the rotated axis
					sample_x = (int)(x + (-l*scale*si + k*scale*co) + 0.5);
					sample_y = (int)(y + ( l*scale*co + k*scale*si) + 0.5);

					//Get the GAUSSIAN weighted x and y responses
					gauss_s1 = IGAUSSIAN(xs-sample_x, ys-sample_y, scale25);

					sample_x += iborder - 1;
					sample_y += iborder - 1;

					//rr1 = sample_y - s22;
					//cc1 = sample_x;
					//rr2 = rr1 + s2;
					//cc2 = cc1 + s22;

					//ind11 = rr1 * iwidth;
					//ind12 = rr2 * iwidth;

					//dxx1 = integralData[(ind11 + cc1)] - integralData[(ind11 + cc2)] - integralData[(ind12 + cc1)] + integralData[(ind12 + cc2)];
					//dxx1 = *(integralData+(sample_y - s22)*iwidth+sample_x) - *(integralData+(sample_y - s22)*iwidth+sample_x+s22) - *(integralData+(sample_y - s22+s2)*iwidth+sample_x) + *(integralData+(sample_y - s22+s2)*iwidth+sample_x+s22);

					//cc1 = sample_x - s22;
					//cc2 = cc1 + s22;

					//dxx2 = integralData[(ind11 + cc1)] - integralData[(ind11 + cc2)] - integralData[(ind12 + cc1)] + integralData[(ind12 + cc2)];
					//dxx2 = *(integralData+(sample_y - s22)*iwidth+sample_x-s22) - *(integralData+(sample_y - s22)*iwidth+sample_x) - *(integralData+(sample_y - s22+s2)*iwidth+sample_x-s22) + *(integralData+(sample_y - s22+s2)*iwidth+sample_x);

					rx = FMAX(0.0, (*(integralData+(ind11=(sample_y - s22)*iwidth)+sample_x) - *(integralData+ind11+(cc2=sample_x+s22)) - *(integralData+(ind12=(sample_y - s22+s2)*iwidth)+sample_x) + *(integralData+ind12+cc2)))
					- 1*FMAX(0.0, (*(integralData+ind11+(cc1=sample_x-s22)) - *(integralData+ind11+sample_x) - *(integralData+ind12+cc1) + *(integralData+ind12+sample_x)));

					// Y BoxIntegral(integral, row, column-s2, s2, s) - BoxIntegral(integral, row-s2, column-s2, s2, s);

					//rr1 = sample_y;
					//cc1 = sample_x - s22;
					//rr2 = rr1 + s22;
					//cc2 = cc1 + s2;

					//ind11 = rr1 * iwidth;
					//ind12 = rr2 * iwidth;
					//dxx1 = integralData[(ind11 + cc1)] - integralData[(ind11 + cc2)] - integralData[(ind12 + cc1)] + integralData[(ind12 + cc2)];
					//dxx1 = *(integralData+(sample_y)*iwidth+sample_x-s22) - *(integralData+(sample_y)*iwidth+sample_x-s22+s2) - *(integralData+(sample_y + s22)*iwidth+sample_x-s22) + *(integralData+(sample_y + s22)*iwidth+sample_x-s22+s2);

					//rr1 = sample_y - s22;
					//rr2 = rr1 + s22;

					//ind11 = rr1 * iwidth;
					//ind12 = rr2 * iwidth;
					//dxx2 = integralData[(ind11 + cc1)] - integralData[(ind11 + cc2)] - integralData[(ind12 + cc1)] + integralData[(ind12 + cc2)];
					//dxx2 = *(integralData+(sample_y - s22)*iwidth+sample_x-s22) - *(integralData+(sample_y - s22)*iwidth+sample_x-s22+s2) - *(integralData+(sample_y)*iwidth+sample_x-s22) + *(integralData+(sample_y)*iwidth+sample_x-s22+s2);

					ry = FMAX(0.0, (*(integralData+(ind11=(sample_y)*iwidth)+(cc1=sample_x-s22)) - *(integralData+ind11+(cc2=cc1+s2)) - *(integralData+(ind12=(sample_y + s22)*iwidth)+cc1) + *(integralData+ind12+cc2)))
					- 1*FMAX(0.0, (*(integralData+(ind11=(sample_y - s22)*iwidth)+(cc1=sample_x-s22)) - *(integralData+ind11+(cc2=cc1+s2)) - *(integralData+(ind12=(sample_y)*iwidth)+cc1) + *(integralData+ind12+cc2)));


					//Get the IGAUSSIAN weighted x and y responses on rotated axis
					rrx = -rx*si + ry*co;
					rry = rx*co + ry*si;

					rrx = gauss_s1*rrx;
					rry = gauss_s1*rry;

					dx += rrx;
					dy += rry;
					if(rrx < 0) rrx = -rrx;
					if(rry < 0) rry = -rry;
					mdx += (rrx);
					mdy += (rry);
				}
			}

			gauss_s2 = FGAUSSIAN(cx-2.0, cy-2.0, 1.5);

			*(data_ptr++) = dx*gauss_s2;
			*(data_ptr++) = dy*gauss_s2;
			*(data_ptr++) = mdx*gauss_s2;
			*(data_ptr++) = mdy*gauss_s2;

			len += (dx*dx + dy*dy + mdx*mdx + mdy*mdy) * gauss_s2*gauss_s2;

		}
	}

	//Convert to Unit Vector
	len = 1.0 / sqrt(len);
	for(data_ptr = start; data_ptr < end;)
	{
		*(data_ptr++) *= len;
	}
}

static void writePointsResult(const int useOrientation, const int count, register double *outData)
{
	int i, x, y;
	double scale, orientation;

	if(useOrientation == 1)
	{
		for (i = 0; i < count; ++i)
		{
			x = (int)(*(outData++) + 0.5);
			y = (int)(*(outData++) + 0.5);
			scale = *(outData++);
			*(outData++) = (orientation = getPointOrientation(x-1, y-1, scale, integral));
			outData++;

			getDescriptor(x, y, scale, cos(orientation), sin(orientation), integral, outData, outData+64);
			outData += 64;
		}
	} else {
		for (i = 0; i < count; ++i)
		{
			getDescriptor((int)(*(outData)+0.5), (int)(*(outData+1)+0.5), *(outData+2), 1.0, 0.0, integral, outData+5, outData+69);
			outData += 69;
		}
	}
}

static int locateObject(const int minPointsForHomography)
{
	if(matchedPointsCount < minPointsForHomography) return 0;
	
	if(matchedPointsCount == 4)
	{
		const int np2 = matchedPointsCount * 2;

		int i;
		
		double corners1[np2];
		double corners2[np2];
		double image1_coord[np2];
		
		register double *cnp1, *cnp2, *mp;
		
		cnp1 = corners1;
		cnp2 = corners2;
		mp = matchedPointsData;
		
		for(i = 0; i < matchedPointsCount; ++i)
		{
			mp += 2;
			*(cnp1++) = *(mp++);
			*(cnp1++) = *(mp++);
			*(cnp2++) = *(mp++);
			*(cnp2++) = *(mp++);
		}
		
		if(findHomography(matchedPointsCount, corners1, corners2, homography)){
			return 0;
		}
		projectPoints(homography, corners2, &*image1_coord, matchedPointsCount);
		
		int num_inliers = 0;
		mp = image1_coord;
		cnp1 = corners1;
		for( i = 0; i < matchedPointsCount; ++i )
		{
			double dx = *(mp++) - *(cnp1++);
			double dy = *(mp++) - *(cnp1++);
			double distance = sqrt(dx*dx + dy*dy);
			
			if( distance < INLIER_THRESHOLD )
			{
				num_inliers++;
			}
		}
		
		if(num_inliers < 4) return 0;
		
	} else if(matchedPointsCount > 4)
	{
		double corners1[matchedPointsCount*2];
		double corners2[matchedPointsCount*2];		
		double best_inlier_set1[matchedPointsCount*2];
		double best_inlier_set2[matchedPointsCount*2];
		
		int number_of_inliers, i;
		
		register double *cnp1, *cnp2, *mp;
		
		cnp1 = corners1;
		cnp2 = corners2;
		mp = matchedPointsData;
		
		for(i = 0; i < matchedPointsCount; ++i)
		{
			mp += 2;
			*(cnp1++) = *(mp++);
			*(cnp1++) = *(mp++);
			*(cnp2++) = *(mp++);
			*(cnp2++) = *(mp++);
		}
		
		//ransac(matchedPointsData, matchedPointsCount, &*best_inlier_set1, &*best_inlier_set2, &number_of_inliers, homography);
		ransac(corners1, corners2, matchedPointsCount, &*best_inlier_set1, &*best_inlier_set2, &number_of_inliers, homography);
		
		if(number_of_inliers < 4) return 0;
		
		cnp1 = best_inlier_set1;
		cnp2 = best_inlier_set2;
		mp = matchedPointsData;
		
		for( i = 0; i < number_of_inliers; ++i )
		{
			mp += 2;
			*(mp++) = *(cnp1++);
			*(mp++) = *(cnp1++);
			*(mp++) = *(cnp2++);
			*(mp++) = *(cnp2++);
		}
		
		matchedPointsCount = number_of_inliers;
		
		refineHomography(homography, best_inlier_set1, best_inlier_set2, number_of_inliers);
		
	} else 
	{
		return 0;
	}
	return 1;
}

static void findMatches(double *set1, double *set2, const int num1, const int num2)
{
	double dist, diff, d1, d2, lap;
	int ind1 = 5, ind2, match_idx;
	int i, j, k;
	register double *mpr, *desc1, *desc2;

	mpr = matchedPointsData;
	matchedPointsCount = 0;

	for(i = 0; i < num1; ++i)
	{
		d1 = d2 = 100000.0;
		ind2 = 5;
		lap = set1[ind1 - 1];
		desc2 = set2+4;

		for(j = 0; j < num2; ++j)
		{
			if(lap != *(desc2++)) // check laplacian
			{
				ind2 += 69;
				desc2 += 68;
				continue;
			}
			
			dist = 0;
			desc1 = set1+ind1;
			
			for( k = 0; k < 64; ++k )
			{
				diff = *(desc1++) - *(desc2++);
				dist += diff * diff;
			}

			dist = sqrt(dist);

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

		// If match has a d1:d2 ratio < 0.65 ipoints are a match
		if(d1/d2 < 0.65)
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

static void clearDataHolders()
{
	if(currentPointsData) free( currentPointsData );
	if(prevFramePointsData) free( prevFramePointsData );
	if(currentPointsData) free( referencePointsData );
	if(referencePointsData) free( matchedPointsData );
	if(homography) free( homography );
	if(integral) free( integral );
	if(determinant) free( determinant );
}

static AS3_Val setupSURF(void* self, AS3_Val args)
{
	// clear all data
	clearDataHolders();
	
	AS3_ArrayValue(args, "IntType, IntType, IntType, IntType, IntType", &width, &height, &octaves, &intervals, &sample_step );

	area = width * height;
	iwidth = width + iborder*2;
	area2 = iwidth * (height + iborder*2);
	
	roi_x = roi_y = 0;
	roi_width = width;
	roi_height = height;

	currentPointsData =		(double*)malloc( (POINTS_POOL*POINT_DATA_LENGTH)* sizeof(double) );
	referencePointsData =	(double*)malloc( (POINTS_POOL*POINT_DATA_LENGTH)* sizeof(double) );
	prevFramePointsData =	(double*)malloc( (POINTS_POOL*POINT_DATA_LENGTH)* sizeof(double) );
	matchedPointsData =		(double*)malloc( (POINTS_POOL*6)* sizeof(double) );
	
	integral =		(double*)malloc( area2* sizeof(double) );
	determinant =	(double*)malloc( octaves*intervals*area* sizeof(double) );
	
	homography = (double*)malloc(9* sizeof(double));
	
	memset(integral, 0.0, area2* sizeof(double));
	memset(determinant, 0.0, octaves*intervals*area* sizeof(double));
	memset(homography, 0.0, 9* sizeof(double));

	return AS3_Ptr(integral);
}

static AS3_Val resizeDataHolders(void* self, AS3_Val args)
{
	AS3_ArrayValue(args, "IntType, IntType, IntType, IntType, IntType", &width, &height, &octaves, &intervals, &sample_step );

	area = width * height;
	iwidth = width + iborder*2;
	area2 = iwidth * (height + iborder*2);
	
	roi_x = roi_y = 0;
	roi_width = width;
	roi_height = height;

	free(integral);
	free(determinant);

	integral =		(double*)malloc( area2* sizeof(double) );
	determinant =	(double*)malloc( octaves*intervals*area* sizeof(double) );
	
	memset(integral, 0.0, area2* sizeof(double));
	memset(determinant, 0.0, octaves*intervals*area* sizeof(double));

	return AS3_Ptr(integral);
}

static AS3_Val getDataPointers(void* self, AS3_Val args)
{
	AS3_Val pointers = AS3_Array("AS3ValType", NULL);
	
	AS3_Set(pointers, AS3_Int(0), AS3_Ptr(integral));
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
	AS3_Set(pointers, AS3_Int(15), AS3_Ptr(determinant));
	return pointers;
}


static AS3_Val setThreshold(void* self, AS3_Val args)
{
	AS3_ArrayValue(args, "DoubleType", &threshold );
	return 0;
}
static AS3_Val setMaxPoints(void* self, AS3_Val args)
{
	AS3_ArrayValue(args, "IntType", &max_points );
	return 0;
}

static AS3_Val updateReferencePointsData(void* self, AS3_Val args)
{
	int useOrientation;

	AS3_ArrayValue(args, "IntType", &useOrientation);

	currentPointsCount = 0;

	buildDeterminant(integral, determinant);
	
	getInterestPoints(determinant, referencePointsData);

	referencePointsCount = currentPointsCount;

	writePointsResult(useOrientation, referencePointsCount, referencePointsData);

	return AS3_Ptr(referencePointsData);
}

static AS3_Val runSURFTasks(void* self, AS3_Val args)
{
	int useOrientation;
	int options;
	int minPointsForHomography;
	AS3_ArrayValue(args, "IntType, IntType, IntType", &useOrientation, &options, &minPointsForHomography);

	if(options == 4){
		prevFramePointsCount = currentPointsCount;
		memcpy(prevFramePointsData, currentPointsData, (currentPointsCount*POINT_DATA_LENGTH) * sizeof(double));
	}

	currentPointsCount = 0;

	buildDeterminant(integral, determinant);
	getInterestPoints(determinant, currentPointsData);

	writePointsResult(useOrientation, currentPointsCount, currentPointsData);

	if(options == 2) {
		findMatches(currentPointsData, referencePointsData, currentPointsCount, referencePointsCount);
	} else if(options == 3) {
		findMatches(currentPointsData, referencePointsData, currentPointsCount, referencePointsCount);
		homographyIsGood = locateObject(minPointsForHomography);
	} else if(options == 4) {
		findMatches(currentPointsData, prevFramePointsData, currentPointsCount, prevFramePointsCount);
	}

	return 0;
}

static AS3_Val findReferenceMatches(void* self, AS3_Val args)
{
	AS3_ArrayValue(args, "IntType, IntType", &referencePointsCount);
	
	findMatches(currentPointsData, referencePointsData, currentPointsCount, referencePointsCount);
	
	return 0;
}

static AS3_Val disposeSURF(void* self, AS3_Val args)
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