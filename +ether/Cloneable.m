classdef Cloneable < handle
	%CLONEABLE Interface definition for cloneable objects
	%   Detailed explanation goes here

	properties
	end

	methods(Abstract)
		%-------------------------------------------------------------------------
		new = clone(this);
	end

end

