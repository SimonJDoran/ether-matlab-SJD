classdef TimeSeriesProblemProcessor < ether.process.Processor
	%MODELPROCESSOR Summary of this class goes here
	%   Detailed explanation goes here
	
	properties(Constant,Access=private)
		logger = ether.log4m.Logger.getLogger('ether.process.TimeSeriesProblemProcessor');
	end

	methods
		%-------------------------------------------------------------------------
		function this = TimeSeriesProblemProcessor(id, inputIDs, targetID, entityIDs)
			this = this@ether.process.Processor(id, inputIDs, targetID, entityIDs);
			this.targetType = ether.process.Processor.ProblemResult;
		end

		%-------------------------------------------------------------------------
		function bool = process(this, input, target, entities)
			[problem,solver,extractor,locator] = ...
				this.checkProcessArgs(input, target, entities);
			this.logger.debug(...
				@() sprintf('TimeSeriesProblemProcessor running %s with %s', ...
					class(problem), class(solver)));
			dim = input.dimensions(4);
			timeIdx = find(strcmp(dim.labels, 'Time') == 1);
			time = dim.getValuesForLevel(timeIdx);
			time = time-time(1);

			% Only use part of the data. Slices 2:3 and region (115:140,150:175)
			dims = size(input.pixelData);
			nX = dims(1);
			nY = dims(2);
			nZ = dims(3);
			nT = dims(4);
			nVec = prod(dims(1:3));
			mask = zeros(nX, nY, nZ);
			mask(111:176,85:165,2:3) = 1;
%			mask(111:121,85:95,2:3) = 1;
			mask = reshape(mask, nVec, 1);
			idx = find(mask == 1);
			pixelData = shiftdim(input.pixelData, 3);
			pixelData = reshape(pixelData, nT, nVec);
			pixelData = pixelData(:,idx);

			curve = extractor.extract(pixelData);
			onset = locator.locate(time, curve);
			problem.onset = double(onset*problem.abscissaScale);

			result = solver.solve(problem, time, pixelData);
			target.set(input, problem, solver, result, idx);

			target.isReady = true;
			bool = true;
		end
	end

	methods(Access=private)
		%-------------------------------------------------------------------------
		function [problem,solver,extractor,locator] = ...
				checkProcessArgs(this, input, target, entities)
			import ether.process.*;
			problemIdx = find(arrayfun(@(x) isa(x.entity, 'ether.optim.Problem'), ...
				entities));
			if (numel(problemIdx) ~= 1)
				throw(MException('Ether:Process:TimeSeriesProblemProcessor', ...
					'No ether.optim.Problem entity found'));
			end
			problem = entities(problemIdx).entity;
			solver = [];
			if isa(problem, 'ether.optim.Evaluable')
				solverIdx = find(arrayfun(@(x) isa(x.entity, 'ether.optim.Solver'), ...
					entities));
				if isempty(solverIdx)
					throw(MException('Ether:Process:TimeSeriesProblemProcessor', ...
						'No ether.optim.Solver found for ether.optim.Evaluable problem'));
				end
				if numel(solverIdx) > 1
					throw(MException('Ether:Process:TimeSeriesProblemProcessor', ...
						'Multiple ether.optim.Solvers found'));
				end
				solver = entities(solverIdx).entity;
			end
			extractorIdx = find(...
				arrayfun(@(x) isa(x.entity, 'ether.process.CurveExtractor'), ...
					entities));
			if (numel(extractorIdx) ~= 1)
				extractor = Toolkit.getToolkit.createCurveExtractor;
				this.logger.warn(...
					sprintf('No ether.process.CurveExtractor entity found, using default: %s', ...
					class(extractor)));
			else
				extractor = entities(extractorIdx).entity;
			end
			locatorIdx = find(...
				arrayfun(@(x) isa(x.entity, 'ether.process.OnsetLocator'), ...
					entities));
			if (numel(locatorIdx) ~= 1)
				locator = Toolkit.getToolkit.createOnsetLocator;
				this.logger.warn(...
					sprintf('No ether.process.OnsetLocator entity found, using default: %s', ...
					class(locator)));
			else
				locator = entities(locatorIdx).entity;
			end
			if ~isa(target, 'ether.process.ProblemResult')
				throw(MException('Ether:Process:TimeSeriesProblemProcessor', ...
					'Target does not inherit ether.process.ProblemResult'));
			end
		end

	end
	
end

