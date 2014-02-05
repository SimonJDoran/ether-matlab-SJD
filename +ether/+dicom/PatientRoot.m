classdef PatientRoot < handle
	%ROOT Summary of this class goes here
	%   Detailed explanation goes here
	
	properties(Constant)
		logger = ether.log4m.Logger.getLogger('ether.dicom.PatientRoot');
	end

	properties(Access=private)
		patientMap;
	end
	
	methods
		function this = PatientRoot()
			this.patientMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
		end

		function addPatient(this, patient)
			nPatients = numel(patient);
			for ii=1:nPatients
				id = patient(ii).id;
				if ~this.patientMap.isKey(id)
					this.patientMap(id) = patient(ii);
				else
					this.logger.warn('TODO: Implement merging of patients');
				end
			end
		end

		function patient = getPatient(this, id)
			patient = [];
			idIdx = this.patientMap.isKey(id);
			if any(idIdx)
				patient = this.patientMap(id(idIdx));
			end
		end

		%-------------------------------------------------------------------------
		function list = getPatientList(this, orderBy)
			list = ether.collect.CellArrayList('ether.dicom.Patient');
			values = this.patientMap.values;
			patients = [values{:}];
			sortValues = arrayfun(@(x) x.name, patients, 'UniformOutput', false);
			[~,sortIdx] = sort(sortValues);
			patients = patients(sortIdx);
			list.add(patients);
		end

		function hasId = hasPatient(this, id)
			hasId = this.patientMap.isKey(id);
		end

		function patient = removePatient(this, id)
			patient = [];
			idIdx = this.patientMap.isKey(id);
			if any(idIdx)
				patient = this.patientMap(id(idIdx));
				this.patientMap.remove(id(idIdx));
			end
		end

	end
	
end

