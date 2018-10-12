classdef DicomImageReference < ether.aim.ImageReference
	%DICOMIMAGEREFERENCE Summary of this class goes here
	%   Detailed explanation goes here

	properties(SetAccess=private)
		imageStudy = [];
	end

	%----------------------------------------------------------------------------
	properties(Access=private)
		javaRef = [];
	end

	methods
		function this = DicomImageReference(jRef)
			if (numel(jRef) ~= 1) || ~isa(jRef, 'icr.etherj.aim.DicomImageReference')
				return;
			end
			this.javaRef = jRef;
			this.uniqueIdentifier = char(jRef.getUid());
			jStudy = jRef.getStudy();
			this.imageStudy = ether.aim.ImageStudy(jStudy);
		end
	end

end

