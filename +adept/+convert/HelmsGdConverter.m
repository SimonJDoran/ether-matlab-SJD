classdef HelmsGdConverter < ether.process.TimeSeriesConverter
	%HELMSGDCONVERTER Summary of this class goes here
	%   Detailed explanation goes here

	properties(Constant,Access=private)
		logger = ether.log4m.Logger.getLogger('adept.convert.HelmsGdConverter');
	end

	properties(SetAccess=private)
		t1Relaxivity = 4.3;
	end

	properties(Access=private)
		t1Converter;
	end

	methods
		%-------------------------------------------------------------------------
		function this = HelmsGdConverter()
			this@ether.process.TimeSeriesConverter();
			import ether.process.*;
			addlistener(this, 'usePool', 'PostSet', @this.onUsePool);
			addlistener(this, 'useVectors', 'PostSet', @this.onUseVectors);
			this.t1Converter = adept.convert.HelmsT1Converter();
			this.register(this.t1Converter);
			this.name = 'Helms Gd';
			this.description = 'Helms [Gd] Converter';
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
			if isvector(pixelData{2})
				r1 = 1./this.t1Converter.convert(pixelData, props);
				result = this.convertVector(r1);
				return;
			end
			if this.useVectors
				result = this.convertMPI(pixelData, props);
				return;
			end
			r1 = 1./this.t1Converter.convert(pixelData, props);
			dims = size(r1);
			dimCount = ndims(r1);
			switch dimCount
				case 4
					nVol = dims(4);
					initialR1 = mean(r1(:,:,:,1:this.initialCount), 4);
					initialR1 = repmat(initialR1, [1,1,1,nVol]);
					result = (r1-initialR1)/this.t1Relaxivity;
					badIdx = find(any(~isfinite(result), 4));
					if ~isempty(badIdx)
						result = reshape(result, prod(dims(1:3)), nVol);
						result(badIdx,:) = 0;
						result = reshape(result, dims);
					end

				case 2
					nVec = dims(2);
					initialR1 = mean(r1(1:this.initialCount,:), 1);
					initialR1 = repmat(initialR1, [1,nVec]);
					result = (r1-initialR1)/this.t1Relaxivity;
					badIdx = find(any(~isfinite(result), 1));
					if ~isempty(badIdx)
						result(:,badIdx) = 0;
					end

				otherwise
					throw(MException('ADEPT:Convert:HelmsT1Converter', ...
						sprintf('Unsupported number of dimensions: %i', dimCount)));
			end
		end

	end

	methods(Access=private)
		%-------------------------------------------------------------------------
		function result = convertMPI(this, pixelData, props)
			this.logger.debug(@() 'MPI path');
			dimCount = ndims(pixelData{2});
			switch dimCount
				case 4
					result = this.convertMPI4D(pixelData, props);

				case 2
					result = this.convertMPI2D(pixelData{1}, pixelData{2}, props);

				otherwise
					throw(MException('ADEPT:Convert:HelmsGdConverter', ...
						sprintf('Unsupported number of dimensions: %i', dimCount)));
			end
		end

		%-------------------------------------------------------------------------
		function result = convertMPI2D(this, ref, dyn, props)
			dims = size(dyn);
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
					r1 = 1./this.t1Converter.convert({ref(ii),dyn(:,ii)}, props);
					result(:,ii) = this.convertVector(r1);
				end
			else
				for ii=1:nVec
					r1 = 1./this.t1Converter.convert({ref(ii),dyn(:,ii)}, props);
					result(:,ii) = this.convertVector(r1);
				end
			end
		end

		%-------------------------------------------------------------------------
		function result = convertMPI4D(this, pixelData, props)
			dims = size(pixelData{2});
			nVec = prod(dims(1:3));
			vecLength = dims(4);
			dyn = shiftdim(pixelData{2}, 3);
			dyn = reshape(dyn, vecLength, nVec);
			nRefDims = ndims(pixelData{1});
			if nRefDims == 4
				ref = shiftdim(pixelData{1}, 3);
				ref = mean(ref, 1);
			else
				ref = pixelData{1};
			end
			ref = reshape(ref, 1, nVec);
			result = this.convertMPI2D(ref, dyn, props);
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

