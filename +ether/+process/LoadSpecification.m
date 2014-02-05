classdef LoadSpecification < ether.process.Node
	%LOADSPECIFICATION Summary of this class goes here
	%   Detailed explanation goes here

	properties(SetAccess=protected)
		loaderId = uint32(0);
		targetId = uint32(0);
		type = 'UNDEFINED';
	end

	methods
		function this = LoadSpecification(id, loaderId, targetId)
			this@ether.process.Node(id);
			this.loaderId = loaderId;
			this.targetId = targetId;
		end
	end

end

