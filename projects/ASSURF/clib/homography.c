/*
typedef struct {
	int number_of_inliers;
	double inlier_set1[2000]; // I think this enough for the inliers
	double inlier_set2[2000];
}optimization_data;
*/

void ransac(double *corners1, double *corners2, const int npoints, int *best_inlier_ids, int *number_of_inliers, double *bestH);
int findHomography(const int np, register double *obj, register double *img, register double *mat);

void projectPoints(double *mat, register double *points, register double *proj, const int n);
void normalizeData(double *p, double *m, const int num);
int isColinear(double *p, const int num);

//void refineHomography(double *rns_H, double *inlier_set1, double *inlier_set2, int number_of_inliers);
//void lm_evaluate(double *par, int m_dat, double *fvec, void *data, int *info);
//void lm_print(int n_par, double *par, int m_dat, double *fvec, void *data, int iflag, int iter, int nfev);


#include "svdcmp.c"
//#include "lmmin.c"

void ransac(double *corners1, double *corners2, const int npoints, int *best_inlier_ids, int *number_of_inliers, double *bestH)
{
	int N, sample_count;
	int i, j, index;

	srand( 134 ) ;

	N = 10000;
	sample_count = 0;
	int max_inliers = 0;
	double best_variance = 0.0;
	double H[9], invH[9];
	double T1[9], T2[9], invT2[9], tmp[9];
	
	int inlier_ids[npoints];
	int curr_idx[4];
	
	double points1[8];
	double points2[8];
	double image1_coord[npoints<<1];
	double image2_coord[npoints<<1];
	
	const double logProb = log( 1.0 - PROBABILITY_REQUIRED );
	
	int iscolinear;
	while(N > sample_count)
	{
		iscolinear = 1;
		while(iscolinear == 1)
		{
			iscolinear = i = 0;
			while( i < 4 )
			{
				index = (rand() % npoints) << 1;
				iscolinear = 0;
				for( j = 0; j < i; j++)
				{
					if(index == curr_idx[j])
					{
						iscolinear = 1;
						break;
					}
				}
				if(iscolinear == 1) continue;
				curr_idx[i] = index;
			
				// add to list
				points1[i<<1] = corners1[index];
				points1[(i<<1)+1] = corners1[index+1];
				points2[i<<1] = corners2[index];
				points2[(i<<1)+1] = corners2[index+1];
				
				i++;
			}
			if(iscolinear == 0)
			{
				iscolinear = isColinear(points1, i);
			}
		}
		
		normalizeData(&*points1, &*T2, i);
		normalizeData(&*points2, &*T1, i);
		
		if(findHomography(4, points1, points2, &*H))
		{
			sample_count++;
			continue;
		}
		
		invert3x3(T2, &*invT2);
		MultiplyMat(invT2, H, &*tmp, 3, 3, 3, 3);
		MultiplyMat(tmp, T1, &*H, 3, 3, 3, 3);
		
		int num_inliers = 0;
		double sum_distance_squared = 0.0;
		
		invert3x3(H, &*invH);
		
		projectPoints(H, corners2, &*image1_coord, npoints);
		projectPoints(invH, corners1, &*image2_coord, npoints);
		
		for( i = 0; i < npoints; i++ )
		{
			double distance = dSquare(image1_coord[i<<1] - corners1[i<<1]) + dSquare(image1_coord[(i<<1) + 1] - corners1[(i<<1) + 1])
							+ dSquare(image2_coord[i<<1] - corners2[i<<1]) + dSquare(image2_coord[(i<<1) + 1] - corners2[(i<<1) + 1]);
			
			if( distance < INLIER_THRESHOLD_SQ )
			{
				inlier_ids[num_inliers] = i;
				num_inliers++;
				sum_distance_squared += distance;
			}
		}
		
		if(num_inliers >= max_inliers)
		{
			double mean_distance = sqrt(sum_distance_squared) / ((double)num_inliers);
			double variance = sum_distance_squared / ((double)num_inliers - 1.0) - mean_distance * mean_distance * ((double)num_inliers) / ((double)num_inliers - 1.0);
			
			if ((num_inliers > max_inliers) || (num_inliers==max_inliers && variance < best_variance))
			{
				// this is the best H so store its information
				best_variance = variance;
				max_inliers = num_inliers;
				
				memcpy(bestH, H, 9 * sizeof(double));
				memcpy(best_inlier_ids, inlier_ids, num_inliers * sizeof(int));
			}
		}
		
		// update N
		sample_count++;
		if(num_inliers > 0)
		{
			double inv_epsilon = 1.0 - (1.0 - ((double)num_inliers) / ((double)npoints));
			int temp = (int)(logProb / log( 1.0 - (inv_epsilon * inv_epsilon * inv_epsilon * inv_epsilon) ) );
			if(temp > 0 && temp < N){
				N = temp;
			}
		}
	}
	
	*number_of_inliers = max_inliers;
}

int findHomography(const int np, register double *pts1, register double *pts2, register double *mat)
{
	const int np2 = np << 1;

	double a[np2*8], b[np2], temp[np2*8];

	int i, j, ii, jj;
	double sx, sy, dx, dy;

	for( i = 0, j = np; i < np; i++, j++ )
	{
		dx = *(pts1++);
		dy = *(pts1++);
		sx = *(pts2++);
		sy = *(pts2++);
		
		ii = i<<3;
		jj = j<<3;
		
		a[ii] = a[jj+3] = sx;
		a[ii+1] = a[jj+4] = sy;
		a[ii+2] = a[jj+5] = 1;
		a[ii+3] = a[ii+4] = a[ii+5] =
		a[jj] = a[jj+1] = a[jj+2] = 0.0;
		a[ii+6] = -dx*sx;
		a[ii+7] = -dx*sy;
		a[jj+6] = -dy*sx;
		a[jj+7] = -dy*sy;
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

void projectPoints(double *mat, register double *points, register double *proj, const int n)
{
	int i;
	double x, y, Z;
	double m11 = mat[0], m12 = mat[1], m13 = mat[2], m21 = mat[3], m22 = mat[4], m23 = mat[5], m31 = mat[6], m32 = mat[7], m33 = mat[8];
	for( i = 0; i < n; ++i)
	{
		x = *(points++), y = *(points++);
		Z = 1.0 / (m31*x + m32*y + m33);
		*(proj++) =	(m11*x + m12*y + m13) * Z;
		*(proj++) =	(m21*x + m22*y + m23) * Z;
	}
}

void normalizeData(double *p, double *m, const int num)
{
	double scale, tx, ty;
	double meanx = 0.0, meany = 0.0;
	double value = 0.0;
	double invN = 1.0 / (double)num;
	int i;
	
	for(i = 0; i < num; i++)
	{
		meanx += p[i<<1];
		meany += p[(i<<1)+1];
	}
	meanx *= invN;
	meany *= invN;
	
	for(i = 0; i < num; i++)
	{
		value += dSquare(p[i<<1] - meanx) + dSquare(p[(i<<1)+1] - meany);
	}
	
	scale = SQRT2 / (sqrt(value) * invN);
	tx = -scale * meanx;
	ty = -scale * meany;
	
	for(i = 0; i < num; i++)
	{
		p[(i<<1)] = (p[(i<<1)] - meanx) * scale;
		p[(i<<1)+1] = (p[(i<<1)+1] - meany) * scale;
	}
	
	m[1] = m[3] = m[6] = m[7] = 0.0;
	m[0] = scale;
	m[2] = tx;
	m[4] = scale;
	m[5] = ty;
	m[8] = 1.0;
}

int isColinear(double *p, const int num)
{
	int i, j, k;
	double a, b, c=1.0, d, e, f=1.0, cpx, cpy, cpz;

	// check for each 3 points combination 
	for(i = 0; i < num-2; i++)
	{
		a = p[i<<1];
		b = p[(i<<1)+1];
		for(j = i+1; j < num-1; j++)
		{
			d = p[j<<1];
			e = p[(j<<1)+1];
			cpx = b*f - c*e;
			cpy = c*d - a*f;
			cpz = a*e - b*d;
			for(k = j + 1; k < num; k++)
			{
				// check whether pt on the line
				if(fabs(p[k<<1]*cpx + p[(k<<1)+1]*cpy + cpz) < 0.1)
				{
					return 1;
				}
			}
		}
	}
	return 0;
}
/*
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
		*(fvec++) = dSquare(par[9 + i*2] - *(pt2++));;
		*(fvec++) = dSquare(par[9 + i*2 + 1] - *(pt2++));
		
		*(fvec++) = dSquare(image1_coord[i*2] - *(pt1++));
		*(fvec++) = dSquare(image1_coord[i*2 + 1] - *(pt1++));
	}	
}
void lm_print(int n_par, double *par, int m_dat, double *fvec, void *data, int iflag, int iter, int nfev){}
*/