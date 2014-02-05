classdef Toolkit < handle
	%TOOLKIT Summary of this class goes here
	%   Detailed explanation goes here

	properties(Constant)
		Default = 'Default';
	end

	properties(Constant,Access=private)
		toolkitMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
		logger = ether.log4m.Logger.getLogger('ether.process.Toolkit');
	end

	properties(SetAccess=protected)
		packages = {};
	end

	properties(Access=private)
		curveExtractorMap;
		nextId@uint32 = uint32(0);
		onsetLocatorMap;
		solverMap;
	end

	methods(Static)
		%-------------------------------------------------------------------------
		function toolkit = getToolkit(key)
			import ether.process.Toolkit;
			if ~((nargin == 1) && (Toolkit.toolkitMap.isKey(key)))
				key = Toolkit.Default;
			end
			Toolkit.init();
			toolkit = Toolkit.toolkitMap(key);
		end

		%-------------------------------------------------------------------------
		function register(toolkit)
			import ether.process.Toolkit;
			if ~(isscalar(toolkit) && isa(toolkit, 'ether.process.Toolkit'))
				throw(MException('Ether:Process:Toolkit', ...
					'toolkit must be of type ether.process.Toolkit'));
			end
			Toolkit.init();
			nPackages = numel(toolkit.packages);
			for ii=1:nPackages
				Toolkit.setToolkit(toolkit, toolkit.packages{ii});
			end
		end

		%-------------------------------------------------------------------------
		function keyUsed = setToolkit(toolkit, key)
			import ether.process.Toolkit;
			if ~(isscalar(toolkit) && isa(toolkit, 'ether.process.Toolkit'))
				throw(MException('Ether:Process:Toolkit', ...
					'toolkit must be of type ether.process.Toolkit'));
			end
			Toolkit.init();
			if (nargin == 1)
				key = Toolkit.Default;
			end
			% Constant handle field must be mapped to local var
			map = Toolkit.toolkitMap;
			map(key) = toolkit;
			keyUsed = key;
			Toolkit.logger.info(sprintf('Toolkit (%s) assigned to key: %s', ...
				class(toolkit), keyUsed));
		end
	end

	methods(Static,Access=private)
		%-------------------------------------------------------------------------
		function init()
			import ether.process.Toolkit;
			if ~Toolkit.toolkitMap.isKey(Toolkit.Default)
				% Constant handle field must be mapped to local var
				map = Toolkit.toolkitMap;
				map(Toolkit.Default) = ether.process.Toolkit;
			end
		end
	end

	methods
		%-------------------------------------------------------------------------
		function extractor = createCurveExtractor(this, varargin)
			extractor = ether.process.MedianCurveExtractor();
		end

		%-------------------------------------------------------------------------
		function entity = createEntity(this, varargin)
			if isa(varargin{1}, 'org.w3c.dom.Node')
				entity = this.createEntityFromNode(varargin{1});
				if ~isempty(entity)
					this.logger.debug(...
						@() sprintf('Entity instance (id=%i) created: %s (%s)', ...
							entity.id, class(entity), class(entity.entity)));
				end
			else
				throw(MException('Ether:Process:Toolkit', 'Invalid argument'));
			end
		end

		%-------------------------------------------------------------------------
		function iv = createImageVolume(this, varargin)
			if isa(varargin{1}, 'org.w3c.dom.Node')
				iv = this.createImageVolumeFromNode(varargin{1});
			else
				iv = ether.process.ImageVolume(id);
			end
			this.logger.debug(sprintf('ImageVolume instance (id=%i) created: %s', ...
				iv.id, class(iv)));
		end

		%-------------------------------------------------------------------------
		function loader = createLoader(this, varargin)
			switch length(varargin)
				case 1
					loader = this.createLoaderFromNode(varargin{1});
				case 2
					loader = this.createLoaderByClass(varargin{1}, varargin{2});
				otherwise
					throw(MException('Ether:Process:Toolkit', ...
						sprintf('Argument count unsupported: %d. Must be 1 or 2', ...
							nargin)));
			end
			this.logger.debug(sprintf('Loader instance (id=%i) created: %s', ...
				loader.id, class(loader)));
		end

		%-------------------------------------------------------------------------
		function loadSpec = createLoadSpecification(this, varargin)
			switch length(varargin)
				case 1
					loadSpec = this.createLoadSpecFromNode(varargin{1});
				case 4
					loadSpec = this.createLoadSpec(varargin{1}, varargin{2}, ...
						varargin{3}, varargin{4});
				otherwise
					throw(MException('Ether:Process:Toolkit', ...
						sprintf('Argument count unsupported: %d. Must be 1 or 4', ...
							nargin)));
			end
			this.logger.debug(sprintf('LoadSpecification instance (id=%i) created: %s', ...
				loadSpec.id, class(loadSpec)));
		end

		%-------------------------------------------------------------------------
		function locator = createOnsetLocator(this, varargin)
			locator = ether.process.MaxGradientOnsetLocator();
		end

		%-------------------------------------------------------------------------
		function result = createProblemResult(this, varargin)
			if isa(varargin{1}, 'org.w3c.dom.Node')
				result = this.createProblemResultFromNode(varargin{1});
			else
				result = ether.process.ProblemResult();
			end
			this.logger.debug(sprintf('ProblemResult instance (id=%i) created: %s', ...
				result.id, class(result)));
		end

		%-------------------------------------------------------------------------
		function process = createProcess(this, varargin)
			if isa(varargin{1}, 'org.w3c.dom.Node')
				process = this.createProcessFromNode(varargin{1});
			else
				process = ether.process.Process();
			end
			this.logger.debug(sprintf('Process instance created: %s', ...
				class(process)));
		end

		%-------------------------------------------------------------------------
		function processor = createProcessor(this, varargin)
			if isa(varargin{1}, 'org.w3c.dom.Node')
				processor = this.createProcessorFromNode(varargin{1});
			else
				processor = ether.process.Process();
			end
			this.logger.debug(sprintf('Processor instance created: %s', ...
				class(processor)));
		end

		%-------------------------------------------------------------------------
		function id = getId(this)
			id = this.nextId;
			this.nextId = this.nextId+1;
		end

	end
	
	methods(Access=protected)
		%-------------------------------------------------------------------------
		function this = Toolkit()
			this.nextId = bitshift(intmax('uint32'), -1);
			this.curveExtractorMap = ...
				containers.Map('KeyType', 'char', 'ValueType', 'any');
			this.onsetLocatorMap = ...
				containers.Map('KeyType', 'char', 'ValueType', 'any');
			this.solverMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
			this.initMaps;
		end

		%-------------------------------------------------------------------------
		function checkNodeName(~, node, reqName)
			if (~strcmp(node.getNodeName(), reqName))
				throw(MException('Ether:Process:Toolkit', ...
					sprintf('<%s> node required, <%s> supplied', reqName, ...
						char(node.getNodeName()))));
			end
		end

		%-------------------------------------------------------------------------
		function props = readPropertiesChildNode(this, node)
			import ether.process.*;
			props = containers.Map('KeyType', 'char', 'ValueType', 'char');
			propList = node.getElementsByTagName(Xml.NODE_PROPERTIES);
			if propList.getLength ~= 1
				return;
			end
			propNode = propList.item(0);
			kvList = propNode.getElementsByTagName(Xml.NODE_KEYVALUE);
			for ii=0:kvList.getLength-1
				kvNode = kvList.item(ii);
				key = Xml.attr2str(Xml.getRequiredAttr(Xml.ATTR_KEY, kvNode));
				value = Xml.attr2str(Xml.getRequiredAttr(Xml.ATTR_VALUE, kvNode));
				props(key) = value;
			end
		end

	end

	methods(Access=private)
		%-------------------------------------------------------------------------
		function entity = createCurveExtractorFromNode(this, id, className, node)
			import ether.process.*;
			switch className
				case 'ether.process.MedianCurveExtractor'
					entity = Entity(id, ether.process.MedianCurveExtractor());

				otherwise
					entity = [];
					this.logger.warn(@() sprintf('Unknown entity class: %s', ...
						className));
					return;
			end
		end

		%-------------------------------------------------------------------------
		function loadSpec = createDicomLoadSpec(this, node, id, loaderId, ...
				targetId)
			import ether.process.*;
			import ether.dicom.*;
			loadSpec = DicomImageLoadSpecification(id, loaderId, targetId);
			
			patient = this.createPatientFromNode(node);
			studyList = patient.getStudyList();
			study = studyList.get(1);
			seriesList = node.getElementsByTagName(Xml.NODE_SERIES);
			for ii=0:seriesList.getLength-1
				seriesNode = seriesList.item(ii);
				series = this.createSeriesFromNode(seriesNode);
				study.addSeries(series);
			end
			loadSpec.patient = patient;

			overrideList = node.getElementsByTagName(Xml.NODE_OVERRIDE);
			if overrideList.getLength ~= 1
				return;
			end
			props = this.readPropertiesChildNode(overrideList.item(0));
			propKeys = props.keys;
			for ii=1:props.size
				loadSpec.addOverride(propKeys{ii}, props(propKeys{ii}));
			end
		end

		%-------------------------------------------------------------------------
		function entity = createEntityFromNode(this, node)
			import ether.process.*;
			this.checkNodeName(node, Xml.NODE_ENTITY);

			attrs = node.getAttributes();
			className = Xml.attr2str(Xml.getAttr(attrs, Xml.ATTR_CLASS, ''));
			metaClass = meta.class.fromName(className);
			if isempty(metaClass)
				this.logger.warn(@() sprintf('No metaclass info available for %s', ...
					className));
				entity = [];
				return;
			end
			package = metaClass.ContainingPackage.Name;
			toolkit = Toolkit.getToolkit(package);
			if isempty(toolkit)
				entity = [];
				this.logger.warn(@() sprintf('No toolkit found for entity class: %s', ...
					className));
				return;
			end
			if (toolkit ~= this)
				entity = toolkit.createEntity(node);
				return;
			end

			id = Xml.attr2id(Xml.getRequiredAttr(Xml.ATTR_ID, node));
			if this.solverMap.isKey(className)
				entity = this.createSolverFromNode(id, className, node);
				return;
			end
			if this.curveExtractorMap.isKey(className)
				entity = this.createCurveExtractorFromNode(id, className, node);
				return;
			end
			if this.onsetLocatorMap.isKey(className)
				entity = this.createOnsetLocatorFromNode(id, className, node);
				return;
			end

			entity = [];
			this.logger.warn(@() sprintf('Unknown entity class: %s', ...
				className));
		end

		%-------------------------------------------------------------------------
		function iv = createImageVolumeFromNode(this, node)
			import ether.process.*;
			this.checkNodeName(node, Xml.NODE_IMAGE_VOLUME);

			attrs = node.getAttributes();
			id = Xml.attr2id(Xml.getRequiredAttr(Xml.ATTR_ID, node));
			className = Xml.attr2str(Xml.getAttr(attrs, Xml.ATTR_CLASS, ''));
			label = Xml.attr2str(Xml.getAttr(attrs, Xml.ATTR_LABEL));

			switch className
				case 'DicomImageVolume'
					iv = ether.process.DicomImageVolume(id);
				otherwise
					iv = ether.process.ImageVolume(id);
			end
			if ~isempty(label)
				iv.label = label;
			end
		end

		%-------------------------------------------------------------------------
		function loader = createLoaderByClass(~, className, id)
			import ether.process.*;
			switch className
				case 'DicomImageLoader'
					loader = DicomImageLoader(id);
				otherwise
					error = sprintf('Unknown Loader class: %s', className);
					throw(MException('Ether:Process:Toolkit', error));
			end
		end

		%-------------------------------------------------------------------------
		function loader = createLoaderFromNode(this, node)
			import ether.process.*;
			this.checkNodeName(node, Xml.NODE_LOADER);

			className = Xml.attr2str(Xml.getRequiredAttr(Xml.ATTR_CLASS, node));
			id = Xml.attr2id(Xml.getRequiredAttr(Xml.ATTR_ID, node));

			loader = this.createLoaderByClass(className, id);
		end

		%-------------------------------------------------------------------------
		function loadSpec = createLoadSpec(~, className, id, loaderId, ...
				targetId)
			import ether.process.*;
			switch className
				case 'DicomImageLoadSpecification'
					loadSpec = DicomImageLoadSpecification(id, loaderId, targetId);
				otherwise
					error = sprintf('Unknown LoadSpecification class: %s', className);
					throw(MException('Ether:Process:Toolkit', error));
			end
		end

		%-------------------------------------------------------------------------
		function loadSpec = createLoadSpecFromNode(this, node)
			import ether.process.*;
			this.checkNodeName(node, Xml.NODE_LOAD_SPECIFICATION);

			id = Xml.attr2id(Xml.getRequiredAttr(Xml.ATTR_ID, node));
			loaderId = Xml.attr2id(Xml.getRequiredAttr(Xml.ATTR_LOADER_ID, node));
			targetId = Xml.attr2id(Xml.getRequiredAttr(Xml.ATTR_TARGET_ID, node));

			childNode = Xml.getFirstNonTextNode(node);
			childName = char(childNode.getNodeName());
			switch childName
				case Xml.NODE_DICOM
					loadSpec = this.createDicomLoadSpec(childNode, id, loaderId, ...
						targetId);
				otherwise
					throw(MException('Ether:Process:Toolkit', ...
						sprintf('Unknown LoadSpecification type: <%s>', childName)));
			end
		end

		%-------------------------------------------------------------------------
		function entity = createOnsetLocatorFromNode(this, id, className, node)
			import ether.process.*;
			switch className
				case 'ether.process.MaxGradientOnsetLocator'
					entity = Entity(id, ether.process.MaxGradientOnsetLocator());

				otherwise
					entity = [];
					this.logger.warn(@() sprintf('Unknown entity class: %s', ...
						className));
					return;
			end
		end

		%-------------------------------------------------------------------------
		function result = createProblemResultFromNode(this, node)
			import ether.process.*;
			this.checkNodeName(node, Xml.NODE_PROBLEM_RESULT);

			attrs = node.getAttributes();
			id = Xml.attr2id(Xml.getRequiredAttr(Xml.ATTR_ID, node));
			label = Xml.attr2str(Xml.getAttr(attrs, Xml.ATTR_LABEL));

			result = ProblemResult(id);
			if ~isempty(label)
				result.label = label;
			end
		end

		%-------------------------------------------------------------------------
		function patient = createPatientFromNode(this, node)
			import ether.process.*;
			this.checkNodeName(node, Xml.NODE_DICOM);

			patientName = Xml.attr2str(Xml.getRequiredAttr(...
				Xml.ATTR_PATIENT_NAME, node));
			patientId = Xml.attr2str(Xml.getRequiredAttr(...
				Xml.ATTR_PATIENT_ID, node));
			patientDob = Xml.attr2str(Xml.getRequiredAttr(...
				Xml.ATTR_PATIENT_DOB, node));

			dicomToolkit = ether.dicom.Toolkit.getToolkit();
			patient = dicomToolkit.createPatient(patientName, patientId, patientDob);
			studyUid = Xml.attr2str(Xml.getRequiredAttr(Xml.ATTR_STUDY_UID, node));
			study = dicomToolkit.createStudy(studyUid);
			patient.addStudy(study);
		end

		%-------------------------------------------------------------------------
		function process = createProcessFromNode(this, node)
			import ether.process.*;
			this.checkNodeName(node, Xml.NODE_PROCESS_DOC);

			attrs = node.getAttributes();
			label = Xml.attr2str(Xml.getAttr(attrs, Xml.ATTR_LABEL));

			process = Process();
			if ~isempty(label)
				process.label = label;
			end
		end

		%-------------------------------------------------------------------------
		function processor = createProcessorFromNode(this, node)
			import ether.process.*;
			this.checkNodeName(node, Xml.NODE_PROCESSOR);

			id = Xml.attr2id(Xml.getRequiredAttr(Xml.ATTR_ID, node));
			className = Xml.attr2str(Xml.getRequiredAttr(Xml.ATTR_CLASS, node));

			targetList = node.getElementsByTagName(Xml.NODE_TARGET);
			if targetList.getLength ~= 1
				error = sprintf('Target count must be 1 in %s: %i', className, id);
				throw(MException('Ether:Process:Toolkit', error));
			end
			targetNode = targetList.item(0);
			targetID = Xml.attr2id(Xml.getRequiredAttr(Xml.ATTR_ID, targetNode));
			inputList = node.getElementsByTagName(Xml.NODE_INPUT);
			inputIDs = uint32(zeros(inputList.getLength, 1));
			for ii=0:inputList.getLength-1
				inputNode = inputList.item(ii);
				inputID = Xml.attr2id(Xml.getRequiredAttr(Xml.ATTR_ID, inputNode));
				inputIDs(ii+1) = inputID;
			end
			entityList = node.getElementsByTagName(Xml.NODE_USES);
			entityIDs = uint32(zeros(entityList.getLength, 1));
			for ii=0:entityList.getLength-1
				entityNode = entityList.item(ii);
				entityID = Xml.attr2id(Xml.getRequiredAttr(Xml.ATTR_ID, entityNode));
				entityIDs(ii+1) = entityID;
			end

			switch className
				case 'ConverterProcessor'
					processor = ConverterProcessor(id, inputIDs, targetID, entityIDs);
				case 'TimeSeriesProblemProcessor'
					processor = TimeSeriesProblemProcessor(id, inputIDs, targetID, ...
						entityIDs);
				otherwise
					error = sprintf('Unknown Processor class: %s', className);
					throw(MException('Ether:Process:Toolkit', error));
			end
		end

		%-------------------------------------------------------------------------
		function series = createSeriesFromNode(this, node)
			import ether.process.*;
			this.checkNodeName(node, Xml.NODE_SERIES);

			modality = Xml.attr2str(Xml.getRequiredAttr(Xml.ATTR_MODALITY, node));
			number = Xml.attr2id(Xml.getRequiredAttr(Xml.ATTR_NUMBER, node));
			seriesUid = Xml.attr2str(Xml.getRequiredAttr(Xml.ATTR_UID, node));

			dicomToolkit = ether.dicom.Toolkit.getToolkit();
			series = dicomToolkit.createSeries(seriesUid);
			series.modality = modality;
			series.number = number;
			sopInstMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
			sopInstList = node.getElementsByTagName(Xml.NODE_SOP_INSTANCE);
			for ii=0:sopInstList.getLength-1
				sopInstNode = sopInstList.item(ii);
				sopInst = this.createSopInstFromNode(sopInstNode);
				sopInstMap(sopInst.instanceUid) = sopInst;
			end
			imageList = node.getElementsByTagName(Xml.NODE_IMAGE);
			for ii=0:imageList.getLength-1
				imageNode = imageList.item(ii);
				sopInstUid = Xml.attr2str(Xml.getRequiredAttr(...
					Xml.ATTR_SOP_INSTANCE_UID, imageNode));
				if sopInstMap.isKey(sopInstUid)
					series.addSopInstance(sopInstMap(sopInstUid));
				else
					throw(MException('Ether:Process:Toolkit', ...
						sprintf('No SOP instance found for UID: %s', sopInstUid)));
				end
				frame = Xml.attr2id(Xml.getRequiredAttr(...
					Xml.ATTR_FRAME_INDEX, imageNode));
				imageUid = sprintf('%s.%i', sopInstUid, frame);
				if ~series.hasImage(imageUid)
					throw(MException('Ether:Process:Toolkit', ...
						sprintf('No image found for UID: %s', imageUid)));
				end
			end
		end

		%-------------------------------------------------------------------------
		function entity = createSolverFromNode(this, id, className, node)
			import ether.process.*;
			switch className
				case 'ether.optim.LeastSquaresSolver'
					entity = Entity(id, ether.optim.LeastSquaresSolver());

				case 'ether.optim.McmcSolver'
					entity = Entity(id, ether.optim.McmcSolver());

				otherwise
					entity = [];
					this.logger.warn(@() sprintf('Unknown entity class: %s', ...
						className));
					return;
			end
			props = this.readPropertiesChildNode(node);
			if props.isKey('UsePool')
				entity.entity.usePool = strcmpi(props('UsePool'), 'true');
			end
		end

		%-------------------------------------------------------------------------
		function sopInst = createSopInstFromNode(this, node)
			import ether.process.*;
			this.checkNodeName(node, Xml.NODE_SOP_INSTANCE);

			uid = Xml.attr2str(Xml.getRequiredAttr(Xml.ATTR_UID, node));
			sopClassUid = Xml.attr2str(Xml.getRequiredAttr(...
				Xml.ATTR_SOP_CLASS_UID, node));
			filename = Xml.attr2str(Xml.getRequiredAttr(Xml.ATTR_FILE, node));
			frames = Xml.attr2id(Xml.getRequiredAttr(Xml.ATTR_FRAMES, node));

			sopInst = ether.dicom.Toolkit.getToolkit().createSopInstance();
			sopInst.instanceUid = uid;
			sopInst.sopClassUid = sopClassUid;
			sopInst.filename = filename;
			sopInst.frameCount = frames;
		end

		%-------------------------------------------------------------------------
		function initMaps(this)
			this.curveExtractorMap('ether.process.MedianCurveExtractor') = 1;
			this.onsetLocatorMap('ether.process.MaxGradientOnsetLocator') = 1;
			this.solverMap('ether.optim.LeastSquaresSolver') = 1;
			this.solverMap('ether.optim.LinearSolver') = 1;
			this.solverMap('ether.optim.McmcArraySolver') = 1;
			this.solverMap('ether.optim.McmcSolver') = 1;
		end

	end

end

