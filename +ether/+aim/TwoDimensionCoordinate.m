classdef TwoDimensionCoordinate < handle
	%TWODIMENSIONCOORDINATE Summary of this class goes here
	%   Detailed explanation goes here
	
	properties(SetAccess=private)
		index = uint32(0);
		x = 0;
		y = 0;
	end
	
	methods
		function this = TwoDimensionCoordinate(index, x, y)
			if ~(isinteger(index) && isfloat(x) && isfloat(y))
				me = MException('Ether:AIM:InvalidCoordinate', ...
					'Invalid coordinate supplied');
				throw(me);
			end
			this.index = uint32(index);
			this.x = x;
			this.y = y;
		end
	end
	
end

