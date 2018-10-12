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
      patientId = '';
		time = '';
      uid = '';
      jRtStruct = ''; % Don't really want to expose this but needs must for RtRoi.
	end

	%----------------------------------------------------------------------------
	properties(Access=private)
		roiList = [];
	end

	%----------------------------------------------------------------------------
	methods
		%-------------------------------------------------------------------------
		function this = RtStruct(jRtStruct)
			import ether.dicom.Tag;
			this.jRtStruct = jRtStruct;
			this.date = char(jRtStruct.getStructureSetModule().getStructureSetDate());
			this.description = char(jRtStruct.getStructureSetModule().getStructureSetDescription());
			this.label = char(jRtStruct.getStructureSetModule().getStructureSetLabel());
			this.name = char(jRtStruct.getStructureSetModule().getStructureSetName());
			this.patientName = char(jRtStruct.getPatientModule().getPatientName());
         this.patientId = char(jRtStruct.getPatientModule().getPatientId());
			this.time = char(jRtStruct.getStructureSetModule().getStructureSetTime());
         this.uid = char(jRtStruct.getSopInstanceUid());
      end
      
		%-------------------------------------------------------------------------
		function desc = getDescription(this)
			desc = this.description;
      end
      
      %-------------------------------------------------------------------------
		function patientName = getPatientName(this)
			patientName = this.patientName;
      end
      
      %-------------------------------------------------------------------------
		function uid = getSopInstanceUid(this)
			uid = this.uid;
      end
      
      %-------------------------------------------------------------------------
		function patientId = getPatientId(this)
			patientId = this.patientId;
      end
      
      %-------------------------------------------------------------------------
		function count = get.roiCount(this)
			count = this.jRtStruct.getStructureSetModule().getStructureSetRoiList().size();
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
			jSSRoiList = this.jRtStruct.getStructureSetModule().getStructureSetRoiList();
			for i=0:jSSRoiList.size()-1
				roi = ether.dicom.RtRoi(jSSRoiList.get(i), this);
				roiList.add(roi);
			end
		end

	end

end

