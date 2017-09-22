classdef Study < handle
	%STUDY DICOM Study
	%   A Study has a UID and contains zero or more Series. Each Study belongs to
	%   a Patient.

	%----------------------------------------------------------------------------
	properties
	end

	%----------------------------------------------------------------------------
	properties(SetAccess=private)
		accession;
		date;
		description;
		id;
		instanceUid;
		Series;
	end

	%----------------------------------------------------------------------------
	properties(Access=private)
		jStudy;
		seriesMap;
	end

	methods
		%-------------------------------------------------------------------------
		function this = Study(jStudy)
			this.jStudy = jStudy;
			this.instanceUid = char(jStudy.getUid());
			this.date = ether.dicom.Utils.daToDateVector(char(jStudy.getDate()));
			desc = char(jStudy.getDescription());
			if isempty(desc)
				desc = '';
			end
			this.description = desc;
			id = char(jStudy.getId());
			if isempty(id)
				id = '';
			end
			this.id = id;
			accession = char(jStudy.getAccession());
			if isempty(accession)
				accession = '';
			end
			this.accession = accession;
			this.seriesMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
			% Process the children
			toolkit = ether.dicom.Toolkit.getToolkit();
			jSeriesList = jStudy.getSeriesList();
			nSeries = jSeriesList.size();
			for i=0:nSeries-1
				series = toolkit.createSeries(jSeriesList.get(i));
				this.addSeries(series);
			end
		end

		%-------------------------------------------------------------------------
		function series = get.Series(this)
			series = this.getAllSeries();
		end

		%-------------------------------------------------------------------------
		function array = getAllSeries(this)
			values = this.seriesMap.values;
			series = [values{:}];
			sortValues = arrayfun(@(x) x.number, series);
			[~,sortIdx] = sort(sortValues);
			array = series(sortIdx);
		end

		%-------------------------------------------------------------------------
		function series = getSeries(this, uid)
			series = [];
			if this.seriesMap.isKey(uid)
				series = this.seriesMap(uid);
			end
		end

		%-------------------------------------------------------------------------
		function list = getSeriesList(this)
			list = ether.collect.CellArrayList('ether.dicom.Series');
			list.add(this.getAllSeries());
		end

		%-------------------------------------------------------------------------
		function bool = hasSeries(this, uid)
			bool = this.seriesMap.isKey(uid);
		end

		%-------------------------------------------------------------------------
		function series = removeSeries(this, uid)
			series = this.getSeries(uid);
			if (isempty(series))
				return;
			end
			this.seriesMap.remove(uid);
		end
	end

	%----------------------------------------------------------------------------
	methods(Access=private)
		%-------------------------------------------------------------------------
		function bool = addSeries(this, series)
			if (~strcmp(series.studyUid, this.instanceUid))
				throw(MException('Ether:DICOM:Study', ...
					['Series'' Study UID doesn''t match: ',series.studyUid']));
			end
			uid = series.instanceUid;
			bool = ~this.seriesMap.isKey(uid);
			if bool
				this.seriesMap(uid) = series;
			end
		end
	end

end

