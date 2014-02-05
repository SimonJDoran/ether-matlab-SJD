classdef Entity < ether.process.Node
	%ENTITY Summary of this class goes here
	%   Detailed explanation goes here

	properties(SetAccess=protected)
		entity = [];
	end

	methods
		function this = Entity(id, entity)
			this = this@ether.process.Node(id);
			this.entity = entity;
		end
	end

end

