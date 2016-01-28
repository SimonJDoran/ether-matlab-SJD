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
	end

	%----------------------------------------------------------------------------
	methods
		%-------------------------------------------------------------------------
		function this = ImageAnnotationCollection()
			this.annotations = containers.Map('KeyType', 'char', 'ValueType', 'any');
		end

		%-------------------------------------------------------------------------
		function bool = addAnnotation(this, annotation)
			bool = false;
			if ~isa(annotation, 'ether.aim.ImageAnnotation')
				return;
			end
			this.annotations(annotation.uniqueIdentifier) = annotation;
			bool = true;
		end

		%-------------------------------------------------------------------------
		function annotations = getAllAnnotations(this)
			annotations = this.annotations.values;
			if numel(annotations) > 0
				annotations = annotations{:};
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
			count = this.annotations.size();
		end

		%-------------------------------------------------------------------------
		function annotation = removeAnnotation(this, uid)
			annotation = [];
			if ~this.annotations.isKey(uid)
				return;
			end
			annotation = this.annotations(uid);
			this.annotations.remove(uid);
		end

	end % methods

end

