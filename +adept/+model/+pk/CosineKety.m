classdef CosineKety < ether.optim.TimeSeriesProblem & adept.model.pk.CosineBasis
	%COSINEKETY Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
	end

	methods
		%-------------------------------------------------------------------------
		function this = CosineKety()
			this.name = 'CosineKety';
			this.description = 'Kety Model with Cosine Input';
			this.parameterCount = 3;
			this.parameterNames = {'Ktrans','ve','Onset'};
			this.parameterRanges = {[0,1],[0,0.5],[0,1]};
			this.derivedCount = 1;
			this.derivedNames = {'Kep'};
			this.derivedRanges = {[0,5]};

			this.plasma = adept.model.pk.Plasma();
			% Defaults
			this.plasma.a1 = 13.5;
			this.plasma.m1 = 22.8;
			this.plasma.a2 = 17.9;
			this.plasma.m2 = 0.171;
			this.abscissaScale = 1/60;

			this.dose = 0.1;
			this.onset = 0.45;
		end

		%-------------------------------------------------------------------------
		function result = computeDerivedParameters(this, x, params)
			result = params(1)/params(2);
		end

		%-------------------------------------------------------------------------
		% params = [Ktrans,ve,t0]
		function result = evaluate(this, x, params)
			if ~isvector(params)
				throw(MException('Ether:Optim:Evaluable', ...
					'Parameters must be a vector'));
			end
			tB = 2*pi/this.plasma.m1;
			a1 = this.plasma.a1*this.dose/tB;
			a2 = this.plasma.a2*this.dose/ ...
				(a1*this.convCosineExp(tB, this.plasma.m1, this.plasma.m2));
			kep = params(1)/params(2);
			t0 = params(3);
			t = x*this.abscissaScale;

			bolusResponseCurve = params(1)*a1*this.convBolusExp(...
				t-t0, this.plasma.m1, kep);
			washoutResponseCurve = params(1)*a1*a2*this.convBolusExpExp(...
				t-t0, this.plasma.m1, this.plasma.m2, kep);

			result = bolusResponseCurve + washoutResponseCurve;
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
			tB = 2*pi/this.plasma.m1;
			a1 = this.plasma.a1*this.dose/tB;
			a2 = this.plasma.a2*this.dose/ ...
				(a1*this.convCosineExp(tB, this.plasma.m1, this.plasma.m2));
			t = x*this.abscissaScale;

			bolus = a1*this.bolus(t, this.plasma.m1);
			washout = a1*a2*this.convBolusExp(t, this.plasma.m1, ...
				this.plasma.m2);
			input = bolus + washout;
		end

		%-------------------------------------------------------------------------
		function result = inputValid(this, y)
			result = inputValid@ether.optim.TimeSeriesProblem(this, y);
			if result ~= ether.optim.Problem.Valid
				return;
			end
			if any(y == 0)
				result = -262144;
				return;
			end
		end

		%-------------------------------------------------------------------------
		function result = solutionValid(this, params)
			result = solutionValid@ether.optim.TimeSeriesProblem(this, params);
			if result ~= ether.optim.Problem.Valid
				return;
			end
		end

	end
	
end

