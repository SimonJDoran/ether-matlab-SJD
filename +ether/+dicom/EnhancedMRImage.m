classdef EnhancedMRImage < ether.dicom.MRImage
	%ENHANCEDMRIMAGE 2D MR DICOM image frame from multiframe SOP instance
	%   Detailed explanation goes here
	
	properties(Constant,Access=private)
		logger = ether.log4m.Logger.getLogger('ether.dicom.EnhancedMRImage');
	end

	methods
		%-------------------------------------------------------------------------
		function this = EnhancedMRImage(sopInstance, frame)
			this@ether.dicom.MRImage(sopInstance, frame);
		end

		%-------------------------------------------------------------------------
		% Image Overrides
		%-------------------------------------------------------------------------

		%-------------------------------------------------------------------------
		function imageOrientation = getImageOrientation(this)
			import ether.dicom.Tag;
			if ~all(isfinite(this.imageOrientation))
				seqPath = [Tag.PerFrameFunctionalGroupsSequence,this.frame,...
					Tag.PlaneOrientationSequence,1];
				[value,error,message] = this.sopInstance.getSequenceValue(seqPath, ...
					Tag.ImageOrientationPatient);
				if error
					this.logger.error(...
						'Invalid Image. Image Orientation (0020,0037) not found.');
					this.logger.error(message);
					this.imageOrientation = [1.0;0.0;0.0;0.0;1.0;0.0];
				else
					this.imageOrientation = value;
				end
			end
			imageOrientation = this.imageOrientation;
		end

		%-------------------------------------------------------------------------
		function imagePosition = getImagePosition(this)
			import ether.dicom.Tag;
			if ~all(isfinite(this.imagePosition))
				seqPath = [Tag.PerFrameFunctionalGroupsSequence,this.frame,...
					Tag.PlanePositionSequence,1];
				[value,error,message] = this.sopInstance.getSequenceValue(seqPath, ...
					Tag.ImagePositionPatient);
				if error
					this.logger.error(...
						'Invalid Image. Image Position (0020,0032) not found.');
					this.logger.error(message);
					this.imagePosition = [0.0;0.0;0.0];
				else
					this.imagePosition = value;
				end
			end
			imagePosition = this.imagePosition;
		end

		%-------------------------------------------------------------------------
		function pixelSpacing = getPixelSpacing(this)
			import ether.dicom.Tag;
			if ~all(isfinite(this.pixelSpacing))
				seqPath = [Tag.PerFrameFunctionalGroupsSequence,this.frame,...
					Tag.PixelMeasuresSequence,1];
				[value,error,message] = this.sopInstance.getSequenceValue(seqPath, ...
					Tag.PixelSpacing);
				if error
					this.logger.error(...
						'Invalid Image. Pixel Spacing (0028,0030) not found.');
					this.logger.error(message);
					this.pixelSpacing(:) = 0.0;
				else
					this.pixelSpacing = value;
				end
			end
			pixelSpacing = this.pixelSpacing;
		end

		%-------------------------------------------------------------------------
		function sliceThickness = getSliceThickness(this)
			import ether.dicom.Tag;
			if ~isfinite(this.sliceThickness)
				seqPath = [Tag.PerFrameFunctionalGroupsSequence,this.frame,...
					Tag.PixelMeasuresSequence,1];
				[value,error,message] = this.sopInstance.getSequenceValue(seqPath, ...
					Tag.SliceThickness);
				if error
					this.logger.error(...
						'Invalid Image. Slice Thickness (0018,0050) not found.');
					this.logger.error(message);
					this.sliceThickness = 0.0;
				else
					this.sliceThickness = value;
				end
			end
			sliceThickness = this.sliceThickness;
		end

		%-------------------------------------------------------------------------
		function windowCentre = getWindowCentre(this)
			import ether.dicom.Tag;
			if ~isfinite(this.windowCentre)
				seqPath = [Tag.PerFrameFunctionalGroupsSequence,this.frame,...
					Tag.FrameVOILUTSequence,1];
				[value,error,message] = this.sopInstance.getSequenceValue(seqPath, ...
					Tag.WindowCenter);
				if error
					this.logger.error(...
						'Invalid Image. Window Centre (0028,1050) not found.');
					this.logger.error(message);
					this.windowCentre = 1.0;
				else
					this.windowCentre = value;
				end
			end
			windowCentre = this.windowCentre;
		end

		%-------------------------------------------------------------------------
		function windowWidth = getWindowWidth(this)
			import ether.dicom.Tag;
			if ~isfinite(this.windowWidth)
				seqPath = [Tag.PerFrameFunctionalGroupsSequence,this.frame,...
					Tag.FrameVOILUTSequence,1];
				[value,error,message] = this.sopInstance.getSequenceValue(seqPath, ...
					Tag.WindowWidth);
				if error
					this.logger.error(...
						'Invalid Image. Window Width (0028,1051) not found.');
					this.logger.error(message);
					this.windowWidth = 1.0;
				else
					this.windowWidth = value;
				end
			end
			windowWidth = this.windowWidth;
		end

		%-------------------------------------------------------------------------
		% MRImage Overrides
		%-------------------------------------------------------------------------

		%-------------------------------------------------------------------------
		function te = getEchoTime(this)
			import ether.dicom.Tag;
			if ~isfinite(this.echoTime)
				seqPath = [Tag.PerFrameFunctionalGroupsSequence,this.frame,...
					Tag.MREchoSequence,1];
				[value,error,message] = this.sopInstance.getSequenceValue(seqPath, ...
					Tag.EffectiveEchoTime);
				if error
					this.logger.error(...
						'Invalid Image. Effective Echo Time (0018,9082) not found.');
					this.logger.error(message);
					this.echoTime = 0.0;
				else
					this.echoTime = value;
				end
			end
			te = this.echoTime;
		end

		%-------------------------------------------------------------------------
		function fa = getFlipAngle(this)
			import ether.dicom.Tag;
			if ~isfinite(this.flipAngle)
				seqPath = [Tag.SharedFunctionalGroupsSequence,1,...
					Tag.MRTimingAndRelatedParametersSequence,1];
				[value,error,message] = this.sopInstance.getSequenceValue(seqPath, ...
					Tag.FlipAngle);
				if error
					this.logger.error(...
						'Invalid Image. Flip Angle (0018,1314) not found.');
					this.logger.error(message);
					this.flipAngle = 0.0;
				else
					this.flipAngle = value;
				end
			end
			fa = this.flipAngle;
		end

		%-------------------------------------------------------------------------
		function ti = getInversionTime(this)
			import ether.dicom.Tag;
			if ~isfinite(this.inversionTime)
				seqPath = [Tag.SharedFunctionalGroupsSequence,1,...
					Tag.MRTimingAndRelatedParametersSequence,1];
				[value,error] = this.sopInstance.getSequenceValue(seqPath, ...
					Tag.InversionTime);
				if error
					this.inversionTime = 0.0;
				else
					this.inversionTime = value;
				end
			end
			ti = this.inversionTime;
		end

		%-------------------------------------------------------------------------
		function tr = getRepetitionTime(this)
			import ether.dicom.Tag;
			if ~isfinite(this.repetitionTime)
				seqPath = [Tag.SharedFunctionalGroupsSequence,1,...
					Tag.MRTimingAndRelatedParametersSequence,1];
				[value,error,message] = this.sopInstance.getSequenceValue(seqPath, ...
					Tag.RepetitionTime);
				if error
					this.logger.error(...
						'Invalid Image. Repetition Time (0018,0080) not found.');
					this.logger.error(message);
					this.repetitionTime = 0.0;
				else
					this.repetitionTime = value;
				end
			end
			tr = this.repetitionTime;
		end

	end

	methods(Access=protected)
		%-------------------------------------------------------------------------
		function sopInstanceInfoChange(this, source, eventData)
			import ether.dicom.*;
			this.logger.debug(@() ...
				sprintf('InfoChanged event detected in MultiframeMRImage: %s', this.uid));
			% General image parameters
			this.instanceNumber = this.sopInstance.instanceNumber;
			this.seriesNumber = this.sopInstance.getValue(Tag.SeriesNumber);
			this.rows = this.sopInstance.getValue(Tag.Rows);
			this.columns = this.sopInstance.getValue(Tag.Columns);
			this.frameOfReferenceUid = this.sopInstance.getValue(Tag.FrameOfReferenceUID);
			this.pixelSpacing(:) = NaN;
			this.sliceThickness = NaN;
			this.imageOrientation(:) = NaN;
			this.imagePosition(:) = NaN;
			this.windowCentre = NaN;
			this.windowWidth = NaN;
			this.getImageOrientation();
			this.getImagePosition();
			this.getPixelSpacing();
			this.getSliceThickness();
			sliceLoc = this.sopInstance.getValue(Tag.SliceLocation);
			if ~isempty(sliceLoc)
				this.sliceLocation = sliceLoc;
			end
			patPos = this.sopInstance.getValue(Tag.PatientPosition);
			if ~isempty(patPos)
				this.patientPosition = patPos;
			end
			this.getWindowCenter();
			this.getWindowWidth();
			this.pixelData = dicomread(this.sopInstance.filename, 'frames', ...
				double(this.frame));
			% MR specifics
			this.echoTime = NaN;
			this.flipAngle = NaN;
			this.inversionTime = NaN;
			this.repetitionTime = NaN;
			this.getEchoTime();
			this.getFlipAngle();
			this.getInversionTime();
			this.getRepetitionTime();
			% Flag completion
			this.isLoaded = true;
		end
	end

end

