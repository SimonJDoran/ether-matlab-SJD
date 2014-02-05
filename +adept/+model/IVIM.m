classdef IVIM < ether.optim.ArrayEvaluable
	%IVIM Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
	end

	methods
		%-------------------------------------------------------------------------
		function this = IVIM()
			this.name = 'IVIM';
			this.description = 'IntraVoxel Incoherent Motion';
			this.parameterCount = 4;
			this.parameterNames = {'S0','f','D','D*'};
		end

		%-------------------------------------------------------------------------
		function derived = computeDerivedParameters(~, x, params)
			derived = [];
		end

		%-------------------------------------------------------------------------
		% params = [s0, f, D, D*]
		function result = evaluate(this, x, params)
			if ~isvector(params)
				throw(MException('Ether:Optimisation:Evaluable', ...
					'Parameters must be a vector'));
			end
			result = params(1)*(params(2)*exp(-x*params(4))+ ...
				(1-params(2))*exp(-x*params(3)));
		end

		%-------------------------------------------------------------------------
		% params = [s0, f, D, D*]
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
				(repmat(params(2,:), nX, 1).*exp(-x*params(4,:))+ ...
				repmat(1-params(2,:), nX, 1).*exp(-x*params(3,:)));
			result = reshape(result, targetDims);
		end

		%-------------------------------------------------------------------------
		function [lower,upper] = getConstraints(this, x)
			lower = [1e-3,1e-2,1e-6,6e-3];
			upper = [5e5,0.6,4e-3,0.1];
		end

		%-------------------------------------------------------------------------
		function indepData = getExemplarIndepData(~, nPoints)
			indepMax = 1000.0;
			indepData = (0:nPoints-1)*indepMax/(nPoints-1);
		end

		%-------------------------------------------------------------------------
		function params = getExemplarParameters(~)
			params = [1000,0.15,0.002,0.02];
		end

		%-------------------------------------------------------------------------
		function params = getInitialConditions(~, indepData, depData)
			params = [800,0.12,0.003,0.015];
		end

	end
	
end

