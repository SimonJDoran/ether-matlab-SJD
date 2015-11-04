classdef DicomReceiver < ether.dicom.PathScanListener
	%DICOMRECEIVER Builds PatientRoot from SopInstances
	%   Additional PatientRoots created if duplicate SopInstances found 

	%----------------------------------------------------------------------------
	properties(Constant,Access=private)
		logger = ether.log4m.Logger.getLogger('ether.dicom.io.DicomReceiver');
	end

	%----------------------------------------------------------------------------
	properties(Access=private)
		patientMap;
		sopInstMap;
		duplicates;
	end

	%----------------------------------------------------------------------------
	methods
		%-------------------------------------------------------------------------
		function this = DicomReceiver()
			this.patientMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
			this.duplicates = {};
		end

		%-------------------------------------------------------------------------
		function clear(this)
			this.patientMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
			this.duplicates = {};
		end

		%-------------------------------------------------------------------------
		function [root,duplicates] = getPatientRoot(this)
			root = ether.dicom.Toolkit.getToolkit.createPatientRoot;
			values = this.patientMap.values;
			root.addPatient([values{:}]);
			duplicates = {};
		end

		%-------------------------------------------------------------------------
		%	Callback method.
		function scanFinish(~, ~, ~)
		end

		%-------------------------------------------------------------------------
		%	Callback method.
		function scanStart(~, ~, ~)
		end

		%-------------------------------------------------------------------------
		%	Callback method.
		function sopInstanceFound(this, ~, data)
			try
				this.processSopInst(data.sopInstance);
			catch ex
				this.logger.warn(ether.formatException(ex));
			end
		end

	end

	%----------------------------------------------------------------------------
	methods(Access=private)
		%-------------------------------------------------------------------------
		function dupe = findDuplicate(this, sopInst)
			if isempty(this.duplicates)
				dupe = this.newDuplicate();
				return;
			end
			uid = sopInst.instanceUid;
			% Search for a duplicate that doesn't contain the SOP instance already
			for ii=1:numel(this.duplicates)
				if ~(this.duplicates{ii}.sopInstMap.isKey(uid))
					dupe =  this.duplicates{ii};
					return;
				end
			end
			% Create a new duplicate as all existing ones have been checked
			dupe = this.newDuplicate();
		end

		%-------------------------------------------------------------------------
		function patient = findPatient(this, map, sopInst, toolkit)
			key = ether.dicom.Patient.makeKey(sopInst);
			if ~map.isKey(key)
				patient = toolkit.createPatient(sopInst);
				this.patientMap(key) = patient;
				this.logger.info(@() sprintf(...
					'New patient. Name: %s, ID: %s, DOB: %s', ...
					patient.name, patient.id, datestr(patient.birthDate)));
			end
			patient = this.patientMap(key);
		end

		%-------------------------------------------------------------------------
		function series = findSeries(this, study, sopInst, toolkit)
			if ~study.hasSeries(sopInst.seriesUid)
				series = toolkit.createSeries(sopInst);
				study.addSeries(series);
				this.logger.info(@() sprintf(...
					'New series. Number: %d, Description: %s', ...
					series.number, series.description));
			end
			series = study.getSeries(sopInst.seriesUid);
		end

		%-------------------------------------------------------------------------
		function study = findStudy(this, patient, sopInst, toolkit)
			if ~patient.hasStudy(sopInst.studyUid)
				study = toolkit.createStudy(sopInst);
				patient.addStudy(study);
				this.logger.info(@() sprintf(...
					'New study. ID: %s, Date: %s, Description: %s', ...
					study.id, datestr(study.date), study.description));
			end
			study = patient.getStudy(sopInst.studyUid);
		end

		%-------------------------------------------------------------------------
		function dupe = newDuplicate(~)
			patMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
			siMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
			dupe = struct('patientMap', patMap, 'sopInstMap', siMap);
		end

		%-------------------------------------------------------------------------
		function processDuplicate(this, sopInst, toolkit)
			dupe = this.findDuplicate(sopInst);
			patient = this.findPatient(dupe.patientMap, sopInst, toolkit);
			study = this.findStudy(patient, sopInst, toolkit);
			series = this.findSeries(study, sopInst, toolkit);
			series.addSopInstance(sopInst, toolkit);
			dupe.sopInstMap(sopInst.instanceUid) = sopInst;
		end

		%-------------------------------------------------------------------------
		function processSopInst(this, sopInst)
			toolkit = ether.dicom.Toolkit.getToolkit();
			patient = this.findPatient(this.patientMap, sopInst, toolkit);
			study = this.findStudy(patient, sopInst, toolkit);
			series = this.findSeries(study, sopInst, toolkit);
			if series.hasSopInstance(sopInst.instanceUid)
				this.processDuplicate(sopInst, toolkit);
				return;
			end
			series.addSopInstance(sopInst, toolkit);
		end
	end

end

