classdef Xml < handle
	%XML Collection of utility methods for XML processing
	%   Detailed explanation goes here
	
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
		function str = getAttrStr(attrs, attrName, defaultValue)
			import ether.Xml;
			if nargin == 3
				str = Xml.attr2str(Xml.getAttr(attrs, attrName, defaultValue));
			else
				str = Xml.attr2str(Xml.getAttr(attrs, attrName));
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

