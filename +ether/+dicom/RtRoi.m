classdef RtRoi < handle
	%RTROI Summary of this class goes here
	%   Detailed explanation goes here
	
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
		jRtRoi = [];
		parent = [];
	end

	%----------------------------------------------------------------------------
	methods
		%-------------------------------------------------------------------------
		function this = RtRoi(jRtRoi, rtStruct)
			this.jRtRoi = jRtRoi;
			this.parent = rtStruct;
		end

		%-------------------------------------------------------------------------
		function count = get.contourCount(this)
			count = this.getContourCount();
		end

		%-------------------------------------------------------------------------
		function count = get.name(this)
			count = char(this.jRtRoi.getRoiName());
		end

		%-------------------------------------------------------------------------
		function count = get.referencedFrameOfReferenceUid(this)
			count = char(this.jRtRoi.getReferencedFrameOfReferenceUid());
		end

		%-------------------------------------------------------------------------
		function count = get.number(this)
			count = this.jRtRoi.getRoiNumber();
		end

		%-------------------------------------------------------------------------
		function contour = getContour(this, idx)
			contour = this.getContourList().get(idx);
		end

		%-------------------------------------------------------------------------
		function count = getContourCount(this)
			count = this.jRtRoi.getContourCount();
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

	end
	
	%----------------------------------------------------------------------------
	methods(Access=private)
		%-------------------------------------------------------------------------
		function contourList = createContourList(this)
			contourList = ether.collect.CellArrayList('ether.dicom.RtContour');
			jContourList = this.jRtRoi.getContourList();
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

