classdef UID < handle
	%UID String constants for UIDs with UID name retrieval
	%   Provides easy access to DICOM's pre-defined UIDs as constant strings.

	properties(Constant)
		ImplicitVRLittleEndian = '1.2.840.10008.1.2';
		ExplicitVRLittleEndian = '1.2.840.10008.1.2.1';
		DeflatedExplicitVRLittleEndian = '1.2.840.10008.1.2.1.99';
		ExplicitVRBigEndian = '1.2.840.10008.1.2.2';
		CTImageStorage = '1.2.840.10008.5.1.4.1.1.2';
		EnhancedCTImageStorage = '1.2.840.10008.5.1.4.1.1.2.1';
		NuclearMedicineImageStorage = '1.2.840.10008.5.1.4.1.1.20';
		UltrasoundMultiframeImageStorage = '1.2.840.10008.5.1.4.1.1.3.1';
		MRImageStorage = '1.2.840.10008.5.1.4.1.1.4';
		EnhancedMRImageStorage = '1.2.840.10008.5.1.4.1.1.4.1';
		MRSpectroscopyStorage = '1.2.840.10008.5.1.4.1.1.4.2';
	end

	properties
	end

	methods(Static)
		function name = nameOf(uid)
			persistent map;
			if isempty(map)
				map = ether.dicom.UID.createMap();
			end
			name = [];
			if map.isKey(uid)
				name = map(uid);
			end
		end

	end

	methods(Static, Access=private)
		function map = createMap()
			import ether.dicom.UID;
			map = containers.Map('KeyType','char','ValueType','char');
			map(UID.ImplicitVRLittleEndian) = 'Implicit VR Little Endian';
			map(UID.ExplicitVRLittleEndian) = 'Explicit VR Little Endian';
			map(UID.DeflatedExplicitVRLittleEndian) = ...
				'Deflated Explicit VR Little Endian';
			map(UID.ExplicitVRBigEndian) = 'Explicit VR Big Endian';
			map(UID.CTImageStorage) = 'CT Image Storage';
			map(UID.EnhancedCTImageStorage) = 'Enhanced CT Image Storage';
			map(UID.NuclearMedicineImageStorage) = 'Nuclear Medicine Image Storage';
			map(UID.UltrasoundMultiframeImageStorage) = ...
				'Ultrasound Multiframe Image Storage';
			map(UID.MRImageStorage) = 'MR Image Storage';
			map(UID.EnhancedMRImageStorage) = 'Enhanced MR Image Storage';
			map(UID.MRSpectroscopyStorage) = 'MR Spectroscopy Storage';
		end
	end

	methods(Access=private)
		function this = UID()
		end

	end

end

