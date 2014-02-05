classdef Loadable < handle
	%LOADABLE Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
	end
	
	methods(Abstract)
		value = load(this, loader, loadSpec);
	end
	
end

