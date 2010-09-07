#include "math.h"
#include "stdio.h"
#define max(a,b) (a>b?a:b)
#define min(a,b) (a<b?a:b)


//namespace rpp {

int quartic(double dd[5], double sol[4], double soli[4], int* Nsol);
int cubic(double A[4], double X[3], int* L);
int signR(double Z);
double CBRT(double Z);

/*-------------------- Global Function Description Block ----------------------
 *
 *     ***QUINTIC************************************************25.03.98
 *     Solution of a quintic equation by a hybrid method:
 *     first real solution is obtained numerically by the Newton method,
 *     the remaining four roots are obtained analytically by QUARTIC
 *     NO WARRANTY, ALWAYS TEST THIS SUBROUTINE AFTER DOWNLOADING
 *     ******************************************************************
 *     dd(0:4)     (i)  vector containing the polynomial coefficients
 *     sol(1:4)    (o)  results, real part
 *     soli(1:4)   (o)  results, imaginary part
 *     Nsol        (o)  number of real solutions 
 *
 *     17-Oct-2004 / Raoul Rausch
 *     Conversion from Fortran to C
 *
 *
 *-----------------------------------------------------------------------------
 */
/*
int quintic(double dd[6], double sol[5], double soli[5], int *Nsol, double xstart)
{
	double  dd4[5], sol4[4], soli4[4], xnew, xs;//, soli4[4];dd[6], sol[5], soli[5],
	double sum, sum1, eC;
	const double eps = 1.e-8;
	int i, Nsol4;

	*Nsol = 0;

	//printf("\n Quintic!\n");

	if (dd[5] == 0.0)
	{ 
		//printf("\n ERROR: NOT A QUINTIC EQUATION");
		return 0;
	}

	// Newton iteration of one real root
	xs= xstart;
	xnew = xstart;	//added rr
	do
	{
		xs = xnew;	//added rr
		sum = dd[0];
		for (i=1;i<6;i++)	sum += dd[i]*pow(xs,i);	// Don't know what ** means
		sum1 = dd[1];
		for (i=1;i<5;i++)	sum1 += (double)(i+1)*dd[i+1]*pow(xs,i);
		xnew = xs - sum/sum1;
		//if (fabs(xnew-xs) > eps)
		//xs =xnew;
		//printf("\n %f\t%f!", xs, xnew);
	}while (fabs(xnew-xs) > eps);

	eC = xnew;
	//
	// "eC" is one real root of quintic equation
	// reduce quintic to quartic equation using "eC"
	dd4[4] = dd[5];
	for (i=4;i>0;i--)	dd4[i-1] = dd[i] + eC*dd4[i];

	quartic(dd4, sol4, soli4, &Nsol4);

	
	sol[0] = eC;
	soli[0] = 0.0;

	for (i=0;i<4;i++)
	{
		sol[i+1] =sol4[i];
		soli[i+1] = soli4[i];
	}
	*Nsol = Nsol4 + 1;

	return 0;
}
*/

/*-------------------- Global Function Description Block ----------------------
 *
 *     ***QUARTIC************************************************25.03.98
 *     Solution of a quartic equation
 *     ref.: J. E. Hacke, Amer. Math. Monthly, Vol. 48, 327-328, (1941)
 *     NO WARRANTY, ALWAYS TEST THIS SUBROUTINE AFTER DOWNLOADING
 *     ******************************************************************
 *     dd(0:4)     (i)  vector containing the polynomial coefficients
 *     sol(1:4)    (o)  results, real part
 *     soli(1:4)   (o)  results, imaginary part
 *     Nsol        (o)  number of real solutions 
 *     ==================================================================
 *  	17-Oct-2004 / Raoul Rausch
 *		Conversion from Fortran to C
 *
 *
 *-----------------------------------------------------------------------------
 */

 int quartic(double dd[5], double sol[4], double soli[4], int* Nsol)
 {
	double AA[4], z[3];
	double a, b, c, d, f, p, q, r, zsol, xK2, xL, xK, sqp, sqm;
	int ncube, i;
	*Nsol = 0;

	if (dd[4] == 0.0)
	{
		//printf("\n ERROR: NOT A QUARTIC EQUATION");
		return 0;
	}

	a = dd[4];
	b = dd[3];
	c = dd[2];
	d = dd[1];
	f = dd[0];

	p = (-3.0*(b*b) + 8.0 *a*c)/(8.0*(a*a));
	q = ((b*b*b) - 4.0*a*b*c + 8.0 *d*(a*a)) / (8.0*(a*a*a));
	r = (-3.0*(b*b*b*b) + 16.0 *a*(b*b)*c - 64.0 *(a*a)*b*d + 256.0 *(a*a*a)*f)/(256.0*(a*a*a*a));
	
	// Solve cubic resolvent
	AA[3] = 8.0;
	AA[2] = -4.0*p;
	AA[1] = -8.0*r;
	AA[0] = 4.0*p*r - (q*q);

	//printf("\n bcubic %.4e\t%.4e\t%.4e\t%.4e ", AA[0], AA[1], AA[2], AA[3]);
	cubic(AA, z, &ncube);
	//printf("\n acubic %.4e\t%.4e\t%.4e ", z[0], z[1], z[2]);
	
	zsol = - 1.e99;
	for (i=0;i<ncube;i++)	zsol = max(zsol, z[i]);	//Not sure C has max fct
	z[0] =zsol;
	xK2 = 2.0*z[0] -p;
	xK = sqrt(xK2);
	xL = q/(2.0*xK);
	sqp = xK2 - 4.0 * (z[0] + xL);
	sqm = xK2 - 4.0 * (z[0] - xL);

	for (i=0;i<4;i++)	soli[i] = 0.0;
	if ( (sqp >= 0.0) && (sqm >= 0.0))
	{
		//printf("\n case 1 ");
		const double sq_sqp = sqrt(sqp);
		const double sq_sqm = sqrt(sqm);
		sol[0] = 0.5 * (xK + sq_sqp);
		sol[1] = 0.5 * (xK - sq_sqp);
		sol[2] = 0.5 * (-xK + sq_sqm);
		sol[3] = 0.5 * (-xK - sq_sqm);
		*Nsol = 4;
	}
	else if ( (sqp >= 0.0) && (sqm < 0.0))
	{
		//printf("\n case 2 ");
		const double sq_sqp = sqrt(sqp);
		const double sq_sqm = sqrt(-.25 * sqm);
		sol[0] = 0.5 * (xK + sq_sqp);
		sol[1] = 0.5 * (xK - sq_sqp);
		sol[2] = -0.5 * xK;
		sol[3] = -0.5 * xK;
		soli[2] =  sq_sqm;
		soli[3] = -sq_sqm;
		*Nsol = 2;
	}
	else if ( (sqp < 0.0) && (sqm >= 0.0))
	{
		//printf("\n case 3 ");
		const double sq_sqp = sqrt(-0.25 * sqp);
		const double sq_sqm = sqrt(sqm);
		sol[0] = 0.5 * (-xK + sq_sqm);
		sol[1] = 0.5 * (-xK - sq_sqm);
		sol[2] = 0.5 * xK;
		sol[3] = 0.5 * xK;
		soli[2] =  sq_sqp;
		soli[3] = -sq_sqp;
		*Nsol = 2;
	}
	else if ( (sqp < 0.0) && (sqm < 0.0))
	{
		//printf("\n case 4 ");
		const double sq_sqp = sqrt(-0.25 * sqp);
		const double sq_sqm = sqrt(-0.25 * sqm);
		sol[0] = -0.5 * xK;
		sol[1] = -0.5 * xK;
		soli[0] =  sq_sqm;
		soli[1] = -sq_sqm;
		sol[2] = 0.5 * xK;
		sol[3] = 0.5 * xK;
		soli[2] =  sq_sqp;
		soli[3] = -sq_sqp;
		*Nsol = 0;
	}
	
	for (i=0;i<4;i++)	sol[i] -= b/(4.0*a);
	return 0;
 }


 /*-------------------- Global Function Description Block ----------------------
  *
  *     ***CUBIC************************************************08.11.1986
  *     Solution of a cubic equation
  *     Equations of lesser degree are solved by the appropriate formulas.
  *     The solutions are arranged in ascending order.
  *     NO WARRANTY, ALWAYS TEST THIS SUBROUTINE AFTER DOWNLOADING
  *     ******************************************************************
  *     A(0:3)      (i)  vector containing the polynomial coefficients
  *     X(1:L)      (o)  results
  *     L           (o)  number of valid solutions (beginning with X(1))
  *     ==================================================================
  *  	17-Oct-2004 / Raoul Rausch
  *		Conversion from Fortran to C
  *
  *
  *-----------------------------------------------------------------------------
  */

int cubic(double A[4], double X[3], int* L)
{
	const double PI = 3.1415926535897932;
	const double THIRD = 1./3.;
	double U[3],W, P, Q, DIS, PHI;
	int i;

	//define cubic root as statement function
	// In C, the function is defined outside of the cubic fct

	// ====determine the degree of the polynomial ====

	if (A[3] != 0.0)
	{
		//cubic problem
		W = A[2]/A[3]*THIRD;
		P = pow((A[1]/A[3]*THIRD - (W*W)), 3);
		Q = -.5*(2.0*(W*W*W)-(A[1]*W-A[0])/A[3] );
		DIS = (Q*Q)+P;
		if ( DIS < 0.0 )
		{
			//three real solutions!
			//Confine the argument of ACOS to the interval [-1;1]!
			PHI = acos(min(1.0,max(-1.0,Q/sqrt(-P))));
			P=2.0*pow((-P),(5.e-1*THIRD));
			for (i=0;i<3;i++)	U[i] = P*cos((PHI+2*((double)i)*PI)*THIRD)-W;
			X[0] = min(U[0], min(U[1], U[2]));
			X[1] = max(min(U[0], U[1]),max( min(U[0], U[2]), min(U[1], U[2])));
			X[2] = max(U[0], max(U[1], U[2]));
			*L = 3;
		}
		else
		{
			// only one real solution!
			DIS = sqrt(DIS);
			X[0] = CBRT(Q+DIS)+CBRT(Q-DIS)-W;
			*L=1;
		}
	}
	else if (A[2] != 0.0)
	{
		// quadratic problem
		P = 0.5*A[1]/A[2];
		DIS = (P*P)-A[0]/A[2];
		if (DIS > 0.0)
		{
			// 2 real solutions
			const double sq_dis = sqrt(DIS);
			X[0] = -P - sq_dis;
			X[1] = -P + sq_dis;
			*L=2;
		}
		else
		{
			// no real solution
			*L=0;
		}
	}
	else if (A[1] != 0.0)
	{
		//linear equation
		X[0] =A[0]/A[1];
		*L=1;
	}
	else
	{
		//no equation
		*L=0;
	}
 //
 //     ==== perform one step of a newton iteration in order to minimize
 //          round-off errors ====
 //
	for (i=0;i<*L;i++)
	{
		X[i] = X[i] - (A[0]+X[i]*(A[1]+X[i]*(A[2]+X[i]*A[3])))/(A[1]+X[i]*(2.0*A[2]+X[i]*3.0*A[3]));
	//	printf("\n X inside cubic %.15e\n", X[i]);
	}

	return 0;
}


int signR(double Z)
{
	int ret = 0;
	if (Z > 0.0)	ret = 1;
	if (Z < 0.0)	ret = -1;
	//if (Z == 0.0)	ret =0;

	return ret;
}

double CBRT(double Z)
{
	double ret;
	const double THIRD = 1./3.;
	//define cubic root as statement function
	//SIGN has different meanings in both C and Fortran
	// Was unable to use the sign command of C, so wrote my own
	// that why a new variable needs to be introduced that keeps track of the sign of
	// SIGN is supposed to return a 1, -1 or 0 depending on what the sign of the argument is
	ret = fabs(pow(fabs(Z),THIRD)) * signR(Z);
	return ret;
}


//}  // namespace rpp
