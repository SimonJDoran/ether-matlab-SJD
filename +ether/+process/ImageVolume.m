classdef ImageVolume < ether.process.Node
	%IMAGEVOLUMENODE Summary of this class goes here
	%   Detailed explanation goes here

	properties
		dimensions = [];
		displayMax = 0;
		displayMin = 0;
		pixelDepth = 0;
		pixelHeight = 0;
		pixelWidth = 0;
		pixelData = [];
		valueType = '';
	end

	properties(Access=private)
		isDirty = false;
	end

	methods
		%-------------------------------------------------------------------------
		function this = ImageVolume(id)
			this@ether.process.Node(id);
			this.label = sprintf('ImageVolume %i', id);
		end

		%-------------------------------------------------------------------------
		function bool = hasValidDisplayLimits(this)
			bool = ((this.displayMax ~= 0) || ...
					  (this.displayMin ~= 0)) && ...
					 (this.displayMax > this.displayMin);
		end

	end

end

