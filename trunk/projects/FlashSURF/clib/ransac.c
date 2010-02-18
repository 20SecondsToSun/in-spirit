#include <math.h>
#include <time.h>
#include <stdio.h>
#include <stdlib.h>

#include "svdcmp.c"
#include "lmfit/lmmin.c"

static const double INLIER_THRESHOLD = 1.5;
static const double PROBABILITY_REQUIRED = 0.99;

int PseudoInverse(register double *inv, register double *matx, const int M, const int N);
void MultiplyMat(register double *m1, register double *m2, register double *res, const int M1, const int N1, const int M2, const int N2);
int findHomography(const int np, register double *obj, register double *img, register double *mat);
void projectPoints(register double *mat, register double *points, register double *proj, const int n);
void lm_evaluate(double *par, int m_dat, double *fvec, void *data, int *info);
void lm_print(int n_par, double *par, int m_dat, double *fvec, void *data, int iflag, int iter, int nfev);

void lm_minimize(int m_dat, int n_par, double *par,
		 void (*evaluate) (double *par, int m_dat, double *fvec,
                                   void *data, int *info),
                 void (*printout) (int n_par, double *par, int m_dat,
                                   double *fvec, void *data, int iflag,
                                   int iter, int nfev),
		 void *data, lm_control_type * control);

typedef struct
{
	int number_of_inliers;
	double inlier_set1[2000]; // I think this enough for the inliers
	double inlier_set2[2000];
} optimization_data;

//void ransac(register double *matched_points, int npoints, register double *best_inlier_set1, 
void ransac(register double *corners1, register double *corners2, int npoints, register double *best_inlier_set1, 
			register double *best_inlier_set2, int *number_of_inliers, register double *bestH)
{
	int N, sample_count;
	int i, j;

	srand( (unsigned)time(NULL) ) ;

	N = 10000;
	sample_count = 0;
	int max_inliers = 0;
	double best_variance = 0.0;
	double H[9];
	
	double inlier_set1[npoints*2];
	double inlier_set2[npoints*2];
	double points1[8];
	double points2[8];
	//double corners1[npoints*2];
	//double corners2[npoints*2];
	double image1_coord[npoints*2];
	
	/*register double *cnp1 = corners1, *cnp2 = corners2;
	
	for(i = 0; i < npoints; ++i)
	{
		*(cnp1++) = *(matched_points++);
		*(cnp1++) = *(matched_points++);
		*(cnp2++) = *(matched_points++);
		*(cnp2++) = *(matched_points++);
	}*/
	
	while(N > sample_count)
	{
		i = 0;
		while( i < 4 )
		{
			int index = rand() % npoints;
			int duplicate = 0;
			for( j = 0; j < i; ++j)
			{
				if(points1[j*2] == corners1[index*2] && points1[j*2+1] == corners1[index*2+1])
				{
					duplicate = 1;
					break;
				}
			}
			if(duplicate) continue;
			
			// add to list
			points1[i*2] = corners1[index*2];
			points1[i*2+1] = corners1[index*2+1];
			points2[i*2] = corners2[index*2];
			points2[i*2+1] = corners2[index*2+1];
			i++;
		}
		
		// do homography
		if(findHomography(4, points1, points2, &*H))
		{
			sample_count++;
			continue;
		}
		
		int num_inliers = 0;
		double sum_distance = 0.0;
		double sum_distance_squared = 0.0;
		
		projectPoints(H, corners2, &*image1_coord, npoints);
		
		for( i = 0; i < npoints; ++i )
		{
			double dx = image1_coord[i*2] - corners1[i*2];
			double dy = image1_coord[i*2 + 1] - corners1[i*2 + 1];
			double distance = sqrt(dx*dx + dy*dy);
			
			if( distance < INLIER_THRESHOLD )
			{
				inlier_set1[num_inliers*2] =		corners1[i*2];
				inlier_set1[num_inliers*2 + 1] =	corners1[i*2 + 1];
				inlier_set2[num_inliers*2] =		corners2[i*2];
				inlier_set2[num_inliers*2 + 1] =	corners2[i*2 + 1];
				num_inliers++;
				sum_distance += distance;
				sum_distance_squared += distance*distance;
			}
		}
		
		if(num_inliers >= max_inliers)
		{
			double mean_distance = sum_distance / ((double)num_inliers);
			double variance = sum_distance_squared / ((double)num_inliers - 1.0) - mean_distance * mean_distance * ((double)num_inliers) / ((double)num_inliers - 1.0);
			
			if ((num_inliers > max_inliers) || (num_inliers==max_inliers && variance < best_variance))
			{
				// this is the best H so store its information
				best_variance = variance;
				max_inliers = num_inliers;
				
				memcpy(bestH, H, 9 * sizeof(double));
				memcpy(best_inlier_set1, inlier_set1, num_inliers*2 * sizeof(double));
				memcpy(best_inlier_set2, inlier_set2, num_inliers*2 * sizeof(double));
				/*for ( i = 0; i < num_inliers; ++i )
				{
					best_inlier_set1[i*2 + 0] = inlier_set1[i*2 + 0];
					best_inlier_set1[i*2 + 1] = inlier_set1[i*2 + 1];
					best_inlier_set2[i*2 + 0] = inlier_set2[i*2 + 0];
					best_inlier_set2[i*2 + 1] = inlier_set2[i*2 + 1];
				}*/
			}
		}
		
		// update N
		sample_count++;
		if(num_inliers > 0)
		{
			double inv_epsilon = 1.0 - (1.0 - ((double)num_inliers) / ((double)npoints));
			double inv_epsilon2 = inv_epsilon * inv_epsilon;
			double inv_epsilon4 = inv_epsilon2 * inv_epsilon2;
			double log_den = log(1.0 - inv_epsilon4);
			int temp = (int)(log(1.0 - PROBABILITY_REQUIRED) / log_den);
			if(temp > 0 && temp < N){
				N = temp;
			}
			//N = (int)(log(1.0 - PROBABILITY_REQUIRED)/log(1.0 - (inv_epsilon * inv_epsilon * inv_epsilon * inv_epsilon ) ) );
		}
	}
	
	*number_of_inliers = max_inliers;
}

int findHomography(const int np, register double *pts1, register double *pts2, register double *mat)
{
	const int np2 = np * 2;

	double a[np2*8], b[np2*1], temp[np2*8];

	int i, j;
	double sx, sy, dx, dy;

	for( i = 0, j = np; i < np; ++i, ++j )
	{
		dx = *(pts1++);
		dy = *(pts1++);
		sx = *(pts2++);
		sy = *(pts2++);
		a[i*8+0] = a[j*8+3] = sx;
		a[i*8+1] = a[j*8+4] = sy;
		a[i*8+2] = a[j*8+5] = 1;
		a[i*8+3] = a[i*8+4] = a[i*8+5] =
		a[j*8+0] = a[j*8+1] = a[j*8+2] = 0;
		a[i*8+6] = -dx*sx;
		a[i*8+7] = -dx*sy;
		a[j*8+6] = -dy*sx;
		a[j*8+7] = -dy*sy;
		b[i]    = dx;
		b[j]    = dy;
	}

	if(PseudoInverse(&*temp, a, np2, 8)){
		return 1;
	}
	MultiplyMat(temp, b, &*mat, 8, np2, np2, 1);
	mat[8] = 1;
	
	return 0;
}

void projectPoints(register double *mat, register double *points, register double *proj, const int n)
{
	int i;
	double x, y, Z;
	for( i = 0; i < n; ++i)
	{
		x = *(points++), y = *(points++);
		Z = 1./(mat[6]*x + mat[7]*y + mat[8]);
		*(proj++) =	(mat[0]*x + mat[1]*y + mat[2])*Z;
		*(proj++) =	(mat[3]*x + mat[4]*y + mat[5])*Z;
	}
}

void refineHomography(register double *ransac_H, register double *inlier_set1, register double *inlier_set2, const int number_of_inliers)
{
	int i;
	optimization_data data;
	data.number_of_inliers = number_of_inliers;
	memcpy(data.inlier_set1, inlier_set1, number_of_inliers*2 * sizeof(double));
	memcpy(data.inlier_set2, inlier_set2, number_of_inliers*2 * sizeof(double));
	
	double inv_H[9];
	double p[9 + number_of_inliers*2];
	//double *p = (double*)malloc( 9 + number_of_inliers*2 * sizeof(double) );
	double output_coord[number_of_inliers*2];
	
	register double *pt = p;
	
	for( i = 0; i < 9; ++i )
	{
		*(pt++) = ransac_H[i];
	}
	
	PseudoInverse(&*inv_H, ransac_H, 3, 3);
	projectPoints(inv_H, inlier_set1, &*output_coord, number_of_inliers);
	
	for( i = 0; i < number_of_inliers; ++i )
	{		
		*(pt++) =	output_coord[i*2];
		*(pt++) =	output_coord[i*2 + 1];
	}
	
	lm_control_type control;
	control.maxcall = 20000;
	control.epsilon = 1.e-14;
	control.ftol = 1.0e-15;
	control.xtol = 1.0e-15;
	control.gtol = 1.0e-15;
	control.stepbound = 10.0;
	
	lm_minimize(number_of_inliers*4, 9 + number_of_inliers*2, &*p, lm_evaluate, lm_print, &data, &control);
	
	memcpy(ransac_H, p, 9 * sizeof(double));
}

void lm_evaluate(register double *par, int m_dat, register double *fvec, void *data, int *info)
{
	int i;
	double H[9];
	optimization_data *opt_data = (optimization_data *)data;
	int number_of_inliers = opt_data->number_of_inliers;
	
	double image1_coord[number_of_inliers*2];
	double image2_coord[number_of_inliers*2];
	
	register double *pt1 = image2_coord;
	register double *pt2;
	
	for( i = 0; i < number_of_inliers + 9; ++i )
	{
		if( i < 9 ) H[i] = par[i];
		if( i < number_of_inliers)
		{
			*(pt1++) =	par[9 + i*2];
			*(pt1++) =	par[9 + i*2 + 1];
		}
	}
	
	projectPoints(H, image2_coord, &*image1_coord, number_of_inliers);
	
	pt1 = opt_data->inlier_set1;
	pt2 = opt_data->inlier_set2;
	
	for( i = 0; i < number_of_inliers; ++i )
	{
		double dx = par[9 + i*2] - *(pt2++);
		double dy = par[9 + i*2 + 1] - *(pt2++);
		*(fvec++) = dx * dx;
		*(fvec++) = dy * dy;
		
		dx = image1_coord[i*2] - *(pt1++);
		dy = image1_coord[i*2 + 1] - *(pt1++);
		
		*(fvec++) = dx * dx;
		*(fvec++) = dy * dy;
	}	
}

void lm_print(int n_par, double *par, int m_dat, double *fvec, void *data, int iflag, int iter, int nfev)
{
}