classdef CTImage < ether.dicom.Image
	%CTIMAGE 2D CT DICOM image frame
	%   Detailed explanation goes here
	
	properties(Constant,Access=private)
		logger = ether.log4m.Logger.getLogger('ether.dicom.CTImage');
	end

	properties(Access=protected)
	end

	methods
		%-------------------------------------------------------------------------
		function this = CTImage(sopInstance, frame)
			this@ether.dicom.Image(sopInstance, frame);
		end

		%-------------------------------------------------------------------------
		function dump(this)
			dump@ether.dicom.Image(this);
			fprintf(' * Subclass: ether.dicom.CTImage\n');
		end

	end

	methods(Access=protected)
		%-------------------------------------------------------------------------
		function sopInstanceInfoChange(this, source, eventData)
			import ether.dicom.*;
			sopInstanceInfoChange@ether.dicom.Image(source, eventData);
			this.logger.debug(@() ...
				sprintf('InfoChanged event detected in CTImage: %s', this.uid));
		end
	end

end

