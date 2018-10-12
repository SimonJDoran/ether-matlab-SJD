classdef JavaSopInstance < ether.dicom.SopInstance
	%JAVASOPINSTANCE SopInstance implementation using DCM4CHE Java library
	%   Detailed explanation goes here
	
	properties(Constant,Access=private)
		logger = ether.log4m.Logger.getLogger('ether.dicom.JavaSopInstance');
	end

	properties(Access=protected)
		dcm;
	end

	properties(Access=private)
		isLoading = false;
	end

	methods
		%-------------------------------------------------------------------------
		function this = JavaSopInstance(filename, inDcm)
			this@ether.dicom.SopInstance();
			if nargin == 0
				throw(MException('Ether:DICOM:JavaSopInstance', ...
					'Filename required'));
			end
			this.filename = filename;
			if nargin == 2
				if isa(inDcm, 'org.dcm4che2.data.DicomObject')
					this.dcm = ether.dicom.JavaDicom(inDcm);
					this.isLoaded = true;
					this.onInfoLoad
				else
					if isa(inDcm, 'ether.dicom.JavaDicom')
						this.dcm = inDcm;
						this.isLoaded = true;
						this.onInfoLoad
					else
						throw(MException('Ether:DICOM:IllegalArgument', ...
							'Invalid DICOM object'));
					end
				end
				this.filename = filename;
			else
				this.dcm = [];
			end
		end

		%-------------------------------------------------------------------------
		function dump(this)
			if (~this.isLoaded)
				this.read;% TODO parse return values
			end
			this.dumpObject(this.dcm, '');
		end

		%-------------------------------------------------------------------------
		function dcm = getDicomObject(this)
			dcm = this.dcm;
		end

		%-------------------------------------------------------------------------
		function [item,error,message] = getSequenceItem(this, seqPath, idx)
			if (~this.isLoaded)
				this.read;% TODO parse return values
			end
			[item,error,message] = this.dcm.getSequenceItem(seqPath, idx);
		end

		%-------------------------------------------------------------------------
		function [value,error,message] = getSequenceItemCount(this, seqPath)
			% Returns the item count for the SQ given by seqPath
			%   seqPath must be pairs of (sequence tag,index) finishing with an SQ tag
			if (~this.isLoaded)
				this.read;% TODO parse return values
			end
			[value,error,message] = this.dcm.getSequenceItemCount(...
				this.fixSeqPath(seqPath));
		end

		%-------------------------------------------------------------------------
		function [value,error,message] = getSequenceValue(this, seqPath, tag)
			% Returns the item count for the SQ given by seqPath
			%   seqPath must be pairs of (sequence tag,index)
			if (~this.isLoaded)
				this.read;% TODO parse return values
			end
			[value,error,message] = this.dcm.getSequenceValue(...
				this.fixSeqPath(seqPath), tag);
		end

		%-------------------------------------------------------------------------
		function [value,error,message] = getValue(this, tag)
			value = [];
			if (~this.isLoaded)
				this.read; % TODO parse return values
			end
			if isinteger(tag)
				[value,error,message] = this.dcm.getValue(tag);
				return;
			end
			if ischar(tag)
				intTag = ether.dicom.Tag.tagOf(tag);
				[value,error,message] = this.dcm.getValue(intTag);
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
			if isempty(fileToRead)
				throw(MException('Ether:DICOM:IllegalArgument', ...
					'Supplied and internal filename cannot both be empty'));
			end
			msg = '';
			this.dcm = [];
			this.isLoaded = false;
			try
				ioHandler = javaObject('henson.DicomIoHandler');
				jDicomObject = ioHandler.read(fileToRead);
				if isempty(jDicomObject)
					bool = false;
					return;
				end
				this.dcm = ether.dicom.JavaDicom(jDicomObject);
				this.filename = fileToRead;
				this.isLoaded = true;
				this.logger.trace(@() sprintf('SOP instance read: %s', this.filename));
				this.onInfoLoad
			catch ex
				this.dcm = [];
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
			this.dcm = [];
		end

	end

	methods(Access=private)
		%-------------------------------------------------------------------------
		function dumpElement(this, elem, indent, etherDcm)
			import ether.dicom.*;
			tagWidth = 20;
			nameWidth = 30;
			valueWidth = 60;
			rawDcm = etherDcm.getRawDicomObject();
			tag = elem.tag();
			vrStr = char(rawDcm.vrOf(tag));
			tagStr = [indent,Tag.format(tag)];
			tagStr = this.pad(tagStr, tagWidth);
			vm = rawDcm.vm(tag);
			vmStr = sprintf('%5d ', vm);
			sizeStr = sprintf('%9d ', elem.length());
			nameStr = this.pad(Tag.nameOf(tag), nameWidth);
			line = [tagStr,vrStr,' ',vmStr,sizeStr,nameStr];
			value = etherDcm.getValue(tag);
			if ischar(value)
				line = [line,this.clip(value, valueWidth)];
			else
				line = [line,this.dumpValue(value, valueWidth)];
			end
			disp(line);
			if strcmp(vrStr, 'SQ')
				this.dumpSqElement(elem, ['> ',indent])
			end
		end

		%-------------------------------------------------------------------------
		function dumpObject(this, etherDcm, indent)
			rawDcm = etherDcm.getRawDicomObject();
			iter = rawDcm.iterator();
			while (iter.hasNext())
				this.dumpElement(iter.next(), indent, etherDcm);
			end
		end

		%-------------------------------------------------------------------------
		function dumpSqElement(this, sq, indent)
			import ether.dicom.*;
			nItems = sq.countItems();
			for i=1:nItems
				fprintf('%sItem %d of %d:\n', indent, i, nItems);
				% MATLAB indices start at 1, Java at 0
				etherDcm = JavaDicom(sq.getDicomObject(i-1));
				this.dumpObject(etherDcm, indent);
			end
		end

		%-------------------------------------------------------------------------
		function str = dumpValue(this, value, valueWidth)
			vm = numel(value);
			if (isinteger(value))
				format = '%d';
			else
				if isfloat(value)
					format = '%f';
				else
					str = '';
					return;
				end
			end
			cells = cell(1, vm);
			for i=1:vm
				cells{i} = sprintf(format, value(i));
			end
			str = strjoin(cells, '\');
			nStr = numel(str);
			if nStr > valueWidth-1
				str = [this.clip(str, valueWidth-3),'...'];
			end
		end

		%-------------------------------------------------------------------------
		function newStr = clip(~, str, width)
			newStr = str;
			nStr = numel(str);
			if nStr >= width
				newStr = [str(1:width-1),' '];
			end
		end

		%-------------------------------------------------------------------------
		function newStr = pad(~, str, width)
			newStr = str;
			nStr = numel(str);
			if nStr < width
				newStr = [str,repmat(' ', 1, width-nStr)];
			end
		end

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
			this.sopClassUid = this.dcm.getValue(Tag.SOPClassUID);
			this.instanceUid = this.dcm.getValue(Tag.SOPInstanceUID);
			this.instanceNumber = this.dcm.getValue(Tag.InstanceNumber);
			this.modality = this.dcm.getValue(Tag.Modality);
			this.seriesUid = this.dcm.getValue(Tag.SeriesInstanceUID);
			this.studyUid = this.dcm.getValue(Tag.StudyInstanceUID);
			toolkit = ether.dicom.Toolkit.getToolkit();
			if toolkit.isImageSOPClass(this.sopClassUid)
				[frameCount,error] = this.dcm.getValue(Tag.NumberOfFrames);
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
