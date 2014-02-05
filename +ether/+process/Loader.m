classdef Loader < ether.process.Node
	%LOADER Summary of this class goes here
	%   Detailed explanation goes here

	properties(SetAccess=private)
		type = 'UNDEFINED';
	end

	methods(Abstract)
		value = loadFile(this, filename);
	end

	methods
		function this = Loader(id, type)
			this@ether.process.Node(id);
			this.type = type;
		end
	end

end

