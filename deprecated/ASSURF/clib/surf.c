#include <math.h>

void writePointsResult(const int useOrientation, const int count, register double *outData);
double getPointOrientation(const int c, const int r, const double scale, register double *integralData);
void getDescriptor(	const int x, const int y, const double scale, const double co, const double si, 
							register double *integralData, double *start, double *end
						);

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

static const int gauss25ID[13] = {6,5,4,3,2,1,0,1,2,3,4,5,6};


double getPointOrientation(const int c, const int r, const double scale, register double *integralData)
{
	int i, j, cc, rr;
	int ind11, ind12, cc1, cc2;
	double gauss, _resx, _resy, nmax;
	int s = dRound(scale);
	int s4 = (s<<2);
	int s2 = (s4>>1);

	unsigned int idx = 0;
	double resX[109];
	double resY[109];
	double Ang[109];

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

				_resx = gauss * (FMAX(0.0, (*(integralData+(ind11=(rr-s2)*iwidth)+cc) - *(integralData+ind11+(cc2=cc+s2)) - *(integralData+(ind12=(rr-s2+s4)*iwidth)+cc) + *(integralData+ind12+cc2)))
				- 1*FMAX(0.0, (*(integralData+ind11+(cc1=cc-s2)) - *(integralData+ind11+cc) - *(integralData+ind12+cc1) + *(integralData+ind12+cc))));
				
				_resy = gauss * (FMAX(0.0, (*(integralData+(ind11=(rr)*iwidth)+(cc1=cc-s2)) - *(integralData+ind11+(cc2=cc1+s4)) - *(integralData+(ind12=(rr+s2)*iwidth)+cc1) + *(integralData+ind12+cc2)))
				- 1*FMAX(0.0, (*(integralData+(ind12=(rr-s2)*iwidth)+cc1) - *(integralData+ind12+cc2) - *(integralData+ind11+cc1) + *(integralData+ind11+cc2))));

				resX[idx] = _resx;
				resY[idx] = _resy;
				Ang[idx] = ANGLE(_resx, _resy);
				++idx;
			}
		}
	}

	// calculate the dominant direction
	double max = 0;
	double ang1, ang2, rx, ry;
	unsigned int k;

	// loop slides pi/3 window around feature point
	for(ang1 = 0; ang1 < two_pi;  ang1 += 0.15)
	{
		ang2 = ( ang1+pi_on_three > two_pi ? ang1-5.0*pi_on_three : ang1+pi_on_three);
		_resx = _resy = 0;
		
		for(k = 0; k < idx; k++) 
		{
			// get angle from the x-axis of the sample point
			const double ang = Ang[k];

			// determine whether the point is within the window
			if (ang1 < ang2 && ang1 < ang && ang < ang2) 
			{
				_resx += resX[k];  
				_resy += resY[k];
			} 
			else if (ang2 < ang1 && ((ang > 0.0 && ang < ang2) 
					|| (ang > ang1 && ang < two_pi) )) 
			{
				_resx += resX[k];
				_resy += resY[k];
			}
		}
		
		// if the vector produced from this window is longer than all
		// previous vectors then this forms the new dominant direction
		nmax = _resx*_resx + _resy*_resy;
		if (nmax > max)
		{
			max = nmax;
			rx = _resx;
			ry = _resy;
		}
	}

	return ANGLE(rx, ry);
}

void getDescriptor(	const int x, const int y, const double scale, const double co, const double si, 
							register double *integralData, double *start, double *end
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
	int s2 = (dRound(scale)<<1);
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

			ix = i + 6;
			jx = j + 6;

			xs = dRound(x + ( -jx*scale*si + ix*scale*co ));
			ys = dRound(y + ( jx*scale*co + ix*scale*si ));

			for (k = i; k < i + 9; ++k)
			{
				for (l = j; l < j + 9; ++l)
				{
					//Get coords of sample point on the rotated axis
					sample_x = dRound(x + (-l*scale*si + k*scale*co));
					sample_y = dRound(y + ( l*scale*co + k*scale*si));

					//Get the GAUSSIAN weighted x and y responses
					gauss_s1 = IGAUSSIAN(xs-sample_x, ys-sample_y, scale25);

					sample_x += iborder - 1;
					sample_y += iborder - 1;

					rx = FMAX(0.0, (*(integralData+(ind11=(sample_y - s22)*iwidth)+sample_x) - *(integralData+ind11+(cc2=sample_x+s22)) - *(integralData+(ind12=(sample_y - s22+s2)*iwidth)+sample_x) + *(integralData+ind12+cc2)))
					- 1*FMAX(0.0, (*(integralData+ind11+(cc1=sample_x-s22)) - *(integralData+ind11+sample_x) - *(integralData+ind12+cc1) + *(integralData+ind12+sample_x)));

					ry = FMAX(0.0, (*(integralData+(ind11=(sample_y)*iwidth)+(cc1=sample_x-s22)) - *(integralData+ind11+(cc2=cc1+s2)) - *(integralData+(ind12=(sample_y + s22)*iwidth)+cc1) + *(integralData+ind12+cc2)))
					- 1*FMAX(0.0, (*(integralData+(ind11=(sample_y - s22)*iwidth)+(cc1=sample_x-s22)) - *(integralData+ind11+(cc2=cc1+s2)) - *(integralData+(ind12=(sample_y)*iwidth)+cc1) + *(integralData+ind12+cc2)));


					//Get the IGAUSSIAN weighted x and y responses on rotated axis
					rrx = gauss_s1 * (-rx*si + ry*co);
					rry = gauss_s1 * (rx*co + ry*si);

					dx += rrx;
					dy += rry;
					mdx += fabs(rrx);
					mdy += fabs(rry);
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

void writePointsResult(const int useOrientation, const int count, register double *outData)
{
	int i, x, y;
	double scale, orientation;

	if(useOrientation == 1)
	{
		for (i = 0; i < count; ++i)
		{
			x = dRound(*(outData++));
			y = dRound(*(outData++));
			scale = *(outData++);
			*(outData++) = (orientation = getPointOrientation(x-1, y-1, scale, integral));
			outData++;

			getDescriptor(x, y, scale, cos(orientation), sin(orientation), integral, outData, outData+64);
			outData += 64;
		}
	} else {
		for (i = 0; i < count; ++i)
		{
			getDescriptor(dRound(*(outData)), dRound(*(outData+1)), *(outData+2), 1.0, 0.0, integral, outData+5, outData+69);
			outData += 69;
		}
	}
}