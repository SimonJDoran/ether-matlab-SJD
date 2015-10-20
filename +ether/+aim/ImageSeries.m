classdef ImageSeries < handle
	%IMAGESERIES Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
		instanceUid = '';
		modality = [];
	end
	
	%----------------------------------------------------------------------------
	properties(Access=private)
		images;
	end

	%----------------------------------------------------------------------------
	methods
		%-------------------------------------------------------------------------
		function this = ImageSeries()
			this.images = containers.Map('KeyType', 'char', 'ValueType', 'any');
		end

		%-------------------------------------------------------------------------
		function bool = addImage(this, image)
			bool = false;
			if ~isa(image, 'ether.aim.Image')
				return;
			end
			this.images(image.sopInstanceUid) = image;
			bool = true;
		end

		%-------------------------------------------------------------------------
		function images = getAllImages(this)
			images = [];
			if this.images.length == 0
				return;
			end
			images = this.images.values;
			images = [images{:}];
		end

		%-------------------------------------------------------------------------
		function image = getImage(this, uid)
			image = [];
			if ~this.images.isKey(uid)
				return;
			end
			image = this.images(uid);
		end

		%-------------------------------------------------------------------------
		function image = removeImage(this, uid)
			image = [];
			if ~this.images.isKey(uid)
				return;
			end
			image = this.images(uid);
			this.images.remove(uid);
		end

	end

end

