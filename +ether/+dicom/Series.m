classdef Series < handle
	%SERIES DICOM Series
	%   A Series has a UID, a modality and contains zero or more SopInstances and
	%   zero or more Images. Each Series belongs to a Study.

	%----------------------------------------------------------------------------
	properties
	end

	%----------------------------------------------------------------------------
	properties(SetAccess=private)
		date;
		description;
		instanceUid;
		modality;
		number;
		studyUid;
		time;
		Images;
		SopInstances;
	end

	%----------------------------------------------------------------------------
	properties(Access=private)
		jSeries;
		sopInstMap;
		imageMap;
	end

	methods
		%-------------------------------------------------------------------------
		function this = Series(jSeries)
			this.jSeries = jSeries;
			this.instanceUid = char(jSeries.getUid());
			this.date = char(jSeries.getDate());
			this.description = char(jSeries.getDescription());
			this.modality = char(jSeries.getModality());
			this.number = jSeries.getNumber();
			this.studyUid = char(jSeries.getStudyUid());
			this.time = jSeries.getTime();
			this.sopInstMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
			this.imageMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
			% Process the children
			toolkit = ether.dicom.Toolkit.getToolkit();
			jSopInstList = jSeries.getSopInstanceList();
			nSopInst = jSopInstList.size();
			for i=0:nSopInst-1
				jSopInst = jSopInstList.get(i);
				dcm = toolkit.createSopInstance(char(jSopInst.getPath()), ...
					jSopInst.getDicomObject());
				this.addSopInstance(dcm);
			end
		end

		%-------------------------------------------------------------------------
		function image = get.Images(this)
			image = this.getAllImages();
		end

		%-------------------------------------------------------------------------
		function sopInst = get.SopInstances(this)
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
	end

	%----------------------------------------------------------------------------
	methods(Access=private)
		%-------------------------------------------------------------------------
		function bool = addSopInstance(this, sopInst)
			toolkit = ether.dicom.Toolkit.getToolkit();
			if (~strcmp(sopInst.seriesUid, this.instanceUid))
				throw(MException('Ether:DICOM:Series', ...
					['SopInstance''s Series UID doesn''t match: ',sopIsnt.seriesUid']));
			end
			uid = sopInst.instanceUid;
			bool = this.sopInstMap.isKey(uid);
			if bool
				return;
			end
			this.sopInstMap(uid) = sopInst;
			images = toolkit.createImages(sopInst);
			imageUids = arrayfun(@(x) x.getUid(), images, 'UniformOutput', false);
			for ii=1:numel(imageUids)
				this.imageMap(imageUids{ii}) = images(ii);
			end
		end
	end

end

