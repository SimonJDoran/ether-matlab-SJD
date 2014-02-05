classdef ProcessToolkit < ether.process.Toolkit
	%PROCESSTOOLKIT Summary of this class goes here
	%   Detailed explanation goes here

	properties(Constant)
		toolkit = adept.ProcessToolkit();
	end

	properties(Constant,Access=private)
		logger = ether.log4m.Logger.getLogger('adept.ProcessToolkit');
	end

	properties(Access=private)
		converterMap;
		modelMap;
	end

	methods
		%-------------------------------------------------------------------------
		function entity = createEntity(this, varargin)
			if isa(varargin{1}, 'org.w3c.dom.Node')
				entity = this.createEntityFromNode(varargin{1});
			else
				entity = [];
				this.logger.debug(@() sprintf('Invalid input arguments'));
			end
		end

	end

	methods(Access=private)
		%-------------------------------------------------------------------------
		function this = ProcessToolkit()
			this.packages = {'adept.convert';'adept.model';'adept.model.pk'};
			this.converterMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
			this.modelMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
			this.initMaps;
		end
		
		%-------------------------------------------------------------------------
		function entity = createEntityFromNode(this, node)
			import ether.process.*;
			this.checkNodeName(node, Xml.NODE_ENTITY);

			id = Xml.attr2id(Xml.getRequiredAttr(Xml.ATTR_ID, node));
			className = Xml.attr2str(Xml.getRequiredAttr(Xml.ATTR_CLASS, node));

			if this.converterMap.isKey(className)
				entity = this.createConverter(id, className, node);
				return;
			end
			if this.modelMap.isKey(className)
				entity = this.createModel(id, className, node);
				return;
			end

			entity = [];
			this.logger.warn(@() sprintf('Unknown entity class: %s', ...
				className));
		end

		%-------------------------------------------------------------------------
		function entity = createConverter(this, id, className, node)
			import ether.process.*;

			switch className
				case 'adept.convert.HelmsT1Converter'
					entity = Entity(id, adept.convert.HelmsT1Converter());

				case 'adept.convert.HelmsGdConverter'
					entity = Entity(id, adept.convert.HelmsGdConverter());

				case 'adept.convert.MZeroConverter'
					entity = Entity(id, adept.convert.MZeroConverter());

				case 'adept.convert.MZeroGdConverter'
					entity = Entity(id, adept.convert.MZeroGdConverter());

				case 'adept.convert.MZeroT1Converter'
					entity = Entity(id, adept.convert.MZeroT1Converter());

				case 'adept.convert.WangT1Converter'
					entity = Entity(id, adept.convert.WangT1Converter());

				otherwise
					throw(MException('ADEPT:ProcessToolkit', ...
						'Unfeasable error! This should never happen.'));
			end
			props = this.readPropertiesChildNode(node);
			if props.isKey('UsePool')
				entity.entity.usePool = strcmpi(props('UsePool'), 'true');
			end
			if props.isKey('UseVectors')
				entity.entity.useVectors = strcmpi(props('UseVectors'), 'true');
			end
			if props.isKey('InitialCount')
				count = props('InitialCount');
				if isnumeric(count) && count > 0
					entity.entity.initialCount = floor(props('InitialCount'));
				end
			end
		end

		%-------------------------------------------------------------------------
		function entity = createModel(this, id, className, node)
			import ether.process.*;

			switch className
				case 'adept.model.pk.CosineKety'
					entity = Entity(id, adept.model.pk.CosineKety());

				case 'adept.model.ADC'
					entity = Entity(id, adept.model.ADC());

				case 'adept.model.AlphaDWI'
					entity = Entity(id, adept.model.AlphaDWI());

				case 'adept.model.IVIM'
					entity = Entity(id, adept.model.IVIM());

				otherwise
					throw(MException('ADEPT:ProcessToolkit', ...
						'Unfeasable error! This should never happen.'));
			end
		end

		%-------------------------------------------------------------------------
		function initMaps(this)
			this.converterMap('adept.convert.HelmsT1Converter') = 1;
			this.converterMap('adept.convert.HelmsGdConverter') = 1;
			this.converterMap('adept.convert.MZeroConverter') = 1;
			this.converterMap('adept.convert.MZeroGdConverter') = 1;
			this.converterMap('adept.convert.MZeroT1Converter') = 1;
			this.converterMap('adept.convert.WangT1Converter') = 1;
			this.modelMap('adept.model.pk.CosineKety') = 1;
			this.modelMap('adept.model.pk.Tofts') = 1;
			this.modelMap('adept.model.ADC') = 1;
			this.modelMap('adept.model.AlphaDWI') = 1;
			this.modelMap('adept.model.IVIM') = 1;
		end

	end

end

