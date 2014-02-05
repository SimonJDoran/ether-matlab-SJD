classdef (Abstract) Linearisable < handle
	%LINEARISABLE Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
	end
	
	methods
		result = linearise(this, data);
		params = delinearise(this, linParams);
		params = delineariseND(this, linParams);
	end
	
end

