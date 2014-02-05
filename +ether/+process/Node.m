classdef Node < handle
	%NODE Summary of this class goes here
	%   Detailed explanation goes here

	properties(Constant)
	end

	properties
		id@uint32 = uint32(0);
		label@char = '';
		isReady@logical = false;
	end

	methods
		%-------------------------------------------------------------------------
		function this = Node(id)
			this.id = id;
			this.label = '';
		end
	end

end

