classdef Toolkit < handle
	%TOOLKIT Factory class for ether.dicom
	%   Allows static registration and retrieval of other Toolkit implementations

	properties(Constant)
		Default = 'Default';
	end

	properties(Constant,Access=private)
		toolkitMap = containers.Map(ether.dicom.Toolkit.Default, ...
			ether.dicom.Toolkit());
	end

	properties(Access=private)
		imageUidMap;
	end

	methods(Static)
		%-------------------------------------------------------------------------
		function toolkit = getToolkit(key)
			import ether.dicom.Toolkit;
			if ~((nargin == 1) && (Toolkit.toolkitMap.iskey(key)))
				key = Toolkit.Default;
			end
			toolkit = Toolkit.toolkitMap(key);
		end

		%-------------------------------------------------------------------------
		function keyUsed = setToolkit(toolkit, key)
			import ether.dicom.Toolkit;
			if ~(isscalar(toolkit) && isa(toolkit, 'ether.dicom.Toolkit'))
				throw(MException('Ether:DICOM:Toolkit', ...
					'toolkit must be of type ether.dicom.Toolkit'));
			end
			if (nargin == 1)
				key = Toolkit.Default;
			end
			% Constant handle field must be mapped to local var
			map = Toolkit.toolkitMap;
			map(key) = toolkit;
			keyUsed = key;
		end
	end

	methods
		%-------------------------------------------------------------------------
		function images = createImages(~, sopInst)
			import ether.dicom.*;
			if ~isa(sopInst, 'ether.dicom.SopInstance')
				throw(MException('Ether:DICOM:Toolkit', 'Not a valid SOP instance'));
			end
			nImages = sopInst.frameCount;
			images = Image.empty(nImages, 0);
			% TODO: Create images based on SOP Class UID of sopInst
			for ii=1:nImages
				images(ii) = Image(sopInst, ii);
			end
		end

		%-------------------------------------------------------------------------
		function root = createPatientRoot(~)
			root = ether.dicom.PatientRoot();
		end

		%-------------------------------------------------------------------------
		function patient = createPatient(~, varargin)
			import ether.dicom.*;
			if (nargin == 2 && isa(varargin{1}, 'ether.dicom.SopInstance'))
				sopInst = varargin{1};
				pn = sopInst.get('PatientName');
				name = Utils.pnToString(pn);
				id = sopInst.get('PatientID');
				da = sopInst.get('PatientBirthDate');
				birthDate = Utils.daToDateVector(da);
			else
				name = varargin{1};
				id = varargin{2};
				birthDate = varargin{3};
			end
			patient = ether.dicom.Patient(name, id, birthDate);
		end

		%-------------------------------------------------------------------------
		function series = createSeries(~, arg)
			if ~isa(arg, 'ether.dicom.SopInstance')
				% arg should be UID
				series = ether.dicom.Series(arg);
				return;
			end
			sopInst = arg;
			uid = sopInst.seriesUid;
			series = ether.dicom.Series(uid);
			series.number = sopInst.get('SeriesNumber');
			series.description = sopInst.get('SeriesDescription');
		end

		%-------------------------------------------------------------------------
		function sopInst = createSopInstance(~)
			sopInst = ether.dicom.SopInstance();
		end

		%-------------------------------------------------------------------------
		function study = createStudy(~, arg)
			import ether.dicom.*;
			if ~isa(arg, 'ether.dicom.SopInstance')
				study = ether.dicom.Study(arg);
				return;
			end
			sopInst = arg;
			uid = sopInst.studyUid;
			study = ether.dicom.Study(uid);
			study.date = Utils.daToDateVector(sopInst.get('StudyDate'));
			study.description = sopInst.get('StudyDescription');
			study.id = sopInst.get('StudyID');
		end

		%-------------------------------------------------------------------------
		function bool = isImageSOPClass(this, uid)
			if isempty(this.imageUidMap)
				this.imageUidMap = this.createImageUidMap;
			end
			bool = this.imageUidMap.isKey(uid);
		end

	end

	methods(Access=private)
		%-------------------------------------------------------------------------
		function this = Toolkit()
			this.imageUidMap = [];
		end

		%-------------------------------------------------------------------------
		function map = createImageUidMap(~)
			import ether.dicom.UID;
			map = containers.Map();
			map(UID.MRImageStorage) = [];
			map(UID.EnhancedMRImageStorage) = [];
			map(UID.CTImageStorage) = [];
		end

	end
end

