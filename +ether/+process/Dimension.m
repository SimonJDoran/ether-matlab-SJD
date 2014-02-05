classdef Dimension < ether.Cloneable
	%DIMENSION Summary of this class goes here
	%   Detailed explanation goes here
	
	properties(SetAccess=private)
		labels = {};
		values = {};
		units = {};
		nLevels = 0;
		length = 0;
	end
	
	methods
		%-------------------------------------------------------------------------
		function this = Dimension(values, varargin)
			this.nLevels = numel(values);
			varLength = cellfun(@(x) numel(x), values);
			if ~(all(varLength == varLength(1)))
				throw(MException('Ether:Process:Dimension', ...
					'All levels of Dimension must have the same number of values'));
			end
			nVarArgs = numel(varargin);
			if nVarArgs == 1
				labelsIn = varargin{1};
				unitsIn = [];
			elseif nVarArgs == 2
				labelsIn = varargin{1};
				unitsIn = varargin{2};
			else
				throw(MException('Ether:Process:Dimension',...
					'Invalid number of input arguments'));
			end
			if numel(labelsIn) ~= this.nLevels
				labelsIn = repmat(cellstr(''), this.nLevels, 1);
			end
			if numel(unitsIn) ~= this.nLevels
				unitsIn = repmat(cellstr(''), this.nLevels, 1);
			end
			this.length = varLength(1);
			this.values = values;
			this.labels = labelsIn;
			this.units = unitsIn;
		end

		%-------------------------------------------------------------------------
		function dim = clone(this)
			dim = ether.process.Dimension(this.values, this.labels, this.units);
		end

		%-------------------------------------------------------------------------
		function result = getValues(this)
			result = this.values{1};
		end

		%-------------------------------------------------------------------------
		function result = getValuesForLevel(this, idx)
			result = this.values{idx};
		end
	end
	
end

