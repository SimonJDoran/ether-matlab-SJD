classdef RtStruct < handle
	%RTSTRUCT Summary of this class goes here
	%   Detailed explanation goes here

	%----------------------------------------------------------------------------
	properties(Dependent)
		roiCount;
	end

	%----------------------------------------------------------------------------
	properties(SetAccess=private)
		date = '';
		description = '';
		label = '';
		name = '';
		patientName = '';
		time = '';
	end

	%----------------------------------------------------------------------------
	properties(Access=private)
		jRtStruct = [];
		roiList = [];
	end

	%----------------------------------------------------------------------------
	methods
		%-------------------------------------------------------------------------
		function this = RtStruct(jRtStruct)
			import ether.dicom.Tag;
			this.jRtStruct = jRtStruct;
			this.date = char(jRtStruct.getStructureSetDate());
			this.description = char(jRtStruct.getStructureSetDescription());
			this.label = char(jRtStruct.getStructureSetLabel());
			this.name = char(jRtStruct.getStructureSetName());
			jDcm = jRtStruct.getDicomObject();
			this.patientName = char(jDcm.getString(Tag.PatientName));
			this.time = char(jRtStruct.getStructureSetTime());
		end

		%-------------------------------------------------------------------------
		function count = get.roiCount(this)
			count = this.getRoiCount();
		end

		%-------------------------------------------------------------------------
		function uids = getReferencedFrameOfReferenceUidList(this)
			jUids = this.jRtStruct.getReferencedFrameOfReferenceUidList();
			uids = ether.collect.CellArrayList('char');
			for i=0:jUids.size()-1
				uids.add(char(jUids.get(i)));
			end
		end

		%-------------------------------------------------------------------------
		function uids = getReferencedSeriesUidList(this)
			jUids = this.jRtStruct.getReferencedSeriesUidList();
			uids = ether.collect.CellArrayList('char');
			for i=0:jUids.size()-1
				uids.add(char(jUids.get(i)));
			end
		end

		%-------------------------------------------------------------------------
		function uids = getReferencedStudyUidList(this)
			jUids = this.jRtStruct.getReferencedStudyUidList();
			uids = ether.collect.CellArrayList('char');
			for i=0:jUids.size()-1
				uids.add(char(jUids.get(i)));
			end
		end

		%-------------------------------------------------------------------------
		function roi = getRoi(this, idx)
			roi = this.roiList().get(idx);
		end

		%-------------------------------------------------------------------------
		function count = getRoiCount(this)
			count = this.jRtStruct.getRoiCount();
		end

		%-------------------------------------------------------------------------
		function roiList = getRoiList(this)
			if (isempty(this.roiList))
				this.roiList = this.createRoiList();
			end
			roiList = this.roiList;
		end

	end

	%----------------------------------------------------------------------------
	methods(Access=private)
		%-------------------------------------------------------------------------
		function roiList = createRoiList(this)
			roiList = ether.collect.CellArrayList('ether.dicom.RtRoi');
			jRoiList = this.jRtStruct.getRoiList();
			for i=0:jRoiList.size()-1
				roi = ether.dicom.RtRoi(jRoiList.get(i), this);
				roiList.add(roi);
			end
		end

	end

end

