classdef Image < handle
	%IMAGE 2D DICOM image frame
	%   Detailed explanation goes here
	
	properties(Constant,Access=private)
		logger = ether.log4m.Logger.getLogger('ether.dicom.Image');
	end

	properties
	end

	properties(SetAccess=protected)
		columns = [];
		frame;
		frameOfReferenceUid = [];
		imageOrientation = [NaN;NaN;NaN;NaN;NaN;NaN];
		imagePosition = [NaN;NaN;NaN];
		instanceNumber = 0;
		isLoaded = false;
		patientPosition = '-1';
		pixelData = [];
		pixelSpacing = [NaN;NaN];
		rows = [];
		rescaleIntercept = NaN;;
		rescaleSlope = NaN;
		scaleIntercept = NaN;
		scaleSlope = NaN;
		seriesNumber = [];
		sliceLocation = [];
		sliceThickness = NaN;
		sopInstance;
		sopInstanceUid;
		uid;
		windowCentre = NaN;
		windowWidth = NaN;
	end

	%----------------------------------------------------------------------------
	methods(Static)
		%-------------------------------------------------------------------------
		function sliceLoc = location(imagePos, imageOri)
			% Slice location is minimum distance from image plane to origin
			import ether.dicom.*;
			sliceLoc = [];
			if ~(isnumeric(imagePos) && (numel(imagePos) == 3) && ...
				  isnumeric(imageOri) && (numel(imageOri) == 6))
				return;
			end
			normal = cross(imageOri(1:3), imageOri(4:6));
			[~,idx] = max(abs(normal));
			sliceLoc = sign(normal(idx))*dot(normal, imagePos);
		end
	end

	%----------------------------------------------------------------------------
	methods
		%-------------------------------------------------------------------------
		function this = Image(sopInstance, frame)
			if (~isa(sopInstance, 'ether.dicom.SopInstance') || ...
				 isempty(sopInstance.filename))
				throw(MException('Ether:DICOM:Image', 'Invalid SOP instance'));
			end
			this.sopInstance = sopInstance;
			sopInstance.addlistener('InfoChanged', @this.sopInstanceInfoChange);
			if (nargin == 1)
				this.frame = 1;
			else
				if (~isscalar(frame) || ~isnumeric(frame) || (frame < 1))
					throw(MException('Ether:DICOM:Image', ...
						'Frame must be a positive integral type'));
				end
				this.frame = uint32(floor(frame));
			end
			this.isLoaded = false;
			this.uid = sprintf('%s.%d', sopInstance.instanceUid, frame);
		end

		%-------------------------------------------------------------------------
		function dump(this)
			fprintf('* ether.dicom.Image (%ix%i) UID: %s\n', this.getColumns, ...
				this.getRows, this.uid);
			fprintf('\tFrameIndex: %i\n', this.frame);
			fprintf('\tFrameOfReferenceUID: %s\n', this.getFrameOfReferenceUid);
			fprintf('\tImageOrientationPatient: [%f,%f,%f,%f,%f,%f]\n', ...
				this.getImageOrientation);
			fprintf('\tImagePositionPatient: [%f,%f,%f]\n', this.getImagePosition);
			fprintf('\tInstanceNumber: %i\n', this.getInstanceNumber);
			fprintf('\tPatientPosition: %s\n', this.getPatientPosition);
			pixSpace = this.getPixelSpacing;
			fprintf('\tPixelSpacing: [%f,%f]\n', pixSpace(1), pixSpace(2));
			ri = this.getRescaleIntercept;
			rs = this.getRescaleSlope;
			if (ri ~= 0.0) || (rs ~= 1.0)
				fprintf('\tRescaleIntercept: %f\n', ri);
				fprintf('\tRescaleSlope: %f\n', rs);
			end
			si = this.getScaleIntercept;
			ss = this.getScaleSlope;
			if (si ~= 0.0) || (ss ~= 1.0)
				fprintf('\tScaleIntercept: %f\n', si);
				fprintf('\tScaleSlope: %f\n', ss);
			end
			fprintf('\tSeriesNumber: %i\n', this.getSeriesNumber);
			fprintf('\tSliceLocation: %f\n', this.getSliceLocation);
			fprintf('\tSliceThickness: %f\n', this.getSliceThickness);
			fprintf('\tWindowCentre: %f\n', this.getWindowCentre);
			fprintf('\tWindowWidth: %f\n', this.getWindowWidth);
		end

		%-------------------------------------------------------------------------
		function columns = getColumns(this)
			if (isempty(this.columns))
				this.columns = this.sopInstance.getValue(ether.dicom.Tag.Columns);
			end
			columns = this.columns;
		end

		%-------------------------------------------------------------------------
		function floatData = getFloatPixelData(this)
			floatData = this.getPixelData();
			ri = this.getRescaleIntercept();
			rs = this.getRescaleSlope();
			ss = this.getScaleSlope();
			if ((ri ~= 0.0) || (rs ~= 1.0) || (ss ~= 1.0))
				floatData = (floatData.*rs+ri)./(rs*ss);
			end
		end

		%-------------------------------------------------------------------------
		function frameIdx = getFrameIndex(this)
			frameIdx = this.frame;
		end

		%-------------------------------------------------------------------------
		function frameOfReferenceUid = getFrameOfReferenceUid(this)
			if (isempty(this.frameOfReferenceUid))
				this.frameOfReferenceUid = this.sopInstance.getValue(...
					ether.dicom.Tag.FrameOfReferenceUID);
			end
			frameOfReferenceUid = this.frameOfReferenceUid;
		end

		%-------------------------------------------------------------------------
		function imageOrientation = getImageOrientation(this)
			if ~all(isfinite(this.imageOrientation))
				this.imageOrientation = this.sopInstance.getValue(...
					ether.dicom.Tag.ImageOrientationPatient);
			end
			imageOrientation = this.imageOrientation;
		end

		%-------------------------------------------------------------------------
		function imagePosition = getImagePosition(this)
			if ~all(isfinite(this.imagePosition))
				this.imagePosition = this.sopInstance.getValue(...
					ether.dicom.Tag.ImagePositionPatient);
			end
			imagePosition = this.imagePosition;
		end

		%-------------------------------------------------------------------------
		function instanceNumber = getInstanceNumber(this)
			if ((this.instanceNumber == 0))
				this.instanceNumber = this.sopInstance.getValue(...
					ether.dicom.Tag.InstanceNumber);
			end
			instanceNumber = this.instanceNumber;
		end

		%-------------------------------------------------------------------------
		function patientPosition = getPatientPosition(this)
			if strcmp(this.patientPosition, '-1')
				this.patientPosition = this.sopInstance.getValue(...
					ether.dicom.Tag.PatientPosition);
			end
			patientPosition = this.patientPosition;
		end

		%-------------------------------------------------------------------------
		function pixelData = getPixelData(this)
			if ~this.isLoaded || isempty(this.pixelData)
				this.pixelData = dicomread(this.sopInstance.filename, 'frames', ...
					double(this.frame));
				this.isLoaded = true;
			end
			pixelData = this.pixelData;
		end

		%-------------------------------------------------------------------------
		function pixelSpacing = getPixelSpacing(this)
			if ~all(isfinite(this.pixelSpacing))
				this.pixelSpacing = this.sopInstance.getValue(...
					ether.dicom.Tag.PixelSpacing);
			end
			pixelSpacing = this.pixelSpacing;
		end

		%-------------------------------------------------------------------------
		function rescaleIntercept = getRescaleIntercept(this)
			if isfinite(this.rescaleIntercept)
				rescaleIntercept = this.rescaleIntercept;
				return;
			end
			[rescaleIntercept,error] = this.sopInstance.getValue(...
				ether.dicom.Tag.RescaleIntercept);
			if error
				rescaleIntercept = 0.0;
			end
			this.rescaleIntercept = rescaleIntercept;
		end

		%-------------------------------------------------------------------------
		function rescaleSlope = getRescaleSlope(this)
			if isfinite(this.rescaleSlope)
				rescaleSlope = this.rescaleSlope;
				return;
			end
			[rescaleSlope,error] = this.sopInstance.getValue(...
				ether.dicom.Tag.RescaleSlope);
			if error
				rescaleSlope = 1.0;
			end
			this.rescaleSlope = rescaleSlope;
		end

		%-------------------------------------------------------------------------
		function rows = getRows(this)
			if (isempty(this.rows))
				this.rows = this.sopInstance.getValue(ether.dicom.Tag.Rows);
			end
			rows = this.rows;
		end

		%-------------------------------------------------------------------------
		function scaleIntercept = getScaleIntercept(this)
			if isfinite(this.scaleIntercept)
				scaleIntercept = this.rescaleIntercept;
				return;
			end
			[scaleIntercept,error] = this.sopInstance.getValue(...
				ether.dicom.Tag.LegacyScaleIntercept);
			if error
				[scaleIntercept,error] = this.sopInstance.getValue(...
					ether.dicom.Tag.ScaleIntercept);
				if error
					scaleIntercept = 0.0;
				end
			end
			this.scaleIntercept = scaleIntercept;
		end

		%-------------------------------------------------------------------------
		function scaleSlope = getScaleSlope(this)
			if isfinite(this.scaleSlope)
				scaleSlope = this.scaleSlope;
				return;
			end
			[scaleSlope,error] = this.sopInstance.getValue(...
				ether.dicom.Tag.LegacyScaleSlope);
			if error
				[scaleSlope,error] = this.sopInstance.getValue(...
					ether.dicom.Tag.ScaleSlope);
				if error
					scaleSlope = 1.0;
				end
			end
			this.scaleSlope = scaleSlope;
		end

		%-------------------------------------------------------------------------
		function seriesNumber = getSeriesNumber(this)
			if (isempty(this.seriesNumber))
				this.seriesNumber = this.sopInstance.getValue(...
					ether.dicom.Tag.SeriesNumber);
			end
			seriesNumber = this.seriesNumber;
		end

		%-------------------------------------------------------------------------
		function uid = getSeriesUid(this)
			uid = this.sopInstance.getValue(ether.dicom.Tag.SeriesInstanceUID);
		end

		%-------------------------------------------------------------------------
		function sliceLocation = getSliceLocation(this)
			if isempty(this.sliceLocation)
				this.sliceLocation = this.sopInstance.getValue(...
					ether.dicom.Tag.SliceLocation);
				% Still empty? Compute from other values
				if isempty(this.sliceLocation)
					this.sliceLocation = ether.dicom.Image.location(...
						this.getImagePosition, this.getImageOrientation, ...
						this.getPatientPosition);
				end
			end
			sliceLocation = this.sliceLocation;
		end

		%-------------------------------------------------------------------------
		function sliceThickness = getSliceThickness(this)
			if ~isfinite(this.sliceThickness)
				this.sliceThickness = this.sopInstance.getValue(...
					ether.dicom.Tag.SliceThickness);
			end
			sliceThickness = this.sliceThickness;
		end

		%-------------------------------------------------------------------------
		function uid = getSopInstanceUid(this)
			if (isempty(this.sopInstanceUid))
				this.sopInstanceUid = this.sopInstance.getValue(...
					ether.dicom.Tag.SOPInstanceUID);
			end
			uid = this.sopInstanceUid;
		end

		%-------------------------------------------------------------------------
		function uid = getUid(this)
			uid = this.uid;
		end

		%-------------------------------------------------------------------------
		function windowCentre = getWindowCentre(this)
			if ~isfinite(this.windowCentre)
				this.windowCentre = this.sopInstance.getValue(...
					ether.dicom.Tag.WindowCenter);
			end
			windowCentre = this.windowCentre;
		end

		%-------------------------------------------------------------------------
		function windowWidth = getWindowWidth(this)
			if ~isfinite(this.windowWidth)
				this.windowWidth = this.sopInstance.getValue(...
					ether.dicom.Tag.WindowWidth);
			end
			windowWidth = this.windowWidth;
		end

		%-------------------------------------------------------------------------
		function unload(this)
			this.pixelData = [];
			this.isLoaded = false;
		end
	end

	methods(Access=protected)
		%-------------------------------------------------------------------------
		function sopInstanceInfoChange(this, source, eventData)
			import ether.dicom.*;
			this.logger.debug(@() ...
				sprintf('InfoChanged event detected in Image: %s', this.uid));
			this.instanceNumber = this.sopInstance.instanceNumber;
			this.seriesNumber = this.sopInstance.getValue(Tag.SeriesNumber);
			this.rows = this.sopInstance.getValue(Tag.Rows);
			this.columns = this.sopInstance.getValue(Tag.Columns);
			this.frameOfReferenceUid = this.sopInstance.getValue(Tag.FrameOfReferenceUID);
			this.pixelSpacing = this.sopInstance.getValue(Tag.PixelSpacing);
			this.pixelDepth = this.sopInstance.getValue(Tag.SliceThickness);
			this.imageOrientation = this.sopInstance.getValue(Tag.ImageOrientationPatient);
			this.imagePosition = this.sopInstance.getValue(Tag.ImagePositionPatient);
			sliceLoc = this.sopInstance.getValue(Tag.SliceLocation);
			if ~isempty(sliceLoc)
				this.sliceLocation = sliceLoc;
			end
			patPos = this.sopInstance.getValue(Tag.PatientPosition);
			if ~isempty(patPos)
				this.patientPosition = patPos;
			end
			this.windowCentre = this.sopInstance.getValue(Tag.WindowCenter);
			this.windowWidth = this.sopInstance.getValue(Tag.WindowWidth);
			this.pixelData = [];
			this.isLoaded = true;
		end
	end
	
end

