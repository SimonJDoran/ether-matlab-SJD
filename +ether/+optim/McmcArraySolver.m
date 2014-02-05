classdef McmcArraySolver < ether.optim.Solver
	%MCMCPARALLELSOLVER Summary of this class goes here
	%   Detailed explanation goes here
	
	properties(Constant)
		logger = ether.log4m.Logger.getLogger('ether.optim.McmcArraySolver');
	end

	properties
	end
	
	properties(Access=private)
		halfX;
		likelihood = ether.optim.Solver.L2;
		lnGammaN;
		lnGammaNByTwo;
		lnTwo = log(2);
		logLikelihood;
		multiplier;
		nBurnIn;
		nIter = 10000;
		nKernel = 50;
		nX;
		rootTwo = sqrt(2);
		ramFraction = 0.75;
		sigmaNum = 2;
		solvePartition;
		targetAccept = 0.5;
	end

	methods
		%-------------------------------------------------------------------------
		function this = McmcArraySolver()
			this.name = 'MCMC (Array)';
			this.description = 'Markov Chain Monte Carlo (Array)';
			this.sigmaType = ether.optim.Solver.SD;
		end

		%-------------------------------------------------------------------------
		function result = solve(this, problem, x, y)
			if ~isa(problem, 'ether.optim.ArrayEvaluable')
				throw(MException('Ether:Optim:Solver:solve', ...
					'Problem must inherit from ether.optim.ArrayEvaluable'));
			end
			if ~isvector(x)
				throw(MException('Ether:Optim:Solver:solve', ...
					'x must be a vector'));
			end
			this.initSolve(x);

			% Find dimension that equals the number of samples
			dims = size(y);
			nY = prod(dims);
			xIdx = find(dims == this.nX, 1, 'first');
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
			y = reshape(y, this.nX, nY/this.nX);
			this.logger.info(sprintf(...
				'Problem: %s, Solver: %s (%i solves, %i samples per solve)', ...
				problem.name, this.name, nY/this.nX, numel(x)));
			if (this.sigmaType == ether.optim.Solver.CI)
				this.logger.debug('Using full walk solve');
				this.solvePartition = @this.solvePartitionFullWalk;
				this.multiplier = @this.multiplierFullWalk;
			else
				this.logger.debug('Using in-flight solve');
				this.solvePartition = @this.solvePartitionInFlight;
				this.multiplier = @this.multiplierInFlight;
			end
			result = this.solve2D(problem, x, y);
			result.parameters = reshape(result.parameters, targetDims);
			result.sigma = reshape(result.sigma, targetDims);
			result.sigmaType = this.sigmaType;
		end
	end

	methods(Access=protected)
		%-------------------------------------------------------------------------
		function isValid = isValidSigmaType(~, sigmaType)
			import ether.optim.Solver;
			isValid = (sigmaType == Solver.SD) || (sigmaType == Solver.CI);
		end

	end
	
	methods(Access=private)
		%-------------------------------------------------------------------------
		function initSolve(this, x)
			this.nX = numel(x);
			this.halfX = this.nX/2;
			this.lnGammaN = gammaln(this.nX);
			this.lnGammaNByTwo = gammaln(this.nX/2);
			this.logLikelihood = @this.logLikelihoodL2;
			this.nBurnIn = this.nIter/10;
		end

		%-------------------------------------------------------------------------
		function result = logLikelihoodL2(this, a, b)
			result = -this.lnTwo-this.halfX*log(pi*sum((a-b).^2))+ ...
				this.lnGammaNByTwo;
		end

		%-------------------------------------------------------------------------
		function result = multiplierFullWalk(this, nParams)
			result = ((nParams+1)*this.nIter+ ... % iterations, logPKeep
				4*nParams+ ... % nAccept, nAcceptCache, kernelSigma, oldParams
				3*this.nX); % resultOld, result, yPartition
		end

		%-------------------------------------------------------------------------
		function result = multiplierInFlight(this, nParams)
			result = (4*nParams+ ... % nAccept, nAcceptCache, kernelSigma, oldParams
				2+... % logPOld, logPMax
				3*this.nX); % resultOld, result, yPartition
		end

		%-------------------------------------------------------------------------
		function [nPart,nWholePart,nYPerPart] = partition2D(...
			this, nY, nYMult, nParams)

			function mb = asMB(bytes)
				mb = bytes/1024^2;
			end

			[~,sysMem] = memory();
			maxWorkBytes = 8*nY*nYMult;
			outputBytes = 8*nY*nParams*2; % fitParams, sigma
			availableBytes = sysMem.PhysicalMemory.Available;
			this.logger.debug(...
				sprintf('Available RAM: %gMB of %gMB', ...
					asMB(sysMem.PhysicalMemory.Available), ...
					asMB(sysMem.PhysicalMemory.Total)));
			this.logger.debug(...
				sprintf('Output required: %gMB', asMB(outputBytes)));
			this.logger.debug(...
				sprintf('Total required: %gMB', asMB(maxWorkBytes+outputBytes)));
			nPart = 1;
			nWholePart = 1;
			nYPerPart = nY;
			workBytes = this.ramFraction*(availableBytes-outputBytes);
			if (maxWorkBytes > workBytes)
				nWholePart = floor(maxWorkBytes/workBytes);
				nPart = nWholePart+1;
				workFraction = workBytes/maxWorkBytes;
				nYPerPart = floor(nY*workFraction);
				this.logger.debug(...
					sprintf('Using %i partitions of %gMB', nPart, asMB(workBytes)));
			end
		end

		%-------------------------------------------------------------------------
		function [nPart,nWholePart,nYPerPart] = partition2DParfor(...
			this, nY, nYMult, nParams, nLab)

			function mb = asMB(bytes)
				mb = bytes/1024^2;
			end
			
			[~,sysMem] = memory();
			maxWorkBytes = 8*nY*nYMult;
			outputBytes = 8*nY*nParams*2; % fitParams, sigma
			availableBytes = sysMem.PhysicalMemory.Available;
			this.logger.debug(...
				sprintf('Available RAM: %gMB of %gMB', ...
					asMB(sysMem.PhysicalMemory.Available), ...
					asMB(sysMem.PhysicalMemory.Total)));
			this.logger.debug(...
				sprintf('Output required: %gMB', asMB(outputBytes)));
			this.logger.debug(...
				sprintf('Total required: %gMB', asMB(maxWorkBytes+outputBytes)));
			nPart = 1;
			nWholePart = 1;
			nYPerPart = nY;
			workBytes = this.ramFraction*(availableBytes-outputBytes);
			if (maxWorkBytes > workBytes)
				workFraction = workBytes/maxWorkBytes;
				nYPerPart = floor(nY*workFraction);
				% All partitions but the last should have n x nYPerLab columns
				% where n is integer 
				nYPerLab = floor(nYPerPart/nLab);
				nYPerPart = nYPerLab*nLab;
				workBytes = 8*nYPerPart*nYMult;
				nWholePart = floor(maxWorkBytes/workBytes);
				nPart = nWholePart+1;
				this.logger.debug(...
					sprintf('Using %i partitions of %gMB', nPart, asMB(workBytes)));
			end

		end

		%-------------------------------------------------------------------------
		function result = solve2D(this, problem, x, y)
			if this.usePool
				result = solve2DParfor(this, problem, x, y);
				return;
			end

			dims = size(y);
			nY = dims(2);
			nParams = problem.parameterCount;
			nYMult = this.multiplier(nParams);
			[nPart,nWholePart,nYPerPart] = this.partition2D(nY, nYMult, nParams);

			% Solve single partition and bail
			if (nPart == 1)
				result = this.solvePartition(problem, x, y);
				return;
			end

			% Allocate results arrays
			result.parameters = zeros(nParams, nY);
			result.sigma = zeros(nParams, nY);

			% Solve each partition in turn
			for kk=1:nPart
				yStartIdx = (kk-1)*nYPerPart+1;
				yEndIdx = kk*nYPerPart;
				if (kk > nWholePart)
					yEndIdx = nY;
				end
				yPartition = y(:,yStartIdx:yEndIdx);
				partResult = ...
					this.solvePartition(problem, x, yPartition);
				result.parameters(:,yStartIdx:yEndIdx) = partResult.parameters;
				result.sigma(:,yStartIdx:yEndIdx) = partResult.sigma;
			end % for(1:nPart)
		end

		%-------------------------------------------------------------------------
		function result = solve2DParfor(this, problem, x, y)
			dims = size(y);
			nY = dims(2);
			nParams = problem.parameterCount;
			nYMult = this.multiplier(nParams);
			nLab = this.initPool();
			[nPart,nWholePart,nYPerPart] = this.partition2DParfor(...
				nY, nYMult, nParams, nLab);

			% Solve the partitions
			if (nPart == 1)
				if (nLab == 1)
					result = this.solvePartition(problem, x, y);
					return;
				end

				% Allocate results arrays
				result.parameters = zeros(nParams, nY);
				result.sigma = zeros(nParams, nY);

				this.logger.debug(sprintf('Using %i labs in pool', nLab));
				nYPerLab = ceil(nY/nLab);
				nWholeLab = floor(nY/nYPerLab);
				% Cell arrays to hold results: result cannot be
				% written to inside parfor body.
				fitCells = cell(nLab, 1);
				parfor ii=1:nLab
					yStartIdx = (ii-1)*nYPerLab+1;
					yEndIdx = ii*nYPerLab;
					if (ii > nWholeLab)
						yEndIdx = nY;
					end
					this.logger.debug(sprintf('Lab %i, y(:,%i:%i)', ...
						ii, yStartIdx, yEndIdx));
					yPartition = y(:,yStartIdx:yEndIdx);
					partResult = this.solvePartition(problem, x, yPartition);
					fitCells{ii} = partResult;
				end
				this.logger.debug(sprintf(...
					'Reassembling results from cells 1-%i', nLab));
				for ii=1:nLab
					yStartIdx = (ii-1)*nYPerLab+1;
					yEndIdx = ii*nYPerLab;
					if (ii > nWholeLab)
						yEndIdx = nY;
					end
					cellResult = fitCells{ii};
					result.parameters(:,yStartIdx:yEndIdx) = cellResult.parameters;
					result.sigma(:,yStartIdx:yEndIdx) = cellResult.sigma;
				end
			else
				% Allocate results arrays
				result.parameters = zeros(nParams, nY);
				result.sigma = zeros(nParams, nY);

				this.logger.debug(sprintf('Using %i labs in pool', nLab));
				% Solve each partition in turn
				for kk=1:nPart
					yPartStartIdx = (kk-1)*nYPerPart+1;
					yPartEndIdx = kk*nYPerPart;
					if (kk > nWholePart)
						yPartEndIdx = nY;
					end
					nYThisPart = yPartEndIdx-yPartStartIdx+1;
					nYPerLab = ceil(nYThisPart/nLab);
					nWholeLab = floor(nYThisPart/nYPerLab);
					this.logger.debug(sprintf('Partition %i, y(:,%i:%i)', ...
						kk, yPartStartIdx, yPartEndIdx));

					fitCells = cell(nLab, 1);
					parfor ii=1:nLab
						yStartIdx = yPartStartIdx+(ii-1)*nYPerLab;
						yEndIdx = yPartStartIdx+ii*nYPerLab-1;
						if (ii > nWholeLab)
							yEndIdx = yPartEndIdx;
						end
						this.logger.debug(sprintf('Partition %i, Lab %i, y(:,%i:%i)', ...
							kk, ii, yStartIdx, yEndIdx));
						yLab = y(:,yStartIdx:yEndIdx);
						partResult = this.solvePartition(problem, x, yLab);
						fitCells{ii} = partResult;
					end
					this.logger.debug(sprintf('Reassembling results from cells %i-%i', ...
						(kk-1)*nLab+1, kk*nLab));
					for ii=1:nLab
						yStartIdx = yPartStartIdx+(ii-1)*nYPerLab;
						yEndIdx = yPartStartIdx+ii*nYPerLab-1;
						if (ii > nWholeLab)
							yEndIdx = yPartEndIdx;
						end
						cellResult = fitCells{ii};
						result.parameters(:,yStartIdx:yEndIdx) = cellResult.parameters;
						result.sigma(:,yStartIdx:yEndIdx) = cellResult.sigma;
					end
				end % for(1:nPart)
			end
		end

		%-------------------------------------------------------------------------
		function	result = solvePartitionFullWalk(this, problem, x, y)
			dims = size(y);
			nY = dims(2);

			x = x(:);
			initial = problem.getInitialConditions(x, y);
			[lower,upper] = problem.getConstraints(x);
			nParams = problem.parameterCount;

			% Allocate arrays
			fitParams = zeros(nParams, nY);
			sigma = zeros(nParams, nY);
			iterations = zeros(nParams, nY, this.nIter);
			nAccept = zeros(nParams, nY);
			nAcceptCache = zeros(nParams, nY);
			kernelSigma = repmat(0.01*initial(:), 1, nY);
			oldParams = repmat(initial(:), 1, nY);
			resultOld = problem.evaluateArray(x, oldParams);
			logPOld = this.logLikelihood(y, resultOld);
			logPKeep = zeros(nY, this.nIter);

			for ii=1:this.nIter
				for jj=1:nParams
					delta = randn(1, nY).*kernelSigma(jj,:);
					params = oldParams;
					params(jj,:) = params(jj,:)+delta;
					badIdx = (params(jj,:) < lower(jj)) | (params(jj,:) > upper(jj));

					result = problem.evaluateArray(x, params);
					nfIdx = ~all(isfinite(result), 1);
					goodIdx = ~(badIdx | nfIdx);
					logP = this.logLikelihood(y, result);
					alpha = exp(logP-logPOld);

					alphaIdx = rand(1, nY) <= alpha;
					acceptIdx = alphaIdx & goodIdx;
					iterations(jj,acceptIdx,ii) = params(jj,acceptIdx);
					nAccept(jj,acceptIdx) = nAccept(jj,acceptIdx)+1;
					logPOld(acceptIdx) = logP(acceptIdx);
					oldParams(:,acceptIdx) = params(:,acceptIdx);

					rejectIdx = ~acceptIdx;
					iterations(jj,rejectIdx,ii) = oldParams(jj,rejectIdx);
				end % for(1:nParams)
				logPKeep(:,ii) = logPOld;
				if (mod(ii, this.nKernel) == 0)
					% Update kernel sigma every nKernel iterations to get kernel
					% sigma to converge on the target acceptance
					kernelSigma = kernelSigma.*(this.targetAccept*( ...
						this.nKernel+1)./(this.nKernel+1.-(nAccept-nAcceptCache)));
					nAcceptCache = nAccept;
				end
			end % for(1:this.nIter)
			[~,logPIdx] = max(logPKeep, [], 2);
			% Explicit loop for sigma to avoid creating a huge temporary array in
			% std()
			for ii=1:nY
				fitParams(:,ii) = iterations(:,ii,logPIdx(ii));
				for jj=1:nParams
					sigma(jj,ii) = std(iterations(jj,ii,this.nBurnIn+1:end));
				end
			end
			result = ether.optim.Result();
			result.parameters = fitParams;
			result.sigma = sigma;
		end

		%-------------------------------------------------------------------------
		function	result = solvePartitionInFlight(this, problem, x, y)
			dims = size(y);
			nY = dims(2);

			x = x(:);
			initial = problem.getInitialConditions(x, y);
			[lower,upper] = problem.getConstraints(x);
			nParams = problem.parameterCount;

			% Output arrays
			fitParams = zeros(nParams, nY);

			% Working arrays
			nAccept = zeros(nParams, nY);
			nAcceptCache = zeros(nParams, nY);
			kernelSigma = repmat(0.01*initial(:), 1, nY);
			oldParams = repmat(initial(:), 1, nY);
			resultOld = problem.evaluateArray(x, oldParams);
			logPOld = this.logLikelihood(y, resultOld);
			logPMax = logPOld;
			sigma1 = zeros(nParams, nY);
			sigma2 = zeros(nParams, nY);

			for ii=1:this.nIter
				for jj=1:nParams
					delta = randn(1, nY).*kernelSigma(jj,:);
					params = oldParams;
					params(jj,:) = params(jj,:)+delta;
					badIdx = (params(jj,:) < lower(jj)) | (params(jj,:) > upper(jj));
					params(jj,badIdx) = oldParams(jj,badIdx);

					result = problem.evaluateArray(x, params);
					nfIdx = ~all(isfinite(result), 1);
					goodIdx = ~(badIdx | nfIdx);
					logP = this.logLikelihood(y, result);
					alpha = exp(logP-logPOld);

					alphaIdx = rand(1, nY) <= alpha;
					acceptIdx = alphaIdx & goodIdx;
					nAccept(jj,acceptIdx) = nAccept(jj,acceptIdx)+1;
					logPOld(acceptIdx) = logP(acceptIdx);
					oldParams(jj,acceptIdx) = params(jj,acceptIdx);
				end % for(1:nParams)
				updateIdx = (logPMax < logPOld);
				fitParams(:,updateIdx) = oldParams(:,updateIdx);
				sigma1 = sigma1+fitParams;
				sigma2 = sigma2+fitParams.*fitParams;
				if (mod(ii, this.nKernel) == 0)
					% Update kernel sigma every nKernel iterations to get kernel
					% sigma to converge on the target acceptance
					kernelSigma = kernelSigma.*(this.targetAccept*( ...
						this.nKernel+1)./(this.nKernel+1.-(nAccept-nAcceptCache)));
					nAcceptCache = nAccept;
				end
			end % for(1:this.nIter)
			sigma = sqrt(...
				(this.nIter*sigma2-sigma1.*sigma1)/(this.nIter*(this.nIter-1)));
			result = ether.optim.Result();
			result.parameters = fitParams;
			result.sigma = sigma;
		end

	end

end

