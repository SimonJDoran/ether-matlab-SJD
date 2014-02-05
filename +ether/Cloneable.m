classdef Cloneable < handle
	%CLONEABLE Summary of this class goes here
	%   Detailed explanation goes here

	properties
	end

	methods(Abstract)
		%-------------------------------------------------------------------------
		new = clone(this);
	end

end

