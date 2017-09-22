classdef PatientRoot < handle
	%PATIENTROOT Container for DICOM Patients
	%   Detailed explanation goes here
	
	%----------------------------------------------------------------------------
	properties(SetAccess=private)
		Patients;
	end

	properties(Access=private)
		jRoot;
		patientMap;
	end
	
	methods
		%-------------------------------------------------------------------------
		function this = PatientRoot(jRoot)
			this.jRoot = jRoot;
			this.patientMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
			% Process the children
			toolkit = ether.dicom.Toolkit.getToolkit();
			jList = this.jRoot.getPatientList();
			nPatients = jList.size();
			for i=0:nPatients-1
				patient = toolkit.createPatient(jList.get(i));
				this.patientMap(patient.getKey()) = patient;
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
		function patient = get.Patients(this)
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
	end
	
end

