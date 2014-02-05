classdef PathScanListener < handle
	%PATHSCANLISTENER Summary of this class goes here
	%   Detailed explanation goes here

	properties
	end

	methods(Abstract)
		sopInstanceFound(this, source, data);
	end

end

