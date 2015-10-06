classdef Tag
	%TAG Integer constants for DICOM tags
	%   Detailed explanation goes here
	
	%----------------------------------------------------------------------------
	properties(Constant)
		%{ Group 0x0008 }%
		ImageType = uint32(hex2dec('00080008'));
		SOPClassUID = uint32(hex2dec('00080016'));
		SOPInstanceUID = uint32(hex2dec('00080018'));
		StudyDate = uint32(hex2dec('00080020'));
		SeriesDate = uint32(hex2dec('00080021'));
		AcquisitionDate = uint32(hex2dec('00080022'));
		ContentDate = uint32(hex2dec('00080023'));
		StudyTime = uint32(hex2dec('00080030'));
		SeriesTime = uint32(hex2dec('00080031'));
		AcquisitionTime = uint32(hex2dec('00080032'));
		ContentTime = uint32(hex2dec('00080033'));
		AccessionNumber = uint32(hex2dec('00080050'));
		Modality = uint32(hex2dec('00080060'));
		Manufacturer = uint32(hex2dec('00080070'));
		StudyDescription = uint32(hex2dec('00081030'));
		SeriesDescription = uint32(hex2dec('0008103e'));

		%{ Group 0x0010 }%
		PatientName = uint32(hex2dec('00100010'));
		PatientID = uint32(hex2dec('00100020'));
		PatientBirthDate = uint32(hex2dec('00100030'));

		%{ Group 0x0018 }%
		SliceThickness = uint32(hex2dec('00180050'));
		PatientPosition = uint32(hex2dec('00185100'));

		%{ Group 0x0020 }%
		StudyID = uint32(hex2dec('00200010'));
		SeriesNumber = uint32(hex2dec('00200011'));
		InstanceNumber = uint32(hex2dec('00200013'));
		StudyInstanceUID = uint32(hex2dec('0020000d'));
		SeriesInstanceUID = uint32(hex2dec('0020000e'));
		ImagePositionPatient = uint32(hex2dec('00200032'));
		ImageOrientationPatient = uint32(hex2dec('00200037'));
		FrameOfReferenceUID = uint32(hex2dec('00200052'));
		SliceLocation = uint32(hex2dec('00201041'));

		%{ Group 0x0028 }%
		NumberOfFrames = uint32(hex2dec('00280008'));
		Rows = uint32(hex2dec('00280010'));
		Columns = uint32(hex2dec('00280011'));
		PixelSpacing = uint32(hex2dec('00280030'));
		WindowCenter = uint32(hex2dec('00281050'));
		WindowWidth = uint32(hex2dec('00281051'));

		%{ Group 0x7fe0 }%
		PixelData = uint32(hex2dec('7fe00010'));
	end

	%----------------------------------------------------------------------------
	properties(Constant,Access=private)
		ELEM_MASK = uint32(hex2dec('0000ffff'));
	end

	%----------------------------------------------------------------------------
	methods(Static)
		%-------------------------------------------------------------------------
		function name = nameOf(tag)
			name = [];
			if isnumeric(tag)
				key = uint32(tag);
				name = dicomlookup(bitshift(key, -16), ...
					bitand(key, ether.dicom.Tag.ELEM_MASK));
				return;
			end
			if ischar(tag)
				try
					key = uint32(hex2dec(tag));
					name = dicomlookup(bitshift(key, -16), ...
						bitand(key, ether.dicom.Tag.ELEM_MASK));
				catch
					return;
				end
			end
		end

		%-------------------------------------------------------------------------
		function [tag,label] = tagOf(name)
			label = [];
			if ~ischar(name)
				throw(MException('Ether:Dicom:Tag', ...
					'Name must be of class "char"'));
			end
			tag = [];
			[group,element] = dicomlookup(name);
			if ~isempty(group) && ~isempty(element)
				tag = uint32(bitshift(group, 16)+element);
				label = sprintf('(%04x,%04x)', group, element);
			end
		end

		%-------------------------------------------------------------------------
		function tag = toInt(hex)
			tag = uint32(hex2dec(hex));
		end

	end

	%----------------------------------------------------------------------------
	methods(Access=private)
		%-------------------------------------------------------------------------
		function this = Tag()
		end
	end

end

