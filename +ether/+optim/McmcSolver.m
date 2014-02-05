classdef McmcSolver < ether.optim.AbstractSolver
	%MCMCSOLVER Summary of this class goes here
	%   Detailed explanation goes here
	
	properties(Constant)
		logger = ether.log4m.Logger.getLogger('ether.optim.McmcSolver');
	end

	properties(Access=private)
		halfX;
		likelihood = ether.optim.Solver.L2;
		lnGammaN;
		lnGammaNByTwo;
		lnTwo = log(2);
		logLikelihood;
		nBurnIn;
		nIter = 1000;
		nX;
		rootTwo = sqrt(2);
	end

	methods
		function this = McmcSolver()
			this.name = 'MCMC';
			this.description = 'Markov Chain Monte Carlo';
			this.sigmaType = ether.optim.Solver.SD;
		end
	end

	methods(Access=protected)
		function initSolve(this, x)
			this.nX = numel(x);
			this.halfX = this.nX/2;
			this.lnGammaN = gammaln(this.nX);
			this.lnGammaNByTwo = gammaln(this.nX/2);
			this.logLikelihood = @this.logLikelihoodL2;
			this.nBurnIn = this.nIter/10;
		end

		%-------------------------------------------------------------------------
		function isValid = isValidSigmaType(~, sigmaType)
			import ether.optim.Solver;
			isValid = (sigmaType == Solver.SD) || (sigmaType == Solver.CI);
		end

		function result = solveVector(this, problem, x, y)
			import ether.optim.*;
			x = x(:);
			result = ether.optim.Result(this, problem, 1);
			dataTest = problem.inputValid(y);
			if dataTest ~= Problem.Valid
				result.code = dataTest;
				return;
			end
			initial = problem.getInitialConditions(x, y);
			[lower,upper] = problem.getConstraints(x);

			nParams = problem.parameterCount;
			iterations = zeros(nParams, this.nIter, 'single');
			nAccept = zeros(nParams, 1);
			nAcceptCache = zeros(nParams, 1);
			kernelSigma = repmat(0.01, nParams, 1);
			nKernel = 50;
			targetAccept = 0.5;

			try
				oldParams = initial;
				evalOld = problem.evaluate(x, oldParams);
				logPOld = this.logLikelihood(y, evalOld);
				logPKeep = zeros(1, this.nIter);
				iterRandom = randn(nParams, this.nIter);
				alphaRandom = rand(nParams, this.nIter);
				for i=1:this.nIter
					delta = iterRandom(:,i).*kernelSigma;
					for j=1:nParams
						params = oldParams;
						params(j) = params(j)+delta(j);
						if ((params(j) < lower(j)) || (params(j) > upper(j)))
							iterations(j,i) = oldParams(j);
							continue;
						end
						eval = problem.evaluate(x, params);
						if ~all(isfinite(eval))
							iterations(j,i) = oldParams(j);
							continue;
						end
						logP = this.logLikelihood(y, eval);
						alpha = exp(logP-logPOld);
						if (alphaRandom(j,i) <= alpha)
							iterations(j,i) = params(j);
							nAccept(j) = nAccept(j)+1;
							logPOld = logP;
							oldParams = params;
						else
							iterations(j,i) = oldParams(j);
						end
					end % for(1:nParams)
					logPKeep(i) = logPOld;
					if (mod(i, nKernel) == 0)
						% Update kernel sigma every nKernel iterations to get kernel
						% sigma to converge on the target acceptance
						kernelSigma = kernelSigma.*(targetAccept*(nKernel+1)./ ...
							(nKernel+1.-(nAccept-nAcceptCache)));
						nAcceptCache = nAccept;
					end
				end % for(1:this.nIter)

				logPIdx = find(logPKeep == max(logPKeep), 1, 'last');
				fitParams = squeeze(iterations(:,logPIdx));
				fitTest = this.fitResultValid(problem, fitParams, Solver.SolutionFound);
				if fitTest ~= Solver.SolutionFound
					result.code = fitTest;
					return;
				end
				result.parameters = fitParams;
				if problem.derivedCount > 0
					result.derived = problem.computeDerivedParameters(x, fitParams);
				end
				result.code = fitTest;
				sigma = std(iterations(:,this.nBurnIn:end), 0, 2);
				result.sigma = sigma;
			catch ex
				result.code = Solver.InternalError;
				result.thrown = {ex};
			end
		end

	end

	methods(Access=private)
		function result = logLikelihoodL2(this, a, b)
			result = -this.lnTwo-this.halfX*log(pi*sum((a-b).^2))+ ...
				this.lnGammaNByTwo;
		end
	end

end

