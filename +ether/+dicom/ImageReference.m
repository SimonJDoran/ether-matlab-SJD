classdef ImageReference < handle
	%IMAGEREFERENCE Summary of this class goes here
	%   Detailed explanation goes here
	
	properties(Dependent)
		sopClassUid;
		sopInstanceUid;
		referencedFrameNumber;
	end

	properties(Access=private)
		jRef = [];
	end
	
	methods
		function this = ImageReference(jRef)
			this.jRef = jRef;
		end

		%-------------------------------------------------------------------------
		function uid = get.sopClassUid(this)
			uid = char(this.jRef.sopClassUid);
		end

		%-------------------------------------------------------------------------
		function uid = get.sopInstanceUid(this)
			uid = char(this.jRef.sopInstanceUid);
		end

		%-------------------------------------------------------------------------
		function type = get.referencedFrameNumber(this)
			type = this.jRef.referencedFrameNumber;
		end

	end
	
end

