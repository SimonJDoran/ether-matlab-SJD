classdef TwoDimensionPolyline < ether.aim.TwoDimensionGeometricShape
	%TWODIMENSIONPOLYLINE Summary of this class goes here
	%   Detailed explanation goes here

	properties
	end

	methods
		function this = TwoDimensionPolyline(j2dShape)
			this = this@ether.aim.TwoDimensionGeometricShape(j2dShape);
		end
	end

end

