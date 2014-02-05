classdef WangT1Converter < ether.process.Converter
	%WANGT1CONVERTER Summary of this class goes here
	%   Detailed explanation goes here

	properties(Constant,Access=private)
		logger = ether.log4m.Logger.getLogger('adept.convert.HelmsT1Converter');
	end

	properties(SetAccess=private)
		maximumT1 = 6.0;
	end

	methods
		%-------------------------------------------------------------------------
		function this = WangT1Converter()
			this@ether.process.Converter();
			import ether.process.*;
			this.name = 'Wang T1';
			this.description = 'Wang T1 Converter';
			this.inputCountMax = intmax;
			this.inputCountMin = 2;
			this.inputDescriptions = {'Variable Flip Angle'};
			inputType = [Modality.MR,Types.Signal];
			this.inputTypes = {inputType};
			this.outputType = Types.T1;
			this.outputDisplayMax = 1.5;
			this.requiredKeys = {'RepetitionTime';'FlipAngle'};
			this.units = Units.Seconds;
		end

		%-------------------------------------------------------------------------
		function result = convert(this, varargin)
			pixelData = varargin{1};
			props = varargin{2};
			allDimCount = cellfun(@(x) ndims(x), pixelData);
			excessIdx = find(allDimCount > 4);
			if ~isempty(excessIdx)
				throw(MException('ADEPT:Convert:WangT1Converter', ...
					sprintf('Unsupported number of dimensions: %i', ...
						allDimCount(excessIdx))));
			end
			allTr = cellfun(@(x) x('RepetitionTime')/1000, props);
			tr = allTr(1);
			alpha = cellfun(@(x) x('FlipAngle')*pi/180, props);
			lastwarn('');
			warning('off', 'MATLAB:singularMatrix');
			warning('off', 'MATLAB:nearlySingularMatrix');
			switch max(allDimCount)-min(allDimCount)
				case 0
					% Includes scalars and vectors
					result = this.convertDimMatch(pixelData, alpha, tr);

				case 1
					% 3D and 4D combination
					result = this.convert3D4D(pixelData, alpha, tr);

				otherwise
					warning('on', 'MATLAB:singularMatrix');
					warning('on', 'MATLAB:nearlySingularMatrix');
					throw(MException('ADEPT:Convert:WangT1Converter', ...
						'Unsupported combination of dimensions'));
			end
			warning('on', 'MATLAB:singularMatrix');
			warning('on', 'MATLAB:nearlySingularMatrix');
		end

	end

	methods(Access=private)
		%-------------------------------------------------------------------------
		function result = convert3D4D(this, pixelData, alpha, tr)
			nAlpha = numel(alpha);
			allDims = cellfun(@(x) size(x), pixelData, 'UniformOutput', false);
			allDimCount = cellfun(@(x) ndims(x), pixelData);
			quadIdx = find(allDimCount == 4);
			[nVol,quadBigIdx] = max(allDims{quadIdx}(4));
			bigIdx = quadIdx(quadBigIdx);
			if this.useVectors
				result = this.convertMPI(pixelData, alpha, tr, bigIdx);
				return;
			end
			if nAlpha == 2
				result = this.convertTwoPoint(pixelData, alpha, tr, bigIdx);
				return;
			end
			resultDims = allDims{bigIdx};
			[~,sysMem] = memory;
			nVec = prod(resultDims);
			% Factor of 10 approximately accounts for matrix ops in regressBulk()
			lowMem = nAlpha*nVec*4 > sysMem.PhysicalMemory.Available/10;
			if lowMem
				% Required RAM too large, system will almost certainly start paging
				this.logger.warn(...
					['Insufficient RAM available for requested array operation:', ...
					'using MPI implementation.']);
				result = this.convertMPI(pixelData, alpha, tr, bigIdx);
				return;
			end
			data = zeros([nAlpha,resultDims], 'single');
			for ii=1:nAlpha
				if ii == bigIdx
					data(ii,:,:,:,:) = pixelData{ii};
				else
					data(ii,:,:,:,:) = repmat(mean(pixelData{ii}, 4), [1,1,1,nVol]);
				end
			end
			data = reshape(data, nAlpha, nVec);
			invTanAlpha = repmat(1./tan(alpha), 1, nVec);
			invSinAlpha = repmat(1./sin(alpha), 1, nVec);
			gradient = this.regressBulk(data.*invTanAlpha, data.*invSinAlpha);
			data = [];
			invTanAlpha = [];
			invSinAlpha = [];
			gradient(gradient < 0) = nan;
			result = -tr./log(gradient);
			idx = ~isfinite(result) | (result > this.maximumT1) | (result <= 0);
			result(idx) = nan;
			result = reshape(result, resultDims);
		end

		%-------------------------------------------------------------------------
		function result = convertDimMatch(this, pixelData, alpha, tr)
			invTanAlpha = 1./tan(alpha);
			invSinAlpha = 1./sin(alpha);
			% All dimensions the same
			dimCount = ndims(pixelData{1});
			% Minimum of two dimensions.
			if dimCount == 2
				if all(cellfun(@(x) isscalar(x), pixelData))
					% All scalars
					data = pixelData{:};
					result = this.convertVector(data, invTanAlpha, invSinAlpha, tr);
					return;
				end
				if all(cellfun(@(x) isvector(x), pixelData))
					% All vectors
					lengths = cellfun(@(x) numel(x), pixelData);
					nAlpha = numel(alpha);
					[maxLength,maxIdx] = max(lengths);
					data = zeros(nAlpha, maxLength, 'single');
					% Replicate the mean of each shorter vector to the length of the
					% longest, pack with longest
					for ii=1:nAlpha
						if ii == maxIdx
							data(ii,:) = pixelData{ii};
						else
							data(ii,:) = repmat(mean(pixelData{ii}), maxLength);
						end
					end
					result = this.convert2D(data, invTanAlpha, invSinAlpha, tr);
					return;
				end
				% All 2D arrays
				this.logger.error('2D arrays not implemented yet.');
				result = zeros(size(pixelData{1}, 'single'));
				return;
			end
		end

		%-------------------------------------------------------------------------
		function result = convertMPI(this, pixelData, alpha, tr, dynIdx)
			invTanAlpha = 1./tan(alpha);
			invSinAlpha = 1./sin(alpha);
			dyn = pixelData{dynIdx};
			dims = size(dyn);
			nVec = prod(dims(1:3));
			vecLength = dims(4);
			dyn = shiftdim(dyn, 3);
			dyn = reshape(dyn, vecLength, nVec);
			nAlpha = numel(alpha);
			refIdx = find(1:nAlpha ~= dynIdx);
			nRef = numel(refIdx);
			refData = cell(nRef);
			for ii=1:nRef
				refData{ii} = reshape(mean(pixelData{ii}, 4), [1,nVec]);
			end
			result = zeros(size(dyn), 'single');

			if this.usePool
				nLab = ether.parallel.Pool.size;
				if nLab > 0
					this.logger.info(@() sprintf('Using %i labs in pool', nLab));
				else
					this.logger.warn(@() 'No labs avaiable in pool');
				end
				allInvTanAlpha = repmat(invTanAlpha, 1, vecLength);
				allInvSinAlpha = repmat(invSinAlpha, 1, vecLength);
				parfor ii=1:nVec
					data = zeros(nAlpha, 1, 'single');
					data(refIdx) = refData{refIdx}(ii);
					allData = repmat(data, 1, vecLength);
					allData(dynIdx,:) = dyn(:,ii);
					gradient = this.regressBulk(allData.*allInvTanAlpha, ...
						allData.*allInvSinAlpha);
					gradient(gradient < 0) = nan;
					result(:,ii) = -tr./log(gradient);
				end
			else
				allInvTanAlpha = repmat(invTanAlpha, 1, vecLength);
				allInvSinAlpha = repmat(invSinAlpha, 1, vecLength);
				data = zeros(nAlpha, 1, 'single');
				for ii=1:nVec
					data(refIdx) = refData{refIdx}(ii);
					allData = repmat(data, 1, vecLength);
					allData(dynIdx,:) = dyn(:,ii);
					gradient = this.regressBulk(allData.*allInvTanAlpha, ...
						allData.*allInvSinAlpha);
					gradient(gradient < 0) = nan;
					result(:,ii) = -tr./log(gradient);
				end
			end
			result = reshape(result, [vecLength,dims(1:3)]);
			result = shiftdim(result, 1);
			idx = ~isfinite(result) | (result > this.maximumT1) | (result < 0);
			result(idx) = nan;
		end

		%-------------------------------------------------------------------------
		function result = convertTwoPoint(this, pixelData, alpha, tr, dynIdx)
			dims = size(pixelData{dynIdx});
			nVec = prod(dims(1:3));
			nVol = dims(4);
			nAlpha = numel(alpha);
			dyn = shiftdim(pixelData{dynIdx}, 3);
			dyn = reshape(dyn, nVol, nVec);
			refIdx = 1:nAlpha ~= dynIdx;
			ref = repmat(mean(pixelData{refIdx}, 4), [1,1,1,nVol]);
			ref = shiftdim(ref, 3);
			ref = reshape(ref, nVol, nVec);
			invTanAlpha = 1./tan(alpha);
			invSinAlpha = 1./sin(alpha);
			gradient = (dyn.*invSinAlpha(dynIdx)-ref.*invSinAlpha(refIdx)) ./ ...
				(dyn.*invTanAlpha(dynIdx)-ref.*invTanAlpha(refIdx));
			gradient(gradient < 0) = nan;
			result = single(-tr./log(gradient));
			result = reshape(result, [nVol,dims(1:3)]);
			result = shiftdim(result, 1);
			idx = ~isfinite(result) | (result > this.maximumT1) | (result < 0);
			result(idx) = nan;
		end

		%-------------------------------------------------------------------------
		function result = convertVector(this, data, invTanAlpha, invSinAlpha, tr)
			indepData = data.*invTanAlpha;
			depData = data.*invSinAlpha;
			gradient = ether.regress(indepData, depData);
			gradient(gradient < 0) = nan;
			result = -tr./log(gradient);
			idx = ~isfinite(result) | (result > this.maximumT1) | (result < 0);
			result(idx) = nan;
		end

	end

end

