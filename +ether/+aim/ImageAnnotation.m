classdef ImageAnnotation < ether.aim.Annotation
	%IMAGEANNOTATION Summary of this class goes here
	%   Detailed explanation goes here

	%----------------------------------------------------------------------------
	properties
	end

	%----------------------------------------------------------------------------
	properties(Access=private)
		markups;
		references;
	end

	%----------------------------------------------------------------------------
	methods
		%-------------------------------------------------------------------------
		function this = ImageAnnotation()
			this.markups = containers.Map('KeyType', 'char', 'ValueType', 'any');
			this.references = containers.Map('KeyType', 'char', 'ValueType', 'any');
		end

		%-------------------------------------------------------------------------
		function bool = addMarkup(this, markup)
			bool = false;
			if ~isa(markup, 'ether.aim.Markup')
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
		function markup = removeMarkup(this, uid)
			markup = [];
			if ~this.markups.isKey(uid)
				return;
			end
			markup = this.markups(uid);
			this.markups.remove(uid);
		end

		%-------------------------------------------------------------------------
		function bool = addReference(this, reference)
			bool = false;
			if ~isa(reference, 'ether.aim.Reference')
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
		function reference = removeReference(this, uid)
			reference = [];
			if ~this.references.isKey(uid)
				return;
			end
			reference = this.references(uid);
			this.references.remove(uid);
		end

	end
	
end

