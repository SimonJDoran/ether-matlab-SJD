classdef MaxGradientOnsetLocator < ether.process.OnsetLocator
	%MAXGRADIENTONSETLOCATOR Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
	end
	
	methods
		%-------------------------------------------------------------------------
		function this = MaxGradientOnsetLocator()
			this.name = 'MaxGradient';
			this.description = 'Maximum Gradient Onset Locator';
		end

		%-------------------------------------------------------------------------
		function value = locate(~, time, curve)
			if ~isvector(time) || isscalar(time)
				throw(MException('Ether:Process:MaxGradientOnsetLocator', ...
					'Time is not a vector'));
			end
			if ~isvector(curve) || isscalar(curve)
				throw(MException('Ether:Process:MaxGradientOnsetLocator', ...
					'Curve is not a vector'));
			end
			nPoints = numel(curve);
			if numel(time) ~= nPoints
				throw(MException('Ether:Process:MaxGradientOnsetLocator', ...
					'Time and Curve must be same length'));
			end
			gradient = (curve(2:end)-curve(1:nPoints-1)) ./ ...
				(time(2:end)-time(1:nPoints-1));
			[maxGradient,maxIdx] = max(gradient);
			if maxGradient <= 0
				throw(MException('Ether:Process:MaxGradientOnsetLocator', ...
					'Maximum gradient is negative'));
			end
			yIntercept = curve(maxIdx) - gradient*maxIdx;
			xIntercept = -yIntercept/gradient;
			low = floor(xIntercept);
			if (low >= 1) && (low < nPoints)
				value = interp1(time, xIntercept);
			else
				value = time(1);
			end
		end
	end
	
end

