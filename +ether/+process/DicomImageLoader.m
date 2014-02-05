classdef DicomImageLoader < ether.process.Loader
	%DICOMIMAGELOADER Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
	end
	
	methods
		%-------------------------------------------------------------------------
		function this = DicomImageLoader(id)
			this@ether.process.Loader(id, ether.process.Xml.IMAGE);
			this.isReady = true;
		end

		%-------------------------------------------------------------------------
		function value = loadFile(this, filename)
			value = ether.dicom.SopInstance(filename);
		end
	end
	
end

