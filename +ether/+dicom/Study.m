classdef Study < handle
	%STUDY DICOM Study
	%   A Study has a UID and contains zero or more Series. Each Study belongs to
	%   a Patient.

	%----------------------------------------------------------------------------
	properties
		accession;
		date;
		description;
		id;
		instanceUid;
	end

	%----------------------------------------------------------------------------
	properties(SetAccess=private)
		Series;
	end

	%----------------------------------------------------------------------------
	properties(Access=private)
		seriesMap;
	end

	methods
		%-------------------------------------------------------------------------
		function this = Study(uid)
			this.instanceUid = uid;
			this.seriesMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
			this.date = [0,0,0,0,0,0];
			this.description = '';
			this.id = '';
			this.accession = '';
		end

		%-------------------------------------------------------------------------
		function bool = addSeries(this, series)
			uid = series.instanceUid;
			bool = ~this.seriesMap.isKey(uid);
			if bool
				this.seriesMap(uid) = series;
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
			this.seriesMap.remove(uid);
		end
	end

end

