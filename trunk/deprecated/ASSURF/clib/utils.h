#ifndef _UTILS_H_
#define _UTILS_H_

#define OCTAVES 4
#define INTERVALS 4
#define INIT_SAMPLE 2
#define THRESHOLD 0.004
#define MAXPOINTS 200
#define POINTS_POOL 30000
#define POINT_DATA_LENGTH 69
#define POINT_MATCH_FACTOR 0.55

static const double pi = 3.14159;
static const double two_pi = 6.28318;
static const double pi_on_three = 1.04719667;

static const double INLIER_THRESHOLD_SQ = 30;
static const double PROBABILITY_REQUIRED = 0.99;
static const double SQRT2 = 1.4142135623730951;

inline int IMIN(register int a, register int b)
{
	return (((a) < (b)) ? (a) : (b));
}

inline double FMAX(register double a, register double b)
{
	return (((a) < (b)) ? (b) : (a));
}

inline double IGAUSSIAN(register int x, register int y, register double sig)
{
	return ((1.0 / (two_pi*sig*sig) * exp( -(x*x+y*y) / (2.0*sig*sig))));
}
inline double FGAUSSIAN(register double x, register double y, register double sig)
{
	return ((1.0 / (two_pi*sig*sig) * exp( -(x*x+y*y) / (2.0*sig*sig))));
}

inline double ANGLE(register double X, register double Y)
{
	if(X > 0 && Y >= 0) return atan(Y/X);

	if(X < 0 && Y >= 0) return pi - atan(-Y/X);

	if(X < 0 && Y < 0) return pi + atan(Y/X);

	if(X > 0 && Y < 0) return two_pi - atan(-Y/X);

	return 0.0;
}

inline int dRound(register double dbl)
{
	return (int) (dbl+0.5);
}

inline double dSquare(register double dbl)
{
	return (dbl * dbl);
}

inline double SIGN(register double a, register double b)
{
	return ((b) >= 0 ? fabs(a) : -fabs(a));
}

inline double PYTHAG(register double a, register double b)
{
	register double absa, absb;
	absa = fabs(a);
	absb = fabs(b);

	if(absa > absb) {
		return absa * sqrt(1.0 + dSquare(absb/absa));
	} else {
		return (absb == 0.0) ? 0.0 : absb * sqrt(1.0 + dSquare(absa/absb));
	}
}

#endif
