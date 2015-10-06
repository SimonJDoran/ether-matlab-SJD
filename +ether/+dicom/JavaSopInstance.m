classdef JavaSopInstance < ether.dicom.SopInstance
	%JAVASOPINSTANCE SopInstance implementation using DCM4CHE Java library
	%   Detailed explanation goes here
	
	properties(Constant,Access=private)
		logger = ether.log4m.Logger.getLogger('ether.dicom.JavaSopInstance');
	end

	properties(Access=private)
		isLoading = false;
		jDcm;
	end

	methods
		%-------------------------------------------------------------------------
		function this = JavaSopInstance(filename)
			this@ether.dicom.SopInstance();
			if nargin == 1
				this.filename = filename;
			end
			this.jDcm = [];
		end

		%-------------------------------------------------------------------------
		function value = get(this, tag)
			value = [];
			if (~this.isLoaded && this.autoLoad)
				this.read;
			end
			if isinteger(tag)
				value = this.jDcm.getValue(tag);
				return;
			end
			if ischar(tag)
				intTag = ether.dicom.Tag.tagOf(tag);
				value = this.jDcm.getValue(intTag);
				return;
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
			this.jDcm = [];
			this.isLoaded = false;
			try
				ioHandler = javaObject('henson.DicomIoHandler');
				jDicomObject = ioHandler.read(fileToRead);
				if isempty(jDicomObject)
					bool = false;
					return;
				end
				this.jDcm = ether.dicom.JavaDicom(jDicomObject);
				this.filename = fileToRead;
				this.isLoaded = true;
				this.logger.trace(@() sprintf('SOP instance read: %s', this.filename));
				this.onInfoLoad
			catch ex
				this.jDcm = [];
				msg = ex.message;
				this.isLoaded = false;
				this.logger.warn(@() ...
					sprintf('Exception: %s', ether.formatException(ex)));
			end
			bool = this.isLoaded;
		end

		%-------------------------------------------------------------------------
		function unload(this)
			this.isLoaded = false;
			this.jDcm = [];
		end

	end

	methods(Access=private)
		%-------------------------------------------------------------------------
		function onInfoLoad(this)
			import ether.dicom.*;
			this.sopClassUid = this.jDcm.getValue(Tag.SOPClassUID);
			this.instanceUid = this.jDcm.getValue(Tag.SOPInstanceUID);
			this.instanceNumber = this.jDcm.getValue(Tag.InstanceNumber);
			this.seriesUid = this.jDcm.getValue(Tag.SeriesInstanceUID);
			this.studyUid = this.jDcm.getValue(Tag.StudyInstanceUID);
			toolkit = ether.dicom.Toolkit.getToolkit();
			if toolkit.isImageSOPClass(this.sopClassUid)
				[frameCount,error] = this.jDcm.getValue(Tag.NumberOfFrames);
				if error
					this.numberOfFrames = 1;
				else
					this.numberOfFrames = frameCount;
				end
			else
				this.numberOfFrames = 0;
			end
			this.notify('InfoChanged');
		end

	end

end