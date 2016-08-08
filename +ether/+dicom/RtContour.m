classdef RtContour < handle
	%RTCONTOUR Summary of this class goes here
	%   Detailed explanation goes here
	
	%----------------------------------------------------------------------------
	properties(Dependent)
		geometricType;
		number;
		numberOfContourPoints;
	end

	%----------------------------------------------------------------------------
	properties(Access=private)
		jRtContour = [];
		parent = [];
	end

	%----------------------------------------------------------------------------
	methods
		%-------------------------------------------------------------------------
		function this = RtContour(jRtContour, rtRoi)
			this.jRtContour = jRtContour;
			this.parent = rtRoi;
		end

		%-------------------------------------------------------------------------
		function type = get.geometricType(this)
			type = this.getContourGeometricType();
		end

		%-------------------------------------------------------------------------
		function number = get.number(this)
			number = this.getContourNumber();
		end

		%-------------------------------------------------------------------------
		function number = get.numberOfContourPoints(this)
			number = this.getNumberOfContourPoints();
		end

		%-------------------------------------------------------------------------
		function type = getContourGeometricType(this)
			type = char(this.jRtContour.getContourGeometricType());
		end

		%-------------------------------------------------------------------------
		function number = getContourNumber(this)
			number = this.jRtContour.getContourNumber();
		end

		%-------------------------------------------------------------------------
		function points = getContourPointsList(this)
			jList = this.jRtContour.getContourPointsList();
			nPoints = jList.size();
			points = zeros(nPoints, 3);
			for i=0:nPoints-1;
				point = jList.get(i);
				points(i+1,1:3) = [point.x,point.y,point.z];
			end
		end

		%-------------------------------------------------------------------------
		function refList = getImageReferenceList(this)
			refList = ether.collect.CellArrayList('ether.dicom.ImageReference');
			jRefList = this.jRtContour.getImageReferenceList();
			for i=0:jRefList.size()-1
				ref = ether.dicom.ImageReference(jRefList.get(i));
				refList.add(ref);
			end
		end

		%-------------------------------------------------------------------------
		function number = getNumberOfContourPoints(this)
			number = this.jRtContour.getNumberOfContourPoints();
		end

	end

	%----------------------------------------------------------------------------
	methods(Access=private)
	end

end

