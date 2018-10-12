classdef Toolkit < handle
	%TOOLKIT Factory class for ether.dicom
	%   Allows static registration and retrieval of other Toolkit implementations

	%----------------------------------------------------------------------------
	properties(Constant)
		Default = 'Default';
	end

	%----------------------------------------------------------------------------
	properties(Constant,Access=private)
		toolkitMap = containers.Map(ether.dicom.Toolkit.Default, ...
			ether.dicom.Toolkit());
		logger = ether.log4m.Logger.getLogger('ether.dicom.Toolkit');
	end

	%----------------------------------------------------------------------------
	properties
		useJava = true;
	end

	%----------------------------------------------------------------------------
	properties(Access=private)
		imageUidMap;
		javaOk = true;
		javaTested = false;
		jToolkit = [];
	end

	%----------------------------------------------------------------------------
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

	%----------------------------------------------------------------------------
	methods
		%-------------------------------------------------------------------------
		function images = createImages(~, sopInst)
			import ether.dicom.*;
			if ~isa(sopInst, 'ether.dicom.SopInstance')
				throw(MException('Ether:DICOM:Toolkit', 'Not a valid SOP instance'));
			end
			nImages = sopInst.numberOfFrames;
			sopClassUid = sopInst.sopClassUid;
			switch sopClassUid
				case UID.CTImageStorage
					images = CTImage(sopInst, 1);

				case UID.MRImageStorage
					images = MRImage(sopInst, 1);

				case UID.EnhancedMRImageStorage
					images = EnhancedMRImage.empty(nImages, 0);
					for i=1:nImages
						images(i) = EnhancedMRImage(sopInst, i);
					end

				otherwise
					images = [];
			end
		end

		%-------------------------------------------------------------------------
		function root = createPatientRoot(~, jRoot)
			if isempty(jRoot)
				root = [];
				return;
			end
			if (isa(jRoot, 'icr.etherj.dicom.PatientRoot'))
				root = ether.dicom.PatientRoot(jRoot);
				return;
			end
			throw(MException('Ether:DICOM:Toolkit', ...
				['Illegal argument type: ',class(jRoot),' icr.etherj.dicom.PatientRoot required']));
		end

		%-------------------------------------------------------------------------
		function patient = createPatient(~, jPatient)
			if isempty(jPatient)
				patient = [];
				return;
			end
			if (isa(jPatient, 'icr.etherj.dicom.Patient'))
				patient = ether.dicom.Patient(jPatient);
				return;
			end
			throw(MException('Ether:DICOM:Toolkit', ...
				['Illegal argument type: ',class(jPatient),' icr.etherj.dicom.Patient required']));
		end

		%-------------------------------------------------------------------------
		function rtStruct = createRtStruct(this, arg)
			jRtStruct = [];
			if (isa(arg, 'ether.dicom.SopInstance') || ...
				 isa(arg, 'icr.etherj.dicom.SopInstance'))
				jRtStruct = this.jToolkit.createRtStruct(arg.getDicomObject());
			else
				if (isa(arg, 'org.dcm4che2.data.DicomObject'))
					jRtStruct = this.jToolkit.createRtStruct(arg);
				end
			end
			if (isempty(jRtStruct))
				throw(MException('Ether:DICOM:Toolkit', 'Invalid argument supplied'));
			end
			rtStruct = ether.dicom.RtStruct(jRtStruct);
		end

		%-------------------------------------------------------------------------
		function series = createSeries(~, jSeries)
			if isempty(jSeries)
				series = [];
				return;
			end
			if isa(jSeries, 'icr.etherj.dicom.Series')
				series = ether.dicom.Series(jSeries);
				return;
			end
			throw(MException('Ether:DICOM:Toolkit', ...
				['Illegal argument type: ',class(jSeries),' icr.etherj.dicom.Series required']));
		end

		%-------------------------------------------------------------------------
		function sopInst = createSopInstance(~, filename, dcm)
			import ether.dicom.*;
			switch nargin
				case 2
					sopInst = JavaSopInstance(filename);
					return;

				case 3
					sopInst = JavaSopInstance(filename, dcm);
					return;

				otherwise
					throw(MException('Ether:DICOM:Toolkit', 'Filename required'));
			end
		end

		%-------------------------------------------------------------------------
		function study = createStudy(~, jStudy)
			if isempty(jStudy)
				study = [];
				return;
			end
			if isa(jStudy, 'icr.etherj.dicom.Study')
				study = ether.dicom.Study(jStudy);
				return;
			end
			throw(MException('Ether:DICOM:Toolkit', ...
				['Illegal argument type: ',class(jStudy),' icr.etherj.dicom.Study required']));
		end

		%-------------------------------------------------------------------------
		function bool = isImageSOPClass(this, uid)
			if isempty(this.imageUidMap)
				this.imageUidMap = this.createImageUidMap;
			end
			bool = this.imageUidMap.isKey(uid);
		end

	end

	%----------------------------------------------------------------------------
	methods(Access=private)
		%-------------------------------------------------------------------------
		function this = Toolkit()
			this.imageUidMap = [];
			this.jToolkit = icr.etherj.dicom.DicomToolkit.getToolkit();
		end

		%-------------------------------------------------------------------------
		function map = createImageUidMap(~)
			import ether.dicom.UID;
			map = containers.Map();
			map(UID.MRImageStorage) = [];
			map(UID.EnhancedMRImageStorage) = [];
			map(UID.CTImageStorage) = [];
			map(UID.EnhancedCTImageStorage) = [];
		end

	end
end

