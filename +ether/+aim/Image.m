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
			if (numel(jImage) ~= 1) || ~isa(jImage, 'etherj.aim.Image')
				return;
			end
			this.javaImage = jImage;
			this.sopInstanceUid = char(jImage.getInstanceUid());
		end
	end
	
end

