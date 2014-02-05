classdef CosineBasis < handle
	%COSINEBASIS Summary of this class goes here
	%   Detailed explanation goes here
	
	properties(Access=private)
		% Thresholds for taylor series approximations
		tolFexp_x = 0.6;
		tolFexp_y = 0.45;
		tolFgamma_x = 1.0;
		tolFgamma_y = 0.8;
	end

	methods(Access=protected,Sealed)
		%-------------------------------------------------------------------------
		%	Cosine bolus curve
		function result = bolus(~, t, m)
			t = t(:);
			result = zeros(numel(t), 1);

			% Dimensionless input parameter
			x = m*t;
			small = 0.2;
			idxSmall = (x > 0.0) & (x < small);
			idxBig = (x >= small) & (x < 2*pi);

			% Direct form for large x
			if any(idxBig)
				result(idxBig) = 1.0 - cos(x(idxBig));
			end
			% Taylor series for small x
			if any(idxSmall)
				x2 = x(idxSmall).^2;
				result(idxSmall) = x2/(1*2).* ...
					(1 - x2/(3*4).* ...
					(1 - x2/(5*6).* ...
					(1 - x2/(7*8).* ...
					(1 - x2/(9*10)))));
			end
		end

		%-------------------------------------------------------------------------
		%	Convolution between cosine bolus and exponential
		function result = convBolusExp(this, t, m, k)
			result = zeros(numel(t), 1);
			tB = (2*pi/m); % Bolus end time

			idxB = (t > 0.0) & (t < tB);
			if any(idxB)
				result(idxB) = this.convCosineExp(t(idxB), m, k);
			end
			idxNonB = (t >= tB);
			if any(idxNonB)
				result(idxNonB) = this.convCosineExp(tB, m, k)* ...
					exp(-k*(t(idxNonB)-tB));
			end
		end

		%-------------------------------------------------------------------------
		%	Convolution between cosine bolus and two exponentials
		function result = convBolusExpExp(this, t, m, k1, k2)
			% easy special case, then return straight away
			if (k1 == k2)
				result = this.convBolusGamma(t, m, k1);
				return
			end

			result = zeros(numel(t), 1);

			% Threshold for using direct and gamma approximation
			tG = 1e-4/abs(k2-k1);
			% indices before and after tG
			idxE = (t >= tG);
			idxG = (t < tG);

			% Direct formula
			if any(idxE)
				x1 = this.convBolusExp(t(idxE), m, k1);
				x2 = this.convBolusExp(t(idxE), m, k2);
				result(idxE) = (x1-x2)/(k2-k1);
			end
			% Gamma approximation formula
			if any(idxG)
				k12 = 0.5*(k1 + k2);
				result(idxG) = this.convBolusGamma(t(idxG), m, k12);
			end
		end

		%-------------------------------------------------------------------------
		%	Convolution between cosine bolus and gamma
		function result = convBolusGamma(this, t, m, k)
			result = zeros(numel(t), 1);
			tB = (2*pi/m); % Bolus end time

			idxB = (t > 0.0) & (t < tB);
			if any(idxB)
				result(idxB) = this.convCosineGamma(t(idxB), m, k);
			end

			idxNonB = (t >= tB);
			if any(idxNonB)
				cE = this.convCosineExp(tB, m, k);
				cG = this.convCosineGamma(tB, m, k);
				result(idxNonB) = ((t(idxNonB)-tB)*cE+cG).*exp(-k*(t(idxNonB)-tB));
			end
		end

		%-------------------------------------------------------------------------
		%	Convolution between a raised cosine and an exponential.
		%
		% This function is designed to return an accurate value for a wide range of
		% (positive) inputs (t, m, k), which is ensured by using various Taylor series
		% approximations. The fifth (optional) input is a string that can be used to
		% validate the function by forcing it to use only one of the approximate
		% forms.
		function result = convCosineExp(this, t, m, k)
			t = t(:);
			x = k*t;
			y = m*t;
			nX = numel(x);

			idx0  = (x > this.tolFexp_x) & (y > this.tolFexp_y);
			idxX  = (x <= this.tolFexp_x) & (y > this.tolFexp_y);
			idxY  = (x > this.tolFexp_x) & (y <= this.tolFexp_y);
			idxXY = (x <= this.tolFexp_x) & (y <= this.tolFexp_y);
			idx0X = idx0 | idxX;
			idx0Y = idx0 | idxY;
			idx0XY = idx0 | idxX | idxY;

			% Initialise arrays
			expTerm = zeros(nX, 1);
			trigTerm = zeros(nX, 1);

			% exp term direct form
			if any(idx0Y)
				expTerm(idx0Y) = (1 - exp(-x(idx0Y)))./x(idx0Y);
			end
			% exp term Taylor series expansion
			if any(idxX)
				xE = x(idxX);
				expTerm(idxX) = 1 - xE/2.*( ...
					1 - xE/3.*( ...
					1 - xE/4.*( ...
					1 - xE/5.*( ...
					1 - xE/6.*( ...
					1 - xE/7.*( ...
					1 - xE/8.*( ...
					1 - xE/9.*( ...
					1 - xE/10.*( ...
					1 - xE/11.*( ...
					1 - xE/12.*( ...
					1 - xE/13.*( ...
					1 - xE/14.*( ...
					1 - xE/15 ...
					)))))))))))));
			end

			% trig term direct form
			if any(idx0X)
				trigTerm(idx0X) = x(idx0X).*(1 - cos(y(idx0X))) - ...
					y(idx0X).*sin(y(idx0X));
			end
			% trig term Taylor series expansion
			if any(idxY)
				xT = x(idxY);
				yT = y(idxY).^2;
				trigTerm(idxY) = yT/(1*2).*(xT - 2 - ...
					yT/(3*4).*(xT - 4 - ...
					yT/(5*6).*(xT - 6 - ...
					yT/(7*8).*(xT - 8 - ...
					yT/(9*10).*(xT - 10 - ...
					yT/(11*12).*(xT - 12 - ...
					yT/(13*14).*(xT - 14 ...
					)))))));
			end

			% Assemble the pieces of the function in the region x>tolX OR y>tolY
			result = trigTerm + y.^2.*expTerm;
			if any(idx0XY)
				result(idx0XY) = result(idx0XY)./(x(idx0XY).^2+y(idx0XY).^2);
			end

			% compute Taylor series for whole function in the region x<tolX AND y<tolY
			if any(idxXY)
				xH = x(idxXY);
				yH2 = y(idxXY).^2;
				result(idxXY) = ...
					yH2/(2*3).*(1 - xH/4.*(1-xH/5.*(1-xH/6.*(1-xH/7.*(1-xH/8.*(1-xH/9.*(1-xH/10.*(1-xH/11.*(1-xH/12.*(1-xH/13.*(1-xH/14.*(1-xH/15))))))))))) - ...
					yH2/(4*5).*(1 - xH/6.*(1-xH/7.*(1-xH/8.*(1-xH/9.*(1-xH/10.*(1-xH/11.*(1-xH/12.*(1-xH/13.*(1-xH/14.*(1-xH/15.*(1-xH/16.*(1-xH/17))))))))))) - ...
					yH2/(6*7).*(1 - xH/8.*(1-xH/9.*(1-xH/10.*(1-xH/11.*(1-xH/12.*(1-xH/13.*(1-xH/14.*(1-xH/15.*(1-xH/16.*(1-xH/17.*(1-xH/18.*(1-xH/19))))))))))) - ...
					yH2/(8*9).*(1 - xH/10.*(1-xH/11.*(1-xH/12.*(1-xH/13.*(1-xH/14.*(1-xH/15.*(1-xH/16.*(1-xH/17.*(1-xH/18.*(1-xH/19.*(1-xH/20.*(1-xH/21))))))))))) - ...
					yH2/(10*11).*(1 - xH/12.*(1-xH/13.*(1-xH/14.*(1-xH/15.*(1-xH/16.*(1-xH/17.*(1-xH/18.*(1-xH/19.*(1-xH/20.*(1-xH/21.*(1-xH/22.*(1-xH/23))))))))))) - ...
					yH2/(12*13).*(1 - xH/14.*(1-xH/15.*(1-xH/16.*(1-xH/17.*(1-xH/18.*(1-xH/19.*(1-xH/20.*(1-xH/21.*(1-xH/22.*(1-xH/23.*(1-xH/24.*(1-xH/25)))))))))))  ...
					))))));
			end

			result = result.*t;
		end

		%-------------------------------------------------------------------------
		%	Convolution between a raised cosine and a gamma.
		%
		% This function is designed to return an accurate value for a wide range of
		% (positive) inputs (t, m, k), which is ensured by using various Taylor series
		% approximations. The fifth (optional) input is a string that can be used to
		% validate the function by forcing it to use only one of the approximate
		% forms.
		function result = convCosineGamma(this, t, m, k)
			t = t(:);
			x = k*t;
			y = m*t;
			nX = numel(x);

			idx0  = (x > this.tolFgamma_x) & (y > this.tolFgamma_y);
			idxX  = (x <= this.tolFgamma_x) & (y > this.tolFgamma_y);
			idxY  = (x > this.tolFgamma_x) & (y <= this.tolFgamma_y);
			idxXY = (x <= this.tolFgamma_x) & (y <= this.tolFgamma_y);
			idx0X = idx0 | idxX;
			idx0Y = idx0 | idxY;
			idx0XY = idx0 | idxX | idxY;

			% Initialise arrays
			expTerm = zeros(nX, 1);
			trigTerm = zeros(nX, 1);

			% exp term direct form
			if any(idx0Y)
				xE = x(idx0Y);
				yE2 = y(idx0Y).^2;
				xE2 = xE.^2;
				expTerm(idx0Y) = (3+yE2./xE2).*(1-exp(-xE)) - (yE2+xE2)./xE.*exp(-xE);
			end
			% exp term Taylor series expansion
			if any(idxX)
				xE = x(idxX);
				yE2 = y(idxX).^2;
				expTerm(idxX) = yE2/2 - 0 ... % this line is an exception to the pattern
					- xE/1.*(yE2/3 - 2 ...
					- xE/2.*(yE2/4 - 1 ...
					- xE/3.*(yE2/5 + 0 ...
					- xE/4.*(yE2/6 + 1 ...
					- xE/5.*(yE2/7 + 2 ...
					- xE/6.*(yE2/8 + 3 ...
					- xE/7.*(yE2/9 + 4 ...
					- xE/8.*(yE2/10 + 5 ...
					- xE/9.*(yE2/11 + 6 ...
					- xE/10.*(yE2/12 + 7 ...
					- xE/11.*(yE2/13 + 8 ...
					- xE/12.*(yE2/14 + 9 ...
					- xE/13.*(yE2/15 + 10 ...
					- xE/14.*(yE2/16 + 11 ...
					- xE/15.*(yE2/17 + 12 ...
					- xE/16.*(yE2/18 + 13 ...
					- xE/17.*(yE2/19 + 14 ...
					- xE/18.*(yE2/20 + 15 ...
					- xE/19.*(yE2/21 + 16 ...
					- xE/20.*(yE2/22 + 17 ...
					))))))))))))))))))));
			end

			% trig term direct form
			if any(idx0X)
				xT = x(idx0X);
				yT = y(idx0X);
				trigTerm(idx0X) = (xT.^2-yT.^2).*(1 - cos(yT)) - 2*xT.*yT.*sin(yT);
			end
			% trig term Taylor series expansion
			if any(idxY)
				xT = 4*x(idxY); % note the extra factor of 4
				xT2 = x(idxY).^2;
				yT2 = y(idxY).^2;
				trigTerm(idxY) = ...
					yT2/(1*2).*  (xT2 - 1*xT + 0      - ...  % last term on this line is an exception to the pattern
					yT2/(3*4).*  (xT2 - 2*xT + 2*2*3  - ...
					yT2/(5*6).*  (xT2 - 3*xT + 2*3*5  - ...
					yT2/(7*8).*  (xT2 - 4*xT + 2*4*7  - ...
					yT2/(9*10).* (xT2 - 5*xT + 2*5*9  - ...
					yT2/(11*12).*(xT2 - 6*xT + 2*6*11 - ...
					yT2/(13*14).*(xT2 - 7*xT + 2*7*13 - ...
					yT2/(15*16).*(xT2 - 8*xT + 2*8*15 - ...
					yT2/(17*18).*(xT2 - 9*xT + 2*9*17 - ...
					yT2/(19*20).*(xT2 - 10*xT + 2*10*19 ...
					))))))))));
			end

			% Assemble the pieces of the function in the region x>tolX OR y>tolY
			result = trigTerm + y.^2.*expTerm;
			if any(idx0XY)
				result(idx0XY) = result(idx0XY)./((x(idx0XY).^2+y(idx0XY).^2).^2);
			end

			% compute Taylor series for whole function in the region x<tolX AND y<tolY
			if any(idxXY)
				xH = x(idxXY);
				yH2 = y(idxXY).^2;
				result(idxXY) = ...
					yH2/(2*3*4).*(1 - xH/5.*(2-xH/6.*(3-xH/7.*(4-xH/8.*(5-xH/9.*(6-xH/10.*(7-xH/11.*(8-xH/12.*(9-xH/13.*(10-xH/14.*(11-xH/15.*(12-xH/16.*(13-xH/17.*(14-xH/18.*(15-xH/19.*(16-xH/20))))))))))))))) - ...
					yH2/(5*6).*  (1 - xH/7.*(2-xH/8.*(3-xH/9.*(4-xH/10.*(5-xH/11.*(6-xH/12.*(7-xH/13.*(8-xH/14.*(9-xH/15.*(10-xH/16.*(11-xH/17.*(12-xH/18.*(13-xH/19.*(14-xH/20.*(15-xH/21.*(16-xH/22))))))))))))))) - ...
					yH2/(7*8).*  (1 - xH/9.*(2-xH/10.*(3-xH/11.*(4-xH/12.*(5-xH/13.*(6-xH/14.*(7-xH/15.*(8-xH/16.*(9-xH/17.*(10-xH/18.*(11-xH/19.*(12-xH/20.*(13-xH/21.*(14-xH/22.*(15-xH/23.*(16-xH/24))))))))))))))) - ...
					yH2/(9*10).* (1 - xH/11.*(2-xH/12.*(3-xH/13.*(4-xH/14.*(5-xH/15.*(6-xH/16.*(7-xH/17.*(8-xH/18.*(9-xH/19.*(10-xH/20.*(11-xH/21.*(12-xH/22.*(13-xH/23.*(14-xH/24.*(15-xH/25.*(16-xH/26))))))))))))))) - ...
					yH2/(11*12).*(1 - xH/13.*(2-xH/14.*(3-xH/15.*(4-xH/16.*(5-xH/17.*(6-xH/18.*(7-xH/19.*(8-xH/20.*(9-xH/21.*(10-xH/22.*(11-xH/23.*(12-xH/24.*(13-xH/25.*(14-xH/26.*(15-xH/27.*(16-xH/28))))))))))))))) - ...
					yH2/(13*14).*(1 - xH/15.*(2-xH/16.*(3-xH/17.*(4-xH/18*(5-xH/19.*(6-xH/20.*(7-xH/21.*(8-xH/22.*(9-xH/23.*(10-xH/24.*(11-xH/25.*(12-xH/26.*(13-xH/27.*(14-xH/28.*(15-xH/29.*(16-xH/30))))))))))))))) - ...
					yH2/(15*16).*(1 - xH/17.*(2-xH/18.*(3-xH/19.*(4-xH/20.*(5-xH/21.*(6-xH/22.*(7-xH/23.*(8-xH/24.*(9-xH/25.*(10-xH/26.*(11-xH/27.*(12-xH/28.*(13-xH/29.*(14-xH/30.*(15-xH/31.*(16-xH/32))))))))))))))) ...
					)))))));
			end

			result = result.*t.^2;
		end

	end
	
end

