classdef XmlProcessReader
	%XMLPROCESSREADER Summary of this class goes here
	%   Detailed explanation goes here

	properties(Constant,Access=private)
		logger = ether.log4m.Logger.getLogger('ether.process.XmlProcessReader');
	end

	methods
		function process = read(this, filepath)
			import ether.process.*;

			this.logger.info(@() sprintf('Parsing %s', filepath));
			document = xmlread(filepath);
			rootNode = document.getDocumentElement();
			if (~strcmp(rootNode.getNodeName(), Xml.NODE_PROCESS_DOC))
				throw(MException('XmlProcess', 'Incorrect document type'));
			end

			this.logger.info(@() 'Constructing Process from document...');
			Toolkit.register(adept.ProcessToolkit.toolkit);
			toolkit = Toolkit.getToolkit();
			process = toolkit.createProcess(rootNode);

			this.logger.debug(@() 'Creating Loaders...');
			loaderList = rootNode.getElementsByTagName(Xml.NODE_LOADER);
			for ii=0:loaderList.getLength-1
				loader = toolkit.createLoader(loaderList.item(ii));
				process.addLoaders(loader);
			end

			this.logger.debug(@() 'Creating LoadSpecifications...');
			loadSpecList = rootNode.getElementsByTagName(Xml.NODE_LOAD_SPECIFICATION);
			for ii=0:loadSpecList.getLength-1
				loadSpec = toolkit.createLoadSpecification(loadSpecList.item(ii));
				process.addLoadSpecifications(loadSpec);
			end

			this.logger.debug(@() 'Creating ImageVolumes...');
			ivList = rootNode.getElementsByTagName(Xml.NODE_IMAGE_VOLUME);
			for ii=0:ivList.getLength-1
				iv = toolkit.createImageVolume(ivList.item(ii));
				process.addImageVolumes(iv);
			end

			this.logger.debug(@() 'Creating ProblemResult...');
			prList = rootNode.getElementsByTagName(Xml.NODE_PROBLEM_RESULT);
			for ii=0:prList.getLength-1
				pr = toolkit.createProblemResult(prList.item(ii));
				process.addProblemResults(pr);
			end

			this.logger.debug(@() 'Creating Entities...');
			entityList = rootNode.getElementsByTagName(Xml.NODE_ENTITY);
			for ii=0:entityList.getLength-1
				entity = toolkit.createEntity(entityList.item(ii));
				process.addEntities(entity);
			end

			this.logger.debug(@() 'Creating Processors...');
			procList = rootNode.getElementsByTagName(Xml.NODE_PROCESSOR);
			for ii=0:procList.getLength-1
				proc = toolkit.createProcessor(procList.item(ii));
				process.addProcessors(proc);
			end
		end
	end

end

