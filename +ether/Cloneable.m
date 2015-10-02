classdef Cloneable < handle
	%CLONEABLE Interface: Object can clone itself
	%   Detailed explanation goes here

	%----------------------------------------------------------------------------
	properties
	end

	%----------------------------------------------------------------------------
	methods(Abstract)
		%-------------------------------------------------------------------------
		new = clone(this);
	end

end

