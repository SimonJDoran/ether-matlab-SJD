classdef (Abstract) Solver < ether.parallel.PoolUser
	%SOLVER Summary of this class goes here
	%   Detailed explanation goes here

	properties(Constant)
		L1@int32 = int32(1);
		L2@int32 = int32(2);
		NA@int32 = int32(1);
		SD@int32 = int32(2);
		CI@int32 = int32(3);
		SolutionFound@int32 = int32(1);
		IterationMax@int32 = int32(0);
		OutputError@int32 = int32(-1);
		InvalidConstraints@int32 = int32(-2);
		NoConvergence@int32 = int32(-4);
		NeverEvaluated@int32 = int32(-255);
		InternalError@int32 = int32(-256);
	end

	properties
		sigmaType = ether.optim.Solver.NA;
	end

	properties(SetAccess=protected)
		name;
		description;
	end
	
	properties(Access=private)
		statusMap;
	end

	methods(Abstract)
		% Solve the problem for y = f(x), return an ether.optim.Result
		result = solve(this, problem, x, y);
	end

	methods
		%-------------------------------------------------------------------------
		function this = Solver()
			this.statusMap = containers.Map('KeyType', 'int32', 'ValueType', 'char');
			this.statusMap(this.SolutionFound) = 'Solution Found';
			this.statusMap(this.IterationMax) = 'Maximum Iterations Reached';
			this.statusMap(this.OutputError) = 'Output Error';
			this.statusMap(this.InvalidConstraints) = 'Invalid Constraints';
			this.statusMap(this.NoConvergence) = 'No Convergence';
			this.statusMap(this.InternalError) = 'Internal Error';
		end

		%-------------------------------------------------------------------------
		function status = getStatus(this, code)
			if this.statusMap.isKey(code)
				status = this.statusMap(code);
			else
				status = [];
			end
		end

		%-------------------------------------------------------------------------
		function set.sigmaType(this, sigmaType)
			if this.isValidSigmaType(sigmaType)
				this.sigmaType = sigmaType;
			else
				this.logger.warn(sprintf(...
					'Ignoring invalid sigmaType: %i', sigmaType));
				dbstack(1)
			end
		end
	end

	methods(Access=protected)
		%-------------------------------------------------------------------------
		function result = fitResultValid(~, problem, params, exitCode)
			import ether.optim.*;
			if exitCode <= 0
				result = exitCode;
				return;
			end
			problemTest = problem.solutionValid(params);
			if problemTest ~= Problem.Valid
				result = problemTest;
				return;
			end
			result = Solver.SolutionFound;
		end

		%-------------------------------------------------------------------------
		function isValid = isValidSigmaType(this, sigmaType)
			isValid = true;
		end

	end
end

