classdef JavaDicom
	%JAVADICOM Wrapper for org.dcm4che2.data.DicomObject
	%   Detailed explanation goes here
	
	%----------------------------------------------------------------------------
	properties(SetAccess=private)
		jDcm;
	end
	
	%----------------------------------------------------------------------------
	methods
		%-------------------------------------------------------------------------
		function [value,error,message] = getValue(this, tag)
			import ether.dicom.*;
			value = [];
			[vr,error,message] = this.getVR(tag);
			if error
				return;
			end
			switch vr
				case {'AE','AS','CS','LO','LT','PN','SH','ST','UI','UT'}
					[vm,error,message] = this.getVM(tag);
					if (error || (vm == 0))
						return;
					end
					if (vm == 1)
						value = char(this.jDcm.getString(tag));
					else
						value = char(this.jDcm.getStrings(tag));
						value = strjoin(value, '\');
					end

				case 'DS'
					[vm,error,message] = this.getVM(tag);
					if (error || (vm == 0))
						return;
					end
					if (vm == 1)
						value = this.jDcm.getString(tag);
					else
						value = char(this.jDcm.getStrings(tag));
					end
					value = str2double(value);

				case 'IS'
					[vm,error,message] = this.getVM(tag);
					if (error || (vm == 0))
						return;
					end
					if (vm == 1)
						value = this.jDcm.getString(tag);
					else
						value = char(this.jDcm.getStrings(tag));
					end
					value = int32(str2double(value));

				case {'DA','DT','TM'}
					[vm,error,message] = this.getVM(tag);
					if (error || (vm == 0))
						return;
					end
					value = char(this.jDcm.getString(tag));

				case {'OF','FL'}
					[vm,error,message] = this.getVM(tag);
					if (error || (vm == 0))
						return;
					end
					if vm == 1
						value = this.jDcm.getFloat(tag);
					else
						value = this.jDcm.getFloats(tag);
					end

				case 'FD'
					[vm,error,message] = this.getVM(tag);
					if (error || (vm == 0))
						return;
					end
					if vm == 1
						value = this.jDcm.getDouble(tag);
					else
						value = this.jDcm.getDoubles(tag);
					end

				case {'OB','UN'}
					[vm,error,message] = this.getVM(tag);
					if (error || (vm == 0))
						return;
					end
					value = this.jDcm.getBytes(tag);

				case {'OW','US','SS'}
					% PixelData can have VM == 1 and 1000's of pixels
					if tag == Tag.PixelData
						value = this.jDcm.getShorts(tag);
						return;
					end
					% Java short == int16
					[vm,error,message] = this.getVM(tag);
					if (error || (vm == 0))
						return;
					end
					if vm == 1
						value = this.jDcm.getShort(tag);
					else
						value = this.jDcm.getShorts(tag);
					end

				case {'AT','SL','UL'}
					% Java int == int32
					[vm,error,message] = this.getVM(tag);
					if (error || (vm == 0))
						return;
					end
					if vm == 1
						value = this.jDcm.getInt(tag);
					else
						value = this.jDcm.getInts(tag);
					end

				case 'SQ'
					value = this.jDcm.get(tag);

				otherwise
					error = true;
					message = sprintf('Invalid VR for tag 0x%08x: %s', vr);
					return;
			end
		end

		%-------------------------------------------------------------------------
		function [vm,error,message] = getVM(this, tag)
			message = '';
			try
				vm = this.jDcm.vm(tag);
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
		function [vr,error,message] = getVR(this, tag)
			vr = '';
			message = '';
			try
				vr = char(henson.Henson.getVr(this.jDcm, tag));
				error = isempty(vr);
			catch ex
				error = true;
				if(isa(ex, 'matlab.exception.JavaException'))
					message = ex.errMsg;
					
					ex.printStackTrace;
				end
			end
		end

		%-------------------------------------------------------------------------
		function this = JavaDicom(jDcm)
			if ~isjava(jDcm) || ...
				~isa(jDcm, 'org.dcm4che2.data.DicomObject')
				throw(MException('Ether:DICOM:IllegalArgument', ...
					'JavaDicom must wrap Java class org.dcm4che2.data.DicomObject'));
			end
			this.jDcm = jDcm;
		end
	end
	
end

