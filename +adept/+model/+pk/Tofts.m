classdef Tofts < ether.optim.TimeSeriesProblem & ether.optim.ArrayEvaluable
	%TOFTS Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
	end

	methods
		%-------------------------------------------------------------------------
		function this = Tofts()
			this.name = 'Tofts';
			this.description = 'Kety Model with Bi-exponential Input';
			this.parameterCount = 3;
			this.parameterNames = {'Ktrans','ve','Onset'};

			this.plasma = adept.model.pk.Plasma();
			% Default to Parker equivalent
			this.plasma.a1 = 161.0;
			this.plasma.m1 = 12.0;
			this.plasma.a2 = 18.3;
			this.plasma.m2 = 0.169;
			this.abscissaScale = 1/60;

			this.dose = 0.1;
			this.onset = 0.45;
		end

		%-------------------------------------------------------------------------
		% params = TODO
		function result = evaluate(this, x, params)
			if ~isvector(params)
				throw(MException('Ether:Optimisation:Evaluable', ...
					'Parameters must be a vector'));
			end
			t = x*this.abscissaScale-params(3);
			priorIdx = t <= 0;
			kep = params(1)/params(2);
			fast = this.plasma.a1/(this.plasma.m1-kep)* ...
				(exp(-kep*t)-exp(-this.plasma.m1*t));
			slow = this.plasma.a2/(this.plasma.m2-kep)* ...
				(exp(-kep*t)-exp(-this.plasma.m2*t));
			result = this.dose*params(1)*(fast+slow);
			result(priorIdx) = 0;
		end

		%-------------------------------------------------------------------------
		% params = TODO
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

			nY = numel(params)/this.parameterCount;
			kep = repmat(params(1,:)./params(2,:), nX, 1);
			t0 = params(3,:);
			t = repmat(x*this.abscissaScale, 1, nY)-repmat(t0, nX, 1);
			priorIdx = t <= 0;
			fast = this.plasma.a1./(this.plasma.m1-kep).* ...
				(exp(-kep.*t)-exp(-this.plasma.m1*t));
			slow = this.plasma.a2./(this.plasma.m2-kep).* ...
				(exp(-kep.*t)-exp(-this.plasma.m2*t));
			result = repmat(this.dose*params(1,:), nX, 1).*(fast+slow);
			result(priorIdx) = 0;
			result = reshape(result, targetDims);
		end

		%-------------------------------------------------------------------------
		function [lower,upper] = getConstraints(this, x)
			lower = [1e-6,1e-6,this.abscissaScale*min(x)];
			upper = [25.0,1.0,this.abscissaScale*max(x)];
		end

		%-------------------------------------------------------------------------
		function indepData = getExemplarIndepData(~, nPoints)
			indepMax = 180.0;
			indepData = (0:nPoints-1)*indepMax/(nPoints-1);
		end

		%-------------------------------------------------------------------------
		function params = getExemplarParameters(~)
			params = [0.25,0.05,0.5];
		end

		%-------------------------------------------------------------------------
		function params = getInitialConditions(this, x, y)
			params = [0.2,0.1,this.onset];
		end

		%-------------------------------------------------------------------------
		function input = getInputFunction(this, x)
			t = x*this.abscissaScale;
			idx = t > 0;
			input = zeros(1, numel(t));
			fastCurve = this.dose*this.plasma.a1*exp(-this.plasma.m1*t(idx));
			slowCurve = this.dose*this.plasma.a2*exp(-this.plasma.m2*t(idx));
			input(idx) = fastCurve + slowCurve;
		end

	end
	
end

