classdef LeastSquaresSolver < ether.optim.AbstractSolver
	%LEASTSQUARESSOLVER Summary of this class goes here
	%   Detailed explanation goes here
	
	properties(Constant,Access=private)
		logger = ether.log4m.Logger.getLogger('ether.optim.LeastSquaresSolver');
	end

	properties
	end
	
	methods
		%-------------------------------------------------------------------------
		function this = LeastSquaresSolver()
			this@ether.optim.AbstractSolver();
			this.name = 'LSq';
			this.description = 'Least Squares';
		end

	end

	methods(Access=protected)
		%-------------------------------------------------------------------------
		function isValid = isValidSigmaType(~, sigmaType)
			import ether.optim.Solver;
			isValid = (sigmaType == Solver.NA);
		end

		%-------------------------------------------------------------------------
		function result = solveVector(this, problem, x, y)
			import ether.optim.*;
			x = x(:);
			result = ether.optim.Result(this, problem, 1);
			dataTest = problem.inputValid(y);
			if dataTest ~= 1
				result.code = dataTest;
				return;
			end
			initial = problem.getInitialConditions(x, y);
			[lower,upper] = problem.getConstraints(x);
			try
				[fitParams,resNorm,residual,exitCode] = ...
					lsqcurvefit(@(params,x) problem.evaluate(x, params), ...
						initial(:), x, double(y), lower(:), upper(:), ...
						optimset('Display', 'off'));
				fitTest = this.fitResultValid(problem, fitParams, exitCode);
				if fitTest ~= Solver.SolutionFound
					result.code = fitTest;
					return;
				end
				result.parameters = fitParams;
				result.derived = problem.computeDerivedParameters(x, fitParams);
				result.code = fitTest;
			catch ex
				result.code = Solver.InternalError;
				result.thrown = {ex};
			end
		end

	end

end

