classdef ADC < ether.optim.ArrayEvaluable & ether.optim.Linearisable
	%ADC Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
	end
	
	methods
		%-------------------------------------------------------------------------
		function this = ADC()
			this.name = 'ADC';
			this.description = 'Apparent Diffusion';
			this.parameterCount = 2;
			this.parameterNames = {'S0','D'};
		end

		%-------------------------------------------------------------------------
		function derived = computeDerivedParameters(~, x, params)
			derived = [];
		end
		%-------------------------------------------------------------------------
		function params = delinearise(~, linParams)
			params = [exp(linParams(2)),-linParams(1)];
		end

		%-------------------------------------------------------------------------
		function params = delinearise2D(~, linParams)
			n = numel(linParams)/2;
			params = [exp(linParams(n+1:end));-linParams(1:n)];
		end

		%-------------------------------------------------------------------------
		% params = [s0, D]
		function result = evaluate(~, x, params)
			if ~isvector(params)
				throw(MException('Ether:Optimisation:Evaluable', ...
					'Parameters must be a vector'));
			end
			result = params(1)*exp(-x*params(2));
		end

		%-------------------------------------------------------------------------
		% params = [s0, D]
		function result = evaluateArray(this, x, params)
			x = x(:);
			nX = numel(x);
			dims = size(params);
			paramIdx = find(dims == this.parameterCount, 1, 'first');
			% Set target dimensions to be same as y but replace the sample
			% dimension with problem.parameterCount
			targetDims = circshift(dims, [0,-paramIdx]);
			targetDims = [nX,targetDims(1:end-1)];
			% Ensure sample dimension is first dimension for CPU cache efficiency
			if (paramIdx ~= 1)
				params = shiftdim(params, paramIdx);
			end
			params = reshape(params, this.parameterCount, ...
				numel(params)/this.parameterCount);
			result = repmat(params(1,:), nX, 1).*exp(-x*params(2,:));
			result = reshape(result, targetDims);
		end

		%-------------------------------------------------------------------------
		function [lower,upper] = getConstraints(~, x)
			lower = [1e-3,1e-6];
			upper = [5e5,1e-2];
		end

		%-------------------------------------------------------------------------
		function indepData = getExemplarIndepData(~, nPoints)
			indepMax = 1000.0;
			indepData = (0:nPoints-1)*indepMax/(nPoints-1);
		end

		%-------------------------------------------------------------------------
		function params = getExemplarParameters(~)
			params = [1000,2e-3];
		end

		%-------------------------------------------------------------------------
		function params = getInitialConditions(~, indepData, depData)
			params = [800,0.003];
		end

		%-------------------------------------------------------------------------
		function result = linearise(~, data)
			result = log(data);
		end

	end
	
end

