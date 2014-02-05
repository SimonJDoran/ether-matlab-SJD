classdef ProblemResult < ether.process.Node
	%MODELRESULT Summary of this class goes here
	%   Detailed explanation goes here

	properties(SetAccess=protected)
		source;
		problem;
		solver;
		parameters;
		derived;
		sigma = [];
		sigmaType = ether.optim.Solver.NA;
		code;
		thrown;
	end

	methods
		%-------------------------------------------------------------------------
		function this = ProblemResult(id)
			this@ether.process.Node(id);
			this.label = sprintf('ProblemResult %i', id);
		end

		%-------------------------------------------------------------------------
		function set(this, source, problem, solver, result, varargin)
			import ether.process.*;
			import ether.optim.*;
			% Option idx argument specifies indices of result in volume
			if numel(varargin) == 1
				idx = varargin{1};
			else
				idx = [];
			end
			toolkit = Toolkit.getToolkit();
			this.source = source;
			this.problem = problem;
			this.solver = solver;
			this.sigmaType = result.sigmaType;
			pixDims = size(source.pixelData);
			nParams = problem.parameterCount;
			this.parameters = ImageVolume.empty(nParams, 0);
			if iscell(problem.parameterRanges) && ...
				numel(problem.parameterRanges) == nParams
				paramRanges = problem.parameterRanges;
			else
				paramRanges = [];
			end
			for ii=1:nParams
				iv = ImageVolume(toolkit.getId());
				if isempty(idx)
					pixelData = result.parameters(ii,:);
					pixelData = reshape(pixelData, pixDims(1:3));
				else
					pixelData = zeros(prod(pixDims(1:3)), 1, 'single');
					pixelData(idx) = result.parameters(ii,:);
					pixelData = reshape(pixelData, pixDims(1:3));
				end
				iv.pixelData = pixelData;
				iv.label = problem.parameterNames{ii};
				iv.dimensions = Dimension.empty(4, 0);
				for jj=1:3
					iv.dimensions(jj) = source.dimensions(jj).clone;
				end
				iv.dimensions(4) = Dimension({1}, {'Volume'});
				if ~isempty(paramRanges) && numel(paramRanges{ii}) == 2 && ...
					paramRanges{ii}(1) < paramRanges{ii}(2)
					iv.displayMin = paramRanges{ii}(1);
					iv.displayMax = paramRanges{ii}(2);
				end
				this.parameters(ii) = iv;
			end
			nDerived = problem.derivedCount;
			this.derived = ImageVolume.empty(nDerived, 0);
			if iscell(problem.derivedRanges) && ...
				numel(problem.derivedRanges) == nDerived
				derivedRanges = problem.derivedRanges;
			else
				derivedRanges = [];
			end
			for ii=1:nDerived
				iv = ImageVolume(toolkit.getId());
				if isempty(idx)
					pixelData = result.derived(ii,:);
					pixelData = reshape(pixelData, pixDims(1:3));
				else
					pixelData = zeros(prod(pixDims(1:3)), 1, 'single');
					pixelData(idx) = result.derived(ii,:);
					pixelData = reshape(pixelData, pixDims(1:3));
				end
				iv.pixelData = pixelData;
				iv.label = problem.derivedNames{ii};
				iv.dimensions = Dimension.empty(4, 0);
				for jj=1:3
					iv.dimensions(jj) = source.dimensions(jj).clone;
				end
				iv.dimensions(4) = Dimension({1}, {'Volume'});
				if ~isempty(derivedRanges) && numel(derivedRanges{ii}) == 2 && ...
					derivedRanges{ii}(1) < derivedRanges{ii}(2)
					iv.displayMin = derivedRanges{ii}(1);
					iv.displayMax = derivedRanges{ii}(2);
				end
				this.derived(ii) = iv;
			end
			if isempty(idx)
				this.code = result.code;
				this.code = reshape(this.code, pixDims(1:3));
				this.thrown = result.thrown;
				this.thrown = reshape(this.thrown, pixDims(1:3));
			else
				this.code = repmat(Solver.NeverEvaluated, prod(pixDims(1:3)), 1);
				this.code(idx) = result.code;
				this.code = reshape(this.code, pixDims(1:3));
				this.thrown = cell(prod(pixDims(1:3)), 1);
				this.thrown(idx) = result.thrown(:);
				this.thrown = reshape(this.thrown, pixDims(1:3));
			end
			
			hasSigma = this.sigmaType ~= ether.optim.Solver.NA;
			if (hasSigma)
				this.sigma = ImageVolume.empty(nParams, 0);
				for ii=1:nParams
					iv = ImageVolume(toolkit.getId());
					if isempty(idx)
						pixelData = result.sigma;
						pixelData = reshape(pixelData, pixDims(1:3));
					else
						pixelData = zeros(prod(pixDims(1:3)), 1, 'single');
						pixelData(idx) = result.sigma(ii,:);
						pixelData = reshape(pixelData, pixDims(1:3));
					end
					iv.pixelData = pixelData;
					iv.label = sprintf('Sigma %s (%s)', problem.parameterNames{ii}, ...
						this.sigmaType);
					iv.dimensions = Dimension.empty(4, 0);
					for jj=1:3
						iv.dimensions(jj) = source.dimensions(jj).clone;
					end
					iv.dimensions(4) = Dimension({1}, {'Volume'});
					this.sigma(ii) = iv;
				end
			end
		end
	end

end

