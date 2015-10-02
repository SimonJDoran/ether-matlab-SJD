classdef Patient < handle
	%PATIENT DICOM Patient
	%   A Patient has name, id and birth date, contains zero or more Studies

	properties
		birthDate;
		id;
		name;
	end

	properties(Access=private)
		studyMap;
	end

	methods
		%-------------------------------------------------------------------------
		function this = Patient(name, id, birthDate)
			this.name = name;
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

