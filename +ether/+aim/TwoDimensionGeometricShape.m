classdef (Abstract) TwoDimensionGeometricShape < ether.aim.GeometricShape
	%TWODIMENSIONGEOMETRICSHAPE Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
		imageReferenceUid = '';
		referencedFrameNumber = 0;
	end

	properties(Access=protected)
		coords = [];
	end
	
	methods
		function this = TwoDimensionGeometricShape()
			this.coords = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
		end

		function coords = getTwoDCoordinateArray(this)
			coords = [];
			objCoords = this.getTwoDCoordinates();
			if isempty(objCoords)
				return;
			end
			coords = arrayfun(@(c) [c.x;c.y], objCoords, 'UniformOutput', false);
			coords = [coords{:}]';
		end

		function coords = getTwoDCoordinates(this)
			coords = [];
			if this.coords.length == 0
				return;
			end
			% Guarantee key ordering
			coords = this.coords.values(this.coords.keys);
			coords = [coords{:}];
		end

		%-------------------------------------------------------------------------
		function bool = addTwoDCoordinate(this, coord)
			bool = false;
			if ~isa(coord, 'ether.aim.TwoDimensionCoordinate')
				return;
			end
			this.coords(coord.index) = coord;
			bool = true;
		end

		%-------------------------------------------------------------------------
		function coord = removeTwoDCoordinate(this, idx)
			coord = [];
			if ~this.coords.isKey(idx)
				return;
			end
			coord = this.coords(idx);
			this.coords.remove(idx);
		end

	end
	
end

