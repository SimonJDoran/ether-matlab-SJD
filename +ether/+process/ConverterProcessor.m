classdef ConverterProcessor < ether.process.Processor
	%CONVERTERPROCESSOR Summary of this class goes here
	%   Detailed explanation goes here

	properties(Constant,Access=private)
		logger = ether.log4m.Logger.getLogger('ether.process.ConverterProcessor');
	end

	methods
		%-------------------------------------------------------------------------
		function this = ConverterProcessor(id, inputIDs, targetID, entityIDs)
			this = this@ether.process.Processor(id, inputIDs, targetID, entityIDs);
			this.targetType = ether.process.Processor.ImageVolume;
		end

		%-------------------------------------------------------------------------
		function bool = process(this, inputs, target, entities)
			this.checkProcessArgs(inputs, target, entities);
			converter = entities(1).entity;
			this.logger.debug(@() sprintf('ConverterProcessor running %s', ...
				class(converter)));
			keys = converter.requiredKeys;
			nKeys = numel(keys);
			nInputs = numel(inputs);
			allPixelData = cell(nInputs, 1);
			allProperties = cell(nInputs, 1);
			for ii=1:nInputs
				allPixelData{ii} = inputs(ii).pixelData;
				image = inputs(ii).getImage(1);
				dicomInfo = image.sopInstance.dicomInfo;
				properties = containers.Map();
				for jj=1:nKeys
					key = keys{jj};
					properties(key) = dicomInfo.(key);
				end
				allProperties{ii} = properties;
			end
			tic;
			target.pixelData = converter.convert(allPixelData, allProperties);
			time = toc;
			this.logger.info(@() sprintf('Exec time for conversion: %gs', time));

			allDims = cellfun(@(x) size(x), allPixelData, 'UniformOutput', false);
			allDimCount = cellfun(@(x) ndims(x), allPixelData);
			quadIdx = find(allDimCount == 4);
			[nVol,quadBigIdx] = max(allDims{quadIdx}(4));
			bigIdx = quadIdx(quadBigIdx);
			source = inputs(bigIdx);

			newDims = this.createDimensions(converter, source);
			target.pixelWidth = source.pixelWidth;
			target.pixelHeight = source.pixelHeight;
			target.pixelDepth = source.pixelDepth;
			target.dimensions = newDims;
			if this.hasValidDisplayLimits(converter)
				target.displayMax = converter.outputDisplayMax;
				target.displayMin = converter.outputDisplayMin;
			end
			target.valueType = converter.outputType;
			target.label = converter.outputType;
			target.isReady = true;
			bool = true;
		end
	end

	methods(Access=private)
		%-------------------------------------------------------------------------
		function checkProcessArgs(this, inputs, target, entities)
			if (numel(entities) ~= 1) || ...
				~isa(entities(1).entity, 'ether.process.Converter')
				throw(MException('Ether:Process:ConverterProcessor', ...
					'Entity must inherit from ether.process.Converter'));
			end
			converter = entities(1).entity;
			nInputs = numel(inputs);
			if (nInputs < converter.inputCountMin) || ...
				(nInputs > converter.inputCountMax)
				throw(MException('Ether:Process:ConverterProcessor', ...
					sprintf('%s requires between %i and %i inputs, %i found', ...
						class(converter), converter.inputCountMin, ...
						converter.inputCountMax, nInputs)));
			end
			if ~all(isa(inputs, 'ether.process.DicomImageVolume')) || ...
				~all(strcmp(ether.dicom.Modality.MR, {inputs.modality}))
				throw(MException('Ether:Process:ConverterProcessor', ...
					sprintf('%s requires modality of %s', class(converter), ...
						ether.dicom.Modality.MR)));
			end
		end

		%-------------------------------------------------------------------------
		function dims = createDimensions(this, converter, source)
			dims = ether.process.Dimension.empty(0, 4);
			for ii=1:4
				dims(ii) = source.dimensions(ii);
			end
			if isa(converter, 'ether.process.TimeSeriesConverter')
				dims(4) = this.createTimingDimension(source);
				return;
			end
		end

		%-------------------------------------------------------------------------
		function dim = createTimingDimension(~, source)
			import ether.dicom.*;
			import ether.process.*;
			nZ = source.dimensions(3).length;
			volDim = source.dimensions(4);
			nVol = volDim.length;
			images = source.getImageList().toArray();
			timingData = TimingData.empty(nVol, 0);
			for ii=1:nVol
				idx = ii*nZ;
				timingData(ii) = Utils.createTimingData(images(ii*nZ));
			end
			if numel(unique([timingData.geCtTime])) == nVol
				imageTime = [timingData.geCtTime];
			elseif numel(unique([timingData.acqTime])) == nVol
				imageTime = [timingData.acqTime];
			elseif numel(unique([timingData.contentTime])) == nVol
				imageTime = [timingData.contentTime];
			elseif numel(unique([timingData.triggerTime])) == nVol
				imageTime = [timingData.triggerTime];
			elseif numel(unique([timingData.tempPosId])) == nVol
				imageTime = [timingData.tempPosId];
			else
				throw(MException('Ether:Process:ConverterProcessor', ...
					'Unable to determine image timing'));
			end
			imageTime = imageTime-imageTime(1);
			values = [volDim.values;{imageTime}];
			labels = repmat(cellstr(''), volDim.nLevels+1, 1);
			units = repmat(cellstr(''), volDim.nLevels+1, 1);
			for ii=1:volDim.nLevels
				if ~isempty(volDim.labels{ii})
					labels{ii} = volDim.labels{ii};
				end
				if ~isempty(volDim.units{ii})
					units{ii} = volDim.units{ii};
				end
			end
			labels{end} = 'Time';
			units{end} = Units.Seconds;
			dim = Dimension(values, labels, units);
		end

		%-------------------------------------------------------------------------
		function bool = hasValidDisplayLimits(~, converter)
			bool = ((converter.outputDisplayMax ~= 0) || ...
					  (converter.outputDisplayMin ~= 0)) && ...
					 (converter.outputDisplayMax > converter.outputDisplayMin);
		end

	end
end

