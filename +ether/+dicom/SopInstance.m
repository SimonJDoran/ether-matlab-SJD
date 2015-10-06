classdef SopInstance < handle
	%SOPINSTANCE A DICOM dataset, often the contents of a part 10 file
	%   Detailed explanation goes here
	
	properties(Constant,Access=private)
		logger = ether.log4m.Logger.getLogger('ether.dicom.SopInstance');
	end

	properties
		autoLoad = true;
		sopClassUid;
		filename;
		numberOfFrames = -1;
		instanceUid;
		instanceNumber;
		seriesUid;
		studyUid;
	end

	properties(SetAccess=protected)
		isLoaded;
	end

	events
		InfoChanged;
	end

	%----------------------------------------------------------------------------
	methods(Abstract)
		%-------------------------------------------------------------------------
		value = get(this, tag)
		% Fetch the value associated with uint16 tag

		[bool,msg] = read(this, filename)
		% Read DICOM file
		%   bool is true on successful read, false otherwise
		%   msg contains error text on failed read

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
			this.sopClassUid = [];
			this.instanceUid = [];
			this.instanceNumber = [];
			this.seriesUid = [];
			this.studyUid = [];
			this.autoLoad = true;
			this.isLoaded = false;
		end

		%-------------------------------------------------------------------------
		function numberOfFrames = get.numberOfFrames(this)
			if ((this.numberOfFrames < 0) && ~this.isLoaded && this.autoLoad)
				this.read;
			end
			numberOfFrames = this.numberOfFrames;
		end

		%-------------------------------------------------------------------------
		function instanceNumber = get.instanceNumber(this)
			if (isempty(this.instanceNumber) && ~this.isLoaded && this.autoLoad)
				this.read;
			end
			instanceNumber = this.instanceNumber;
		end

		%-------------------------------------------------------------------------
		function instanceUid = get.instanceUid(this)
			if (isempty(this.instanceUid) && ~this.isLoaded && this.autoLoad)
				this.read;
			end
			instanceUid = this.instanceUid;
		end

		%-------------------------------------------------------------------------
		function sopClassUid = get.sopClassUid(this)
			if (isempty(this.sopClassUid) && ~this.isLoaded && this.autoLoad)
				this.read;
			end
			sopClassUid = this.sopClassUid;
		end

		%-------------------------------------------------------------------------
		function seriesUid = get.seriesUid(this)
			if (isempty(this.seriesUid) && ~this.isLoaded && this.autoLoad)
				this.read;
			end
			seriesUid = this.seriesUid;
		end

		%-------------------------------------------------------------------------
		function studyUid = get.studyUid(this)
			if (isempty(this.studyUid) && ~this.isLoaded && this.autoLoad)
				this.read;
			end
			studyUid = this.studyUid;
		end

	end

end

