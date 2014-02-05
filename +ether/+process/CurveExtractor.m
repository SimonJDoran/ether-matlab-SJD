classdef CurveExtractor < handle
	%CURVEEXTRACTOR Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
		name = 'Undefined';
		description = 'Undefined';
	end
	
	methods(Abstract)
		value = extract(this, curves);
	end
	
end

