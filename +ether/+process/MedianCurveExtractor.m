classdef MedianCurveExtractor < ether.process.CurveExtractor
	%MEDIANCURVEEXTRACTOR Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
	end
	
	methods
		%-------------------------------------------------------------------------
		function this = MedianCurveExtractor()
			this.name = 'Median';
			this.description = 'Median Curve Extractor';
		end

		%-------------------------------------------------------------------------
		function curve = extract(~, allCurves)
			dims = size(allCurves);
			if numel(dims) ~= 2
				throw(MException('Ether:Process:MediaCurveExtractor', ...
					'Curves array must be 2D'));
			end
			curve = median(allCurves, 2)';
		end
	end
	
end

