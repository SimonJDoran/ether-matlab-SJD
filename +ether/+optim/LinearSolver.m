classdef LinearSolver < ether.optim.Solver
	%LINEARSOLVER Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
	end
	
	methods
		function this = LinearSolver()
			this.name = 'Linear';
			this.description = 'Linear Regression';
		end

		function result = solve(~, problem, x, y)
			if ~isvector(x)
				throw(MException('Ether:Optim:LinearSolver:solve', ...
					'x must be a vector'));
			end
			nX = numel(x);
			nY = numel(y);
			result = ether.optim.Result();
			if isvector(y)
				if (nY ~= nX)
					throw(MException('Ether:Optim:LinearSolver:solve', ...
						'Sample count mismatch'));
				end
				linData = problem.linearise(y);
				[g,i] = ether.regress(x, linData);
				result.parameters = problem.delinearise([g,i]);
				return;
			end

			linData = problem.linearise(y);
			[g,i] = ether.regress(x, linData);
			result.parameters = problem.delinearise2D([g,i]);
			result.parameters = squeeze(reshape(result.parameters, [2,size(g)]));
		end

	end

	methods(Access=protected)
		%-------------------------------------------------------------------------
		function isValid = isValidSigmaType(~, sigmaType)
			import ether.optim.Solver;
			isValid = (sigmaType == Solver.NA);
		end

	end
	
end

