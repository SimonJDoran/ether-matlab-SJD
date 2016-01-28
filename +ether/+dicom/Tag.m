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
		RepetitionTime = uint32(hex2dec('00180080'));
		EchoTime = uint32(hex2dec('00180081'));
		InversionTime = uint32(hex2dec('00180082'));
		FlipAngle = uint32(hex2dec('00181314'));
		PatientPosition = uint32(hex2dec('00185100'));
		EffectiveEchoTime = uint32(hex2dec('00189082'));
		MRTimingAndRelatedParametersSequence = uint32(hex2dec('00189112'));
		MREchoSequence = uint32(hex2dec('00189114'));

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
		PlanePositionSequence = uint32(hex2dec('00209113'));
		PlaneOrientationSequence = uint32(hex2dec('00209116'));

		%{ Group 0x0028 }%
		NumberOfFrames = uint32(hex2dec('00280008'));
		Rows = uint32(hex2dec('00280010'));
		Columns = uint32(hex2dec('00280011'));
		PixelSpacing = uint32(hex2dec('00280030'));
		WindowCenter = uint32(hex2dec('00281050'));
		WindowWidth = uint32(hex2dec('00281051'));
		RescaleIntercept = uint32(hex2dec('00281052'));
		RescaleSlope = uint32(hex2dec('00281053'));
		PixelMeasuresSequence = uint32(hex2dec('00289110'));
		FrameVOILUTSequence = uint32(hex2dec('00289132'));
		PixelValueTransformationSequence = uint32(hex2dec('00289145'));

		%{ Group 0x0029 - Philips }%
		LegacyScaleIntercept = uint32(hex2dec('00291052'));
		LegacyScaleSlope = uint32(hex2dec('00291053'));

		%{ Group 0x2005 - Philips }%
		ScaleIntercept = uint32(hex2dec('2005100d'));
		ScaleSlope = uint32(hex2dec('2005100e'));

		%{ Group 0x3006 }%
		StructureSetLabel = uint32(hex2dec('30060002'));
		StructureSetName = uint32(hex2dec('30060004'));
		StructureSetDate = uint32(hex2dec('30060008'));
		StructureSetTime = uint32(hex2dec('30060009'));
		ContourImageSequence = uint32(hex2dec('30060016'));
		StructureSetRoiSequence = uint32(hex2dec('30060020'));
		RoiNumber = uint32(hex2dec('30060022'));
		ReferencedFrameOfReferenceUid = uint32(hex2dec('30060024'));
		RoiName = uint32(hex2dec('30060026'));
		RoiDisplayColour = uint32(hex2dec('3006002a'));
		RoiGenerationAlgorithm = uint32(hex2dec('30060036'));
		RoiContourSequence = uint32(hex2dec('30060039'));
		ContourSequence = uint32(hex2dec('30060040'));
		ContourGeometricType = uint32(hex2dec('30060042'));
		NumberOfContourPoints = uint32(hex2dec('30060046'));
		ContourNumber = uint32(hex2dec('30060048'));
		ContourData = uint32(hex2dec('30060050'));

		%{ Group 0x5200 }%
		SharedFunctionalGroupsSequence = uint32(hex2dec('52009229'));
		PerFrameFunctionalGroupsSequence = uint32(hex2dec('52009230'));

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
		function string = format(tag)
			string = [];
			if isnumeric(tag)
				key = uint32(tag);
				string = sprintf('(%04x,%04x)', bitshift(key, -16), ...
					bitand(key, ether.dicom.Tag.ELEM_MASK));
				return;
			end
			if ischar(tag)
				try
					key = uint32(hex2dec(tag));
					string = sprintf('(%04x,%04x)', bitshift(key, -16), ...
						bitand(key, ether.dicom.Tag.ELEM_MASK));
				catch
					return;
				end
			end
		end

		%-------------------------------------------------------------------------
		function string = formatSequencePath(seqPath, names)
			import ether.dicom.Tag;
			string = [];
			nPath = size(seqPath, 2);
			if ~(isvector(seqPath) && isinteger(seqPath) && (nPath >= 1))
				return;
			end
			odd = mod(nPath, 2) == 1;
			if odd
				nPath = nPath-1;
			end
			string = '';
			if (nargin == 2) && names
				for idx=1:2:nPath
					string = sprintf('%s, %s[%i]', string, Tag.nameOf(seqPath(idx)), ...
						seqPath(idx+1));
				end
				if odd
					string = sprintf('%s, %s', string, Tag.nameOf(seqPath(nPath+1)));
				end
			else
				for idx=1:2:nPath
					string = sprintf('%s, %s[%i]', string, Tag.format(seqPath(idx)), ...
						seqPath(idx+1));
				end
				if odd
					string = sprintf('%s, %s', string, Tag.format(seqPath(nPath+1)));
				end
			end
			string = string(3:end);
		end

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

