classdef Series < handle
	%SERIES DICOM Series
	%   A Series has a UID, a modality and contains zero or more SopInstances and
	%   zero or more Images. Each Series belongs to a Study.

	properties
		description;
		instanceUid;
		modality;
		number;
		studyUid;
	end

	properties(Access=private)
		sopInstMap;
		imageMap;
	end

	methods
		%-------------------------------------------------------------------------
		function this = Series(uid)
			this.instanceUid = uid;
			this.description = [];
			this.modality = [];
			this.number = 65536;
			this.studyUid = '';
			this.sopInstMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
			this.imageMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
		end

		%-------------------------------------------------------------------------
		function bool = addSopInstance(this, sopInst, toolkit)
			if (nargin == 2)
				toolkit = ether.dicom.Toolkit.getToolkit();
			end
			uid = sopInst.instanceUid;
			bool = ~this.sopInstMap.isKey(uid);
			if bool
				this.sopInstMap(uid) = sopInst;
			end
			images = toolkit.createImages(sopInst);
			imageUids = arrayfun(@(x) x.uid, images, 'UniformOutput', false);
			for ii=1:numel(imageUids)
				this.imageMap(imageUids{ii}) = images(ii);
			end
		end

		%-------------------------------------------------------------------------
		function image = getImage(this, uid)
			image = [];
			if this.imageMap.isKey(uid)
				image = this.imageMap(uid);
			end
		end

		%-------------------------------------------------------------------------
		function count = getImageCount(this)
			count = this.imageMap.Count;
		end

		%-------------------------------------------------------------------------
		function list = getImageList(this, orderBy)
			list = ether.collect.CellArrayList('ether.dicom.Image');
			values = this.imageMap.values;
			images = [values{:}];
			sortValues = arrayfun(@(x) x.frame, images);
			[~,sortIdx] = sort(sortValues);
			images = images(sortIdx);
			list.add(images);
		end

		%-------------------------------------------------------------------------
		function sopInst = getSopInstance(this, uid)
			sopInst = [];
			if this.sopInstMap.isKey(uid)
				sopInst = this.sopInstMap(uid);
			end
		end

		%-------------------------------------------------------------------------
		function count = getSopInstanceCount(this)
			count = this.sopInstMap.Count;
		end

		%-------------------------------------------------------------------------
		function list = getSopInstanceList(this, orderBy)
			list = ether.collect.CellArrayList('ether.dicom.SopInstance');
			values = this.sopInstMap.values;
			instances = [values{:}];
			sortValues = arrayfun(@(x) x.instanceNumber, instances);
			[~,sortIdx] = sort(sortValues);
			instances = instances(sortIdx);
			list.add(instances);
		end

		%-------------------------------------------------------------------------
		function bool = hasImage(this, uid)
			bool = this.imageMap.isKey(uid);
		end

		%-------------------------------------------------------------------------
		function bool = hasSopInstance(this, uid)
			bool = this.sopInstMap.isKey(uid);
		end

		%-------------------------------------------------------------------------
		function sopInst = removeSopInstance(this, uid)
			sopInst = this.getSopInstance(uid);
			this.sopInstMap.remove(uid);
		end
	end

end

