classdef MapSet < ether.collect.Set
	%MAPSET Summary of this class goes here
	%   Detailed explanation goes here
	
	properties(Access=private)
		map;
	end
	
	methods
		function this = MapSet()
			this.map = containers.Map();
		end

		function bool = contains(this, value)
			bool = this.map.isKey(value);
		end
	end
	
end

