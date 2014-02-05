classdef AlphaDWI < ether.optim.ArrayEvaluable
	%ALPHADWI Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
	end
	
	methods
		%-------------------------------------------------------------------------
		function this = AlphaDWI()
			this.name = 'AlphaDWI';
			this.description = 'Stretched Exponential DWI';
			this.parameterCount = 3;
			this.parameterNames = {'S0','D','Alpha'};
		end

		%-------------------------------------------------------------------------
		% params = [s0, D, alpha]
		function result = evaluate(this, x, params)
			if ~isvector(params)
				throw(MException('Ether:Optimisation:Evaluable', ...
					'Parameters must be a vector'));
			end
			result = params(1)*exp(-(x*params(2)).^params(3));
		end

		%-------------------------------------------------------------------------
		% params = [s0, D, alpha]
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
			result = repmat(params(1,:), nX, 1).* ...
				exp(-(x*params(2,:)).^repmat(params(3,:), nX, 1));
			result = reshape(result, targetDims);
		end

		%-------------------------------------------------------------------------
		function [lower,upper] = getConstraints(this, x)
			lower = [1e-3,1e-6,0.2];
			upper = [5e5,4e-3,1];
		end

		%-------------------------------------------------------------------------
		function indepData = getExemplarIndepData(~, nPoints)
			indepMax = 1000.0;
			indepData = (0:nPoints-1)*indepMax/(nPoints-1);
		end

		%-------------------------------------------------------------------------
		function params = getExemplarParameters(~)
			params = [1000,0.002,0.75];
		end

		%-------------------------------------------------------------------------
		function params = getInitialConditions(~, indepData, depData)
			params = [800,0.003,0.8];
		end

	end
	
end

