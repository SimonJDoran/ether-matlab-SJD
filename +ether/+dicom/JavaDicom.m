classdef JavaDicom < ether.dicom.DicomObject
	%JAVADICOM Wrapper for org.dcm4che2.data.DicomObject
	%   Detailed explanation goes here
	
	%----------------------------------------------------------------------------
	properties(Access=protected)
		jDcm;
		jSharedSq;
		frameItemMap;
	end

	%----------------------------------------------------------------------------
	methods
		%-------------------------------------------------------------------------
		function dcm = getRawDicomObject(this)
			dcm = this.jDcm;
		end

		%-------------------------------------------------------------------------
		function [item,error,message] = getSequenceItem(this, seqPath, idx)
			if (isvector(seqPath) && isinteger(seqPath) && ...
				  (mod(size(seqPath, 2), 2) == 1))
				[item,error,message] = this.getSequenceItemImpl(seqPath, idx);
				return;
			end
		end

		%-------------------------------------------------------------------------
		function [value,error,message] = getSequenceItemCount(this, seqPath)
			if (isvector(seqPath) && isinteger(seqPath) && ...
				  (mod(size(seqPath, 2), 2) == 1))
				[value,error,message] = this.getSequenceItemCountImpl(seqPath);
				return;
			end
			% TODO: Check seqPath is cell array that can be converted to uint32s
			% and call private method
			value = -1;
			error = true;
			message = 'Invalid SQ path specification';
		end

		%-------------------------------------------------------------------------
		function [value,error,message] = getSequenceValue(this, seqPath, tag)
			if (isvector(seqPath) && isinteger(seqPath) && ...
				  (mod(size(seqPath, 2), 2) == 0) && isinteger(tag))
				[value,error,message] = this.getSequenceValueImpl(seqPath, tag);
				return;
			end
			% TODO: Check seqPath is cell array that can be converted to uint32s
			% and call private method
			value = [];
			error = true;
			message = 'Invalid SQ path specification';
		end

		%-------------------------------------------------------------------------
		function [value,error,message] = getValue(this, tag)
			[value,error,message] = this.getValueImpl(this.jDcm, tag);
		end

		%-------------------------------------------------------------------------
		function [vm,error,message] = getVM(this, tag)
			[vm,error,message] = this.getVMImpl(this.jDcm, tag);
		end

		%-------------------------------------------------------------------------
		function [vr,error,message] = getVR(this, tag)
			[vr,error,message] = this.getVRImpl(this.jDcm, tag);
		end

		%-------------------------------------------------------------------------
		function this = JavaDicom(jDcm)
			if ~(isjava(jDcm) && ...
				  isa(jDcm, 'org.dcm4che2.data.DicomObject'))
				throw(MException('Ether:DICOM:IllegalArgument', ...
					'JavaDicom must wrap Java class org.dcm4che2.data.DicomObject'));
			end
			this.jDcm = jDcm;
			this.frameItemMap = containers.Map('KeyType', 'uint32', ...
				'ValueType', 'any');
		end
	end

	%----------------------------------------------------------------------------
	methods(Access=private)
		%-------------------------------------------------------------------------
		function [value,error,message] = getSequenceItemCountImpl(this, seqPath)
			import ether.dicom.*;
			value = -1;
			error = true;
			message = '';
			try
				value = henson.Henson.getSequenceItemCount(this.jDcm, seqPath);
				error = false;
			catch ex
				if(isa(ex, 'matlab.exception.JavaException'))
					message = ex.errMsg;
					ex.printStackTrace;
				else
					throw(ex);
				end
			end
		end

		%-------------------------------------------------------------------------
		function [item,error,message] = getSequenceItemImpl(this, seqPath, idx)
			import ether.dicom.*;
			item = [];
			error = true;
			message = '';
			try
				switch seqPath(1)
					% Per-frame functional group for multiframe
					case Tag.PerFrameFunctionalGroupsSequence
						frameIdx = seqPath(2);
						if this.frameItemMap.isKey(frameIdx)
							jDicom = this.frameItemMap(frameIdx);
						else
							jDicom = henson.Henson.getSequenceObject(this.jDcm, ...
								seqPath(1:2));
							if isempty(jDicom)
								message = sprintf('No item in SQ %08x at index %i', ...
									seqPath(1), frameIndex);
								return;
							end
							this.frameItemMap(frameIdx) = jDicom;
						end
						finalPath = [seqPath(3:end),idx];

					% General case of a SQ
					otherwise
						jDicom = this.jDcm;
						finalPath = [seqPath,idx];
				end
				% Fetch the final item and value
				jItemDcm = henson.Henson.getSequenceObject(jDicom, finalPath);
				if isempty(jItemDcm)
					message = 'No item found';
					return;
				end
				item = JavaDicom(jItemDcm);
				error = false;
			catch ex
				if(isa(ex, 'matlab.exception.JavaException'))
					message = ex.message;
					if isjava(ex.ExceptionObject)
						ex.ExceptionObject.printStackTrace;
					end
				else
					throw(ex);
				end
			end
		end

		%-------------------------------------------------------------------------
		function [value,error,message] = getSequenceValueImpl(this, seqPath, tag)
			import ether.dicom.*;
			value = [];
			error = true;
			try
				switch seqPath(1)
					% Per-frame functional group for multiframe
					case Tag.PerFrameFunctionalGroupsSequence
						frameIdx = seqPath(2);
						if this.frameItemMap.isKey(frameIdx)
							jDicom = this.frameItemMap(frameIdx);
						else
							jDicom = henson.Henson.getSequenceObject(this.jDcm, ...
								seqPath(1:2));
							if isempty(jDicom)
								message = sprintf('No item in SQ %08x at index %i', ...
									seqPath(1), frameIndex);
								return;
							end
							this.frameItemMap(frameIdx) = jDicom;
						end
						finalPath = seqPath(3:end);

					% General case of a SQ
					otherwise
						jDicom = this.jDcm;
						finalPath = seqPath;
				end
				% Fetch the final item and value
				jItemDcm = henson.Henson.getSequenceObject(jDicom, finalPath);
				if isempty(jItemDcm)
					message = 'No item found';
					return;
				end
				[value,error,message] = this.getValueImpl(jItemDcm, tag);
			catch ex
				if(isa(ex, 'matlab.exception.JavaException'))
					message = ex.message;
					if isjava(ex.ExceptionObject)
						ex.ExceptionObject.printStackTrace;
					end
				else
					throw(ex);
				end
			end
		end

		%-------------------------------------------------------------------------
		function [value,error,message] = getValueImpl(this, jDicom, tag)
			import ether.dicom.*;
			value = [];
			[vr,error,message] = this.getVRImpl(jDicom, tag);
			if error
				return;
			end
			switch vr
				case {'AE','AS','CS','LO','LT','PN','SH','ST','UI','UT'}
					[vm,error,message] = this.getVMImpl(jDicom, tag);
					if (error || (vm == 0))
						return;
					end
					if (vm == 1)
						value = strtrim(char(jDicom.getString(tag)));
					else
						value = strtrim(char(jDicom.getStrings(tag)));
						value = strjoin(value, '\');
					end

				case 'DS'
					[vm,error,message] = this.getVMImpl(jDicom, tag);
					if (error || (vm == 0))
						return;
					end
					if (vm == 1)
						value = str2double(char(jDicom.getString(tag)));
					else
						value = arrayfun(@(x) str2double(char(x)), ...
							jDicom.getStrings(tag));
					end

				case 'IS'
					[vm,error,message] = this.getVMImpl(jDicom, tag);
					if (error || (vm == 0))
						return;
					end
					if (vm == 1)
						value = int32(str2double(char(jDicom.getString(tag))));
					else
						value = arrayfun(@(x) int32(str2double(char(x))), ...
							jDicom.getStrings(tag));
					end

				case {'DA','DT','TM'}
					[vm,error,message] = this.getVMImpl(jDicom, tag);
					if (error || (vm == 0))
						return;
					end
					value = strtrim(char(jDicom.getString(tag)));

				case {'OF','FL'}
					[vm,error,message] = this.getVMImpl(jDicom, tag);
					if (error || (vm == 0))
						return;
					end
					if vm == 1
						value = jDicom.getFloat(tag);
					else
						value = jDicom.getFloats(tag);
					end

				case 'FD'
					[vm,error,message] = this.getVMImpl(jDicom, tag);
					if (error || (vm == 0))
						return;
					end
					if vm == 1
						value = jDicom.getDouble(tag);
					else
						value = jDicom.getDoubles(tag);
					end

				case {'OB','UN'}
					[vm,error,message] = this.getVMImpl(jDicom, tag);
					if (error || (vm == 0))
						return;
					end
					value = jDicom.getBytes(tag);

				case {'OW','US','SS'}
					% PixelData can have VM == 1 and 1000's of pixels
					if tag == Tag.PixelData
						value = jDicom.getShorts(tag);
						return;
					end
					% Java short == int16
					[vm,error,message] = this.getVMImpl(jDicom, tag);
					if (error || (vm == 0))
						return;
					end
					value = jDicom.getShorts(tag);

				case {'AT','SL','UL'}
					% Java int == int32
					[vm,error,message] = this.getVMImpl(jDicom, tag);
					if (error || (vm == 0))
						return;
					end
					if vm == 1
						value = jDicom.getInt(tag);
					else
						value = jDicom.getInts(tag);
					end

				case 'SQ'
					value = jDicom.get(tag);

				otherwise
					error = true;
					message = sprintf('Invalid VR for tag %s: %s', Tag.format(tag), vr);
					return;
			end
		end

		%-------------------------------------------------------------------------
		function [vm,error,message] = getVMImpl(~, jDicom, tag)
			message = '';
			try
				vm = jDicom.vm(tag);
				error = vm < 1;
				if error
					message = sprintf('Tag not found: 0x%08x', tag);
				end
			catch ex
				error = true;
				if(isa(ex, 'matlab.exception.JavaException'))
					message = ex.errMsg;
					ex.printStackTrace;
				end
			end
		end

		%-------------------------------------------------------------------------
		function [vr,error,message] = getVRImpl(~, jDicom, tag)
			vr = '';
			message = '';
			try
				vr = char(henson.Henson.getVr(jDicom, tag));
				error = isempty(vr);
			catch ex
				error = true;
				if(isa(ex, 'matlab.exception.JavaException'))
					message = ex.errMsg;
					ex.printStackTrace;
				end
			end
		end
	end

end

