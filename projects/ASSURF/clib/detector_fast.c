
int fastRotWin[16];
int sampleWin[64];
double sampleWeight[64];
int shiTomasiWin[196];
//int curRotWidth = 0;

void calcShiTomasiWin(const int stride, const int nHalfBoxSize);
double FindShiTomasiScoreAtPoint(const unsigned char *image, const int stride, const xy *irCenter);
int detectPointsFast(const unsigned char *image, const int width, const int height, IPoint *pointsData,
						const int corn_thresh, const double tomasi_thresh, const int maxPoints, const int imgBorder, int checkSimilar, int *duplicates);
void fastRotationEstimation(const unsigned char *image, IPoint *ip);
void getPointSample(const unsigned char *image, const int x, const int y, const int stride, double *sample);
void getPointSampleRotated(const unsigned char *image, const int stride, IPoint *ipt);
void getPointSampleNCC(const unsigned char *image, const int x, const int y, const int stride, double *sample);
void getPointSampleNCCRotated(const unsigned char *image, const int x, const int y, const double orientation, const int stride, double *sample);

int detectPointsFast(const unsigned char *image, const int width, const int height, IPoint *pointsData,
						const int corn_thresh, const double tomasi_thresh, const int maxPoints, const int imgBorder, int checkSimilar, int *duplicates)
{
	int cNum, i, j, k, m, cnt = 0;
	
	xy *corners;
	corners = fast9_detect_nonmax(image, width, height, width, corn_thresh, &cNum);
	//corners = fast10_detect_nonmax(image, width, height, width, corn_thresh, &cNum);
	
	//cNum = cNum < max_screen_points ? cNum : max_screen_points;
	
	for(i=0; i < cNum; i++)
	{
		const xy *corn = &corners[i];
		
		if( useMask == 1 && img_mask[corn->y * width + corn->x] == 0 ) continue;
		
		if(corn->x > imgBorder && corn->y > imgBorder && corn->x < width - imgBorder && corn->y < height - imgBorder)
		{
			const double score = FindShiTomasiScoreAtPoint(image, width, corn);
			
			if(score > tomasi_thresh)
			{
				IPoint *ipt = &pointsData[cnt++];
				
				ipt->x = corn->x;
				ipt->y = corn->y;
				ipt->dx = ipt->dy = 0;
				ipt->scale = 2;
				ipt->pos = (corn->y * width + corn->x);
				ipt->lapsign = 0;
				ipt->score = score;
				ipt->sampled = 0;
			}
		}
	}
	
	free(corners);
	
	//
	if(supressNeighbors)
	{
		qsort(pointsData, cnt, sizeof(IPoint), compareIPoint);
		
		int neighb_map[cnt];
		
		for(i = 0; i < cnt; i++) neighb_map[i] = -1;
		
		for(i = 0; i < cnt; i++)
		{
			if(neighb_map[i] > -1) continue;
			
			const IPoint *p1 = &*(pointsData+i);
			for(j = i+1; j < cnt; j++)
			{
				if(neighb_map[j] > -1) continue;
				
				const IPoint *p2 = &*(pointsData+j);
				const int dx = p1->x - p2->x;
				const int dy = p1->y - p2->y;
				if( fast_sqrt(dx*dx+dy*dy) < supressDist )
				{
					neighb_map[j] = i;
				}
			}
		}
		
		for(i = 0, j = 0; i < cnt; i++)
		{
			if(neighb_map[i] == -1){
				memcpy( pointsData+j, pointsData+i, sizeof(IPoint) );
				j++;
			}
		}
		cnt = j;
	}
	//
	
	//const double threshSim = (double)64.0 * (double)0.08;
	const int nMaxSSDPerPixel = 450;
	const int mnMaxSSD = 8 * 8 * nMaxSSDPerPixel;
	double dist_map[prevFramePointsCount];
	int sim_map[prevFramePointsCount];
	if(checkSimilar == 1)
	{
		int sampled, found;
		const int distThresh = 15 * 15;
		int skip_map[cnt];
		double dist_b;
		IPoint *pt_prev;
		
		for(i=0; i<prevFramePointsCount;i++)
		{
			dist_map[i] = mnMaxSSD + 1;
			sim_map[i] = -1;
			skip_map[i] = 0;
		}
		
		for(i = 0; i < cnt; i++)
		{
			IPoint *pt_new = &pointsData[i];
			pt_new->sample = samplesCurr + (i * 64);
			
			fastRotationEstimation(image, pt_new);
			
			found = -1;
			sampled = 0;
			dist_b = mnMaxSSD + 1;
			for(j = 0; j < prevFramePointsCount; j++)
			{
				pt_prev = &screenPointsPrev[j];
				
				if((iSquare(pt_prev->x+pt_prev->dx - pt_new->x) + iSquare(pt_prev->y+pt_prev->dy - pt_new->y)) < distThresh)
				{
					if(sampled == 0)
					{
						//getPointSampleNCC(img_blur, pt_new->x, pt_new->y, width, &*pt_new->sample);
						//getPointSample(img_blur, pt_new->x, pt_new->y, width, &*pt_new->sample);
						getPointSampleRotated(img_blur, width, pt_new);
						//getPointSampleNCCRotated(img_blur, pt_new->x, pt_new->y, pt_new->orientation, width, pt_new->sample);
						//getPointSampleNCCRotated2(img_blur, width, pt_new);
						pt_new->sampled = sampled = 1;
					}
					if(pt_prev->sampled == 0)
					{
						//getPointSampleNCC(img_prev, pt_prev->x, pt_prev->y, width, &*pt_prev->sample);
						//getPointSample(img_prev, pt_prev->x, pt_prev->y, width, &*pt_prev->sample);
						getPointSampleRotated(img_prev, width, pt_prev);
						//getPointSampleNCCRotated(img_prev, pt_prev->x, pt_prev->y, pt_prev->orientation, width, pt_prev->sample);
						//getPointSampleNCCRotated2(img_prev, width, pt_prev);
						pt_prev->sampled = 1;
					}
					
					double dist = 0.0;
					const double *desc1 = pt_prev->sample;
					const double *desc2 = pt_new->sample;
					k = 64;
					while( --k > -1 )
					{
						//dist += dSquare((*(desc1++)) - (*(desc2++)));
						dist += (*(desc1++)) * (*(desc2++));
					}
					
					const double SA = pt_prev->mean;
					const double SB = pt_new->mean;

					dist = ((2.0*SA*SB - SA*SA - SB*SB)/64.0 + pt_new->stdev + pt_prev->stdev - 2.0*dist);

					if(dist_b > dist && dist_map[j] > dist)
					{
						found = j;
						dist_map[j] = dist_b = dist;
					}
				}
			}
			
			if(found > -1) 
			{
				pt_prev = &screenPointsPrev[found];
				pt_prev->dx = (pt_new->x - pt_prev->x) >> 1;
				pt_prev->dy = (pt_new->y - pt_prev->y) >> 1;
				pt_prev->x = pt_new->x;
				pt_prev->y = pt_new->y;
				pt_prev->pos = pt_new->pos;
				pt_prev->lapsign = 1;
				pt_prev->orientation = pt_new->orientation;
				pt_prev->sample = pt_new->sample;
				
				if(sim_map[found] > -1) skip_map[ sim_map[found] ] = 0;
				skip_map[i] = 1;
				sim_map[found] = i;
			}
		}
		j = 0;
		for(i = 0; i < cnt; i++)
		{
			if(skip_map[i] == 0)
			{
				memcpy(pointsData + j, pointsData + i, sizeof(IPoint));
				j++;
			}
		}
		cnt = j;
	}
	
	if(cnt > maxPoints)
	{
		qsort(pointsData, cnt, sizeof(IPoint), compareIPoint);
		cnt = maxPoints;
	}
	
	if(checkSimilar == 0)
	{
		for(i = 0; i < cnt; i++)
		{		
			fastRotationEstimation(image, &pointsData[i]);
		}
	}
	
	if(checkSimilar == 1 && prevFramePointsCount > 0)
	{
		i = cnt;
		k = 0;
		
		for(j = 0; j < prevFramePointsCount; j++)
		{
			if(sim_map[j] > -1)
			{
				//pointsData[i] = screenPointsPrev[j];
				//frameMatches[k] = frameMatches[j];
				memcpy(pointsData + i, screenPointsPrev + j, sizeof(IPoint));
				memcpy(frameMatches + k, frameMatches + j, sizeof(IPointMatch));
				
				frameMatches[k].first = &pointsData[i];
				
				k++;
				i++;
			}
		}
		*duplicates = k;
	}
	
	return cnt;
}

void fastRotationEstimation(const unsigned char *image, IPoint *ip)
{
	int px = 16;
	double dx = 0.0;
	double dy = 0.0;
	
	const int pos = ip->pos;
	const double centrepx = (double)image[pos];
	
	const int *win = fastRotWin;
	const double *ring_x = fast_ring_x;
	const double *ring_y = fast_ring_y;

	while( --px > -1 )
	{
		const double diff = (double)image[ *(win++) + pos ] - centrepx;
		dx += diff * (*(ring_x++));
		dy += diff * (*(ring_y++));
	}

	ip->orientation = fast_atan2(dy, dx);//ANGLE(dx, dy);
}

double FindShiTomasiScoreAtPoint(const unsigned char *image, const int stride, const xy *irCenter)
{
	double dXX = 0.0;
	double dYY = 0.0;
	double dXY = 0.0;
	
	const int cpos = irCenter->y * stride + irCenter->x;
	const int *win = shiTomasiWin;
	int len = 196 / 4;
	
	while(-- len > -1)
	{
		const double __dx0 = (double)image[ *(win++) + cpos ];
		const double __dx1 = (double)image[ *(win++) + cpos ];
		const double __dy0 = (double)image[ *(win++) + cpos ];
		const double __dy1 = (double)image[ *(win++) + cpos ];
		
		
		const double dx = __dx0 - __dx1;
		const double dy = __dy0 - __dy1;
		
		dXX += dx*dx;
		dYY += dy*dy;
		dXY += dx*dy;
	}
	
	const double nPixels = 0.002551020408163265;//1.0 / (2.0 * (double)((nx+1) * (ny+1)));
	dXX = dXX * nPixels;
	dYY = dYY * nPixels;
	dXY = dXY * nPixels;

	// Find and return smaller eigenvalue:
	return (double)0.5 * (dXX + dYY - fast_sqrt( (dXX + dYY) * (dXX + dYY) - (double)4.0 * (dXX * dYY - dXY * dXY) ));
}

void calcShiTomasiWin(const int stride, const int nHalfBoxSize)
{
	int stx = 0 - nHalfBoxSize;
	int sty = 0 - nHalfBoxSize;
	int enx = 0 + nHalfBoxSize;
	int eny = 0 + nHalfBoxSize;
	int y, x, j = 0;
	
	for(y = sty; y <= eny; y++)
	{
		for(x = stx; x <= enx; x++)
		{
			
			shiTomasiWin[j++] = y*stride + x + 1;
			shiTomasiWin[j++] = y*stride + x - 1;
			shiTomasiWin[j++] = y*stride + x + stride;
			shiTomasiWin[j++] = y*stride + x - stride;
		}
	}
}
void calcSampleWin(const int stride)
{
	int j = 0, k, m;
	
	const int SAMPLE_WIN = 8;
	const int halfWin = SAMPLE_WIN / 2;
	const int step = 1;
	
	for(k = 0; k < SAMPLE_WIN; k++)
	{
		for(m = 0; m < SAMPLE_WIN; m++, j++)
		{
			const int ox = (m - halfWin) * step;
			const int oy = (k - halfWin) * step;
			
			sampleWin[j] = oy * stride + ox;
			
			double dc2 = (double)4.0*(double)(ox*ox+oy*oy)/(double)(SAMPLE_WIN*SAMPLE_WIN);
			
			sampleWeight[j] = exp(-dc2*dc2*1.8);
		}
	}
	
	for (k = 0; k < 16; k++)
	{
		fastRotWin[k] = indY[k] * stride + indX[k];
	}
}

void getPointSampleNCC(const unsigned char *image, const int x, const int y, const int stride, double *sample)
{
	double fmean = 0.0;
	double stddev = 0.0;
	const int cpos = y * stride + x;
	const int *win = sampleWin;
	register double *ptr = sample;
	const double *send = sample+64;
	for(; ptr < send;)
	{							
		const double val = (double)image[ cpos + *(win++) ];
		fmean += val;
		stddev += val * val;
		*(ptr++) = val;
	}
	fmean /= (double)64.0;
	stddev = (double)1.0 / ( fast_sqrt((stddev - (fmean * fmean) ) / (double)63.0) + (double)1.0E-12 );
	for(ptr = sample; ptr < send; ptr++)
	{
		*(ptr) = (*(ptr) - fmean) * stddev;
	}
}

void getPointSampleNCCRotated(const unsigned char *image, const int x, const int y, const double orientation, const int stride, double *sample)
{
	double fmean = 0.0;
	double stddev = 0.0;
	
	register double *ptr = sample;
	const double *send = sample+64;
	const double *weights = sampleWeight;
	
	int k, m;
	
	const int SAMPLE_WIN = 8;
	const int halfWin = SAMPLE_WIN / 2;
	const int step = 1;
	
	double si, co;
	sin_cos(orientation, &si, &co);
	
	for(k = 0; k < SAMPLE_WIN; k++)
	{
		for(m = 0; m < SAMPLE_WIN; m++)
		{
			const int ox = (m*step - halfWin);
			const int oy = (k*step - halfWin);
			
			const int rotX = (co * ox - si * oy) + x;
			const int rotY = (si * ox + co * oy) + y;
			
			const double val = (double)image[ rotY * stride + rotX ];
			
			fmean += val;
			stddev += val * val;
			*(ptr++) = val;
		}
	}
	const double inv = (double)1.0 / (double)64.0;
	fmean *= inv;
	//stddev = (double)1.0 / ( fast_sqrt(stddev * inv - (fmean * fmean)) + (double)1.0E-12 );
	stddev = fast_sqrt(stddev * inv - (fmean * fmean)) + (double)1.0E-12;
	double s = (double)0.5 / stddev;
	for(ptr = sample; ptr < send; ptr++, weights++)
	{
		//*(ptr) = (*(ptr) - fmean) * stddev;
		*(ptr) = (*(ptr) - fmean) * (*(weights)) * s + (double)0.5;
	}
}

void getPointSample(const unsigned char *image, const int x, const int y, const int stride, register double *sample)
{
	const int cpos = y * stride + x;
	const int *win = sampleWin;
	const double inv255 = 0.003921568627451;//(double)1.0 / (double)255.0;
	int i = 64;
	while( --i > -1 )
	{
		*(sample++) = (double)image[ cpos + *(win++) ] * inv255;
	}
}

void getPointSampleRotated(const unsigned char *image, const int stride, IPoint *ipt)
{
	//const double inv255 = 0.003921568627451;//(double)1.0 / (double)255.0;
	
	const int SAMPLE_WIN = 8;
	const int halfWin = SAMPLE_WIN / 2;
	const int step = 1;
	int m, k;
	
	double si, co;
	sin_cos(ipt->orientation, &si, &co);
	
	double ss = 0;
	double sq = 0;
	
	double *sample = ipt->sample;
	
	for(k = 0; k < SAMPLE_WIN; k++)
	{
		for(m = 0; m < SAMPLE_WIN; m++)
		{
			const int ox = (m*step - halfWin);
			const int oy = (k*step - halfWin);
			
			/*const int rotX = (co * ox - si * oy) + x;
			const int rotY = (si * ox + co * oy) + y;			
			const double val = (double)image[ rotY * stride + rotX ] * inv255;*/
			
			const double rotX = (co * (double)ox - si * (double)oy) + (double)ipt->x;
			const double rotY = (si * (double)ox + co * (double)oy) + (double)ipt->y;
			const double val = bilinear_interpolation(image, stride, rotX, rotY);// * inv255;
			
			ss += val;
			sq += val * val;
			
			*(sample++) = val;
		}
	}
	ipt->mean = ss;
	ipt->stdev = sq;	
}