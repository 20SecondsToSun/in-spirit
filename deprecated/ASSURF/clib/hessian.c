#include <math.h>


void buildResponseMap();
void updateResponseMap(register double *img);
int getIpoints(register double *pointsData, const int max_points);


static const int filter_map[5][4] = {{0,1,2,3}, {1,3,4,5}, {3,5,6,7}, {5,7,8,9}, {7,9,10,11}};

typedef struct {
	int width, height, step, filter;
	double *responses;
	unsigned char *laplacian;
}responseLayer;

unsigned char *laplacian;
responseLayer *respMap;
int respMapSize;

inline double getResponseSrc(unsigned int row, unsigned int column, responseLayer *orig, responseLayer *src)
{
	int scale = orig->width / src->width;

    return orig->responses[(scale * row) * orig->width + (scale * column)];
}
inline unsigned char getLaplacianSrc(unsigned int row, unsigned int column, responseLayer *orig, responseLayer *src)
{
	int scale = orig->width / src->width;

    return orig->laplacian[(scale * row) * orig->width + (scale * column)];
}
inline double getResponseOrig(unsigned int row, unsigned int column, responseLayer *orig)
{
    return orig->responses[row * orig->width + column];
}


void buildResponseMap()
{
	// Get image attributes
	int w = width / sample_step;
	int h = height / sample_step;
	int s = sample_step;
	
	int offset = w * h;
	int size = ((w * h) * 4);
	int layers = 4;
	
	if (octaves >= 2) size += ((w>>1) * (h>>1)) * 2, layers += 2;
	if (octaves >= 3) size += ((w>>2) * (h>>2)) * 2, layers += 2;
	if (octaves >= 4) size += ((w>>3) * (h>>3)) * 2, layers += 2;
	if (octaves >= 5) size += ((w>>4) * (h>>4)) * 2, layers += 2;
	
	determinant = (double*)malloc( size * sizeof(double) );
	laplacian = (unsigned char*)malloc( size * sizeof(unsigned char) );
	respMap = (responseLayer*)malloc( layers * sizeof(responseLayer) );
	
	memset(determinant, 0, size * sizeof(double));
    memset(laplacian, 0, size * sizeof(unsigned char));
	
	respMapSize = layers;

	// Calculate approximated determinant of hessian values
	if (octaves >= 1)
	{
		responseLayer l_0;
		l_0.width = w;
		l_0.height = h;
		l_0.step = s;
		l_0.filter = 9;
		l_0.responses = determinant;
		l_0.laplacian = laplacian;
		
		responseLayer l_1;
		l_1.width = w;
		l_1.height = h;
		l_1.step = s;
		l_1.filter = 15;
		l_1.responses = determinant + offset;
		l_1.laplacian = laplacian + offset;
		
		responseLayer l_2;
		l_2.width = w;
		l_2.height = h;
		l_2.step = s;
		l_2.filter = 21;
		l_2.responses = determinant + offset*2;
		l_2.laplacian = laplacian + offset*2;
		
		responseLayer l_3;
		l_3.width = w;
		l_3.height = h;
		l_3.step = s;
		l_3.filter = 27;
		l_3.responses = determinant + offset*3;
		l_3.laplacian = laplacian + offset*3;
		
		respMap[0] = l_0;
		respMap[1] = l_1;
		respMap[2] = l_2;
		respMap[3] = l_3;
		
		offset += offset * 3;
	}
	
	if (octaves >= 2)
	{
		responseLayer l_4;
		l_4.width = w>>1;
		l_4.height = h>>1;
		l_4.step = s<<1;
		l_4.filter = 39;
		l_4.responses = determinant + offset;
		l_4.laplacian = laplacian + offset;
		
		offset += (w>>1)*(h>>1);
		
		responseLayer l_5;
		l_5.width = w>>1;
		l_5.height = h>>1;
		l_5.step = s<<1;
		l_5.filter = 51;
		l_5.responses = determinant + offset;
		l_5.laplacian = laplacian + offset;
		
		respMap[4] = l_4;
		respMap[5] = l_5;
		
		offset += (w>>1)*(h>>1);
	}
	
	if (octaves >= 3)
	{
		responseLayer l_6;
		l_6.width = w>>2;
		l_6.height = h>>2;
		l_6.step = s<<2;
		l_6.filter = 75;
		l_6.responses = determinant + offset;
		l_6.laplacian = laplacian + offset;
		
		offset += (w>>2)*(h>>2);
		
		responseLayer l_7;
		l_7.width = w>>2;
		l_7.height = h>>2;
		l_7.step = s<<2;
		l_7.filter = 99;
		l_7.responses = determinant + offset;
		l_7.laplacian = laplacian + offset;
		
		respMap[6] = l_6;
		respMap[7] = l_7;
		
		offset += (w>>2)*(h>>2);
	}
	
	if (octaves >= 4)
	{
		responseLayer l_8;
		l_8.width = w>>3;
		l_8.height = h>>3;
		l_8.step = s<<3;
		l_8.filter = 147;
		l_8.responses = determinant + offset;
		l_8.laplacian = laplacian + offset;
		
		offset += (w>>3)*(h>>3);
		
		responseLayer l_9;
		l_9.width = w>>3;
		l_9.height = h>>3;
		l_9.step = s<<3;
		l_9.filter = 195;
		l_9.responses = determinant + offset;
		l_9.laplacian = laplacian + offset;
		
		respMap[8] = l_8;
		respMap[9] = l_9;
		
		offset += (w>>3)*(h>>3);
	}
	
	if (octaves >= 5)
	{
		responseLayer l_10;
		l_10.width = w>>4;
		l_10.height = h>>4;
		l_10.step = s<<4;
		l_10.filter = 291;
		l_10.responses = determinant + offset;
		l_10.laplacian = laplacian + offset;
		
		offset += (w>>4)*(h>>4);
		
		responseLayer l_11;
		l_11.width = w>>4;
		l_11.height = h>>4;
		l_11.step = s<<4;
		l_11.filter = 387;
		l_11.responses = determinant + offset;
		l_11.laplacian = laplacian + offset;
		
		respMap[10] = l_10;
		respMap[11] = l_11;
		
		offset += (w>>4)*(h>>4);
	}
}

void updateResponseMap(register double *img)
{
	int i;
	
	for( i = 0; i < respMapSize; i++ )
	{
		responseLayer *rl = &respMap[i];
		double *responses = rl->responses;
		unsigned char *lap = rl->laplacian;
		int step = rl->step;                      // step size for this filter
		int b = ((rl->filter - 1) >> 1) + 1;      // border for this filter
		int l = rl->filter / 3;                   // lobe for this filter (filter size / 3)
		int w = rl->filter;                       // filter size
		double inverse_area = 1.0 / (w * w);           // normalisation factor
		double Dxx, Dyy, Dxy;
		
		int index;
		int stx = dRound(roi_x / step);
		int sty = dRound(roi_y / step);
		int enx = stx + roi_width / step;
		int eny = sty + roi_height / step;
		
		int r, c, ar, ac;
		int r1, r2, r3, r4;
		int ind11, ind12, cc1, cc2;
		int l2 = l<<1;
		int l_2 = l>>1;
		
		for(ar = sty; ar < eny; ar++)
		{
			r = ar * step;
			index = ar * rl->width + stx;
			r1 = r - l + iborder;
			r2 = r - b - 1 + iborder;
			r3 = r - l_2 - 1 + iborder;
			r4 = r - l - 1 + iborder;
			for(ac = stx; ac < enx; ac++, index++)
			{
				c = ac * step;

				// Compute response components
				
				Dxx = (FMAX(0.0, img[(ind11=r1*iwidth)+(cc1=c-b-1+iborder)] - img[ind11+(cc2=cc1+w)] - img[(ind12=(r1+l2-1)*iwidth)+cc1] + img[ind12+cc2])
					- FMAX(0.0, (img[ind11+(cc1=c-l_2-1+iborder)] - img[ind11+(cc2=cc1+l)] - img[ind12+cc1] + img[ind12+cc2])) * 3);
					
				Dyy = (FMAX(0.0, (*(img+(ind11=(r2)*iwidth)+(cc1=c-l+iborder)) - *(img+ind11+(cc2=cc1+l2-1)) - *(img+(ind12=(r2+w)*iwidth)+cc1) + *(img+ind12+cc2)))
					- FMAX(0.0, (*(img+(ind11=(r3)*iwidth)+cc1) - *(img+ind11+cc2) - *(img+(ind12=(r3+l)*iwidth)+cc1) + *(img+ind12+cc2))) * 3);
					
				Dxy = (FMAX(0.0, (*(img+(ind11=(r4)*iwidth)+(cc1=c+iborder)) - *(img+ind11+(cc2=cc1+l)) - *(img+(ind12=(r4+l)*iwidth)+cc1) + *(img+ind12+cc2)))
					+ FMAX(0.0, (*(img+(ind11=(r+iborder)*iwidth)+(cc1=c-l-1+iborder)) - *(img+ind11+(cc2=cc1+l)) - *(img+(ind12=(r+iborder+l)*iwidth)+cc1) + *(img+ind12+cc2)))
					- FMAX(0.0, (*(img+(ind11=(r4)*iwidth)+cc1) - *(img+ind11+cc2) - *(img+(ind12=(r4+l)*iwidth)+cc1) + *(img+ind12+cc2)))
					- FMAX(0.0, (*(img+(ind11=(r+iborder)*iwidth)+(cc1=c+iborder)) - *(img+ind11+(cc2=cc1+l)) - *(img+(ind12=(r+iborder+l)*iwidth)+cc1) + *(img+ind12+cc2))));
					
				// Normalise the filter responses with respect to their size
				Dxx *= inverse_area;
				Dyy *= inverse_area;
				Dxy *= inverse_area;

				// Get the determinant of hessian response & laplacian sign

				responses[index] = (Dxx*Dyy - 0.81*Dxy*Dxy);
				lap[index] = (Dxx + Dyy >= 0 ? 1 : 0);
			}
		}
	}
}

int isExtremum(const int r, const int c, responseLayer *t, responseLayer *m, responseLayer *b)
{
	// bounds check
	int layerBorder = (t->filter + 1) / (t->step << 1);
	if (r <= layerBorder || r >= t->height - layerBorder || c <= layerBorder || c >= t->width - layerBorder)
	{
		return 0;
	}

	// check the candidate point in the middle layer is above thresh
	const double candidate = getResponseSrc(r, c, m, t);
	
	if (candidate < threshold) return 0;

	int rr, cc;
	for (rr = -1; rr <=1; rr++)
	{
		for (cc = -1; cc <=1; cc++)
		{
			// if any response in 3x3x3 is greater candidate not maximum
			if (	getResponseOrig(r+rr, c+cc, t) >= candidate ||
					((rr != 0 && cc != 0) && getResponseSrc(r+rr, c+cc, m, t) >= candidate) ||
					getResponseSrc(r+rr, c+cc, b, t) >= candidate	)
			{
				return 0;
			}
		}
	}

	return 1;
}

int interpolateExtremum(double *pointsData, const int r, const int c, responseLayer *t, responseLayer *m, responseLayer *b)
{
  	// get the step distance between filters
	// check the middle filter is mid way between top and bottom
	int filterStep = (m->filter - b->filter);
	if(filterStep <= 0 || t->filter - m->filter != m->filter - b->filter) return 0;

	double xi, xr, xc;
	double dx, dy, ds, td1, td2;
	double v, dxx, dyy, dss, dxy, dxs, dys;

	// deriv3D
	// hessian3D
	
	v = getResponseSrc(r, c, m, t) * 2.0;

	td1 = (getResponseSrc(r, c + 1, m, t));
	td2 = (getResponseSrc(r, c - 1, m, t));

	dx = (td1 - td2) * 0.5;
	dxx = td1 + td2 - v;

	td1 = (getResponseSrc(r + 1, c, m, t));
	td2 = (getResponseSrc(r - 1, c, m, t));

	dy = (td1 - td2) * 0.5;
	dyy = td1 + td2 - v;

	td1 = (getResponseOrig(r, c, t));
	td2 = (getResponseSrc(r, c, b, t));

	ds = (td1 - td2) * 0.5;  
	dss = td1 + td2 - v;

	dxy = ( getResponseSrc(r + 1, c + 1, m, t) - getResponseSrc(r + 1, c - 1, m, t) -
			getResponseSrc(r - 1, c + 1, m, t) + getResponseSrc(r - 1, c - 1, m, t) ) * 0.25;
	dxs = ( getResponseOrig(r, c + 1, t) - getResponseOrig(r, c - 1, t) -
			getResponseSrc(r, c + 1, b, t) + getResponseSrc(r, c - 1, b, t) ) * 0.25;
	dys = ( getResponseOrig(r + 1, c, t) - getResponseOrig(r - 1, c, t) -
			getResponseSrc(r + 1, c, b, t) + getResponseSrc(r - 1, c, b, t) ) * 0.25;

	double det = -1.0 / ( dxx * ( dyy*dss-dys*dys) - dxy * (dxy*dss-dxs*dys) + dxs * (dxy*dys-dxs*dyy) );

	xc = det * ( dx * ( dyy*dss-dys*dys ) + dy * ( dxs*dys-dss*dxy ) + ds * ( dxy*dys-dyy*dxs ) );
	xr = det * ( dx * ( dys*dxs-dss*dxy ) + dy * ( dxx*dss-dxs*dxs ) + ds * ( dxs*dxy-dys*dxx ) );
	xi = det * ( dx * ( dxy*dys-dxs*dyy ) + dy * ( dxy*dxs-dxx*dys ) + ds * ( dxx*dyy-dxy*dxy ) );

	// If point is sufficiently close to the actual extremum
	if( fabs( xi ) < 0.5  &&  fabs( xr ) < 0.5  &&  fabs( xc ) < 0.5 )
	{		
		register double *ptr = pointsData;
		*(ptr++) = (double)((c + xc) * t->step);
		*(ptr++) = (double)((r + xr) * t->step);
		*(ptr++) = (double)((0.1333) * (m->filter + xi * filterStep));
		*(ptr++) = 0.0;
		*(ptr++) = (double)(getLaplacianSrc(r,c,m,t));

		return 1;
	}

	return 0;
}

int getIpoints(register double *pointsData, const int max_points)
{
  // Get the response layers
  responseLayer *b, *m, *t;
  int o, r, c;
  int stx, sty, enx, eny;
  int step;

  currentPointsCount = 0;

  for (o = 0; o < octaves; ++o)
  {
    b = &respMap[ filter_map[o][0] ];
    m = &respMap[ filter_map[o][1] ];
    t = &respMap[ filter_map[o][2] ];
	
	step = t->step;
	stx = dRound(roi_x / step);
	sty = dRound(roi_y / step);
	enx = stx + roi_width / step;
	eny = sty + roi_height / step;

    // loop over middle response layer at density of the most
    // sparse layer (always top), to find maxima across scale and space
    for (r = sty; r < eny; r++)
    {
      for (c = stx; c < enx; c++)
      {
        if (isExtremum(r, c, t, m, b) && interpolateExtremum(pointsData, r, c, t, m, b))
        {
			currentPointsCount ++;
			if(currentPointsCount == max_points) return 1;
			pointsData += POINT_DATA_LENGTH;
        }
      }
    }
	
	b = m;
    m = t;
    t = &respMap[ filter_map[o][3] ];
	
	step = t->step;
	stx = dRound(roi_x / step);
	sty = dRound(roi_y / step);
	enx = stx + roi_width / step;
	eny = sty + roi_height / step;

    for (r = sty; r < eny; r++)
    {
      for (c = stx; c < enx; c++)
      {
        if (isExtremum(r, c, t, m, b) && interpolateExtremum(pointsData, r, c, t, m, b))
        {
			currentPointsCount ++;
			if(currentPointsCount == max_points) return 1;
			pointsData += POINT_DATA_LENGTH;
        }
      }
    }
  }

  return 0;
}