classdef ArrayEvaluable < ether.optim.Evaluable
	%ARRAYEVALUABLE Extension of Evaluable that denotes evaluation uses arrays of inputs.
	%   Detailed explanation goes here
	
	properties
	end
	
	methods
		% Evaluate the Problem over the vector x for each column of params
		result = evaluateArray(this, x, params);
	end
	
end

