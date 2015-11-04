classdef Patient < handle
	%PATIENT DICOM Patient
	%   A Patient has name, id and birth date, contains zero or more Studies

	%----------------------------------------------------------------------------
	properties(Constant)
		HFS = 'HFS';
		HFP = 'HFP';
		FFS = 'FFS';
		FFP = 'FFP';
	end

	%----------------------------------------------------------------------------
	properties
		birthDate;
		id;
		name;
		otherId = '';
	end

	%----------------------------------------------------------------------------
	properties(Access=private)
		studyMap;
	end

	%----------------------------------------------------------------------------
	methods(Static)
		%-------------------------------------------------------------------------
		function key = makeKey(sopInst)
			import ether.dicom.*;
			patName = Patient.fixName(sopInst.getValue(Tag.PatientName));
			da = sopInst.getValue(Tag.PatientBirthDate);
			patBirthDate = Utils.daToDateVector(da);
			patId = sopInst.getValue(Tag.PatientID);
			key = sprintf('%s_%s_%s', strrep(patName, ' ', '_'), ...
				ether.dicom.Utils.dateToDA(patBirthDate), patId);
		end
	end

	%----------------------------------------------------------------------------
	methods(Static,Access=private)
		%-------------------------------------------------------------------------
		function name = fixName(nameIn)
			name = [];
			if ischar(nameIn)
				name = nameIn;
				return;
			end
			if isstruct(nameIn)
				components = struct2cell(nameIn);
				name = strjoin(components, '^');
				return;
			end
		end
	end

	%----------------------------------------------------------------------------
	methods
		%-------------------------------------------------------------------------
		function this = Patient(name, id, birthDate)
			this.name = ether.dicom.Patient.fixName(name);
			this.id = id;
			this.birthDate = birthDate;
			this.studyMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
		end

		%-------------------------------------------------------------------------
		function bool = addStudy(this, study)
			uid = study.instanceUid;
			bool = ~this.studyMap.isKey(uid);
			if bool
				this.studyMap(uid) = study;
			end
		end

		%-------------------------------------------------------------------------
		function key = getKey(this)
			key = sprintf('%s_%s_%s', strrep(this.name, ' ', '_'), ...
				ether.dicom.Utils.dateToDA(this.birthDate), this.id);
		end

		%-------------------------------------------------------------------------
		function study = getStudy(this, uid)
			study = [];
			if this.studyMap.isKey(uid)
				study = this.studyMap(uid);
			end
		end

		%-------------------------------------------------------------------------
		function list = getStudyList(this, orderBy)
			list = ether.collect.CellArrayList('ether.dicom.Study');
			values = this.studyMap.values;
			studies = [values{:}];
			sortValues = arrayfun(@(x) datenum(x.date), studies);
			[~,sortIdx] = sort(sortValues);
			studies = studies(sortIdx);
			list.add(studies);
		end

		%-------------------------------------------------------------------------
		function bool = hasStudy(this, uid)
			bool = this.studyMap.isKey(uid);
		end

		%-------------------------------------------------------------------------
		function study = removeStudy(this, uid)
			study = this.getStudy(uid);
			this.studyMap.remove(uid);
		end

	end
	
end

