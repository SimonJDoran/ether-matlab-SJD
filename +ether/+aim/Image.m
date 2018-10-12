classdef Image < handle
	%IMAGE Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
		sopClassUid = '';
		sopInstanceUid = '';
	end
	
	%----------------------------------------------------------------------------
	properties(Access=private)
		javaImage = [];
	end

	methods
		function this = Image(jImage)
			if (numel(jImage) ~= 1) || ~isa(jImage, 'icr.etherj.aim.Image')
				return;
			end
			this.javaImage = jImage;
			this.sopClassUid = char(jImage.getSopClassUid());
			this.sopInstanceUid = char(jImage.getSopInstanceUid());
		end
	end
	
end

