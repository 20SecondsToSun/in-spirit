package ru.inspirit.image.mem
{
	import apparat.asm.*;
	import apparat.inline.Macro;
	import apparat.math.FastMath;
	import apparat.memory.Memory;

	/**
	 * @author Eugene Zatepyakin
	 */
	public final class MemImageMacro extends Macro
	{	
		public static function fillUCharBuffer(ptr:int, img:Vector.<uint>):void
		{
			var i:int = 0;
			var n:int = img.length;
			var bit32:int = (n >> 6) + 1;
			
			__asm(
				'loop:',
				DecLocalInt(bit32),
				GetLocal(bit32),
				PushByte(0),
				IfEqual('endLoop')
				);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					//
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					//
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					//
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					//
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					//
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					//
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					//
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
					MemImageMacro.fillUCharPass(ptr, i, img);
			__asm(
				Jump('loop'),
				'endLoop:'
				);
			__asm(
				'loop1:',
				GetLocal(i),
				GetLocal(n),
				IfEqual('endLoop1')
				);
					MemImageMacro.fillUCharPass(ptr, i, img);
			__asm(
				Jump('loop1'),
				'endLoop1:'
			);
		}
		
		public static function fillIntBuffer(ptr:int, img:Vector.<uint>):void
		{
			var i:int = 0;
			var n:int = img.length;
			var bit32:int = (n >> 5) + 1;
			
			__asm(
				'loop:',
				DecLocalInt(bit32),
				GetLocal(bit32),
				PushByte(0),
				IfEqual('endLoop')
				);
					MemImageMacro.fillIntPass(ptr, i, img);
					MemImageMacro.fillIntPass(ptr, i, img);
					MemImageMacro.fillIntPass(ptr, i, img);
					MemImageMacro.fillIntPass(ptr, i, img);
					MemImageMacro.fillIntPass(ptr, i, img);
					MemImageMacro.fillIntPass(ptr, i, img);
					MemImageMacro.fillIntPass(ptr, i, img);
					MemImageMacro.fillIntPass(ptr, i, img);
					//
					MemImageMacro.fillIntPass(ptr, i, img);
					MemImageMacro.fillIntPass(ptr, i, img);
					MemImageMacro.fillIntPass(ptr, i, img);
					MemImageMacro.fillIntPass(ptr, i, img);
					MemImageMacro.fillIntPass(ptr, i, img);
					MemImageMacro.fillIntPass(ptr, i, img);
					MemImageMacro.fillIntPass(ptr, i, img);
					MemImageMacro.fillIntPass(ptr, i, img);
					//
					MemImageMacro.fillIntPass(ptr, i, img);
					MemImageMacro.fillIntPass(ptr, i, img);
					MemImageMacro.fillIntPass(ptr, i, img);
					MemImageMacro.fillIntPass(ptr, i, img);
					MemImageMacro.fillIntPass(ptr, i, img);
					MemImageMacro.fillIntPass(ptr, i, img);
					MemImageMacro.fillIntPass(ptr, i, img);
					MemImageMacro.fillIntPass(ptr, i, img);
					//
					MemImageMacro.fillIntPass(ptr, i, img);
					MemImageMacro.fillIntPass(ptr, i, img);
					MemImageMacro.fillIntPass(ptr, i, img);
					MemImageMacro.fillIntPass(ptr, i, img);
					MemImageMacro.fillIntPass(ptr, i, img);
					MemImageMacro.fillIntPass(ptr, i, img);
					MemImageMacro.fillIntPass(ptr, i, img);
					MemImageMacro.fillIntPass(ptr, i, img);
			__asm(
				Jump('loop'),
				'endLoop:'
				);
			__asm(
				'loop1:',
				GetLocal(i),
				GetLocal(n),
				IfEqual('endLoop1')
				);
					MemImageMacro.fillIntPass(ptr, i, img);
			__asm(
				Jump('loop1'),
				'endLoop1:'
			);
		}
		
		public static function computeIntegralImage(srcPtr:int, dstPtr:int, w:int, h:int):void
		{
			var rowI:int = srcPtr;
			var rowII:int = dstPtr;
			var sum:int = 0;
			var i:int = __cint(w + 1);
			var j:int;
			
			__asm(
				'loop:',
				DecLocalInt(i),
				GetLocal(i),
				PushByte(0),
				IfEqual('endLoop') );
			//	
			__asm( GetLocal(sum),GetLocal(rowI),GetByte,AddInt,SetLocal(sum),GetLocal(sum),GetLocal(rowII),SetInt );
			__asm( IncLocalInt( rowI ), GetLocal( rowII ), PushByte( 4 ), AddInt, SetLocal(rowII));
			//
			__asm(
				Jump('loop'),
				'endLoop:'
				);
			// 

			var prowII:int = dstPtr;
			for( i = 1; i < h; )
			{
				sum = 0;
				for(j = 0; j < w; )
				{
					__asm( GetLocal(sum),GetLocal(rowI),GetByte,AddInt,SetLocal(sum),
							GetLocal(prowII),GetInt,GetLocal(sum),AddInt,GetLocal(rowII),SetInt );
					__asm( IncLocalInt(j),IncLocalInt(rowI) );
					__asm( GetLocal( rowII ), PushByte( 4 ), AddInt, SetLocal(rowII) );
					__asm( GetLocal( prowII ), PushByte( 4 ), AddInt, SetLocal(prowII) );
				}
				__asm( IncLocalInt(i) );
			}
		}
		
		public static function pyrDown(fromPtr:int, toPtr:int, newW:int, newH:int):void
		{
			var i:int;
			var ow:int = newW << 1;
			var out:int = toPtr;
			var rem:int = (newW >> 5) + 1;
			var tail:int = (newW % 32) + 1;
			var br:int;
			
			var row0:int = fromPtr;
			var row1:int = row0 + ow;

			for(i = 0; i < newH; ++i)
			{
				
				br = rem;
				__asm(
					'loop:',
					DecLocalInt(br),
					GetLocal(br),
					PushByte(0),
					IfEqual('endLoop')
					);
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
					//
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
					MemImageMacro.pyrPass(row0, row1, out);
				__asm(
					Jump('loop'),
					'endLoop:'
				);
				// finish
				br = tail;
				__asm(
					'loop1:',
					DecLocalInt(br),
					GetLocal(br),
					PushByte(0),
					IfEqual('endLoop1')
					);
					MemImageMacro.pyrPass(row0, row1, out);
				__asm(
					Jump('loop1'),
					'endLoop1:'
					);
					
				row0 += ow;
				row1 = row0 + ow;
			}
		}
		
		public static function bilinearInterpolation(imgPtr:int, stride:int, x:Number, y:Number, val:Number):void
		{
			var mnx:int = x;
			var mny:int = y;
			var mxx:int = FastMath.rint( x + 0.4999 );
			var mxy:int = FastMath.rint( y + 0.4999 );
			
			var alfa:Number = mxx - x;
			var beta:Number = mxy - y;
			
			if( alfa < 0.001 ) alfa = 0;
			if( beta < 0.001 ) beta = 0;
			
			var mnyw:int = mny * stride;
			var mxyw:int = mxy * stride;	
			
			if( alfa < 0.001 ) 
			{
				val = (beta * Memory.readUnsignedByte(imgPtr + mnyw+mxx) + (1.0-beta) * Memory.readUnsignedByte(imgPtr + mxyw+mxx));						
			}
			else if( alfa > 0.999 )
			{
				val = (beta * Memory.readUnsignedByte(imgPtr + mnyw+mnx) + (1.0-beta) * Memory.readUnsignedByte(imgPtr + mxyw+mnx));
			}
			else if( beta < 0.001 )
			{
				val = (alfa * Memory.readUnsignedByte(imgPtr + mxyw+mnx) + (1.0-alfa) * Memory.readUnsignedByte(imgPtr + mxyw+mxx));
			}
			else if( beta > 0.999 )
			{
				val = (alfa * Memory.readUnsignedByte(imgPtr + mnyw+mnx) + (1.0-alfa) * Memory.readUnsignedByte(imgPtr + mnyw+mxx));
			}
			else
			{
				val = (beta * (alfa * Memory.readUnsignedByte(imgPtr + mnyw+mnx) + (1.0-alfa) *  Memory.readUnsignedByte(imgPtr + mnyw+mxx))
					+ (1.0-beta) * (alfa * Memory.readUnsignedByte(imgPtr + mxyw+mnx) + (1.0-alfa) * Memory.readUnsignedByte(imgPtr + mxyw+mxx)));
			}
		}
		
		internal static function fillUCharPass(ptr:int, i:int, img:Vector.<uint>):void
		{
			__asm(
				GetLocal(img),
				GetLocal(i),
				GetProperty(AbcMultinameL(AbcNamespaceSet(AbcNamespace(NamespaceKind.PACKAGE, "")))),
				ConvertInt,
				GetLocal(ptr),
				SetByte,
				IncLocalInt(i),
				IncLocalInt(ptr)
			);
		}
		internal static function fillIntPass(ptr:int, i:int, img:Vector.<uint>):void
		{
			__asm(
				GetLocal(img),
				GetLocal(i),
				GetProperty(AbcMultinameL(AbcNamespaceSet(AbcNamespace(NamespaceKind.PACKAGE, "")))),
				ConvertInt,
				GetLocal(ptr),
				SetInt,
				IncLocalInt(i),
				GetLocal(ptr),
				PushByte(4),
				AddInt,
				SetLocal(ptr)
			);
		}
		
		internal static function pyrPass(row0:int, row1:int, out:int):void
		{
			__asm(
				GetLocal(row0),
				GetByte,
				IncLocalInt(row0),
				GetLocal(row0),
				GetByte,
				AddInt,				
				GetLocal(row1),
				GetByte,
				AddInt,
				IncLocalInt(row1),
				GetLocal(row1),
				GetByte,
				AddInt,
				PushByte(2),
				ShiftRight, 
				GetLocal( out ), 
				SetByte,
				IncLocalInt(out),
				IncLocalInt(row0),
				IncLocalInt(row1)
			);
		}
	}
}
