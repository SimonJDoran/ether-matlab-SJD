classdef Series < handle
	%SERIES DICOM Series
	%   A Series has a UID, a modality and contains zero or more SopInstances and
	%   zero or more Images. Each Series belongs to a Study.

	%----------------------------------------------------------------------------
	properties
		date;
		description;
		instanceUid;
		modality;
		number;
		studyUid;
		time;
	end

	%----------------------------------------------------------------------------
	properties(SetAccess=private)
		Image;
		SopInstance;
	end

	%----------------------------------------------------------------------------
	properties(Access=private)
		sopInstMap;
		imageMap;
	end

	methods
		%-------------------------------------------------------------------------
		function this = Series(uid)
			this.instanceUid = uid;
			this.date = '';
			this.description = '';
			this.modality = ether.dicom.Modality.OT;
			this.number = 65536;
			this.studyUid = '';
			this.time = 0;
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
			imageUids = arrayfun(@(x) x.getUid(), images, 'UniformOutput', false);
			for ii=1:numel(imageUids)
				this.imageMap(imageUids{ii}) = images(ii);
			end
		end

		%-------------------------------------------------------------------------
		function image = get.Image(this)
			image = this.getAllImages();
		end

		%-------------------------------------------------------------------------
		function sopInst = get.SopInstance(this)
			sopInst = this.getAllSopInstances();
		end

		%-------------------------------------------------------------------------
		function array = getAllImages(this)
			values = this.imageMap.values;
			array = [values{:}];
			sortValues = arrayfun(@(x) x.getFrameIndex, array);
			[~,sortIdx] = sort(sortValues);
			array = array(sortIdx);
		end

		%-------------------------------------------------------------------------
		function array = getAllSopInstances(this)
			values = this.sopInstMap.values;
			array = [values{:}];
			sortValues = arrayfun(@(x) x.instanceNumber, array);
			[~,sortIdx] = sort(sortValues);
			array = array(sortIdx);
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
			list.add(this.getAllImages());
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
			list.add(this.getAllSopInstances());
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

