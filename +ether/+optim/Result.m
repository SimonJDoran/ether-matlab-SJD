classdef Result < handle
	%RESULT Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
		code = ether.optim.Solver.NeverEvaluated;
		derived = [];
		parameters = [];
		sigma = [];
		sigmaType = ether.optim.Solver.NA;
		thrown = {};
	end
	
	methods
		function this = Result(varargin)
			if numel(varargin) ~= 3
				return;
			end
			solver = varargin{1};
			problem = varargin{2};
			nVec = varargin{3};
			this.sigmaType = solver.sigmaType;
			this.parameters = zeros(problem.parameterCount, nVec, 'single');
			if problem.derivedCount > 0
				this.derived = zeros(problem.derivedCount, nVec, 'single');
			end
			if this.sigmaType ~= ether.optim.Solver.NA
				this.sigma = zeros(problem.parameterCount, nVec, 'single');
			end
			this.thrown = cell(1, nVec);
		end
	end
	
end

