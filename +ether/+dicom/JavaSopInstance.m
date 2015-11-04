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
		function dump(this)
		end

		%-------------------------------------------------------------------------
		function [value,error,message] = getSequenceItemCount(this, seqPath)
			% Returns the item count for the SQ given by seqPath
			%   seqPath must be pairs of (sequence tag,index) finishing with an SQ tag
			if (~this.isLoaded)
				this.read;
			end
			[value,error,message] = this.jDcm.getSequenceItemCount(...
				this.fixSeqPath(seqPath));
		end

		%-------------------------------------------------------------------------
		function [value,error,message] = getSequenceValue(this, seqPath, tag)
			% Returns the item count for the SQ given by seqPath
			%   seqPath must be pairs of (sequence tag,index)
			if (~this.isLoaded)
				this.read;
			end
			[value,error,message] = this.jDcm.getSequenceValue(...
				this.fixSeqPath(seqPath), tag);
		end

		%-------------------------------------------------------------------------
		function [value,error,message] = getValue(this, tag)
			value = [];
			if (~this.isLoaded)
				this.read;
			end
			if isinteger(tag)
				[value,error,message] = this.jDcm.getValue(tag);
				return;
			end
			if ischar(tag)
				intTag = ether.dicom.Tag.tagOf(tag);
				[value,error,message] = this.jDcm.getValue(intTag);
				return;
			end
			error = true;
			message = 'Tag invalid';
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
		function seqPath = fixSeqPath(~, seqPathIn)
			% MATLAB indices start at 1, Java at zero
			seqPath = seqPathIn;
			idx = 2:2:numel(seqPathIn);
			seqPath(idx) = seqPath(idx)-1;
		end

		%-------------------------------------------------------------------------
		function onInfoLoad(this)
			import ether.dicom.*;
			this.sopClassUid = this.jDcm.getValue(Tag.SOPClassUID);
			this.instanceUid = this.jDcm.getValue(Tag.SOPInstanceUID);
			this.instanceNumber = this.jDcm.getValue(Tag.InstanceNumber);
			this.modality = this.jDcm.getValue(Tag.Modality);
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