#include <math.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "AS3.h"


float *realData;
float *imagData;
float *realFFTData;
float *imagFFTData;
float *amplFFTData;
float *phaseFFTData;

float *shiftedData;
int *drawData;

int imageW;
int imageH;
int imageW2;
int imageH2;
int numChannels;
int area2;

static const float INV_LOG2 = 1.4426950408889634;

static void cleanUp();
static void calculateAmp(int n, int m, float *gAmp, float *gRe, float *gIm);
static void calculatePhase(int n, int m, float *gPhase, float *gRe, float *gIm);
static void FFT2DRGB(int n, int m, int inverse, float *gRe, float *gIm, float *GRe, float *GIm);
static void FFT2DGray(int n, int m, int inverse, float *gRe, float *gIm, float *GRe, float *GIm);
static void plotImageData(int tw, int th, float *data, int *outData, int shift, int add128);
static void shiftData(float *from, float *to);


static AS3_Val getBufferPointers(void* self, AS3_Val args)
{
	AS3_Val pointers = AS3_Array("AS3ValType", NULL);
	
	AS3_Set(pointers, AS3_Int(0), AS3_Ptr(&realData));
	AS3_Set(pointers, AS3_Int(1), AS3_Ptr(&imagData));
	AS3_Set(pointers, AS3_Int(2), AS3_Ptr(&realFFTData));
	AS3_Set(pointers, AS3_Int(3), AS3_Ptr(&imagFFTData));
	AS3_Set(pointers, AS3_Int(4), AS3_Ptr(&amplFFTData));
	AS3_Set(pointers, AS3_Int(5), AS3_Ptr(&drawData));
	AS3_Set(pointers, AS3_Int(6), AS3_Ptr(&shiftedData));
	AS3_Set(pointers, AS3_Int(7), AS3_Ptr(&phaseFFTData));
	
	return pointers;
}

static AS3_Val allocateBuffers(void* self, AS3_Val args)
{
	int nw, nh, nw2, nh2, numCh;
	AS3_ArrayValue(args, "IntType, IntType, IntType, IntType, IntType", &nw, &nh, &nw2, &nh2, &numCh );
	
	if(nw != imageW || nh != imageH || numCh != numChannels)
	{
		imageW = nw;
		imageH = nh;
		imageW2 = nw2;
		imageH2 = nh2;
		numChannels = numCh;
		
		cleanUp();

		area2 = (imageW2 * imageH2) * numChannels;

		realData = (float*)malloc( area2 * sizeof(float) );
		imagData = (float*)malloc( area2 * sizeof(float) );

		realFFTData = (float*)malloc( area2 * sizeof(float) );
		imagFFTData = (float*)malloc( area2 * sizeof(float) );

		amplFFTData = (float*)malloc( area2 * sizeof(float) );
		phaseFFTData = (float*)malloc( area2 * sizeof(float) );
		
		shiftedData = (float*)malloc( area2 * sizeof(float) );
		
		drawData = (int*)malloc( (imageW2 * imageH2) * sizeof(int) );
	}
	
	memset(realData, 0.0, area2 * sizeof(float));
	memset(imagData, 0.0, area2 * sizeof(float));
	
	return 0;
}

static AS3_Val analyzeImage(void* self, AS3_Val args)
{
	int doFFT = 0;
	int doInverse = 0;
	int doAmplitude = 0;
	int doPhase = 0;
	
	AS3_ArrayValue(args, "IntType, IntType, IntType, IntType", &doFFT, &doAmplitude, &doPhase, &doInverse );
	
	if(numChannels == 3)
	{
		if(doFFT == 1)
		{
			FFT2DRGB(imageW2, imageH2, -1, realData, imagData, realFFTData, imagFFTData);
		}
		
		if(doAmplitude == 1)
		{
			calculateAmp(imageW2, imageH2, amplFFTData, realFFTData, imagFFTData);
		}
		if(doPhase == 1)
		{
			calculatePhase(imageW2, imageH2, phaseFFTData, realFFTData, imagFFTData);
		}
	
		if(doInverse == 1)
		{
			FFT2DRGB(imageW2, imageH2, 1, realFFTData, imagFFTData, realData, imagData);
		}
	}
	else
	{
		if(doFFT == 1)
		{
			FFT2DGray(imageW2, imageH2, -1, realData, imagData, realFFTData, imagFFTData);
		}
		
		if(doAmplitude == 1)
		{
			calculateAmp(imageW2, imageH2, amplFFTData, realFFTData, imagFFTData);
		}
		if(doPhase == 1)
		{
			calculatePhase(imageW2, imageH2, phaseFFTData, realFFTData, imagFFTData);
		}
	
		if(doInverse == 1)
		{
			FFT2DGray(imageW2, imageH2, 1, realFFTData, imagFFTData, realData, imagData);
		}
	}
	
	return 0;
}

static AS3_Val drawImageData(void* self, AS3_Val args)
{
	int tw = 0;
	int th = 0;
	int shift = 0;
	int add128 = 0;
	int dataType = 0;
	
	AS3_ArrayValue(args, "IntType, IntType, IntType, IntType, IntType", &dataType, &tw, &th, &shift, &add128 );
	
	if(dataType == 0)
	{
		plotImageData(tw, th, realData, drawData, shift, add128);
	} else if(dataType == 1)
	{
		plotImageData(tw, th, imagData, drawData, shift, add128);
	} else if(dataType == 2)
	{
		plotImageData(tw, th, realFFTData, drawData, shift, add128);
	} else if(dataType == 3)
	{
		plotImageData(tw, th, imagFFTData, drawData, shift, add128);
	} else if(dataType == 4)
	{
		plotImageData(tw, th, amplFFTData, drawData, shift, add128);
	}
	
	return 0;
}

static AS3_Val shiftImageData(void* self, AS3_Val args)
{
	int dataType = 0;
	int reverse = 0;
	
	AS3_ArrayValue(args, "IntType, IntType", &dataType, &reverse );
	
	if(dataType == 0)
	{
		if(reverse)
		{
			shiftData(shiftedData, realData);
		} else {
			shiftData(realData, shiftedData);
		}
	} else if(dataType == 1)
	{
		if(reverse)
		{
			shiftData(shiftedData, imagData);
		} else {
			shiftData(imagData, shiftedData);
		}
	} else if(dataType == 2)
	{
		if(reverse)
		{
			shiftData(shiftedData, realFFTData);
		} else {
			shiftData(realFFTData, shiftedData);
		}
	} else if(dataType == 3)
	{
		if(reverse)
		{
			shiftData(shiftedData, imagFFTData);
		} else {
			shiftData(imagFFTData, shiftedData);
		}
	} else if(dataType == 4)
	{
		if(reverse)
		{
			shiftData(shiftedData, amplFFTData);
		} else {
			shiftData(amplFFTData, shiftedData);
		}
	}
	
	return 0;
}

static void FFT2DRGB(int n, int m, int inverse, float *gRe, float *gIm, float *GRe, float *GIm)
{
	int x, y, ind1, ind2;
	int i, j, k;
	int i1, l1, l2, l;
	float tx = 0, ty = 0;
	float u1, u2, t1, t2, z, ca, sa, d;
	
	/*int l2n = 0, p = 1; //l2n will become log_2(n)
	while(p < n) {p <<= 1; l2n++;}
	int l2m = 0; p = 1; //l2m will become log_2(m)
	while(p < m) {p <<= 1; l2m++;}*/
	int l2n = log(n) * INV_LOG2 + 0.5;
	int l2m = log(m) * INV_LOG2 + 0.5;
	//m = 1 << l2m; n = 1 << l2n; //Make sure m and n will be powers of 2, otherwise you'll get in an infinite loop
	
	//Erase all history of this array
	memcpy(GRe, gRe, area2 * sizeof(float));
	memcpy(GIm, gIm, area2 * sizeof(float));	
   
	//Bit reversal of each row
	for(y = 0; y < m; y++) //for each row
	{
		j = 0;
		for(i = 0; i < n - 1; i++)
		{
			ind1 = (y * n + i) * 3;
			ind2 = (y * n + j) * 3;
			
			// R
			GRe[ind1] = gRe[ind2];
			GIm[ind1++] = gIm[ind2++];
			// G
			GRe[ind1] = gRe[ind2];
			GIm[ind1++] = gIm[ind2++];
			// B
			GRe[ind1] = gRe[ind2];
			GIm[ind1] = gIm[ind2];
			
			k = n>>1;
			while (k <= j) {j -= k; k>>=1;}
			j += k;
		}
	}
	
	//Bit reversal of each column
	for(x = 0; x < n; x++) //for each column
	{
		j = 0;
		for(i = 0; i < m - 1; i++)
		{
			if(i < j)
			{
				ind1 = (i * n + x) * 3;
				ind2 = (j * n + x) * 3;
				
				// R
				tx = GRe[ind1];
				ty = GIm[ind1];
				GRe[ind1] = GRe[ind2];
				GIm[ind1++] = GIm[ind2];
				GRe[ind2] = tx;
				GIm[ind2++] = ty;
				// G
				tx = GRe[ind1];
				ty = GIm[ind1];
				GRe[ind1] = GRe[ind2];
				GIm[ind1++] = GIm[ind2];
				GRe[ind2] = tx;
				GIm[ind2++] = ty;
				// B
				tx = GRe[ind1];
				ty = GIm[ind1];
				GRe[ind1] = GRe[ind2];
				GIm[ind1] = GIm[ind2];
				GRe[ind2] = tx;
				GIm[ind2] = ty;
			}
			k = m>>1;
			while (k <= j) {j -= k; k>>=1;}
			j += k;
		}
	}
	
	//Calculate the FFT of the columns
	for(x = 0; x < n; x++) //for each column
	{
		//This is the 1D FFT:
		ca = -1.0;
		sa = 0.0;
		l1 = 1;
		l2 = 1;
		for(l=0; l < l2n; l++)
		{
			l1 = l2;
			l2 <<= 1;
			u1 = 1.0;
			u2 = 0.0;
			for(j = 0; j < l1; j++)
			{
				for(i = j; i < n; i += l2)
				{
					i1 = i + l1;
					
					ind1 = (i1 * n + x) * 3;
					ind2 = (i * n + x) * 3;
					
					// R
					t1 = u1 * GRe[ind1] - u2 * GIm[ind1];
					t2 = u1 * GIm[ind1] + u2 * GRe[ind1];
					GRe[ind1] = GRe[ind2] - t1;
					GIm[ind1++] = GIm[ind2] - t2;
					GRe[ind2] += t1;
					GIm[ind2++] += t2;
					// G
					t1 = u1 * GRe[ind1] - u2 * GIm[ind1];
					t2 = u1 * GIm[ind1] + u2 * GRe[ind1];
					GRe[ind1] = GRe[ind2] - t1;
					GIm[ind1++] = GIm[ind2] - t2;
					GRe[ind2] += t1;
					GIm[ind2++] += t2;
					// B
					t1 = u1 * GRe[ind1] - u2 * GIm[ind1];
					t2 = u1 * GIm[ind1] + u2 * GRe[ind1];
					GRe[ind1] = GRe[ind2] - t1;
					GIm[ind1] = GIm[ind2] - t2;
					GRe[ind2] += t1;
					GIm[ind2] += t2;
				}
				z =  u1 * ca - u2 * sa;
				u2 = u1 * sa + u2 * ca;
				u1 = z;
			}
			sa = (float)inverse * sqrt((1.0 - ca) * 0.5);
			ca = sqrt((1.0 + ca) * 0.5);
		}
	}
	
	//Calculate the FFT of the rows
	for(y = 0; y < m; y++) //for each row
	{
		//This is the 1D FFT:
		ca = -1.0;
		sa = 0.0;
		l1= 1;
		l2 = 1;
		for(l = 0; l < l2m; l++)
		{
			l1 = l2;
			l2 <<= 1;
			u1 = 1.0;
			u2 = 0.0;
			for(j = 0; j < l1; j++)
			{
				for(i = j; i < n; i += l2)
				{
					i1 = i + l1;
					
					ind1 = (y * n + i1) * 3;
					ind2 = (y * n + i) * 3;
					
					// R
					t1 = u1 * GRe[ind1] - u2 * GIm[ind1];
					t2 = u1 * GIm[ind1] + u2 * GRe[ind1];
					GRe[ind1] = GRe[ind2] - t1;
					GIm[ind1++] = GIm[ind2] - t2;
					GRe[ind2] += t1;
					GIm[ind2++] += t2;
					// G
					t1 = u1 * GRe[ind1] - u2 * GIm[ind1];
					t2 = u1 * GIm[ind1] + u2 * GRe[ind1];
					GRe[ind1] = GRe[ind2] - t1;
					GIm[ind1++] = GIm[ind2] - t2;
					GRe[ind2] += t1;
					GIm[ind2++] += t2;
					// B
					t1 = u1 * GRe[ind1] - u2 * GIm[ind1];
					t2 = u1 * GIm[ind1] + u2 * GRe[ind1];
					GRe[ind1] = GRe[ind2] - t1;
					GIm[ind1] = GIm[ind2] - t2;
					GRe[ind2] += t1;
					GIm[ind2] += t2;
				}
				z =  u1 * ca - u2 * sa;
				u2 = u1 * sa + u2 * ca;
				u1 = z;
			}
			sa = (float)inverse * sqrt((1.0 - ca) * 0.5);
			ca = sqrt((1.0 + ca) * 0.5);
		}
	}
 
	if(inverse == 1) d = 1.0 / (float)n; else d = 1.0 / (float)m;
	
	register float *re2, *im2, *end;
	for( re2 = GRe, im2 = GIm, end = GRe+area2; re2 < end; )
	{
		*(re2++) *= d;
		*(im2++) *= d;
	}
}

static void FFT2DGray(int n, int m, int inverse, float *gRe, float *gIm, float *GRe, float *GIm)
{
	int x, y, ind1, ind2;
	int i, j, k;
	int i1, l1, l2, l;
	float tx = 0, ty = 0;
	float u1, u2, t1, t2, z, ca, sa, d;
	
	/*int l2n = 0, p = 1; //l2n will become log_2(n)
	while(p < n) {p <<= 1; l2n++;}
	int l2m = 0; p = 1; //l2m will become log_2(m)
	while(p < m) {p <<= 1; l2m++;}*/
	int l2n = log(n) * INV_LOG2 + 0.5;
	int l2m = log(m) * INV_LOG2 + 0.5;
	//m = 1 << l2m; n = 1 << l2n; //Make sure m and n will be powers of 2, otherwise you'll get in an infinite loop
	
	//Erase all history of this array
	memcpy(GRe, gRe, area2 * sizeof(float));
	memcpy(GIm, gIm, area2 * sizeof(float));	
   
	//Bit reversal of each row
	for(y = 0; y < m; y++) //for each row
	{
		j = 0;
		for(i = 0; i < n - 1; i++)
		{
			ind1 = (y * n + i);
			ind2 = (y * n + j);
			
			GRe[ind1] = gRe[ind2];
			GIm[ind1] = gIm[ind2];
			
			k = n>>1;
			while (k <= j) {j -= k; k>>=1;}
			j += k;
		}
	}
	
	//Bit reversal of each column
	for(x = 0; x < n; x++) //for each column
	{
		j = 0;
		for(i = 0; i < m - 1; i++)
		{
			if(i < j)
			{
				ind1 = (i * n + x);
				ind2 = (j * n + x);
				
				tx = GRe[ind1];
				ty = GIm[ind1];
				GRe[ind1] = GRe[ind2];
				GIm[ind1] = GIm[ind2];
				GRe[ind2] = tx;
				GIm[ind2] = ty;
			}
			k = m>>1;
			while (k <= j) {j -= k; k>>=1;}
			j += k;
		}
	}
	
	//Calculate the FFT of the columns
	for(x = 0; x < n; x++) //for each column
	{
		//This is the 1D FFT:
		ca = -1.0;
		sa = 0.0;
		l1 = 1;
		l2 = 1;
		for(l=0; l < l2n; l++)
		{
			l1 = l2;
			l2 <<= 1;
			u1 = 1.0;
			u2 = 0.0;
			for(j = 0; j < l1; j++)
			{
				for(i = j; i < n; i += l2)
				{
					i1 = i + l1;
					
					ind1 = (i1 * n + x);
					ind2 = (i * n + x);
					
					// R
					t1 = u1 * GRe[ind1] - u2 * GIm[ind1];
					t2 = u1 * GIm[ind1] + u2 * GRe[ind1];
					GRe[ind1] = GRe[ind2] - t1;
					GIm[ind1] = GIm[ind2] - t2;
					GRe[ind2] += t1;
					GIm[ind2] += t2;
				}
				z =  u1 * ca - u2 * sa;
				u2 = u1 * sa + u2 * ca;
				u1 = z;
			}
			sa = (float)inverse * sqrt((1.0 - ca) * 0.5);
			ca = sqrt((1.0 + ca) * 0.5);
		}
	}
	
	//Calculate the FFT of the rows
	for(y = 0; y < m; y++) //for each row
	{
		//This is the 1D FFT:
		ca = -1.0;
		sa = 0.0;
		l1= 1;
		l2 = 1;
		for(l = 0; l < l2m; l++)
		{
			l1 = l2;
			l2 <<= 1;
			u1 = 1.0;
			u2 = 0.0;
			for(j = 0; j < l1; j++)
			{
				for(i = j; i < n; i += l2)
				{
					i1 = i + l1;
					
					ind1 = (y * n + i1);
					ind2 = (y * n + i);
					
					// R
					t1 = u1 * GRe[ind1] - u2 * GIm[ind1];
					t2 = u1 * GIm[ind1] + u2 * GRe[ind1];
					GRe[ind1] = GRe[ind2] - t1;
					GIm[ind1] = GIm[ind2] - t2;
					GRe[ind2] += t1;
					GIm[ind2] += t2;
				}
				z =  u1 * ca - u2 * sa;
				u2 = u1 * sa + u2 * ca;
				u1 = z;
			}
			sa = (float)inverse * sqrt((1.0 - ca) * 0.5);
			ca = sqrt((1.0 + ca) * 0.5);
		}
	}
 
	if(inverse == 1) d = 1.0 / (float)n; else d = 1.0 / (float)m;
	
	register float *re2, *im2, *end;
	for( re2 = GRe, im2 = GIm, end = GRe+area2; re2 < end; )
	{
		*(re2++) *= d;
		*(im2++) *= d;
	}
}

static void calculateAmp(int n, int m, float *gAmp, float *gRe, float *gIm)
{
	register float *re, *im, *am, *end;
	for( re = gRe, im = gIm, am = gAmp, end = gAmp+area2; am < end; re++, im++)
	{
		*(am++) = sqrt((*re) * (*re) + (*im) * (*im));
	}
}

static void calculatePhase(int n, int m, float *gPhase, float *gRe, float *gIm)
{
	register float *re, *im, *ph, *end;
	for( re = gRe, im = gIm, ph = gPhase, end = gPhase+area2; ph < end; re++, im++)
	{
		*(ph++) = atan2((*re), (*im));
	}
}

static void shiftData(float *from, float *to)
{
	int i, j, ind;
	
	int hw = imageW2 >> 1;
	int hh = imageH2 >> 1;
	
	register float *out = to;
	
	if(numChannels == 3)
	{
		for(i = 0; i < imageH2; i++)
		{
			for(j = 0; j < imageW2; j++)
			{
				ind = (((i + hh) % imageH2) * imageW2 + ((j + hw) % imageW2)) * 3;

				*(out++) = from[ind++];
				*(out++) = from[ind++];
				*(out++) = from[ind];
			}
		}
	}
	else
	{
		for(i = 0; i < imageH2; i++)
		{
			for(j = 0; j < imageW2; j++)
			{
				ind = (((i + hh) % imageH2) * imageW2 + ((j + hw) % imageW2));

				*(out++) = from[ind];
			}
		}
	}
}
static void plotImageData(int tw, int th, float *data, int *outData, int shift, int add128)
{
	int i, j, ind = 0;
	
	int r, g, b;
	int hw = imageW2 >> 1;
	int hh = imageH2 >> 1;
	int stride = (imageW2 - tw) * numChannels;
	
	register int *out = outData;
	
	if(numChannels == 3)
	{
		for(i = 0; i < th; i++)
		{
			for(j = 0; j < tw; j++)
			{
				if(shift)
				{
					ind = (((i + hh) % imageH2) * imageW2 + ((j + hw) % imageW2)) * 3;
				}

				r = (int)data[ind++];
				g = (int)data[ind++];
				b = (int)data[ind++];

				if(add128)
				{
					r += 128;
					g += 128;
					b += 128;
				}

				r = r < 0 ? 0 : (r > 255 ? 255 : r);
				g = g < 0 ? 0 : (g > 255 ? 255 : g);
				b = b < 0 ? 0 : (b > 255 ? 255 : b);

				*(out++) = ((r<<16)+(g<<8)+b);
			}
			ind += stride;
		}
	}
	else
	{
		for(i = 0; i < th; i++)
		{
			for(j = 0; j < tw; j++)
			{
				if(shift)
				{
					ind = (((i + hh) % imageH2) * imageW2 + ((j + hw) % imageW2));
				}

				r = (int)data[ind++];

				if(add128)
				{
					r += 128;
				}

				r = r < 0 ? 0 : (r > 255 ? 255 : r);

				*(out++) = ((r<<16)+(r<<8)+r);
			}
			ind += stride;
		}
	}
}


static void cleanUp()
{
	if(realData) free(realData);
	if(imagData) free(imagData);
	if(realFFTData) free(realFFTData);
	if(imagFFTData) free(imagFFTData);
	if(amplFFTData) free(amplFFTData);
	if(drawData) free(drawData);
	if(shiftedData) free(shiftedData);
	if(phaseFFTData) free(phaseFFTData);
}
static AS3_Val freeBuffers(void* self, AS3_Val args)
{
	cleanUp();
	
	imageW = 0;
	imageH = 0;
	imageW2 = 0;
	imageH2 = 0;
	numChannels = 0;
		
	return 0;
}

int main()
{
	AS3_Val getBufferPointers_m = AS3_Function( NULL, getBufferPointers );
	AS3_Val allocateBuffers_m = AS3_Function( NULL, allocateBuffers );
	AS3_Val freeBuffers_m = AS3_Function( NULL, freeBuffers );
	AS3_Val analyzeImage_m = AS3_Function( NULL, analyzeImage );
	AS3_Val drawImageData_m = AS3_Function( NULL, drawImageData );
	AS3_Val shiftImageData_m = AS3_Function( NULL, shiftImageData );

	AS3_Val result = AS3_Object("getBufferPointers: AS3ValType, allocateBuffers: AS3ValType, freeBuffers: AS3ValType, analyzeImage: AS3ValType, drawImageData: AS3ValType, shiftImageData: AS3ValType",
	getBufferPointers_m, allocateBuffers_m, freeBuffers_m, analyzeImage_m, drawImageData_m, shiftImageData_m);

	AS3_Release( getBufferPointers_m );
	AS3_Release( allocateBuffers_m );
	AS3_Release( freeBuffers_m );
	AS3_Release( analyzeImage_m );
	AS3_Release( drawImageData_m );
	AS3_Release( shiftImageData_m );

	AS3_LibInit( result );

	return 0;
}