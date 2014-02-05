classdef MZeroT1Converter < ether.process.Converter
	%MZEROT1CONVERTER Summary of this class goes here
	%   Detailed explanation goes here

	properties(Constant,Access=private)
		logger = ether.log4m.Logger.getLogger('adept.convert.MZeroT1Converter');
	end

	properties(SetAccess=private)
		maximumT1 = 6.0;
	end

	properties(Access=private)
		m0Converter;
	end

	methods
		%-------------------------------------------------------------------------
		function this = MZeroT1Converter()
			this@ether.process.Converter();
			import ether.process.*;
			addlistener(this, 'usePool', 'PostSet', @this.onUsePool);
			addlistener(this, 'useVectors', 'PostSet', @this.onUseVectors);
			this.m0Converter = adept.convert.MZeroConverter();
			this.register(this.m0Converter);
			this.name = 'M0 T1';
			this.description = 'M0 T1 Converter';
			this.inputCountMax = this.m0Converter.inputCountMax;
			this.inputCountMin = this.m0Converter.inputCountMin;
			this.inputDescriptions = this.m0Converter.inputDescriptions;
			this.inputTypes = this.m0Converter.inputTypes;
			this.outputType = Types.T1;
			this.outputDisplayMax = 1.5;
			this.requiredKeys = unique(...
				{this.m0Converter.requiredKeys{:},'FlipAngle','RepetitionTime'});
			this.units = Units.Seconds;
		end

		%-------------------------------------------------------------------------
		function result = convert(this, varargin)
			pixelData = varargin{1};
			props = varargin{2};
			allDimCount = cellfun(@(x) ndims(x), pixelData);
			excessIdx = find(allDimCount > 4);
			if ~isempty(excessIdx)
				throw(MException('ADEPT:Convert:MZeroT1Converter', ...
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
					throw(MException('ADEPT:Convert:MZeroT1Converter', ...
						'Unsupported combination of dimensions'));
			end
		end

	end

	methods(Access=private)
		%-------------------------------------------------------------------------
		function result = convert3D4D(this, pixelData, props)
			allDims = cellfun(@(x) size(x), pixelData, 'UniformOutput', false);
			allDimCount = cellfun(@(x) ndims(x), pixelData);
			quadIdx = find(allDimCount == 4);
			[~,quadBigIdx] = max(allDims{quadIdx}(4));
			bigIdx = quadIdx(quadBigIdx);
			if this.useVectors
				result = this.convertMPI(pixelData, props, bigIdx);
				return;
			end
			% Array-op implementation
			m0 = this.m0Converter.convert(pixelData, props);
			tr = props{bigIdx}('RepetitionTime')/1000;
			alpha = props{bigIdx}('FlipAngle')*pi/180;
			m0Dyn = pixelData{bigIdx};
			result = (1-m0Dyn./(m0.*sin(alpha)))./(1-m0Dyn./(m0.*tan(alpha)));
			result(result < 0) = nan;
			result = -tr./log(result);
			idx = ~isfinite(result) | (result > this.maximumT1) | (result < 0);
			result(idx) = nan;
		end

		%-------------------------------------------------------------------------
		function result = convertMPI(this, pixelData, props, bigIdx)
			m0 = this.m0Converter.convert(pixelData, props);
			tr = props{bigIdx}('RepetitionTime')/1000;
			alpha = props{bigIdx}('FlipAngle')*pi/180;
			dimCount = ndims(pixelData{bigIdx});
			switch dimCount
				case 4
					result = this.convertMPI4D(m0, pixelData{bigIdx}, alpha, tr);

				case 2
					result = this.convertMPI2D(m0, pixelData{bigIdx}, alpha, tr);

				otherwise
					throw(MException('ADEPT:Convert:MZeroT1Converter', ...
						sprintf('Unsupported number of dimensions: %i', dimCount)));
			end
		end

		%-------------------------------------------------------------------------
		function result = convertMPI2D(this, m0, dyn, alpha, tr)
			dims = size(dyn);
			nVec = dims(2);
			result = zeros(dims, 'single');
			sinAlpha = sin(alpha);
			tanAlpha = tan(alpha);

			if this.usePool
				nLab = ether.parallel.Pool.size;
				if nLab > 0
					this.logger.info(@() sprintf('Using %i labs in pool', nLab));
				else
					this.logger.warn(@() 'No labs available in pool');
				end
				parfor ii=1:nVec
					result(:,ii) = this.convertVector(...
						m0(ii), dyn(:,ii), sinAlpha, tanAlpha, tr);
				end
			else
				for ii=1:nVec
					result(:,ii) = this.convertVector(...
						m0(ii), dyn(:,ii), sinAlpha, tanAlpha, tr);
				end
			end
		end

		%-------------------------------------------------------------------------
		function result = convertMPI4D(this, m0, dyn, alpha, tr)
			dynDims = size(dyn);
			nVec = prod(dynDims(1:3));
			vecLength = dynDims(4);
			dyn = shiftdim(dyn, 3);
			dyn = reshape(dyn, vecLength, nVec);
			nM0Dims = ndims(m0);
			if nM0Dims == 4
				newM0 = shiftdim(m0, 3);
				newM0 = mean(newM0, 1);
			else
				newM0 = m0;
			end
			newM0 = reshape(newM0, 1, nVec);
			result = this.convertMPI2D(newM0, dyn, alpha, tr);
			result = reshape(result, [vecLength,dynDims(1:3)]);
			result = shiftdim(result, 1);
		end

		%-------------------------------------------------------------------------
		function result = convertVector(this, m0, dyn, sinAlpha, tanAlpha, tr)
			if ~isscalar(m0)
				m0 = mean(m0);
			end
			result = (1-dyn./(m0.*sinAlpha))./(1-dyn./(m0.*tanAlpha));
			result(result < 0) = nan;
			result = -tr./log(result);
			idx = ~isfinite(result) | (result > this.maximumT1) | (result < 0);
			result(idx) = nan;
		end

		%-------------------------------------------------------------------------
		function onUsePool(this, source, event)
			this.m0Converter.usePool = this.usePool;
		end

		%-------------------------------------------------------------------------
		function onUseVectors(this, source, event)
			this.m0Converter.useVectors = this.useVectors;
		end

	end

end


