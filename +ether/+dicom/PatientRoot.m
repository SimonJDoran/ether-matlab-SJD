classdef PatientRoot < handle
	%PATIENTROOT Container for DICOM Patients
	%   Detailed explanation goes here
	
	properties(Constant)
		logger = ether.log4m.Logger.getLogger('ether.dicom.PatientRoot');
	end

	%----------------------------------------------------------------------------
	properties(SetAccess=private)
		Patient;
	end

	properties(Access=private)
		patientMap;
	end
	
	methods
		%-------------------------------------------------------------------------
		function this = PatientRoot()
			this.patientMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
		end

		%-------------------------------------------------------------------------
		function addPatient(this, patient)
			nPatients = numel(patient);
			for ii=1:nPatients
				key = patient(ii).getKey();
				if ~this.patientMap.isKey(key)
					this.patientMap(key) = patient(ii);
				else
					this.logger.warn('TODO: Implement merging of patients');
				end
			end
		end

		%-------------------------------------------------------------------------
		function array = getAllPatients(this)
			values = this.patientMap.values;
			patients = [values{:}];
			sortValues = arrayfun(@(x) x.name, patients, 'UniformOutput', false);
			[~,sortIdx] = sort(sortValues);
			array = patients(sortIdx);
		end

		%-------------------------------------------------------------------------
		function patient = get.Patient(this)
			patient = this.getAllPatients();
		end

		%-------------------------------------------------------------------------
		function patient = getPatient(this, key)
			patient = [];
			keyIdx = this.patientMap.isKey(key);
			if any(keyIdx)
				patient = this.patientMap(key(keyIdx));
			end
		end

		%-------------------------------------------------------------------------
		function ids = getPatientIds(this)
			ids = this.patientMap.keys();
		end

		%-------------------------------------------------------------------------
		function list = getPatientList(this, orderBy)
			list = ether.collect.CellArrayList('ether.dicom.Patient');
			list.add(this.getAllPatients());
		end

		%-------------------------------------------------------------------------
		function hasKey = hasPatient(this, key)
			hasKey = this.patientMap.isKey(key);
		end

		%-------------------------------------------------------------------------
		function patient = removePatient(this, key)
			patient = [];
			keyIdx = this.patientMap.isKey(key);
			if any(keyIdx)
				patient = this.patientMap(key(keyIdx));
				this.patientMap.remove(key(keyIdx));
			end
		end

	end
	
end

