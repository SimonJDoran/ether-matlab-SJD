classdef TimeSeriesProblem < ether.optim.Evaluable
	%PKMODEL Summary of this class goes here
	%   Detailed explanation goes here

	properties
		dose;
		onset;
	end

	properties(SetAccess=protected)
		abscissaScale = 1;
		plasma;
	end

	methods(Abstract)
		input = getInputFunction(this, x);
	end

	methods
		%-------------------------------------------------------------------------
		function result = solutionValid(this, params)
			result = solutionValid@ether.optim.Evaluable(this, params);
		end

	end

end

