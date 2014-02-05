classdef Processor < ether.process.Node
	%PROCESSOR Summary of this class goes here
	%   Detailed explanation goes here

	properties(Constant)
		Unknown = 1;
		ImageVolume = 2;
		ProblemResult = 3;
	end

	properties(SetAccess=protected)
		targetType = ether.process.Processor.Unknown;
	end

	properties(SetAccess=private)
		inputIDs = [];
		targetID = [];
		entityIDs = [];
	end

	methods(Abstract)
		result = process(this, inputs, target, entities);
	end

	methods
		function this = Processor(id, inputIDs, targetID, entityIDs)
			this = this@ether.process.Node(id);
			this.inputIDs = inputIDs;
			this.targetID = targetID;
			this.entityIDs = entityIDs;
		end
	end
	
end

