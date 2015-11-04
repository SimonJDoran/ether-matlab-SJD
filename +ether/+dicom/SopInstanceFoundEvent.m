classdef SopInstanceFoundEvent < event.EventData
	%SOPINSTANCEFOUNDEVENT Event emitted by PathScanner, wraps SopInstance
	%   Detailed explanation goes here

	%----------------------------------------------------------------------------
	properties(SetAccess=private)
		sopInstance;
	end

	%----------------------------------------------------------------------------
	methods
		%-------------------------------------------------------------------------
		function this = SopInstanceFoundEvent(sopInstance)
			this.sopInstance = sopInstance;
		end
	end

end

