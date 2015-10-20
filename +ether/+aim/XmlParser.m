classdef XmlParser < handle
	%XMLPARSER Summary of this class goes here
	%   Detailed explanation goes here
	
	%----------------------------------------------------------------------------
	properties
	end
	
	%----------------------------------------------------------------------------
	properties(Constant,Access=private)
		AIM_V4_0 = 'AIMv4_0';
		ATTR_AIM_VERSION = 'aimVersion';
		ATTR_ROOT = 'root';
		ATTR_VALUE = 'value';
		ATTR_XSI_TYPE = 'xsi:type';
		NODE_ANNOTATION = 'ImageAnnotation';
		NODE_ANNOTATIONS = 'imageAnnotations';
		NODE_ANNOTATION_COLLECTION = 'ImageAnnotationCollection';
		NODE_COMMENT = 'comment';
		NODE_COORDINATE_INDEX = 'coordinateIndex';
		NODE_DATE_TIME = 'dateTime';
		NODE_IMAGE = 'Image';
		NODE_IMAGE_COLLECTION = 'imageCollection';
		NODE_IMAGE_REFERENCE_UID = 'imageReferenceUid';
		NODE_IMAGE_SERIES = 'imageSeries';
		NODE_IMAGE_STUDY = 'imageStudy';
		NODE_INCLUDE_FLAG = 'includeFlag';
		NODE_INSTANCE_UID = 'instanceUid';
		NODE_MARKUP = 'MarkupEntity';
		NODE_MARKUP_COLLECTION = 'markupEntityCollection';
		NODE_MODALITY = 'modality';
		NODE_NAME = 'name';
		NODE_IMAGE_REFERENCE = 'ImageReferenceEntity';
		NODE_IMAGE_REFERENCE_COLLECTION = 'imageReferenceEntityCollection';
		NODE_REFERENCED_FRAME_NUMBER = 'referencedFrameNumber';
		NODE_SHAPE_ID = 'shapeIdentifier';
		NODE_SOP_CLASS_UID = 'sopClassUid';
		NODE_SOP_INSTANCE_UID = 'sopInstanceUid';
		NODE_START_DATE = 'startDate';
		NODE_START_TIME = 'startTime';
		NODE_TEXT = '#text';
		NODE_UID = 'uniqueIdentifier';
		NODE_X = 'x';
		NODE_Y = 'y';
		NODE_2D_COORDINATE = 'TwoDimensionSpatialCoordinate';
		NODE_2D_COORDINATE_COLLECTION = 'twoDimensionSpatialCoordinateCollection';
	end

	%----------------------------------------------------------------------------
	methods(Static)
		function result = parse(filename)
			try
				doc = xmlread(filename);
				fprintf('File read - %s\n', filename);
				result = ether.aim.XmlParser.parseDoc(doc);
			catch me
				fprintf(2, 'Error reading file - %s\n', me.message);
				result = [];
			end
		end
	end

	%----------------------------------------------------------------------------
	methods(Static,Access=private)
		%-------------------------------------------------------------------------
		function parseAnnotation(annoNode, collection)
			import ether.Xml;
			import ether.aim.*;
			if ~strcmp(char(annoNode.getNodeName), XmlParser.NODE_ANNOTATION)
				return;
			end

			annotation = ImageAnnotation();
			childNodes = annoNode.getChildNodes();
			for i=0:childNodes.getLength-1
				node = childNodes.item(i);
				switch char(node.getNodeName)
					case XmlParser.NODE_TEXT
						continue

					case XmlParser.NODE_UID
						annotation.uniqueIdentifier = Xml.getAttrStr(...
							node.getAttributes(), XmlParser.ATTR_ROOT);

					case XmlParser.NODE_DATE_TIME
						annotation.dateTime = Xml.getAttrStr(node.getAttributes(), ...
							XmlParser.ATTR_VALUE);

					case XmlParser.NODE_NAME
						annotation.name = Xml.getAttrStr(node.getAttributes(), ...
							XmlParser.ATTR_VALUE);

					case XmlParser.NODE_COMMENT
						annotation.comment = Xml.getAttrStr(node.getAttributes(), ...
							XmlParser.ATTR_VALUE);

					case XmlParser.NODE_MARKUP_COLLECTION
						markups = node.getChildNodes;
						for j=0:markups.getLength-1
							XmlParser.parseMarkup(markups.item(j), annotation);
						end

					case XmlParser.NODE_IMAGE_REFERENCE_COLLECTION
						references = node.getChildNodes;
						for j=0:references.getLength-1
							XmlParser.parseReference(references.item(j), annotation);
						end

					otherwise
				end
			end
			if ~isempty(annotation.uniqueIdentifier)
				collection.addAnnotation(annotation);
			end
		end

		%-------------------------------------------------------------------------
		function result = parseDoc(document)
			import ether.Xml;
			import ether.aim.*;
			rootNode = document.getDocumentElement();
			if (~strcmp(rootNode.getNodeName(), XmlParser.NODE_ANNOTATION_COLLECTION))
				throw(MException('XmlParser', 'Incorrect document type'));
			end
			result = ImageAnnotationCollection();
			attrs = rootNode.getAttributes();
			aimVersion = Xml.getAttrStr(attrs, XmlParser.ATTR_AIM_VERSION);
			if ~isempty(aimVersion)
				result.aimVersion = aimVersion;
			end

			childNodes = rootNode.getChildNodes();
			for i=0:childNodes.getLength-1
				node = childNodes.item(i);
				switch char(node.getNodeName)
					case XmlParser.NODE_TEXT
						continue

					case XmlParser.NODE_UID
						result.uniqueIdentifier = Xml.getAttrStr(node.getAttributes(), ...
							XmlParser.ATTR_ROOT);

					case XmlParser.NODE_DATE_TIME
						result.dateTime = Xml.getAttrStr(node.getAttributes(), ...
							XmlParser.ATTR_VALUE);

					case XmlParser.NODE_ANNOTATIONS
						annotations = node.getChildNodes;
						for j=0:annotations.getLength-1
							XmlParser.parseAnnotation(annotations.item(j), result);
						end

					otherwise
				end
			end
		end

		%-------------------------------------------------------------------------
		function parseImage(imageNode, series)
			import ether.Xml;
			import ether.aim.*;
			if ~strcmp(char(imageNode.getNodeName), XmlParser.NODE_IMAGE)
				return;
			end

			image = ether.aim.Image();
			childNodes = imageNode.getChildNodes();
			for i=0:childNodes.getLength-1
				node = childNodes.item(i);
				switch char(node.getNodeName)
					case XmlParser.NODE_TEXT
						continue

					case XmlParser.NODE_SOP_CLASS_UID
						image.sopClassUid = Xml.getAttrStr(...
							node.getAttributes(), XmlParser.ATTR_ROOT);

					case XmlParser.NODE_SOP_INSTANCE_UID
						image.sopInstanceUid = Xml.getAttrStr(...
							node.getAttributes(), XmlParser.ATTR_ROOT);

					otherwise
				end
			end
			if ~isempty(image.sopInstanceUid)
				series.addImage(image);
			end
		end

		%-------------------------------------------------------------------------
		function parseMarkup(markupNode, annotation)
			import ether.Xml;
			import ether.aim.*;
			if ~strcmp(char(markupNode.getNodeName), XmlParser.NODE_MARKUP)
				return;
			end

			attrs = markupNode.getAttributes();
			class = Xml.getAttrStr(attrs, XmlParser.ATTR_XSI_TYPE);
			switch class
				case 'TwoDimensionPolyline'
					markup = TwoDimensionPolyline();

				otherwise
					return;
			end
			childNodes = markupNode.getChildNodes();
			for i=0:childNodes.getLength-1
				node = childNodes.item(i);
				switch char(node.getNodeName)
					case XmlParser.NODE_TEXT
						continue

					case XmlParser.NODE_UID
						markup.uniqueIdentifier = Xml.getAttrStr(...
							node.getAttributes(), XmlParser.ATTR_ROOT);

					case XmlParser.NODE_SHAPE_ID
						number = Xml.getAttrStr(...
							node.getAttributes(), XmlParser.ATTR_VALUE);
						number = uint32(str2double(number));
						if isfinite(number)
							markup.shapeIdentifier = number;
						end

					case XmlParser.NODE_INCLUDE_FLAG
						markup.includeFlag = strcmp('true', Xml.getAttrStr(...
							node.getAttributes(), XmlParser.ATTR_VALUE));

					case XmlParser.NODE_IMAGE_REFERENCE_UID
						markup.imageReferenceUid = Xml.getAttrStr(...
							node.getAttributes(), XmlParser.ATTR_ROOT);

					case XmlParser.NODE_REFERENCED_FRAME_NUMBER
						number = Xml.getAttrStr(...
							node.getAttributes(), XmlParser.ATTR_VALUE);
						number = uint32(str2double(number));
						if isfinite(number)
							markup.referencedFrameNumber = number;
						end

					case XmlParser.NODE_2D_COORDINATE_COLLECTION
						coords = node.getChildNodes;
						for j=0:coords.getLength-1
							XmlParser.parseTwoDCoordinate(coords.item(j), markup);
						end

					otherwise
				end
			end
			if ~isempty(markup.uniqueIdentifier)
				annotation.addMarkup(markup);
			end
		end

		%-------------------------------------------------------------------------
		function parseReference(refNode, annotation)
			import ether.Xml;
			import ether.aim.*;
			if ~strcmp(char(refNode.getNodeName), XmlParser.NODE_IMAGE_REFERENCE)
				return;
			end

			attrs = refNode.getAttributes();
			class = Xml.getAttrStr(attrs, XmlParser.ATTR_XSI_TYPE);
			switch class
				case 'DicomImageReferenceEntity'
					reference = DicomImageReference();

				otherwise
					return;
			end
			childNodes = refNode.getChildNodes();
			for i=0:childNodes.getLength-1
				node = childNodes.item(i);
				switch char(node.getNodeName)
					case XmlParser.NODE_TEXT
						continue

					case XmlParser.NODE_UID
						reference.uniqueIdentifier = Xml.getAttrStr(...
							node.getAttributes(), XmlParser.ATTR_ROOT);

					case XmlParser.NODE_IMAGE_STUDY
						XmlParser.parseStudy(node, reference);

					otherwise
				end
			end
			if ~isempty(reference.uniqueIdentifier)
				annotation.addReference(reference);
			end
		end

		%-------------------------------------------------------------------------
		function parseStudy(studyNode, reference)
			import ether.Xml;
			import ether.aim.*;
			if ~strcmp(char(studyNode.getNodeName), XmlParser.NODE_IMAGE_STUDY)
				return;
			end

			study = ether.aim.ImageStudy();
			childNodes = studyNode.getChildNodes();
			for i=0:childNodes.getLength-1
				node = childNodes.item(i);
				switch char(node.getNodeName)
					case XmlParser.NODE_TEXT
						continue

					case XmlParser.NODE_INSTANCE_UID
						study.instanceUid = Xml.getAttrStr(...
							node.getAttributes(), XmlParser.ATTR_ROOT);

					case XmlParser.NODE_START_DATE
						study.startDate = Xml.getAttrStr(...
							node.getAttributes(), XmlParser.ATTR_VALUE);

					case XmlParser.NODE_START_TIME
						study.startTime = Xml.getAttrStr(...
							node.getAttributes(), XmlParser.ATTR_VALUE);

					case XmlParser.NODE_IMAGE_SERIES
						XmlParser.parseSeries(node, study);

					otherwise
				end
			end
			if ~isempty(study.instanceUid)
				reference.imageStudy = study;
			end
		end

		%-------------------------------------------------------------------------
		function parseSeries(seriesNode, study)
			import ether.Xml;
			import ether.aim.*;
			if ~strcmp(char(seriesNode.getNodeName), XmlParser.NODE_IMAGE_SERIES)
				return;
			end

			series = ether.aim.ImageSeries();
			childNodes = seriesNode.getChildNodes();
			for i=0:childNodes.getLength-1
				node = childNodes.item(i);
				switch char(node.getNodeName)
					case XmlParser.NODE_TEXT
						continue

					case XmlParser.NODE_INSTANCE_UID
						series.instanceUid = Xml.getAttrStr(...
							node.getAttributes(), XmlParser.ATTR_ROOT);

%					case XmlParser.NODE_MODALITY

					case XmlParser.NODE_IMAGE_COLLECTION
						images = node.getChildNodes;
						for j=0:images.getLength-1
							XmlParser.parseImage(images.item(j), series);
						end

					otherwise
				end
			end
			if ~isempty(series.instanceUid)
				study.imageSeries = series;
			end
		end

		%-------------------------------------------------------------------------
		function parseTwoDCoordinate(coordNode, shape)
			import ether.Xml;
			import ether.aim.*;
			if ~strcmp(char(coordNode.getNodeName), XmlParser.NODE_2D_COORDINATE)
				return;
			end

			childNodes = coordNode.getChildNodes();
			idx = -1;
			x = NaN;
			y = NaN;
			for i=0:childNodes.getLength-1
				node = childNodes.item(i);
				switch char(node.getNodeName)
					case XmlParser.NODE_TEXT
						continue

					case XmlParser.NODE_COORDINATE_INDEX
						value = str2double(Xml.getAttrStr(node.getAttributes(), ...
							XmlParser.ATTR_VALUE));
						if isfinite(value) && (value >= 0)
							idx = uint32(value);
						end

					case XmlParser.NODE_X
						x = str2double(Xml.getAttrStr(node.getAttributes(), ...
							XmlParser.ATTR_VALUE));

					case XmlParser.NODE_Y
						y = str2double(Xml.getAttrStr(node.getAttributes(), ...
							XmlParser.ATTR_VALUE));

					otherwise
				end
			end
			if (idx >= 0) && isfinite(x) && isfinite(y)
				shape.addTwoDCoordinate(TwoDimensionCoordinate(idx, x, y));
			end
		end

	end % methods(Static,Access=private)

	%----------------------------------------------------------------------------
	methods(Access=private)
		%-------------------------------------------------------------------------
		function this = XmlParser()
		end
	end

end

