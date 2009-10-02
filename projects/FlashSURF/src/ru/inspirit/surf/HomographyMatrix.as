package ru.inspirit.surf 
{
	import flash.geom.Matrix3D;
	import flash.geom.Point;

	/**
	 * Homography Matrix [3x3]
	 * used for projecting corresponding matches
	 * 
	 * @author Eugene Zatepyakin
	 */
	public class HomographyMatrix 
	{		
		public var m11:Number = 1;
		public var m12:Number = 0;
		public var m13:Number = 0;
		
		public var m21:Number = 0;
		public var m22:Number = 1;
		public var m23:Number = 0;
		
		public var m31:Number = 0;
		public var m32:Number = 0;
		public var m33:Number = 1;
		
		public function HomographyMatrix(data:Vector.<Number> = null)
		{
			if(data)
			{
				m11 = data[0];
				m12 = data[1];
				m13 = data[2];
				m21 = data[3];
				m22 = data[4];
				m23 = data[5];
				m31 = data[6];
				m32 = data[7];
				m33 = data[8];
			}
		}
		
		public function identity():void
		{
			m11 = m22 = m33 = 1;
			m12 = m13 = m21 = m23 = m31 = m32 = 0;
		}
		
		public function projectPoint(point:Point):Point
		{
			var x:Number = point.x;
			var y:Number = point.y;
			var Z:Number = 1 / (m31 * x + m32 * y + m33);
			point.x = (m11*x + m12*y + m13) * Z;
			point.y = (m21*x + m22*y + m23) * Z;
			return point;			
		}
		
		public function scale(value:Number):void
		{
			m11 *= value;
			m12 *= value;
			m13 *= value;
			m21 *= value;
			m22 *= value;
			m23 *= value;
			//m31 *= value;
			//m32 *= value;
			//m33 *= value;
		}
		
		// not working ?
		// gram-schmidt ortho-norm
		public function getCameraFromWorld():Matrix3D
		{
			var mag:Number = 1 / Math.sqrt( m11*m11 + m21*m21 + m31*m31 );
			
			var data:Vector.<Number> = Vector.<Number>([ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 ]);
			
			// translation
			data[12] = m13 * mag;
			data[13] = m23 * mag;
			data[14] = m33 * mag;
			
			// rotation x
			data[0] = m11 * mag;
			data[4] = m21 * mag;
			data[8] = m31 * mag;
			
			// rotation y
			data[1] = m12 * mag - data[0] * data[0] * (m12*mag);
			data[5] = m22 * mag - data[4] * data[4] * (m22*mag);
			data[9] = m32 * mag - data[8] * data[8] * (m32*mag);
			
			// normalize
			mag = 1 / Math.sqrt( data[1]*data[1] + data[5]*data[5] + data[9]*data[9] );
			data[1] *= mag;
			data[5] *= mag;
			data[9] *= mag;
			
			// rotation z
			// cross product x^y (or may be wedge ?)
			data[2] =  data[4]*data[9] - data[5]*data[8];
			data[6] =  data[8]*data[1] - data[9]*data[0];
			data[10] = data[0]*data[5] - data[1]*data[4];
			
			var mat:Matrix3D = new Matrix3D(data);
			return mat;
		}

		public function transpose():void
		{
			var _m21:Number = m21;
			var _m31:Number = m31;
			
			var _m12:Number = m12;
			//var _m22:Number = m22;
			var _m32:Number = m32;
			
			var _m13:Number = m13;
			var _m23:Number = m23;
			//var _m33:Number = m33;
			
			m12 = _m21;
			m13 = _m31;
			m21 = _m12;
			//m22 = _m22;
			m23 = _m32;
			m31 = _m13;
			m32 = _m23;
			//m33 = _m33;
		}
		
		public function multiply(mat:HomographyMatrix):HomographyMatrix
		{			
			return new HomographyMatrix(Vector.<Number>([ 
				m11 * mat.m11 + m12*mat.m21 + m13*mat.m31, m11*mat.m12 + m12*mat.m22 + m13*mat.m32, m11*mat.m13 + m12*mat.m23 + m13*mat.m33,
				m21 * mat.m11 + m22*mat.m21 + m23*mat.m31, m21*mat.m12 + m22*mat.m22 + m23*mat.m32, m21*mat.m13 + m22*mat.m23 + m23*mat.m33,
				m31 * mat.m11 + m32*mat.m21 + m33*mat.m31, m31*mat.m12 + m32*mat.m22 + m33*mat.m32, m31*mat.m13 + m32*mat.m23 + m33*mat.m33
				 ]));
		}

		public function invert(invertedMatrix:HomographyMatrix):Boolean
		{
			var det:Number = m11 * (m22*m33 - m23*m32) - m12 * (m21*m33 - m23*m31) + m13 * (m21*m32 - m22*m31);
			
			if(det == 0) return false;
			
			det = 1 / det;
			
			invertedMatrix.m11 = det * (m22*m33 - m23*m32);
			invertedMatrix.m12 = det * (m13*m32 - m12*m33);
			invertedMatrix.m13 = det * (m12*m23 - m13*m22);
			
			invertedMatrix.m21 = det * (m23*m31 - m21*m33);
			invertedMatrix.m22 = det * (m11*m33 - m13*m31);
			invertedMatrix.m23 = det * (m13*m21 - m11*m23);
			
			invertedMatrix.m31 = det * (m21*m32 - m22*m31);
			invertedMatrix.m32 = det * (m12*m31 - m11*m32);
			invertedMatrix.m33 = det * (m11*m22 - m12*m21);
			
			return true;
		}
		
		public function clone():HomographyMatrix
		{
			return new HomographyMatrix( Vector.<Number>([ m11, m12, m13, m21, m22, m23, m31, m32, m33 ]) );
		}
	}
}
