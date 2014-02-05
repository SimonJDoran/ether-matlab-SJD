classdef AbstractSolver < ether.optim.Solver
	%ABSTRACTSOLVER Summary of this class goes here
	%   Detailed explanation goes here
	
	properties(Constant,Access=private)
		logger = ether.log4m.Logger.getLogger('ether.optim.AbstractSolver');
	end

	methods
		%-------------------------------------------------------------------------
		function this = AbstractSolver()
			this@ether.optim.Solver();
		end
	end

	methods(Sealed)
		%-------------------------------------------------------------------------
		function result = solve(this, problem, x, y)
			if ~isvector(x)
				throw(MException('Ether:Optim:Solver:solve', ...
					'x must be a vector'));
			end
			nX = numel(x);
			nY = numel(y);
			if isvector(y)
				if (nY ~= nX)
					throw(MException('Ether:Optim:Solver:solve', ...
						'Sample count mismatch'));
				end
				this.initSolve(x);
				result = this.solveVector(problem, x, y);
				return;
			end

			% Find dimension that equals the number of samples
			dims = size(y);
			xIdx = find(dims == nX, 1, 'first');
			if isempty(xIdx)
				throw(MException('Ether:Optim:Solver:solve', ...
					'Sample count mismatch'));
			end
			% Set target dimensions to be same as y but replace the sample
			% dimension with problem.parameterCount
			resultDims = circshift(dims, [0,-xIdx]);
			targetDims = resultDims(1:end-1);
			targetDims = [problem.parameterCount,targetDims];
			% Ensure sample dimension is first dimension for CPU cache efficiency
			if (xIdx ~= 1)
				y = shiftdim(y, xIdx);
			end
			y = reshape(y, nX, nY/nX);
			this.initSolve(x);
			result = this.solve2D(problem, x, y);
			result.parameters = reshape(result.parameters, targetDims);
			if ~isempty(result.sigma)
				result.sigma = reshape(result.sigma, targetDims);
			end
		end
	end

	methods(Access=protected)
		%-------------------------------------------------------------------------
		function initSolve(this, x)
		end

		%-------------------------------------------------------------------------
		function result = solveVector(~, problem, x, y)
			result = ether.optim.Result();
			result.parameters = zeros(problem.parameterCount, 1);
		end
	end

	methods(Access=private)
		%-------------------------------------------------------------------------
		function result = solve2D(this, problem, x, y)
			dims = size(y);
			nY = dims(2);
			result = ether.optim.Result(this, problem, nY);
			hasSigma = this.sigmaType ~= ether.optim.Solver.NA;
			this.logger.info(sprintf(...
				'Problem: %s, Solver: %s (%i solves, %i samples per solve)', ...
				problem.name, this.name, nY, numel(x)));
			tic;
			if this.usePool
				nLab = ether.parallel.Pool.size;
				if nLab > 0
					this.logger.info(@() sprintf('Using %i labs in pool', nLab));
				else
					this.logger.warn(@() 'No labs available in pool');
				end
				% Cell arrays because fitParams and sigma can't be indexed directly
				% in parfor body
				fitCell = cell(nY, 1);
				parfor ii=1:nY
					vecResult = this.solveVector(problem, x, y(:,ii));
					fitCell{ii} = vecResult;
				end
				this.logger.debug(sprintf(...
					'Reassembling results from cells 1-%i', nY));
				for ii=1:nY
					fitResult = fitCell{ii};
					result.code(ii) = fitResult.code;
					result.parameters(:,ii) = fitResult.parameters;
					if problem.derivedCount > 0
						result.derived(:,ii) = fitResult.derived;
					end
					if hasSigma
						result.sigma(:,ii) = fitResult.sigma;
					end
					if ~isempty(fitResult.thrown)
						result.thrown{ii} = fitResult.thrown{1};
					end
				end
			else
				for ii=1:nY
					fitResult = this.solveVector(problem, x, y(:,ii));
					result.code(ii) = fitResult.code;
					result.parameters(:,ii) = fitResult.parameters;
					result.derived(:,ii) = fitResult.derived;
					if hasSigma
						result.sigma(:,ii) = fitResult.sigma;
					end
					if ~isempty(fitResult.thrown)
						result.thrown{ii} = fitResult.thrown{1};
					end
				end
			end
			elapsed = toc;
			this.logger.info(sprintf(...
				'Solve complete in %.2fs (%.1fms per solve)', elapsed, elapsed/nY*1000));
		end

	end

end

