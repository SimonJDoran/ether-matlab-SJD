classdef ImageSeries < handle
	%IMAGESERIES Summary of this class goes here
	%   Detailed explanation goes here
	
	properties(SetAccess=private)
		instanceUid = '';
		modality = [];
	end
	
	%----------------------------------------------------------------------------
	properties(Access=private)
		images;
		javaSeries = [];
	end

	%----------------------------------------------------------------------------
	methods
		%-------------------------------------------------------------------------
		function this = ImageSeries(jSeries)
			this.images = containers.Map('KeyType', 'char', 'ValueType', 'any');
			if (numel(jSeries) ~= 1) || ~isa(jSeries, 'etherj.aim.ImageSeries')
				return;
			end
			this.javaSeries = jSeries;
			this.instanceUid = char(jSeries.getInstanceUid());
			this.modality = ether.aim.Code(jSeries.getModality());
			jImages = jSeries.getImageList();
			for i=0:jImages.size()-1
				image = ether.aim.Image(jImages.get(i));
				this.images(image.sopInstanceUid) = image;
			end
		end

		%-------------------------------------------------------------------------
		function [bool,message] = addImage(this, image)
			bool = false;
			message = '';
			if ~isempty(this.javaIa)
				message = 'ImageAnnotation is read-only as it is wrapping a Java object';
				return;
			end
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
		function [image,message] = removeImage(this, uid)
			image = [];
			message = '';
			if ~isempty(this.javaIa)
				message = 'ImageAnnotation is read-only as it is wrapping a Java object';
				return;
			end
			if ~this.images.isKey(uid)
				return;
			end
			image = this.images(uid);
			this.images.remove(uid);
		end

	end

end

