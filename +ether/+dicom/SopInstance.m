classdef SopInstance < handle
	%SOPINSTANCE A DICOM dataset, often the contents of a part 10 file
	%   Detailed explanation goes here
	
	properties(Constant)
		logger = ether.log4m.Logger.getLogger('ether.dicom.SopInstance');
	end

	properties
		autoLoad = true;
		sopClassUid;
		filename;
		frameCount = -1;
		instanceUid;
		instanceNumber;
		seriesUid;
		studyUid;
	end

	properties(SetAccess=private)
		isLoaded;
	end

	properties(Access=private)
		dicomInfo;
		isLoading = false;
		overrideMap;
		originalMap;
	end

	events
		InfoChanged;
	end

	methods
		%-------------------------------------------------------------------------
		function this = SopInstance(filename)
			if (nargin == 1)
				this.filename = filename;
			else
				this.filename = [];
			end
			this.dicomInfo = [];
			this.frameCount = -1;
			this.sopClassUid = [];
			this.instanceUid = [];
			this.instanceNumber = [];
			this.seriesUid = [];
			this.studyUid = [];
			this.autoLoad = true;
			this.isLoaded = false;
			this.overrideMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
			this.originalMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
		end

		%-------------------------------------------------------------------------
		function value = get(this, tagName)
			value = [];
			if (~this.isLoaded && this.autoLoad)
				this.read;
			end
			if isfield(this.dicomInfo, tagName)
				value = this.dicomInfo.(tagName);
			end
		end

		%-------------------------------------------------------------------------
% 		function dicomInfo = get.dicomInfo(this)
% 			if (~this.isLoaded && this.autoLoad)
% 				this.read;
% 			end
% 			dicomInfo = this.dicomInfo;
% 		end

		%-------------------------------------------------------------------------
		function frameCount = get.frameCount(this)
			if ((this.frameCount < 0) && ~this.isLoaded && this.autoLoad)
				this.read;
			end
			frameCount = this.frameCount;
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
		function oldValue = override(this, key, value)
			if ~isfield(this.dicomInfo, key)
				oldValue = [];
				return;
			end
			oldValue = this.dicomInfo.(key);
			if ~this.originalMap.isKey(key)
				this.originalMap(key) = oldValue;
			end
			this.overrideInternal(key, value);
			this.overrideMap(key) = value;
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
					this.frameCount = this.dicomInfo.FrameCount;
				else
					this.frameCount = 1;
				end
			else
				this.frameCount = 0;
			end
			if this.overrideMap.size > 0
				keys = this.overrideMap.keys;
				for ii=1:this.overrideMap.size
					this.overrideInternal(keys{ii}, this.overrideMap(keys{ii}));
				end
			end
			this.notify('InfoChanged');
		end

		%-------------------------------------------------------------------------
		function overrideInternal(this, key, value)
			fieldClass = class(this.dicomInfo.(key));
			switch fieldClass
				case 'double' 
					this.dicomInfo.(key) = str2double(value);

				otherwise
					this.logger.warn(@() ...
						sprintf('Unsupported override class: %s', fieldClass));
			end
		end

	end
	
end

