classdef PathScanListener < handle
	%PATHSCANLISTENER Interface: Listens to SopInstanceFound events emitted by PathScanner
	%   Detailed explanation goes here

	%----------------------------------------------------------------------------
	properties
	end

	%----------------------------------------------------------------------------
	methods(Abstract)
		%-------------------------------------------------------------------------
		sopInstanceFound(this, source, data);
	end

end

