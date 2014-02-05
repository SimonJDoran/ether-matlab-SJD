classdef SopInstanceFoundEvent < event.EventData
	%SOPINSTANCEFOUNDEVENT Summary of this class goes here
	%   Detailed explanation goes here

	properties(SetAccess=private)
		sopInstance;
	end

	methods
		function this = SopInstanceFoundEvent(sopInstance)
			this.sopInstance = sopInstance;
		end
	end

end

