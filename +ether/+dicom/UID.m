classdef UID < handle
	%UID String constants for UIDs with UID name retrieval
	%   Provides easy access to DICOM's pre-defined UIDs as constant strings.

	properties(Constant)
		%{ Transfer Syntax }%
		ImplicitVRLittleEndian = '1.2.840.10008.1.2';
		ExplicitVRLittleEndian = '1.2.840.10008.1.2.1';
		DeflatedExplicitVRLittleEndian = '1.2.840.10008.1.2.1.99';
		ExplicitVRBigEndian = '1.2.840.10008.1.2.2';
		JPEGBaseline8Bit = '1.2.840.10008.1.2.4.50';
		JPEGBaseline12Bit = '1.2.840.10008.1.2.4.51';
		JPEGLosslessNonHierarchical = '1.2.840.10008.1.2.4.57';
		JPEGLosslessNonHierarchicalFirstOrderPrediction = '1.2.840.10008.1.2.4.70';
		JPEGLSLossless = '1.2.840.10008.1.2.4.80';
		JPEGLSLossy = '1.2.840.10008.1.2.4.81';
		JPEG2000Lossless = '1.2.840.10008.1.2.4.90';
		JPEG2000 = '1.2.840.10008.1.2.4.91';
		JPEG2000MulticomponentLossless = '1.2.840.10008.1.2.4.92';
		JPEG2000Multicomponent = '1.2.840.10008.1.2.4.93';

		%{ SOP Class }%
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
			map(UID.JPEGBaseline8Bit) = 'JPEG Baseline 8-Bit';
			map(UID.JPEGBaseline12Bit) = 'JPEG Baseline 12-Bit';
			map(UID.JPEGLosslessNonHierarchical) = ...
				'JPEG Lossless Non-Hierarchical';
			map(UID.JPEGLosslessNonHierarchicalFirstOrderPrediction) = ...
				'JPEG Lossless Non-Hierarchical First Order Prediction';
			map(UID.JPEGLSLossless) = ...
				'JPEG-LS Lossless';
			map(UID.JPEGLS) = ...
				'JPEG-LS';
			map(UID.JPEG2000Lossless) = ...
				'JPEG 2000 Lossless';
			map(UID.JPEG2000) = ...
				'JPEG 2000';
			map(UID.JPEG2000MulticomponentLossless) = ...
				'JPEG 2000 Multicomponent Lossless';
			map(UID.JPEG2000Multicomponent) = ...
				'JPEG 2000 Multicomponent';
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

