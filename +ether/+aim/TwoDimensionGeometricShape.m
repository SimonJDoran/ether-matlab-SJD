classdef (Abstract) TwoDimensionGeometricShape < ether.aim.GeometricShape
	%TWODIMENSIONGEOMETRICSHAPE Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
		imageReferenceUid = '';
		referencedFrameNumber = 0;
	end

	properties(Dependent)
		coordCount;
	end

	properties(Access=protected)
		coords = [];
		java2dShape = [];
	end

	methods
		function this = TwoDimensionGeometricShape(j2dShape)
			this.coords = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
			if ((numel(j2dShape) ~= 1) || ...
				 ~isa(j2dShape, 'etherj.aim.TwoDimensionGeometricShape'))
				return;
			end
			this.java2dShape = j2dShape;
			this.uniqueIdentifier = char(j2dShape.getUid());
			this.description = char(j2dShape.getDescription());
			this.label = char(j2dShape.getLabel());
			this.lineColour = char(j2dShape.getLineColour());
			this.includeFlag = j2dShape.getIncludeFlag();
			this.shapeIdentifier = j2dShape.getShapeId();
			this.imageReferenceUid = char(j2dShape.getImageReferenceUid());
			this.referencedFrameNumber = j2dShape.getReferencedFrameNumber();
			jCoords = j2dShape.getCoordinateList();
			for i=0:jCoords.size()-1
				jCoord = jCoords.get(i);
				coord = ether.aim.TwoDimensionCoordinate(uint32(jCoord.getIndex()), ...
					jCoord.getX(), jCoord.getY());
				this.coords(coord.index) = coord;
			end
		end

		function value = get.coordCount(this)
			value = this.coords.length;
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
		function [bool,message] = addTwoDCoordinate(this, coord)
			bool = false;
			message = '';
			if ~isempty(this.java2dShape)
				message = 'TwoDimensionGeometricShape is read-only as it is wrapping a Java object';
				return;
			end
			if ~isa(coord, 'ether.aim.TwoDimensionCoordinate')
				return;
			end
			this.coords(coord.index) = coord;
			bool = true;
		end

		%-------------------------------------------------------------------------
		function [coord,message] = removeTwoDCoordinate(this, idx)
			coord = [];
			message = '';
			if ~isempty(this.java2dShape)
				message = 'TwoDimensionGeometricShape is read-only as it is wrapping a Java object';
				return;
			end
			if ~this.coords.isKey(idx)
				return;
			end
			coord = this.coords(idx);
			this.coords.remove(idx);
		end

	end
	
end

