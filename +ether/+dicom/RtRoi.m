classdef RtRoi < handle
	%RTROI Summary of this class goes here
	%   Detailed explanation goes here
   
   % Modified from James' original to make compatible with changes to 
   % underlying etherj libraries. In short, the Java class RtRoi has been
   % withdrawn from the latest etherj library in favour of an approach that
   % follows the DICOM standard better. However, the radiomic code uses
   % the MATLAB RtRoi class, so this is a temporary fix to maintain
   % compatibility, rather than a complete rewrite.
	
	%----------------------------------------------------------------------------
	properties(Dependent)
		contourCount;
		referencedFrameOfReferenceUid;
		name;
		number;
	end

	%----------------------------------------------------------------------------
	properties(Access=private)
		contourList = [];
		imageRefList = [];
		jSSRoi = [];
      jrts = [];
		parent = [];
	end

	%----------------------------------------------------------------------------
	methods
		%-------------------------------------------------------------------------
		function this = RtRoi(jSSRoi, rtStruct)
			this.jSSRoi = jSSRoi;
         this.jrts = rtStruct.jRtStruct;
			this.parent = rtStruct;
      end

		%-------------------------------------------------------------------------
		function name = get.name(this)
			name = char(this.jSSRoi.getRoiName());
		end

		%-------------------------------------------------------------------------
		function rfor = get.referencedFrameOfReferenceUid(this)
			rfor = char(this.jSSRoi.getReferencedFrameOfReferenceUid());
		end

		%-------------------------------------------------------------------------
		function roiNumber = get.number(this)
			roiNumber = this.jSSRoi.getRoiNumber();
		end

		%-------------------------------------------------------------------------
		function contour = getContour(this, idx)
			contour = this.getRoiContourModule().getContourList().get(idx);
		end

		%-------------------------------------------------------------------------
		function count = getContourCount(this)
			count = this.getRoiContourModule().getContourList().size();
		end

		%-------------------------------------------------------------------------
		function contourList = getContourList(this)
			if (isempty(this.contourList))
				this.contourList = this.createContourList();
			end
			contourList = this.contourList;
		end

		%-------------------------------------------------------------------------
		function imageRefList = getImageReferenceList(this)
			if (isempty(this.imageRefList))
				this.imageRefList = this.createImageReferenceList();
			end
			imageRefList = this.imageRefList;
      end
      
      %-------------------------------------------------------------------------
		function refSeriesList = getReferencedSeriesUidList(this)			
			jRForList = this.jrts.getStructureSetModule()...
                                  .getReferencedFrameOfReferenceList();
         refSeriesList = ether.collect.CellArrayList('char');
         for i = 0:jRForList.size()-1
            jStudyUidList = jRForList.get(i).getRtReferencedStudyList();
            for j = 0:jStudyUidList.size()-1
               jSeriesUidList = jStudyUidList.get(j).getRtReferencedSeriesList();
               for k = 0:jSeriesUidList.size()-1
                  refSeriesList.add(char(jSeriesUidList.get(i).getSeriesInstanceUid()));
               end
            end
         end
      end
      
      
      %-------------------------------------------------------------------------
		function name = getPatientName(this)
         name = this.jrts.getPatientModule().getPatientName(); 
      end
      
   end
	
	%----------------------------------------------------------------------------
	methods(Access=private)
		%-------------------------------------------------------------------------
		function [contourList, message] = createContourList(this)
         contourList = [];
         jrcList = this.jrts.getRoiContourModule().getRoiContourList();
         found = false;
         for i=0:jrcList.size()-1
            jrc = jrcList.get(i);
            if jrc.getReferencedRoiNumber() == this.number
               found = true;
               break
            end
         end
         if ~found
            message = 'Source RT-STRUCT is invalid: incorrect referencing '...
               + 'of ROI number between StructureSetROI and ROICountour modules.';
            return;
         end
         
			contourList = ether.collect.CellArrayList('ether.dicom.RtContour');
			jContourList = jrc.getContourList();
			for i=0:jContourList.size()-1
				contour = ether.dicom.RtContour(jContourList.get(i), this);
				contourList.add(contour);
			end
		end

		%-------------------------------------------------------------------------
		function refList = createImageReferenceList(this)
			refList = ether.collect.CellArrayList('ether.dicom.ImageReference');
			jRefList = this.jRtRoi.getImageReferenceList();
			for i=0:jRefList.size()-1
				ref = ether.dicom.ImageReference(jRefList.get(i));
				refList.add(ref);
			end
		end

	end

end

