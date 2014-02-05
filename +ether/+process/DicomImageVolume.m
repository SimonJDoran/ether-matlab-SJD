classdef DicomImageVolume < ether.process.ImageVolume & ether.process.Loadable
	%DICOMIMAGEVOLUME Summary of this class goes here
	%   Detailed explanation goes here
	
	properties(Constant)
		logger = ether.log4m.Logger.getLogger('ether.process.DicomImageVolume');
	end

	properties
		frameOfReferenceUid = [];
		patientDob = [];
		patientId = [];
		patientName = [];
		studyUid = [];
		modality = [];
	end

	properties(Access=private)
		imageMap;
		seriesMap;
		sopInstMap;
	end

	methods
		%-------------------------------------------------------------------------
		function this = DicomImageVolume(id)
			this@ether.process.ImageVolume(id);
			this.imageMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
			this.seriesMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
			this.sopInstMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
		end

		%-------------------------------------------------------------------------
		function image = getImage(this, idx)
			values = this.imageMap.values;
			allImages = [values{:}];
			sortValues = arrayfun(@(x) this.naturalOrderKey(x), allImages);
			[~,sortIdx] = sort(sortValues);
			image = allImages(sortIdx(idx));
		end

		%-------------------------------------------------------------------------
		function list = getImageList(this, orderBy)
			list = ether.collect.CellArrayList('ether.dicom.Image');
			values = this.imageMap.values;
			images = [values{:}];
			sortValues = arrayfun(@(x) this.naturalOrderKey(x), images);
			[~,sortIdx] = sort(sortValues);
			images = images(sortIdx);
			list.add(images);
		end

		%-------------------------------------------------------------------------
		function value = load(this, loader, loadSpec)
			import ether.process.*;
			if ~isa(loader, 'ether.process.DicomImageLoader')
				throw(MException('Ether:Process:DicomImageVolume', ...
					'Loader must be DicomImageLoader'));
			end
			if ~isa(loadSpec, 'ether.process.DicomImageLoadSpecification')
				throw(MException('Ether:Process:DicomImageVolume', ...
					'LoadSpecification must be DicomImageLoadSpecification'));
			end
			value = 1;
			this.clear;
			patient = loadSpec.patient;
			this.patientDob = patient.birthDate;
			this.patientId = patient.id;
			this.patientName = patient.name;
			study = patient.getStudyList().get(1);
			this.studyUid = study.instanceUid;
			this.loadStudy(study);
	
			values = this.imageMap.values;
			images = [values{:}];
			keys = arrayfun(@this.naturalOrderKey, images);
			[~,sortIdx] = sort(keys);
			images = images(sortIdx);
			refImage = images(1);
			allCols = arrayfun(@(image) image.columns, images);
			allRows = arrayfun(@(image) image.rows, images);
			if (~all(allCols == refImage.columns) || ~all(allRows == refImage.rows))
				throw(MException('Ether:Process:DicomImageVolume', ...
					'Image XY dimensions not equal'));
			end
			nX = refImage.columns;
			x = zeros(nX, 1);
			x(1:end) = 1:nX;
			xDim = Dimension({x}, {'X'});
			nY = refImage.columns;
			y = zeros(nY, 1);
			y(1:end) = 1:nY;
			yDim = Dimension({y}, {'Y'});
			sliceLocs = arrayfun(@(image) image.sliceLocation, images);
			[uniqueLocs, ~, idxUnique] = unique(sliceLocs);
			nZ = numel(uniqueLocs);
			z = uniqueLocs;
			zDim = Dimension({z}, {'Z'});
			nVolumes = numel(images)/nZ;
			volumes = zeros(nVolumes, 1);
			volumes(1:end) = 1:nVolumes;
			volumeDim = Dimension({volumes}, {'Volume'});
			this.dimensions = [xDim;yDim;zDim;volumeDim];
			this.pixelData = zeros(nX, nY, nZ, nVolumes, 'single');
			overrides = loadSpec.getOverrides;
			for ii=1:nVolumes
				for jj=1:nZ
					idx = (ii-1)*nZ+jj;
					image = images(idx);
					z = idxUnique(idx);
					this.pixelData(:,:,z,ii) = image.pixelData;
					this.setImageOverrides(image, overrides);
					image.unload;
				end
			end
			this.valueType = [this.modality,'Signal'];
			this.isReady = true;
			if this.logger.isEnabled(ether.log4m.Level.DEBUG)
				this.logger.debug(sprintf('(%ix%ix%ix%i) DicomImageVolume "%s" loaded', ...
					this.dimensions(1).length, this.dimensions(2).length, ...
					this.dimensions(3).length, this.dimensions(4).length, this.label));
			end
		end
	end

	methods(Access=private)
		%-------------------------------------------------------------------------
		function clear(this)
			this.imageMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
			this.seriesMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
			this.sopInstMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
			this.modality = [];
			this.pixelWidth = [];
			this.pixelHeight = [];
			this.pixelDepth = [];
			this.frameOfReferenceUid = [];
		end

		%-------------------------------------------------------------------------
		function loadStudy(this, study)
			seriesList = study.getSeriesList();
			series = seriesList.get(1);
			this.modality = series.modality;
			imageList = series.getImageList();
			refImage = imageList.get(1);
			this.frameOfReferenceUid = refImage.frameOfReferenceUid;
			this.pixelWidth = refImage.pixelWidth;
			this.pixelHeight = refImage.pixelHeight;
			this.pixelDepth = refImage.pixelDepth;
			for ii=1:seriesList.size()
				series = seriesList.get(ii);
				if ~strcmp(series.modality, this.modality)
					this.clear;
					throw(MException('Ether:Process:DicomImageVolume', ...
						'All series must be of same modality'));
				end
				this.seriesMap(series.instanceUid) = series;
				sopInstList = series.getSopInstanceList();
				for jj=1:sopInstList.size()
					sopInst = sopInstList.get(jj);
					this.sopInstMap(sopInst.instanceUid) = sopInst;
				end
				imageList = series.getImageList();
				for jj=1:imageList.size()
					image = imageList.get(jj);
					this.imageMap(image.uid) = image;
				end
			end
		end

		%-------------------------------------------------------------------------
		function key = naturalOrderKey(~, image)
			key = bitshift(uint64(image.seriesNumber), 32)+ ...
				bitshift(uint64(image.instanceNumber), 16)+ ...
				uint64(image.frame);
		end

		%-------------------------------------------------------------------------
		function setImageOverrides(~, image, overrides)
			if overrides.size < 1
				return;
			end
			keys = overrides.keys;
			for ii=1:overrides.size
				image.sopInstance.override(keys{ii}, overrides(keys{ii}));
			end
		end

	end

end

