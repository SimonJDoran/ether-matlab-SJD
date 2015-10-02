classdef Image < handle
	%IMAGE 2D DICOM image frame
	%   Detailed explanation goes here
	
	properties
		autoLoad = true;
	end

	properties(SetAccess=private)
		columns = [];
		frame;
		frameOfReferenceUid = [];
		imageOrientation = [0;0;0;0;0;0];
		imagePosition = [0;0;0];
		instanceNumber = 0;
		isLoaded = false;
		patientPosition = [];
		pixelData = [];
		pixelDepth = 0;
		pixelHeight = 0;
		pixelWidth = 0;
		rows = [];
		seriesNumber = 0;
		sliceLocation = 0;
		sopInstance;
		uid;
		windowCentre = 0;
		windowWidth = 0;
	end

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
			this.autoLoad = true;
		end

		%-------------------------------------------------------------------------
		function columns = get.columns(this)
			if (isempty(this.columns) && this.autoLoad)
				this.columns = this.sopInstance.get('Columns');
			end
			columns = this.columns;
		end

		%-------------------------------------------------------------------------
		function frameOfReferenceUid = get.frameOfReferenceUid(this)
			if (isempty(this.frameOfReferenceUid) && this.autoLoad)
				this.frameOfReferenceUid = this.sopInstance.get('FrameOfReferenceUID');
			end
			frameOfReferenceUid = this.frameOfReferenceUid;
		end

		%-------------------------------------------------------------------------
		function imageOrientation = get.imageOrientation(this)
			if (all(this.imageOrientation == 0) && this.autoLoad)
				this.imageOrientation = this.sopInstance.get('ImageOrientationPatient');
			end
			imageOrientation = this.imageOrientation;
		end

		%-------------------------------------------------------------------------
		function imagePosition = get.imagePosition(this)
			if (all(this.imagePosition == 0) && this.autoLoad)
				this.imagePosition = this.sopInstance.get('ImagePositionPatient');
			end
			imagePosition = this.imagePosition;
		end

		%-------------------------------------------------------------------------
		function instanceNumber = get.instanceNumber(this)
			if ((this.instanceNumber == 0) && this.autoLoad)
				this.instanceNumber = this.sopInstance.get('InstanceNumber');
			end
			instanceNumber = this.instanceNumber;
		end

		%-------------------------------------------------------------------------
		function pixelData = get.pixelData(this)
			if (~this.isLoaded && this.autoLoad)
				this.pixelData = dicomread(this.sopInstance.filename, 'frames', ...
					double(this.frame));
				this.isLoaded = true;
			end
			pixelData = this.pixelData;
		end

		%-------------------------------------------------------------------------
		function pixelDepth = get.pixelDepth(this)
			if ((this.pixelDepth == 0) && this.autoLoad)
				this.pixelDepth = this.sopInstance.get('SliceThickness');
			end
			pixelDepth = this.pixelDepth;
		end

		%-------------------------------------------------------------------------
		function pixelHeight = get.pixelHeight(this)
			if ((this.pixelHeight == 0) && this.autoLoad)
				pixelSpacing = this.sopInstance.get('PixelSpacing');
				this.pixelHeight = pixelSpacing(1);
				this.pixelWidth = pixelSpacing(2);
			end
			pixelHeight = this.pixelHeight;
		end

		%-------------------------------------------------------------------------
		function pixelWidth = get.pixelWidth(this)
			if ((this.pixelWidth == 0) && this.autoLoad)
				pixelSpacing = this.sopInstance.get('PixelSpacing');
				this.pixelHeight = pixelSpacing(1);
				this.pixelWidth = pixelSpacing(2);
			end
			pixelWidth = this.pixelWidth;
		end

		%-------------------------------------------------------------------------
		function rows = get.rows(this)
			if (isempty(this.rows) && this.autoLoad)
				this.rows = this.sopInstance.get('Rows');
			end
			rows = this.rows;
		end

		%-------------------------------------------------------------------------
		function windowCentre = get.windowCentre(this)
			if ((this.windowCentre == 0) && this.autoLoad)
				this.windowCentre = this.sopInstance.get('WindowCenter');
			end
			windowCentre = this.windowCentre;
		end

		%-------------------------------------------------------------------------
		function windowWidth = get.windowWidth(this)
			if ((this.windowWidth == 0) && this.autoLoad)
				this.windowWidth = this.sopInstance.get('WindowWidth');
			end
			windowWidth = this.windowWidth;
		end

		%-------------------------------------------------------------------------
		function unload(this)
			this.pixelData = [];
			this.isLoaded = false;
		end
	end

	methods(Access=private)
		%-------------------------------------------------------------------------
		function sopInstanceInfoChange(this, source, eventData)
			this.instanceNumber = this.sopInstance.instanceNumber;
			this.seriesNumber = this.sopInstance.get('SeriesNumber');
			this.rows = this.sopInstance.get('Rows');
			this.columns = this.sopInstance.get('Columns');
			this.frameOfReferenceUid = this.sopInstance.get('FrameOfReferenceUID');
			pixelSpacing = this.sopInstance.get('PixelSpacing');
			this.pixelHeight = pixelSpacing(1);
			this.pixelWidth = pixelSpacing(2);
			this.pixelDepth = this.sopInstance.get('SliceThickness');
			this.imageOrientation = this.sopInstance.get('ImageOrientationPatient');
			this.imagePosition = this.sopInstance.get('ImagePositionPatient');
			sliceLoc = this.sopInstance.get('SliceLocation');
			if ~isempty(sliceLoc)
				this.sliceLocation = sliceLoc;
			end
			patPos = this.sopInstance.get('PatientPosition');
			if ~isempty(patPos)
				this.patientPosition = patPos;
			end
			this.windowCentre = this.sopInstance.get('WindowCenter');
			this.windowWidth = this.sopInstance.get('WindowWidth');
			this.pixelData = dicomread(this.sopInstance.filename, 'frames', ...
				double(this.frame));
			this.isLoaded = true;
		end
	end
	
end

