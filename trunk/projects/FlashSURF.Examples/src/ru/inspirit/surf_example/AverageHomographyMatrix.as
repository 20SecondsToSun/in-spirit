package ru.inspirit.surf_example 
{
	import ru.inspirit.surf.HomographyMatrix;

	/**
	 * Helper class to get average value of several Homography matrices
	 * you can specify how many matrices will be used
	 * 
	 * @author Eugene Zatepyakin
	 */
	public class AverageHomographyMatrix extends HomographyMatrix 
	{
		public static var maxLength:int = 3;
		
		public var matrices:Vector.<HomographyMatrix>;
		public var lastIndex:int;
		
		public function AverageHomographyMatrix(data:Vector.<Number> = null) 
		{
			super(data);
			
			lastIndex = 0;
			matrices = new Vector.<HomographyMatrix>();
		}

		public function addMatrix(matrix:HomographyMatrix):void 
		{
			matrices[lastIndex] = matrix;
			var n:int = matrices.length;
			var m:HomographyMatrix;
			
			m11 = m22 = m33 = m12 = m13 = m21 = m23 = m31 = m32 = 0;
			
			for(var i:int = 0; i < n; ++i) 
			{
				m = matrices[i];
				
				m11 += m.m11;
				m12 += m.m12;
				m13 += m.m13;
				m21 += m.m21;
				m22 += m.m22;
				m23 += m.m23;
				m31 += m.m31;
				m32 += m.m32;
				m33 += m.m33;
			}
			
			var invDel:Number = 1 / n;
			m11 *= invDel;
			m12 *= invDel;
			m13 *= invDel;
			m21 *= invDel;
			m22 *= invDel;
			m23 *= invDel;
			m31 *= invDel;
			m32 *= invDel;
			m33 *= invDel;
			
			lastIndex = ++lastIndex % maxLength;
		}
	}
}
