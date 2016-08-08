classdef Patient < handle
	%PATIENT DICOM Patient
	%   A Patient has name, id and birth date, contains zero or more Studies

	%----------------------------------------------------------------------------
	properties
		birthDate;
		id;
		name;
		otherId = '';
	end

	%----------------------------------------------------------------------------
	properties(SetAccess=private)
		Study;
	end

	%----------------------------------------------------------------------------
	properties(Access=private)
		jPatient;
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
		function this = Patient(jPatient)
			this.jPatient = jPatient;
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
		function value = get.birthDate(this)
			value = char(this.jPatient.getBirthDate());
		end

		%-------------------------------------------------------------------------
		function value = get.id(this)
			value = char(this.jPatient.getId());
		end

		%-------------------------------------------------------------------------
		function value = get.name(this)
			value = char(this.jPatient.getName());
		end

		%-------------------------------------------------------------------------
		function value = get.otherId(this)
			value = char(this.jPatient.getOtherId());
		end

		%-------------------------------------------------------------------------
		function study = get.Study(this)
			study = this.getAllStudies();
		end

		%-------------------------------------------------------------------------
		function array = getAllStudies(this)
			if (this.studyMap.length ~= this.jPatient.getStudyCount())
				jList = this.jPatient.getStudyList();
				nStudies = jList.size();
				for i=0:nStudies-1
					this.addStudy(ether.dicom.Study(jList.get(i)));
				end
			end
			values = this.studyMap.values;
			studies = [values{:}];
			sortValues = arrayfun(@(x) datenum(x.date), studies);
			[~,sortIdx] = sort(sortValues);
			array = studies(sortIdx);
		end

		%-------------------------------------------------------------------------
		function key = getKey(this)
			key = sprintf('%s_%s_%s', strrep(this.name, ' ', '_'), ...
				this.birthDate, this.id);
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
			list.add(this.getAllStudies());
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

