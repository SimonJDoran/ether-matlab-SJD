classdef ImageAnnotation < ether.aim.Annotation
	%IMAGEANNOTATION Summary of this class goes here
	%   Detailed explanation goes here

	%----------------------------------------------------------------------------
	properties
	end

	%----------------------------------------------------------------------------
	properties(Access=private)
		javaIa = [];
		markups;
		references;
	end

	%----------------------------------------------------------------------------
	methods
		%-------------------------------------------------------------------------
		function this = ImageAnnotation(jIa)
			this.markups = containers.Map('KeyType', 'char', 'ValueType', 'any');
			this.references = containers.Map('KeyType', 'char', 'ValueType', 'any');
			if (numel(jIa) ~= 1) || ~isa(jIa, 'icr.etherj.aim.ImageAnnotation')
				return;
			end
			this.javaIa = jIa;
			this.uniqueIdentifier = char(jIa.getUid());
			this.comment = char(jIa.getComment());
			this.dateTime = char(jIa.getDateTime());
			this.name = char(jIa.getName());
			jMarkups = jIa.getMarkupList();
			for j=0:jMarkups.size()-1
				jMarkup = jMarkups.get(j);
				if isa(jMarkup, 'icr.etherj.aim.TwoDimensionPolyline')
					markup = ether.aim.TwoDimensionPolyline(jMarkup);
				elseif isa(jMarkup, 'icr.etherj.aim.TwoDimensionCircle')
					markup = ether.aim.TwoDimensionCircle(jMarkup);
				else
					continue;
				end
				this.markups(markup.uniqueIdentifier) = markup;
			end
			jRefs = jIa.getReferenceList();
			for j=0:jRefs.size()-1
				jRef = jRefs.get(j);
				if ~isa(jRef, 'icr.etherj.aim.DicomImageReference')
					continue;
				end
				ref = ether.aim.DicomImageReference(jRef);
				this.references(ref.uniqueIdentifier) = ref;
			end
		end

		%-------------------------------------------------------------------------
		function [bool,message] = addMarkup(this, markup)
			bool = false;
			message = '';
			if ~isempty(this.javaIa)
				message = 'ImageAnnotation is read-only as it is wrapping a Java object';
				return;
			end
			if ~isa(markup, 'ether.aim.Markup')
				message = 'Supplied markup must be: ether.aim.Markup';
				return;
			end
			this.markups(markup.uniqueIdentifier) = markup;
			bool = true;
		end

		%-------------------------------------------------------------------------
		function markups = getAllMarkups(this)
			markups = [];
			if this.markups.length == 0
				return;
			end
			markups = this.markups.values;
			markups = [markups{:}];
		end

		%-------------------------------------------------------------------------
		function markup = getMarkup(this, uid)
			markup = [];
			if ~this.markups.isKey(uid)
				return;
			end
			markup = this.markups(uid);
		end

		%-------------------------------------------------------------------------
		function [markup,message] = removeMarkup(this, uid)
			markup = [];
			message = '';
			if ~isempty(this.javaIa)
				message = 'ImageAnnotation is read-only as it is wrapping a Java object';
				return;
			end
			if ~this.markups.isKey(uid)
				return;
			end
			markup = this.markups(uid);
			this.markups.remove(uid);
		end

		%-------------------------------------------------------------------------
		function [bool,message] = addReference(this, reference)
			bool = false;
			message = '';
			if ~isempty(this.javaIa)
				message = 'ImageAnnotation is read-only as it is wrapping a Java object';
				return;
			end
			if ~isa(reference, 'ether.aim.Reference')
				message = 'Supplied reference must be: ether.aim.Reference';
				return;
			end
			this.references(reference.uniqueIdentifier) = reference;
			bool = true;
		end

		%-------------------------------------------------------------------------
		function references = getAllReferences(this)
			references = [];
			if this.references.length == 0
				return;
			end
			references = this.references.values;
			references = [references{:}];
		end

		%-------------------------------------------------------------------------
		function reference = getReference(this, uid)
			reference = [];
			if ~this.references.isKey(uid)
				return;
			end
			reference = this.references(uid);
		end

		%-------------------------------------------------------------------------
		function [reference,message] = removeReference(this, uid)
			reference = [];
			message = '';
			if ~isempty(this.javaIa)
				message = 'ImageAnnotation is read-only as it is wrapping a Java object';
				return;
			end
			if ~this.references.isKey(uid)
				return;
			end
			reference = this.references(uid);
			this.references.remove(uid);
		end

		%-------------------------------------------------------------------------
		function refList = getReferencedSeriesUidList(this)
			refList = ether.collect.CellArrayList('char');
			refs = this.getAllReferences();
			seriesUids = arrayfun(...
				@(ref) ref.imageStudy.imageSeries.instanceUid, ...
				refs, 'UniformOutput', false);
			seriesUids = unique(seriesUids);
			for i=1:numel(seriesUids)
				refList.add(seriesUids(i));
			end
		end
	end
	
end

