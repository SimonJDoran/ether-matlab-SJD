classdef Xml < handle
	%PROCESS Summary of this class goes here
	%   Detailed explanation goes here
	
	properties(Constant)
		ATTR_CLASS = 'class';
		ATTR_COLUMNS = 'columns';
		ATTR_FILE = 'file';
		ATTR_FRAME_INDEX = 'frame-index';
		ATTR_FRAMES = 'frames';
		ATTR_ID = 'id';
		ATTR_KEY = 'key';
		ATTR_LABEL = 'label';
		ATTR_LOADER_ID = 'loader-id';
		ATTR_MODALITY = 'modality';
		ATTR_NUMBER = 'number';
		ATTR_PATIENT_DOB = 'patient-birthdate';
		ATTR_PATIENT_ID = 'patient-id';
		ATTR_PATIENT_NAME = 'patient-name';
		ATTR_ROWS = 'rows';
		ATTR_SOP_CLASS_UID = 'sop-class-uid';
		ATTR_SOP_INSTANCE_UID = 'sop-instance-uid';
		ATTR_SERIES = 'series';
		ATTR_STUDY_UID = 'study-uid';
		ATTR_TARGET_ID = 'target-id';
		ATTR_UID = 'uid';
		ATTR_VALUE = 'value';
		NODE_DICOM = 'dicom';
		NODE_ENTITY = 'entity';
		NODE_IMAGE = 'image';
		NODE_IMAGE_VOLUME = 'image-volume';
		NODE_INPUT = 'input';
		NODE_KEYVALUE = 'key-value';
		NODE_LOAD_SPECIFICATION = 'load-specification';
		NODE_LOADER = 'loader';
		NODE_OVERRIDE = 'override';
		NODE_PROBLEM_RESULT = 'problem-result';
		NODE_PROCESS_DOC = 'ether-process';
		NODE_PROCESSOR = 'processor';
		NODE_PROPERTIES = 'properties';
		NODE_SERIES = 'series';
		NODE_SOP_INSTANCE = 'sop-instance';
		NODE_TARGET = 'target';
		NODE_USES = 'uses';

		IMAGE = 'IMAGE';
	end

	methods(Static)
		%-------------------------------------------------------------------------
		function id = attr2id(attr)
			id = uint32(str2double(char(attr.getValue())));
		end

		%-------------------------------------------------------------------------
		function str = attr2str(attr)
			if ~isempty(attr)
				str = char(attr.getValue());
			else
				if ~ischar(attr)
					str = [];
				else
					str = '';
				end
			end
		end

		%-------------------------------------------------------------------------
		function attr = getAttr(attrs, attrName, defaultValue)
			attr = attrs.getNamedItem(attrName);
			if numel(attr) ~= 1
				if nargin == 3
					attr = defaultValue;
				else
					attr = [];
				end
			end
		end

		%-------------------------------------------------------------------------
		function child = getFirstNonTextNode(node)
			child = [];
			children  = node.getChildNodes();
			for ii=0:children.getLength()-1
				if ~strcmp(children.item(ii).getNodeName(), '#text')
					child = children.item(ii);
					break
				end
			end
		end

		%-------------------------------------------------------------------------
		function attr = getRequiredAttr(reqAttr, domNode)
			attrs = domNode.getAttributes();
			attr = attrs.getNamedItem(reqAttr);
			if numel(attr) ~= 1
				throw(MException('Ether:Process:Xml', ...
					sprintf('No %s attribute for <%s> node', reqAttr, ...
						domNode.getNodeName)));
			end
		end

	end

	methods(Access=private)
		%-------------------------------------------------------------------------
		function this = Xml()
		end
	end

end

