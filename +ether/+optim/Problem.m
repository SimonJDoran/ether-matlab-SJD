classdef (Abstract) Problem < handle
	%PROBLEM Summary of this class goes here
	%   Detailed explanation goes here
	
	properties(Constant)
		Valid = 1;
		NonFinite = -65536;
		InternalError = -65537;
	end

	properties(SetAccess=protected)
		name;
		description;
		inputDescription = {};
		inputType = {};
		parameterCount;
		parameterNames;
		parameterRanges;
		parameterUnits;
	end

	methods
		% Determine whether the dependent data samples are valid for optimisation with this Problem.
		function result = inputValid(this, y)
			import ether.optim.*;
			result = Problem.Valid;
			if ~all(isfinite(y))
				result = Problem.NonFinite;
			end
		end

		%-------------------------------------------------------------------------
		function set.parameterCount(this, count)
			if (~isscalar(count) || ~isfinite(count) || (count < 0))
				throw(MException('Ether:Optim:Problem', ...
					'Invalid parameter count'));
			end
			this.parameterCount = count;
		end

	end
	
end

