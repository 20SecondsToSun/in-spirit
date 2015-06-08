_More info is coming_...

## Usage ##
**SVD**
```
/**
* A - input matrix
* m - num of rows
* n - num of cols
**/
decompose(A:Vector.<Number>, m:int, n:int):void;

/**
* inv - output inverted matrix
* mtx - input matrix
* m - num of rows
* n - num of cols
**/
pseudoInverse(inv:Vector.<Number>, mtx:Vector.<Number>, m:int, n:int):void;

/**
* A - input matrix
* m - num of rows
* n - num of cols
* x - result vector
* B - input matrix
**/
solve(A:Vector.<Number>, m:int, n:int, x:Vector.<Number>, B:Vector.<Number>):void;

// Decomposed data can be accessed
svdInstance.W // singular values vector
svdInstance.U // m x n matrix whose columns are orthogonal
svdInstance.V // n x n orthogonal matrix
```

**Polynomial**

```
/**
* Solves quartics of the form x^4 + Ax^3 + Bx^2 + Cx + D ==0
* return number of found roots
**/
solveQuartic(a:Number, b:Number, c:Number, d:Number, result:Vector.<Number>):int;
solveQuarticNeumark(a:Number, b:Number, c:Number, d:Number, result:Vector.<Number>):int;
solveQuarticDescartes(a:Number, b:Number, c:Number, d:Number, result:Vector.<Number>):int;
solveQuarticFerrari(a:Number, b:Number, c:Number, d:Number, result:Vector.<Number>):int;

/**
* Solving cubics like x^3 + Ax^2 + Bx + C == 0
**/
solveCubic(a:Number, b:Number, c:Number, result:Vector.<Number>):int;

/**
* refine cubic root value
**/
cubicNewtonRootPolish(p:Number, q:Number, r:Number, root:Number, iterations:int):Number;

/**
* Estimate max error of result
**/
quarticError(a:Number, b:Number, c:Number, d:Number, roots:Vector.<Number>, rootCount:int):Number;

// experimental (probably faster)
solveCubic2(p:Number, q:Number, r:Number, result:Vector.<Number>):int;

/**
* Solve a quadratic of the form Ax^2 + Bx + C == 0
**/
solveQuadratic(a:Number, b:Number, c:Number, result:Vector.<Number>):int;
```

## Download ##
[Download SWC lib](http://in-spirit.googlecode.com/files/linalg.zip)