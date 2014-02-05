classdef OnsetLocator < handle
	%ONSETLOCATOR Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
		name = 'Undefined';
		description = 'Undefined';
	end
	
	methods(Abstract)
		value = locate(this, time, curve)
	end
	
end

