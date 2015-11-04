classdef MRImage < ether.dicom.Image
	%MRIMAGE 2D MR DICOM image frame
	%   Detailed explanation goes here
	
	properties(Constant,Access=private)
		logger = ether.log4m.Logger.getLogger('ether.dicom.MRImage');
	end

	properties(Access=protected)
		echoTime = NaN;
		flipAngle = NaN;
		inversionTime = NaN;
		repetitionTime = NaN;
	end

	methods
		%-------------------------------------------------------------------------
		function this = MRImage(sopInstance, frame)
			this@ether.dicom.Image(sopInstance, frame);
		end

		%-------------------------------------------------------------------------
		function dump(this)
			dump@ether.dicom.Image(this);
			fprintf(' * Subclass: ether.dicom.MRImage\n');
			fprintf('\tEchoTime: %f\n', this.getEchoTime);
			fprintf('\tFlipAngle: %f\n', this.getFlipAngle);
			ti = this.getInversionTime;
			if ti > 0.0
				fprintf('\tInversionTime: %f\n', ti);
			end
			fprintf('\tRepetitionTime: %f\n', this.getRepetitionTime);
		end

		%-------------------------------------------------------------------------
		function te = getEchoTime(this)
			if isnan(this.echoTime)
				this.echoTime = this.sopInstance.getValue(ether.dicom.Tag.EchoTime);
			end
			te = this.echoTime;
		end

		%-------------------------------------------------------------------------
		function flipAngle = getFlipAngle(this)
			if isnan(this.flipAngle)
				this.flipAngle = this.sopInstance.getValue(ether.dicom.Tag.FlipAngle);
			end
			flipAngle = this.flipAngle;
		end

		%-------------------------------------------------------------------------
		function ti = getInversionTime(this)
			if isnan(this.inversionTime)
				this.inversionTime = this.sopInstance.getValue(...
					ether.dicom.Tag.InversionTime);
			end
			ti = this.inversionTime;
		end

		%-------------------------------------------------------------------------
		function tr = getRepetitionTime(this)
			if isnan(this.repetitionTime)
				this.repetitionTime = this.sopInstance.getValue(...
					ether.dicom.Tag.RepetitionTime);
			end
			tr = this.repetitionTime;
		end

	end

	methods(Access=protected)
		%-------------------------------------------------------------------------
		function sopInstanceInfoChange(this, source, eventData)
			import ether.dicom.*;
			sopInstanceInfoChange@ether.dicom.Image(source, eventData);
			this.logger.debug(@() ...
				sprintf('InfoChanged event detected in MRImage: %s', this.uid));
			this.echoTime = this.sopInstance.getValue(Tag.EchoTime);
			this.flipAngle = this.sopInstance.getValue(Tag.FlipAngle);
			this.inversionTime = this.sopInstance.getValue(Tag.InversionTime);
			this.repetitionTime = this.sopInstance.getValue(Tag.RepetitionTime);
		end
	end

end

