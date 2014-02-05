classdef MZeroGdConverter < ether.process.TimeSeriesConverter
	%MZEROGDCONVERTER Summary of this class goes here
	%   Detailed explanation goes here

	properties(Constant,Access=private)
		logger = ether.log4m.Logger.getLogger('adept.convert.MZeroGdConverter');
	end

	properties(SetAccess=private)
		t1Relaxivity = 4.3;
	end

	properties(Access=private)
		t1Converter;
	end

	methods
		%-------------------------------------------------------------------------
		function this = MZeroGdConverter()
			this@ether.process.TimeSeriesConverter();
			import ether.process.*;
			addlistener(this, 'usePool', 'PostSet', @this.onUsePool);
			addlistener(this, 'useVectors', 'PostSet', @this.onUseVectors);
			this.t1Converter = adept.convert.MZeroT1Converter();
			this.register(this.t1Converter);
			this.name = 'M0 Gd';
			this.description = 'M0 [Gd] Converter';
			this.inputCountMax = this.t1Converter.inputCountMax;
			this.inputCountMin = this.t1Converter.inputCountMin;
			this.inputDescriptions = this.t1Converter.inputDescriptions;
			this.inputTypes = this.t1Converter.inputTypes;
			this.outputType = Types.Concentration;
			this.outputDisplayMax = 1.0;
			this.requiredKeys = this.t1Converter.requiredKeys;
			this.units = Units.Mmol;
		end

		%-------------------------------------------------------------------------
		function result = convert(this, varargin)
			pixelData = varargin{1};
			props = varargin{2};
			allDimCount = cellfun(@(x) ndims(x), pixelData);
			excessIdx = find(allDimCount > 4);
			if ~isempty(excessIdx)
				throw(MException('ADEPT:Convert:MZeroGdConverter', ...
					sprintf('Unsupported number of dimensions: %i', ...
						allDimCount(excessIdx))));
			end
			switch max(allDimCount)-min(allDimCount)
				case 0
					% Includes scalars and vectors
					result = this.convertDimMatch(pixelData, props);

				case 1
					% 3D and 4D combination
					result = this.convert3D4D(pixelData, props);

				otherwise
					throw(MException('ADEPT:Convert:MZeroGdConverter', ...
						'Unsupported combination of dimensions'));
			end
		end

	end

	methods(Access=private)
		%-------------------------------------------------------------------------
		function result = convert3D4D(this, pixelData, props)
			if this.useVectors
				allDims = cellfun(@(x) size(x), pixelData, 'UniformOutput', false);
				allDimCount = cellfun(@(x) ndims(x), pixelData);
				quadIdx = find(allDimCount == 4);
				[~,quadBigIdx] = max(allDims{quadIdx}(4));
				bigIdx = quadIdx(quadBigIdx);
				result = this.convertMPI(pixelData, props, bigIdx);
				return;
			end
			% Array-op implementation
			r1 = 1./this.t1Converter.convert(pixelData, props);
			dims = size(r1);
			nVol = dims(4);
			initialR1 = mean(r1(:,:,:,1:this.initialCount), 4);
			initialR1 = repmat(initialR1, [1,1,1,nVol]);
			result = (r1-initialR1)./this.t1Relaxivity;
			badIdx = find(any(~isfinite(result), 4));
			if ~isempty(badIdx)
				result = reshape(result, prod(dims(1:3)), nVol);
				result(badIdx,:) = 0;
				result = reshape(result, dims);
			end
		end

		%-------------------------------------------------------------------------
		function result = convertMPI(this, pixelData, props, bigIdx)
			r1 = 1./this.t1Converter.convert(pixelData, props);
			dimCount = ndims(pixelData{bigIdx});
			switch dimCount
				case 4
					result = this.convertMPI4D(r1);

				case 2
					result = this.convertMPI2D(r1);

				otherwise
					throw(MException('ADEPT:Convert:MZeroGdConverter', ...
						sprintf('Unsupported number of dimensions: %i', dimCount)));
			end
		end

		%-------------------------------------------------------------------------
		function result = convertMPI2D(this, r1)
			dims = size(r1);
			nVec = dims(2);
			result = zeros(dims, 'single');

			if this.usePool
				nLab = ether.parallel.Pool.size;
				if nLab > 0
					this.logger.info(@() sprintf('Using %i labs in pool', nLab));
				else
					this.logger.warn(@() 'No labs available in pool');
				end
				parfor ii=1:nVec
					result(:,ii) = this.convertVector(r1(:,ii));
				end
			else
				for ii=1:nVec
					result(:,ii) = this.convertVector(r1(:,ii));
				end
			end
		end

		%-------------------------------------------------------------------------
		function result = convertMPI4D(this, r1)
			dims = size(r1);
			nVec = prod(dims(1:3));
			vecLength = dims(4);
			r1 = shiftdim(r1, 3);
			r1 = reshape(r1, vecLength, nVec);
			result = this.convertMPI2D(r1);
			result = reshape(result, [vecLength,dims(1:3)]);
			result = shiftdim(result, 1);
		end

		%-------------------------------------------------------------------------
		function result = convertVector(this, r1)
			if any(~isfinite(r1))
				result = zeros(size(r1));
				return;
			end
			initialR1 = mean(r1(1:this.initialCount));
			result = (r1-initialR1)/this.t1Relaxivity;
		end

		%-------------------------------------------------------------------------
		function onUsePool(this, source, event)
			this.t1Converter.usePool = this.usePool;
		end

		%-------------------------------------------------------------------------
		function onUseVectors(this, source, event)
			this.t1Converter.useVectors = this.useVectors;
		end

	end

end

