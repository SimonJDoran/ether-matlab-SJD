classdef CosineFastExchange < ether.optim.TimeSeriesProblem & adept.model.pk.CosineBasis
	%COSINEFASTEXCHANGE Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
		t1Zero = 1;
		t1Relax = 4.3;
		tr;
	end

	properties(Dependent)
		alpha;
	end

	properties(Access=private)
		privAlpha;
		sinAlpha;
		cosAlpha;
	end

	methods
		%-------------------------------------------------------------------------
		function this = CosineFastExchange()
			this.name = 'CosineFastExchange';
			this.description = 'Kety Model (Fast Exchange) with Cosine Input';
			this.parameterCount = 6;
			this.parameterNames = {'S0';'T1 Initial';'Ktrans';'ve';'vp';'Onset'};

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
		% params = [s0,t1Initial,Ktrans,ve,vp,t0]
		function result = evaluate(this, x, params)
			if ~isvector(params)
				throw(MException('Ether:Optimisation:Evaluable', ...
					'Parameters must be a vector'));
			end
			tB = 2*pi/this.plasma.m1;
			a1 = this.plasma.a1*this.dose/tB;
			a2 = this.plasma.a2*this.dose/ ...
				(a1*this.convCosineExp(tB, this.plasma.m1, this.plasma.m2));
			kep = params(3)/params(4);
			t0 = params(6);
			t = x*this.abscissaScale;

			bolus = kep*a1*this.convBolusExp(t-t0, this.plasma.m1, kep);
			washout = kep*a1*a2*this.convBolusExpExp(t-t0, this.plasma.m1, ...
				this.plasma.m2, kep);
			ce = bolus+washout;
			cp = this.getInputFunction((t-t0)/this.abscissaScale);
			gd = params(4)*ce+params(5)*cp;
			t1 = 1.0./(1.0/params(2)+this.t1Relax*gd);
			result = this.spgr(params(1), t1);
		end

		%-------------------------------------------------------------------------
		function alpha = get.alpha(this)
			alpha = this.privAlpha;
		end

		%-------------------------------------------------------------------------
		% params = [s0,t1Initial,Ktrans,ve,vp,t0]
		function [lower,upper] = getConstraints(this, x)
			lower = [1800;1e-3;1e-6;1e-6;1e-6;this.abscissaScale*min(x)];
			upper = [2200;2.5;25.0;1.0;1.0;this.abscissaScale*max(x)];
		end

		%-------------------------------------------------------------------------
		function indepData = getExemplarIndepData(~, nPoints)
			indepMax = 180.0;
			indepData = (0:nPoints-1)*indepMax/(nPoints-1);
		end

		%-------------------------------------------------------------------------
		% params = [s0,t1Initial,Ktrans,ve,vp,t0]
		function params = getExemplarParameters(~)
			params = [2000;1;0.25;0.1;0.03;0.5];
		end

		%-------------------------------------------------------------------------
		% params = [s0,t1Initial,Ktrans,ve,vp,t0]
		function params = getInitialConditions(this, x, y)
			t = x*this.abscissaScale;
			idx = t<this.onset;
			if any(idx)
				signal = mean(y(idx));
			else
				signal = y(1);
			end
			t1 = this.t1Zero;
			s0 = signal/this.spgr(1, t1);
			params = [s0;t1;0.2;0.15;0.02;this.onset];
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
		function set.alpha(this, alpha)
			if ~isscalar(alpha)
				throw(MException('ADEPT:Model:PK:CosineFastExchange', ...
					'Alpha must be scalar'));
			end
			this.privAlpha = alpha;
			this.sinAlpha = sind(alpha);
			this.cosAlpha = cosd(alpha);
		end
	end

	methods(Access=private)
		function signal = spgr(this, s0, t1)
			exponent = exp(-this.tr./t1);
			signal = s0*(this.sinAlpha*(1.0-exponent) ./ ...
				(1.0-this.cosAlpha*exponent));
		end
	end
	
end

