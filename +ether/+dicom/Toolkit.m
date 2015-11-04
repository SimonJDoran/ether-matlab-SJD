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
			if nImages > 0
				if nImages == 1
					images = MRImage(sopInst, 1);
				else
					images = EnhancedMRImage.empty(nImages, 0);
					% TODO: Create images based on SOP Class UID of sopInst
					for ii=1:nImages
						images(ii) = EnhancedMRImage(sopInst, ii);
					end
				end
			else
				images = [];
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
				name = sopInst.getValue(Tag.PatientName);
				id = sopInst.getValue(Tag.PatientID);
				if isempty(id)
					id = '';
				end
				da = sopInst.getValue(Tag.PatientBirthDate);
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
			import ether.dicom.*;
			if ~isa(arg, 'ether.dicom.SopInstance')
				% arg should be UID
				series = ether.dicom.Series(arg);
				return;
			end
			sopInst = arg;
			uid = sopInst.seriesUid;
			series = ether.dicom.Series(uid);
			series.number = sopInst.getValue(Tag.SeriesNumber);
			desc = sopInst.getValue(Tag.SeriesDescription);
			if isempty(desc)
				desc = '';
			end
			series.description = desc;
			series.modality = sopInst.getValue(Tag.Modality);
			series.time = Utils.tmToSeconds(sopInst.getValue(Tag.SeriesTime));
		end

		%-------------------------------------------------------------------------
		function sopInst = createSopInstance(this)
			if ~this.javaTested
				this.testJava();
			end
			if this.useJava && this.javaOk
				sopInst = ether.dicom.JavaSopInstance();
			else
				sopInst = ether.dicom.NativeSopInstance();
			end
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
			study.date = Utils.daToDateVector(sopInst.getValue(Tag.StudyDate));
			desc = sopInst.getValue(Tag.StudyDescription);
			if isempty(desc)
				desc = '';
			end
			study.description = desc;
			id = sopInst.getValue(Tag.StudyID);
			if isempty(id)
				id = '';
			end
			study.id = id;
			accession = sopInst.getValue(Tag.AccessionNumber);
			if isempty(accession)
				accession = '';
			end
			study.accession = accession;
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
			this.useJava = true;
			this.javaOk = true;
			this.javaTested = false;
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

		%-------------------------------------------------------------------------
		function testJava(this)
			try
				testObject = javaObject('henson.DicomIoHandler');
				this.javaOk = isjava(testObject);
			catch ex
				this.javaOk = false;
				this.logger.warn(@() ...
					sprintf('Exception: %s', ether.formatException(ex)));
			end
			this.javaTested = true;
			if this.javaOk
				this.logger.info('Java components of ether.dicom available');
			else
				this.logger.info('Java components of ether.dicom NOT available');
			end
		end

	end
end

