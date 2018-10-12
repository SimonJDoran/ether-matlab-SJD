classdef ImageAnnotationCollection < ether.aim.AnnotationCollection
	%IMAGEANNOTATIONCOLLECTION Summary of this class goes here
	%   Detailed explanation goes here

	%----------------------------------------------------------------------------
	properties
		person = [];
	end

	%----------------------------------------------------------------------------
	properties(Access=private)
		annotations;
		javaIac = [];
	end

	%----------------------------------------------------------------------------
	properties(Dependent)
 		annotationCount;
	end

	%----------------------------------------------------------------------------
	methods
		%-------------------------------------------------------------------------
		function this = ImageAnnotationCollection(jIac)
			this.annotations = containers.Map('KeyType', 'char', 'ValueType', 'any');
			if ((numel(jIac) ~= 1) || ~isa(jIac, 'icr.etherj.aim.ImageAnnotationCollection'))
				return;
			end
			this.javaIac = jIac;
			this.aimVersion = char(jIac.getAimVersion());
			this.dateTime = char(jIac.getDateTime());
			this.description = char(jIac.getDescription());
			this.equipment = ether.aim.Equipment(jIac.getEquipment());
			this.uniqueIdentifier = char(jIac.getUid());
			this.user = ether.aim.User(jIac.getUser());
			this.person = ether.aim.Person(jIac.getPerson());
			jIaList = jIac.getAnnotationList();
			for i=0:jIaList.size()-1
				jIa = jIaList.get(i);
				ia = ether.aim.ImageAnnotation(jIa);
				this.annotations(ia.uniqueIdentifier) = ia;
			end
		end

		%-------------------------------------------------------------------------
		function [bool,message] = addAnnotation(this, annotation)
			bool = false;
			message = '';
			if ~isempty(this.javaIac)
				message = 'ImageAnnotationCollection is read-only as it is wrapping a Java object';
				return;
			end
			if ~isa(annotation, 'ether.aim.ImageAnnotation')
				message = 'Supplied annotation must be: ether.aim.ImageAnnotation';
				return;
			end
			this.annotations(annotation.uniqueIdentifier) = annotation;
			bool = true;
		end

		%-------------------------------------------------------------------------
		function annotations = getAllAnnotations(this)
			annotations = this.annotations.values;
			if numel(annotations) > 0
				annotations = [annotations{:}];
			else
				annotations = [];
			end
		end

		%-------------------------------------------------------------------------
		function annotation = getAnnotation(this, uid)
			annotation = [];
			if ~this.annotations.isKey(uid)
				return;
			end
			annotation = this.annotations(uid);
		end

		%-------------------------------------------------------------------------
		function count = getAnnotationCount(this)
			count = this.annotations.length();
		end

		%-------------------------------------------------------------------------
		function iac = getJavaIac(this)
			iac = this.javaIac;
		end

		%-------------------------------------------------------------------------
		function value = get.annotationCount(this)
			value = this.annotations.length();
		end

		%-------------------------------------------------------------------------
		function [annotation,message] = removeAnnotation(this, uid)
			annotation = [];
			message = '';
			if ~isempty(this.javaIac)
				message = 'ImageAnnotationCollection is read-only as it is wrapping a Java object';
				return;
			end
			if ~this.annotations.isKey(uid)
				message = ['No annotation found for key: ',uid];
				return;
			end
			annotation = this.annotations(uid);
			this.annotations.remove(uid);
		end

	end % methods

end

