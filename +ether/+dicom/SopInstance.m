classdef SopInstance < handle
	%SOPINSTANCE A DICOM dataset, often the contents of a part 10 file
	%   Detailed explanation goes here
	
	properties(Constant,Access=private)
		logger = ether.log4m.Logger.getLogger('ether.dicom.SopInstance');
	end

	properties
		sopClassUid;
		filename;
		numberOfFrames = -1;
		instanceUid;
		instanceNumber;
		modality;
		seriesUid;
		studyUid;
	end

	properties(SetAccess=protected)
		isLoaded = false;
	end

	events
		InfoChanged;
	end

	%----------------------------------------------------------------------------
	methods(Abstract)
		%-------------------------------------------------------------------------
		dump(this)
		% Outputs all tags to console
		%   Too expensive to use as display()

		%-------------------------------------------------------------------------
		dcm = getDicomObject(this)
		% Returns DicomObject contained in this SOP instance

		%-------------------------------------------------------------------------
		[item,error,message] = getSequenceItem(this, seqPath, idx)
		% Returns the item at index idx for the SQ given by seqPath

		%-------------------------------------------------------------------------
		[value,error,message] = getSequenceItemCount(this, seqPath)
		% Returns the item count for the SQ given by seqPath
		%   seqPath must be pairs of (sequence tag,index) finishing with an SQ tag

		%-------------------------------------------------------------------------
		[value,error,message] = getSequenceValue(this, seqPath, tag)
		% Returns the value for the SQ item given by seqPath
		%   seqPath must be even length integer array consisting of pairs of
		%   (SQ tag,index)

		%-------------------------------------------------------------------------
		[value,error,message] = getValue(this, tag)
		% Fetch the value associated with uint16 tag

		%-------------------------------------------------------------------------
		[bool,msg] = read(this, filename)
		% Read DICOM file
		%   bool is true on successful read, false otherwise
		%   msg contains error text on failed read

		%-------------------------------------------------------------------------
		unload(this)
		% Free internal resources to conserve RAM
	end

	%----------------------------------------------------------------------------
	methods
		%-------------------------------------------------------------------------
		function this = SopInstance(filename)
			if (nargin == 1)
				this.filename = filename;
			else
				this.filename = [];
			end
			this.numberOfFrames = -1;
			this.sopClassUid = '';
			this.instanceUid = '';
			this.instanceNumber = [];
			this.modality = '';
			this.seriesUid = '';
			this.studyUid = '';
			this.isLoaded = false;
		end

		%-------------------------------------------------------------------------
		function numberOfFrames = get.numberOfFrames(this)
			if ((this.numberOfFrames < 0) && ~this.isLoaded)
				this.read;
			end
			numberOfFrames = this.numberOfFrames;
		end

		%-------------------------------------------------------------------------
		function instanceNumber = get.instanceNumber(this)
			if (isempty(this.instanceNumber) && ~this.isLoaded)
				this.read;
			end
			instanceNumber = this.instanceNumber;
		end

		%-------------------------------------------------------------------------
		function instanceUid = get.instanceUid(this)
			if (isempty(this.instanceUid) && ~this.isLoaded)
				this.read;
			end
			instanceUid = this.instanceUid;
		end

		%-------------------------------------------------------------------------
		function modality = get.modality(this)
			if (isempty(this.modality) && ~this.isLoaded)
				this.read;
			end
			modality = this.modality;
		end

		%-------------------------------------------------------------------------
		function sopClassUid = get.sopClassUid(this)
			if (isempty(this.sopClassUid) && ~this.isLoaded)
				this.read;
			end
			sopClassUid = this.sopClassUid;
		end

		%-------------------------------------------------------------------------
		function seriesUid = get.seriesUid(this)
			if (isempty(this.seriesUid) && ~this.isLoaded)
				this.read;
			end
			seriesUid = this.seriesUid;
		end

		%-------------------------------------------------------------------------
		function studyUid = get.studyUid(this)
			if (isempty(this.studyUid) && ~this.isLoaded)
				this.read;
			end
			studyUid = this.studyUid;
		end

	end

end

