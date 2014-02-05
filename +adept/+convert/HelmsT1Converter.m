classdef HelmsT1Converter < ether.process.Converter
	%HELMST1CONVERTER Summary of this class goes here
	%   Detailed explanation goes here

	properties(Constant,Access=private)
		logger = ether.log4m.Logger.getLogger('adept.convert.HelmsT1Converter');
	end

	properties(SetAccess=private)
		maximumT1 = 6.0;
	end

	methods
		%-------------------------------------------------------------------------
		function this = HelmsT1Converter()
			this@ether.process.Converter();
			import ether.process.*;
			this.name = 'Helms T1';
			this.description = 'Helms T1 Converter';
			this.inputCountMax = 2;
			this.inputCountMin = 2;
			this.inputDescriptions = {'Low Flip Angle';'High Flip Angle'};
			inputType = [Modality.MR,Types.Signal];
			this.inputTypes = {inputType,inputType};
			this.outputType = Types.T1;
			this.outputDisplayMax = 1.5;
			this.outputDisplayMin = 0;
			this.requiredKeys = {'RepetitionTime';'FlipAngle'};
			this.units = Units.Seconds;
		end

		%-------------------------------------------------------------------------
		function result = convert(this, varargin)
			pixelData = varargin{1};
			props = varargin{2};
			refProps = props{1};
			tr = refProps('RepetitionTime')/1000;
			refAlpha = refProps('FlipAngle')*pi/180;
			dynProps = props{2};
			dynAlpha = dynProps('FlipAngle')*pi/180;
			if isvector(pixelData{2})
				result = this.convertVector(pixelData{1}, pixelData{2}, refAlpha, ...
					dynAlpha, tr);
				return;
			end
			if this.useVectors
				result = this.convertMPI(pixelData{1}, pixelData{2}, refAlpha, ...
					dynAlpha, tr);
				return;
			end
			dynDims = size(pixelData{2});
			dimCount = ndims(pixelData{2});
			ref = mean(pixelData{1}, dimCount);
			switch dimCount
				case 4
					nVol = dynDims(4);
					ref = repmat(ref, [1,1,1,nVol]);

				case 2
					nVec = dynDims(2);
					ref = repmat(ref, [1,nVec]);

				otherwise
					throw(MException('ADEPT:Convert:HelmsT1Converter', ...
						sprintf('Unsupported number of dimensions: %i', dimCount)));
			end
			result = 2*tr*( ...
				(ref/refAlpha-pixelData{2}/dynAlpha) ./ ...
				(pixelData{2}*dynAlpha-ref*refAlpha));
			idx = ~isfinite(result) | (result > this.maximumT1) | (result < 0);
			result(idx) = nan;
		end

	end

	methods(Access=private)
		%-------------------------------------------------------------------------
		function result = convertMPI(this, ref, dyn, refAlpha, dynAlpha, tr)
			this.logger.debug(@() 'MPI path');
			dimCount = ndims(dyn);
			switch dimCount
				case 4
					result = this.convertMPI4D(ref, dyn, refAlpha, dynAlpha, tr);

				case 2
					result = this.convertMPI2D(ref, dyn, refAlpha, dynAlpha, tr);

				otherwise
					throw(MException('ADEPT:Convert:HelmsT1Converter', ...
						sprintf('Unsupported number of dimensions: %i', dimCount)));
			end
		end

		%-------------------------------------------------------------------------
		function result = convertMPI2D(this, ref, dyn, refAlpha, dynAlpha, tr)
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
					result(:,ii) = this.convertVector(ref(ii), dyn(:,ii), refAlpha, ...
						dynAlpha, tr);
				end
			else
				for ii=1:nVec
					result(:,ii) = this.convertVector(ref(ii), dyn(:,ii), refAlpha, ...
						dynAlpha, tr);
				end
			end
		end

		%-------------------------------------------------------------------------
		function result = convertMPI4D(this, ref, dyn, refAlpha, dynAlpha, tr)
			dynDims = size(dyn);
			nVec = prod(dynDims(1:3));
			vecLength = dynDims(4);
			dyn = shiftdim(dyn, 3);
			dyn = reshape(dyn, vecLength, nVec);
			nRefDims = ndims(ref);
			if nRefDims == 4
				newRef = shiftdim(ref, 3);
				newRef = mean(newRef, 1);
			else
				newRef = ref;
			end
			newRef = reshape(newRef, 1, nVec);
			result = this.convertMPI2D(newRef, dyn, refAlpha, dynAlpha, tr);
			result = reshape(result, [vecLength,dynDims(1:3)]);
			result = shiftdim(result, 1);
		end

		%-------------------------------------------------------------------------
		function result = convertVector(this, ref, dyn, refAlpha, dynAlpha, tr)
			if ~isscalar(ref)
				ref = mean(ref);
			end
			result = 2*tr*( ...
				(ref/refAlpha-dyn/dynAlpha)./(dyn*dynAlpha-ref*refAlpha));
			idx = ~isfinite(result) | (result > this.maximumT1) | (result < 0);
			result(idx) = nan;
		end

	end

end

