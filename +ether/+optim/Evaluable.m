classdef (Abstract) Evaluable < ether.optim.Problem
	%EVALUABLE Interface for Problems that require evaluation during optimisation.
	%   Detailed explanation goes here
	
	properties(Constant)
		DerivedNonFinite = -131072;
	end

	properties(SetAccess=protected)
		derivedCount = 0;
		derivedNames = {};
		derivedRanges = {};
		derivedUnits = {};
	end
	
	methods(Abstract)
		% Compute the derived parameters of the Problem given vector x and params.
		derived = computeDerivedParameters(this, x, params);

		% Evaluate the Problem over the vector x for params.
		result = evaluate(this, x, params);

		% Return the constraints of the Problem.
		[lower,upper] = getConstraints(this, x);

		% Return an exemplar set of independent data for the Problem.
		indepData = getExemplarIndepData(this, nPoints);

		% Return an exemplar set of parameters for the Problem.
		params = getExemplarParameters(this);

		% Return an initial estimate for the solution to the Problem.
		params = getInitialConditions(this, x, y);

	end

	methods
		% Check the parameters of the solution are valid for the Problem.
		function result = derivedValid(this, derived)
			import ether.optim.*;
			result = Problem.Valid;
			if ~all(isfinite(derived))
				result = Evaluable.DerivedNonFinite;
				return;
			end
		end

		%-------------------------------------------------------------------------
		function result = inputValid(this, params)
			result = inputValid@ether.optim.Problem(this, params);
		end

		% Check the parameters of the solution are valid for the Problem.
		function result = solutionValid(this, params)
			import ether.optim.*;
			result = Problem.Valid;
			if ~all(isfinite(params))
				result = Problem.NonFinite;
				return;
			end
		end

		%-------------------------------------------------------------------------
		function set.derivedCount(this, count)
			if (~isscalar(count) || ~isfinite(count) || (count < 0))
				throw(MException('Ether:Optim:Problem', ...
					'Invalid derived parameter count'));
			end
			this.derivedCount = count;
		end

	end
	
end

