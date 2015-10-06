classdef NativeSopInstance < ether.dicom.SopInstance
	%NATIVESOPINSTANCE SopInstance implementation using MATLAB's dicominfo
	%   Detailed explanation goes here
	
	properties(Constant)
		logger = ether.log4m.Logger.getLogger('ether.dicom.NativeSopInstance');
	end

	properties(Access=private)
		dicomInfo;
		isLoading = false;
	end

	methods
		%-------------------------------------------------------------------------
		function this = NativeSopInstance(filename)
			this@ether.dicom.SopInstance();
			if nargin == 1
				this.filename = filename;
			end
			this.dicomInfo = [];
		end

		%-------------------------------------------------------------------------
		function value = get(this, tag)
			value = [];
			if (~this.isLoaded && this.autoLoad)
				this.read;
			end
			if ischar(tag)
				tagName = tag;
			else
				tagName = ether.dicom.Tag.nameOf(tag);
			end
			if isfield(this.dicomInfo, tagName)
				value = this.dicomInfo.(tagName);
			end
		end

		%-------------------------------------------------------------------------
		function [bool,msg] = read(this, filename)
			if (nargin == 2)
				fileToRead = filename;
			else
				fileToRead = this.filename;
			end
			msg = '';
			this.dicomInfo = [];
			this.isLoaded = false;
			try
				this.dicomInfo = dicominfo(fileToRead);
				this.filename = fileToRead;
				this.isLoaded = true;
				this.logger.trace(@() sprintf('SOP instance read: %s', this.filename));
				this.onInfoLoad
			catch ex
				this.dicomInfo = [];
				msg = ex.message;
				this.isLoaded = false;
			end
			bool = this.isLoaded;
		end

		%-------------------------------------------------------------------------
		function unload(this)
			this.isLoaded = false;
			this.dicomInfo = [];
		end

	end

	methods(Access=private)
		%-------------------------------------------------------------------------
		function onInfoLoad(this)
			this.sopClassUid = this.dicomInfo.SOPClassUID;
			this.instanceUid = this.dicomInfo.SOPInstanceUID;
			this.instanceNumber = this.dicomInfo.InstanceNumber;
			this.seriesUid = this.dicomInfo.SeriesInstanceUID;
			this.studyUid = this.dicomInfo.StudyInstanceUID;
			toolkit = ether.dicom.Toolkit.getToolkit();
			if toolkit.isImageSOPClass(this.sopClassUid)
				if isfield(this.dicomInfo, 'FrameCount')
					this.numberOfFrames = this.dicomInfo.FrameCount;
				else
					this.numberOfFrames = 1;
				end
			else
				this.numberOfFrames = 0;
			end
			this.notify('InfoChanged');
		end

	end

end