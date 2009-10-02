package
{
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	/**
     * Tesselates an area into several triangles to allow free transform distortion on BitmapData objects.
     * 
     * @author        Thomas Pfeiffer (aka kiroukou)
     *                 kiroukou@gmail.com
     *                 www.flashsandy.org
     * 
     * The original Actionscript2.0 version of the class was written by Thomas Pfeiffer (aka kiroukou),
     *   inspired by Andre Michelle (andre-michelle.com).
     * 
     * 
     * Copyright (c) 2005 Thomas PFEIFFER. All rights reserved.
     * 
     * Licensed under the CREATIVE COMMONS Attribution-NonCommercial-ShareAlike 2.0 you may not use this
     *   file except in compliance with the License. You may obtain a copy of the License at:
     *   http://creativecommons.org/licenses/by-nc-sa/2.0/fr/deed.en_GB
     *   
     *   @author Eugene Zatepyakin 
     *   (small refactoring to add performance. Idealy it should be rewritten using drawTrinagles() method)
     * 
     */
	

	public class DistortImage 
	{

		protected var _sMat:Matrix, _tMat:Matrix;
		protected var _xMin:Number, _xMax:Number, _yMin:Number, _yMax:Number;
		protected var _hseg:uint, _vseg:uint;
		protected var _hsLen:Number, _vsLen:Number;
		protected var _p:Vector.<TrianglePoint>;
		protected var _tri:Vector.<Triangle>;
		protected var _w:Number, _h:Number;

		public var smoothing:Boolean = true;


		/**
		 * Constructor.
		 *
		 * @param	w		Width of the image to be processed
		 * @param	h		Height of image to be processed
		 * @param	hseg	Horizontal precision
		 * @param	vseg	Vertical precision
		 *
		 */
		public function DistortImage(w:Number, h:Number, hseg:uint=2, vseg:uint=2):void 
		{
			_w = w;
			_h = h;
			_vseg = vseg;
			_hseg = hseg;
			_init();
		}


		/**
		 * Tesselates the area into triangles.
		 */
		protected function _init():void 
		{
			_p = new Vector.<TrianglePoint>((_vseg + 2)*(_hseg + 2), true);
			_tri = new Vector.<Triangle>(((_vseg + 1)*(_hseg + 1))*2, true);
			_xMin = _yMin = 0;
			_xMax = _w; _yMax = _h;
			_hsLen = _w / ( _hseg + 1 );
			_vsLen = _h / ( _vseg + 1 );
			var ind:int = 0;
			var ix:int;
			var iy:int;
			// create points:
			for ( ix = 0; ix < _vseg + 2; ++ix )
			{
				for ( iy = 0; iy < _hseg + 2; ++iy, ++ind )
				{
					_p[ind] = new TrianglePoint(ix * _hsLen, iy * _vsLen);
				}
			}
			// create triangles:
			ind = 0;
			for ( ix = 0; ix < _vseg + 1; ++ix )
			{
				for ( iy = 0; iy < _hseg + 1; ++iy )
				{
					_tri[ind++] = new Triangle( _p[ int(iy + ix * ( _hseg + 2 )) ], _p[ int(iy + ix * ( _hseg + 2 ) + 1) ], _p[ int(iy + ( ix + 1 ) * ( _hseg + 2 )) ] );
					_tri[ind++] = new Triangle( _p[ int(iy + ( ix + 1 ) * ( _hseg + 2 ) + 1) ], _p[ int(iy + ( ix + 1 ) * ( _hseg + 2 )) ], _p[ int(iy + ix * ( _hseg + 2 ) + 1) ] );
				}
			}
		}


		/**
		 * Distorts the provided BitmapData according to the provided Point instances and draws it onto the provided Graphics.
		 *
		 * @param	graphics	Graphics on which to draw the distorted BitmapData
		 * @param	bmd			The undistorted BitmapData
		 * @param	tl			Point specifying the coordinates of the top-left corner of the distortion
		 * @param	tr			Point specifying the coordinates of the top-right corner of the distortion
		 * @param	br			Point specifying the coordinates of the bottom-right corner of the distortion
		 * @param	bl			Point specifying the coordinates of the bottom-left corner of the distortion
		 *
		 */
		public function setTransform(graphics:Graphics, bmd:BitmapData, tl:Point, tr:Point, br:Point, bl:Point):void 
		{

			var dx30:Number = bl.x - tl.x;
			var dy30:Number = bl.y - tl.y;
			var dx21:Number = br.x - tr.x;
			var dy21:Number = br.y - tr.y;
			var l:Number = _p.length;
			var iw:Number = 1 / _w;
			var ih:Number = 1 / _h;
			while( --l > -1 )
			{
				var point:TrianglePoint = _p[ l ];
				var gx:Number = ( point.x - _xMin ) * iw;
				var gy:Number = ( point.y - _yMin ) * ih;
				var bx:Number = tl.x + gy * ( dx30 );
				var by:Number = tl.y + gy * ( dy30 );
				point.sx = bx + gx * ( ( tr.x + gy * ( dx21 ) ) - bx );
				point.sy = by + gx * ( ( tr.y + gy * ( dy21 ) ) - by );
			}
			_render(graphics, bmd);
		}

		protected function _render(graphics:Graphics, bmd:BitmapData):void 
		{
			var p0:TrianglePoint, p1:TrianglePoint, p2:TrianglePoint;
			_sMat = new Matrix();
			_tMat = new Matrix();
			var l:Number = _tri.length;
			var iw:Number = 1 / _w;
			var ih:Number = 1 / _h;
			while( --l > -1 ){
				p0 = _tri[ l ].p0;
				p1 = _tri[ l ].p1;
				p2 = _tri[ l ].p2;
				var x0: Number = p0.sx;
				var y0: Number = p0.sy;
				var x1: Number = p1.sx;
				var y1: Number = p1.sy;
				var x2: Number = p2.sx;
				var y2: Number = p2.sy;
				var u0: Number = p0.x;
				var v0: Number = p0.y;
				var u1: Number = p1.x;
				var v1: Number = p1.y;
				var u2: Number = p2.x;
				var v2: Number = p2.y;
				_tMat.tx = u0;
				_tMat.ty = v0;
				_tMat.a = ( u1 - u0 ) * iw;
				_tMat.b = ( v1 - v0 ) * iw;
				_tMat.c = ( u2 - u0 ) * ih;
				_tMat.d = ( v2 - v0 ) * ih;
				_sMat.a = ( x1 - x0 ) * iw;
				_sMat.b = ( y1 - y0 ) * iw;
				_sMat.c = ( x2 - x0 ) * ih;
				_sMat.d = ( y2 - y0 ) * ih;
				_sMat.tx = x0;
				_sMat.ty = y0;
				_tMat.invert();
				_tMat.concat( _sMat );
				// draw:
				graphics.beginBitmapFill( bmd, _tMat, false, smoothing );
				graphics.moveTo( x0, y0 );
				graphics.lineTo( x1, y1 );
				graphics.lineTo( x2, y2 );
				graphics.endFill();
			}
		}


		/**
		 * Sets the size of this DistortImage instance and re-initializes the triangular grid.
		 *
		 * @param	width	New width.
		 * @param	height	New height.
		 */
		public function setSize (width:Number, height:Number):void {
			this._w = width;
			this._h = height;
			this._init();
		}
		/**
		 * Sets the precision of this DistortImage instance and re-initializes the triangular grid.
		 *
		 * @param	horizontal	New horizontal precision.
		 * @param	vertical	New vertical precision.
		 */
		public function setPrecision (horizontal:Number, vertical:Number):void {
			this._hseg = horizontal;
			this._vseg = vertical;
			this._init();
		}
		/**
		 * Width of this DistortImage instance. Property can only be set through the class constructor.
		 */
		public function get width ():Number {
			return _w;
		}
		/**
		 * Height of this DistortImage instance. Property can only be set through the class constructor.
		 */
		public function get height ():Number {
			return _h;
		}
		/**
		 * Horizontal precision of this DistortImage instance. Property can only be set through the class constructor.
		 */
		public function get hPrecision ():uint {
			return _hseg;
		}
		/**
		 * Vertical precision of this DistortImage instance. Property can only be set through the class constructor.
		 */
		public function get vPrecision ():uint {
			return _vseg;
		}


	}
}

internal class TrianglePoint
{
	public var x:Number;
	public var y:Number;
	public var sx:Number;
	public var sy:Number;
	
	public function TrianglePoint(x:Number = 0, y:Number = 0)
	{
		this.x = x;
		this.y = y;
		this.sx = x;
		this.sy = y;
	}
}

internal class Triangle
{
	public var p0:TrianglePoint;
	public var p1:TrianglePoint;
	public var p2:TrianglePoint;
	
	public function Triangle(p0:TrianglePoint, p1:TrianglePoint, p2:TrianglePoint)
	{
		this.p0 = p0;
		this.p1 = p1;
		this.p2 = p2;
	}
}