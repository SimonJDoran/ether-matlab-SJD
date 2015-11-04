classdef NativeDicomDatabase < ether.dicom.DicomDatabase & ...
	ether.db.SqliteDatabase & ether.dicom.PathScanListener
	%NATIVEDICOMDATABASE Summary of this class goes here
	%   Detailed explanation goes here

	%----------------------------------------------------------------------------
	properties(Constant,Access=private)
		logger = ether.log4m.Logger.getLogger('ether.dicom.db.NativeDicomDatabase');
		PATIENT = 'patient';
		PATIENT_DOB = 'patDob';
		PATIENT_ID = 'patId';
		PATIENT_KEY = 'patKey';
		PATIENT_NAME = 'patName';
		PATIENT_OTHERID = 'patOtherId';
		PATIENT_PK = 'pk';
		STUDY = 'study';
		STUDY_PK = 'pk';
		STUDY_PATIENTFK = 'patFk';
		STUDY_UID = 'uid';
		STUDY_ID = 'studyId';
		STUDY_DATE = 'studyDate';
		STUDY_DESC = 'desc';
		STUDY_ACCESSION = 'accession';
		SERIES = 'series';
		SERIES_PK = 'pk';
		SERIES_STUDYFK = 'stuFk';
		SERIES_UID = 'uid';
		SERIES_NUMBER = 'number';
		SERIES_TIME = 'time';
		SERIES_DESC = 'desc';
		SERIES_MODALITY = 'modality';
		INSTANCE = 'instance';
		INSTANCE_PK = 'pk';
		INSTANCE_SERIESFK = 'serFk';
		INSTANCE_UID = 'uid';
		INSTANCE_PATH = 'path';
		INSTANCE_FRAMES = 'frames';
		INSTANCE_SOPCLASSUID = 'sopClassUid';
		INSTANCE_MODALITY = 'modality';
		INSTANCE_NUMBER = 'number';
	end

	%----------------------------------------------------------------------------
	properties(Access=private)
		bufferMax = 256;
		insertInstStmt = [];
		isScanning = false;
		selectInstPkStmt = [];
		selectPatPkStmt = [];
		selectSeriesPkStmt = [];
		selectStudyPkStmt = [];
		selectInstStmt = [];
		sopInstBuffer = [];
		toolkit = [];
	end

	%----------------------------------------------------------------------------
	methods
		%-------------------------------------------------------------------------
		function this = NativeDicomDatabase(filename)
			this@ether.db.SqliteDatabase(filename);
			try
				this.initSql();
				this.checkTables();
				this.prepareStatements();
			catch ex
				close(this.connection);
				% Rethrow Matlab exceptions
				if isa(ex, 'MException')
					rethrow(ex);
				end
				throw(MException('Ether:DB:Sqlite', ex.getMessage()));
			end
			this.toolkit = ether.dicom.Toolkit.getToolkit();
			this.sopInstBuffer = ether.collect.CellArrayList(...
				'ether.dicom.SopInstance');
		end

		%-------------------------------------------------------------------------
		function delete(this)
			this.closeStatement(this.insertInstStmt);
			this.closeStatement(this.selectInstPkStmt);
			this.closeStatement(this.selectInstStmt);
		end

		%-------------------------------------------------------------------------
		function importDirectory(this, path, recurse)
			import ether.dicom.*;
			if ~ischar(path)
				throw(MException('Ether:DICOM:Database', ...
					'Path must be a character string'));
			end
			if (nargin == 2) || ~islogical(recurse)
				recurse = true;
			end
			scanner = PathScanner();
			scanner.addPathScanListener(this);
			scanner.scan(path, recurse);
		end

		%-------------------------------------------------------------------------
		function sopInst = searchInstance(this, uid)
			if ~(ischar(uid))
				throw(MException('Ether:DICOM:Database', 'Invalid UID'));
			end
			[sopInst,seriesFk] = this.getInstance(uid);
			if isempty(sopInst)
				return;
			end
			stmt = this.createStatement();
			sql = ['SELECT ',this.SERIES_UID,',',this.SERIES_STUDYFK,' FROM ',...
				this.SERIES,' WHERE ',this.SERIES_PK,'="',sprintf('%i', seriesFk),'"'];
			rs = stmt.executeQuery(sql);
			if rs.isAfterLast()
				rs.close();
				stmt.close();
				throw(MException('Ether:DICOM:Database', 'Missing series PK'));
			end
			sopInst.seriesUid = char(rs.getString(1));
			studyFk = rs.getInt(2);
			rs.close();
			sql = ['SELECT ',this.STUDY_UID,' FROM ',this.STUDY,' WHERE ', ...
				this.STUDY_PK,'="',sprintf('%i', studyFk),'"'];
			rs = stmt.executeQuery(sql);
			if rs.isAfterLast()
				rs.close();
				stmt.close();
				throw(MException('Ether:DICOM:Database', 'Missing study PK'));
			end
			sopInst.studyUid = char(rs.getString(1));
			rs.close();
		end

		%-------------------------------------------------------------------------
		function setImportQueueLength(this, length)
			if isnumeric(length) && (length >= 1)
				this.bufferMax = int32(length);
			end
		end

		%-------------------------------------------------------------------------
		%	Callback method.
		function sopInstanceFound(this, ~, data)
			try
				this.storeInstance(data.sopInstance);
			catch ex
				this.logger.warn(ether.formatException(ex));
			end
		end

		%-------------------------------------------------------------------------
		%	Callback method.
		function scanStart(this, ~, data)
			this.isScanning = true;
			this.sopInstBuffer.clear;
		end

		%-------------------------------------------------------------------------
		%	Callback method.
		function scanFinish(this, ~, data)
			this.processBuffer;
			this.isScanning = false;
		end

		%-------------------------------------------------------------------------
		function storeInstance(this, sopInst)
			this.sopInstBuffer.add(sopInst);
			if ~this.isScanning || (this.sopInstBuffer.size() >= this.bufferMax)
				this.processBuffer;
			end
		end

		%-------------------------------------------------------------------------
		function storePatient(this, patient)
			try
				stmt = this.createStatement();
				stmt.executeUpdate('BEGIN TRANSACTION');
				patPk = this.getPatientPk(patient.getKey());
				if patPk == 0
					patPk = this.insertPatient(patient);
				end
				studyList = patient.getStudyList();
				for i=1:studyList.size();
					study = studyList.get(i);
					studyPk = this.getStudyPk(study.instanceUid);
					if studyPk == 0
						studyPk = this.insertStudy(study, patPk);
					end
					seriesList = study.getSeriesList();
					for j=1:seriesList.size();
						series = seriesList.get(j);
						seriesPk = this.getSeriesPk(series.instanceUid);
						if seriesPk == 0
							seriesPk = this.insertSeries(series, studyPk);
						end
						sopInstList = series.getSopInstanceList();
						for k=1:sopInstList.size();
							sopInst = sopInstList.get(k);
							sopInstPk = this.getInstancePk(sopInst.instanceUid);
							if sopInstPk == 0
								this.insertInstance(sopInst, seriesPk);
							end
						end
					end
				end
				stmt.executeUpdate('COMMIT TRANSACTION');
				stmt.close();
			catch ex
				this.logger.error(ether.formatException(ex));
				try
					this.logger.debug('Rolling back transaction');
					stmt.executeUpdate('ROLLBACK TRANSACTION');
					this.closeStatement(stmt);
					this.nInserts = 0;
				catch exRoll
					this.logger.error(ether.formatException(exRoll));
				end
			end
		end

	end

	%----------------------------------------------------------------------------
	methods(Access=private)
		%-------------------------------------------------------------------------
		function instPk = getInstancePk(this, uid)
			import ether.dicom.*;
			instPk = 0;
			this.selectInstPkStmt.setString(1, uid);
			rs = this.selectInstPkStmt.executeQuery();
			if ~rs.isAfterLast()
				instPk = rs.getInt(1);
			end
			rs.close();
		end

		%-------------------------------------------------------------------------
		function [sopInst,seriesFk] = getInstance(this, uid)
			sopInst = [];
			seriesFk = [];
			stmt = this.createStatement();
			instSql = ['SELECT ',this.INSTANCE_PATH,',',this.INSTANCE_FRAMES, ...
				',',this.INSTANCE_MODALITY,',', this.INSTANCE_SOPCLASSUID,',', ...
				this.INSTANCE_NUMBER,',',this.INSTANCE_SERIESFK, ...
				' FROM ',this.INSTANCE, ...
				' WHERE ',this.INSTANCE_UID,'="',uid,'"'];
			rs = stmt.executeQuery(instSql);
			if rs.isAfterLast()
				rs.close();
				stmt.close();
				return;
			end
			sopInst = this.toolkit.createSopInstance();
			sopInst.instanceUid = uid;
			sopInst.filename = char(rs.getString(1));
			sopInst.numberOfFrames = rs.getInt(2);
			sopInst.modality = char(rs.getString(3));
			sopInst.sopClassUid = char(rs.getString(4));
			sopInst.instanceNumber = rs.getInt(5);
			seriesFk = rs.getInt(6);
		end

		%-------------------------------------------------------------------------
		function patPk = getPatientPk(this, patKey)
			import ether.dicom.*;
			patPk = 0;
			this.selectPatPkStmt.setString(1, patKey);
			rs = this.selectPatPkStmt.executeQuery();
			if ~rs.isAfterLast()
				patPk = rs.getInt(1);
			end
			rs.close();
		end

		%-------------------------------------------------------------------------
		function seriesPk = getSeriesPk(this, uid)
			import ether.dicom.*;
			seriesPk = 0;
			this.selectSeriesPkStmt.setString(1, uid);
			rs = this.selectSeriesPkStmt.executeQuery();
			if ~rs.isAfterLast()
				seriesPk = rs.getInt(1);
			end
			rs.close();
		end

		%-------------------------------------------------------------------------
		function studyPk = getStudyPk(this, uid)
			studyPk = 0;
			this.selectStudyPkStmt.setString(1, uid);
			rs = this.selectStudyPkStmt.executeQuery();
			if ~rs.isAfterLast()
				studyPk = rs.getInt(1);
			end
			rs.close();
		end

		%-------------------------------------------------------------------------
		function initSql(this)
			import ether.String;
			% Tables
			this.tableNameList.add(String(this.PATIENT));
			this.tableNameList.add(String(this.STUDY));
			this.tableNameList.add(String(this.SERIES));
			this.tableNameList.add(String(this.INSTANCE));

			% Table SQL
			% Patient
			patientSql = ['CREATE TABLE "',this.PATIENT,'" (', ...
				'"',this.PATIENT_PK,'" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,', ...
				'"',this.PATIENT_KEY,'" TEXT UNIQUE NOT NULL,', ...
				'"',this.PATIENT_NAME,'" TEXT NOT NULL,', ...
				'"',this.PATIENT_ID,'" TEXT NOT NULL,', ...
				'"',this.PATIENT_DOB,'" INTEGER NOT NULL,', ...
				'"',this.PATIENT_OTHERID,'" TEXT NOT NULL', ...
				')'];
			this.addTableSql(this.PATIENT, patientSql);
			% Study
			studySql = ['CREATE TABLE "',this.STUDY,'" (', ...
				'"',this.STUDY_PK,'" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,', ...
				'"',this.STUDY_PATIENTFK,'" INTEGER NOT NULL,', ...
				'"',this.STUDY_UID,'" TEXT UNIQUE NOT NULL,', ...
				'"',this.STUDY_ID,'" TEXT NOT NULL,', ...
				'"',this.STUDY_DATE,'" INTEGER NOT NULL,', ...
				'"',this.STUDY_DESC,'" TEXT NOT NULL,', ...
				'"',this.STUDY_ACCESSION,'" TEXT NOT NULL,', ...
				'FOREIGN KEY ("',this.STUDY_PATIENTFK,'") REFERENCES ', ...
					this.PATIENT,'("',this.PATIENT_PK,'")', ...
				')'];
			this.addTableSql(this.STUDY, studySql);
			% Series
			seriesSql = ['CREATE TABLE "',this.SERIES,'" (', ...
				'"',this.SERIES_PK,'" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,', ...
				'"',this.SERIES_STUDYFK,'" INTEGER NOT NULL,', ...
				'"',this.SERIES_UID,'" TEXT UNIQUE NOT NULL,', ...
				'"',this.SERIES_DESC,'" TEXT NOT NULL,', ...
				'"',this.SERIES_NUMBER,'" INTEGER NOT NULL,', ...
				'"',this.SERIES_MODALITY,'" TEXT NOT NULL,', ...
				'"',this.SERIES_TIME,'" REAL NOT NULL,', ...
				'FOREIGN KEY ("',this.SERIES_STUDYFK,'") REFERENCES ', ...
					this.STUDY,'("',this.STUDY_PK,'")', ...
				')'];
			this.addTableSql(this.SERIES, seriesSql);
			% Instance
			instanceSql = ['CREATE TABLE "',this.INSTANCE,'" (', ...
				'"',this.INSTANCE_PK,'" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,', ...
				'"',this.INSTANCE_SERIESFK,'" INTEGER NOT NULL,', ...
				'"',this.INSTANCE_UID,'" TEXT UNIQUE NOT NULL,', ...
				'"',this.INSTANCE_PATH,'" TEXT NOT NULL,', ...
				'"',this.INSTANCE_FRAMES,'" INTEGER NOT NULL,', ...
				'"',this.INSTANCE_MODALITY,'" TEXT NOT NULL,', ...
				'"',this.INSTANCE_SOPCLASSUID,'" TEXT NOT NULL,', ...
				'"',this.INSTANCE_NUMBER,'" INTEGER NOT NULL,', ...
				'FOREIGN KEY ("',this.INSTANCE_SERIESFK,'") REFERENCES ', ...
					this.SERIES,'("',this.SERIES_PK,'")', ...
				')'];
			this.addTableSql(this.INSTANCE, instanceSql);

			% Index SQL
			% Patient
			this.addIndexSql(this.PATIENT, this.PATIENT_NAME);
			this.addIndexSql(this.PATIENT, this.PATIENT_ID);
			this.addIndexSql(this.PATIENT, this.PATIENT_DOB);
			this.addIndexSql(this.PATIENT, this.PATIENT_OTHERID);
			% Study
			this.addIndexSql(this.STUDY, this.STUDY_PATIENTFK);
			this.addIndexSql(this.STUDY, this.STUDY_ID);
			this.addIndexSql(this.STUDY, this.STUDY_DATE);
			% Series
			this.addIndexSql(this.SERIES, this.SERIES_STUDYFK);
			this.addIndexSql(this.SERIES, this.SERIES_MODALITY);
			% Instance
			this.addIndexSql(this.INSTANCE, this.INSTANCE_SERIESFK);
		end

		%-------------------------------------------------------------------------
		function sopInstPk = insertInstance(this, sopInst, seriesFk)
			uid = sopInst.instanceUid;
			stmt = this.insertInstStmt;
			stmt.setInt(1, seriesFk);
			stmt.setString(2, uid);
			stmt.setString(3, sopInst.filename);
			stmt.setInt(4, sopInst.numberOfFrames);
			stmt.setString(5, sopInst.modality);
			stmt.setString(6, sopInst.sopClassUid);
			stmt.setInt(7, sopInst.instanceNumber);
			stmt.executeUpdate();
			rs = stmt.getGeneratedKeys();
			sopInstPk = rs.getInt(1);
			rs.close();
			this.logger.trace(@() sprintf('SOP instance UID %s inserted with PK %i', ...
				uid, sopInstPk));
		end

		%-------------------------------------------------------------------------
		function patPk = insertPatient(this, patient)
			import ether.dicom.*;
			patKey = patient.getKey();
			sql = ['INSERT INTO ',this.PATIENT,'(', ...
				this.PATIENT_KEY,',', ...
				this.PATIENT_NAME,',', ...
				this.PATIENT_ID,',', ...
				this.PATIENT_DOB,',', ...
				this.PATIENT_OTHERID,') ', ...
				'VALUES (?,?,?,?,?)'];
			stmt = this.prepareStatement(sql);
			stmt.setString(1, patKey);
			stmt.setString(2, patient.name);
			stmt.setString(3, patient.id);
			stmt.setInt(4, Utils.dateToInt(patient.birthDate));
			stmt.setString(5, patient.otherId);
			stmt.execute();
			rs = stmt.getGeneratedKeys();
			patPk = rs.getInt(1);
			rs.close();
			stmt.close();
			this.logger.debug(@() sprintf('Patient key %s inserted with PK %i', ...
				patKey, patPk));
		end

		%-------------------------------------------------------------------------
		function seriesPk = insertSeries(this, series, studyFk)
			uid = series.instanceUid;
			sql = ['INSERT INTO ',this.SERIES,'(', ...
				this.SERIES_STUDYFK,',', ...
				this.SERIES_UID,',', ...
				this.SERIES_DESC,',', ...
				this.SERIES_NUMBER,',', ...
				this.SERIES_MODALITY,',', ...
				this.SERIES_TIME,') ', ...
				'VALUES (?,?,?,?,?,?)'];
			stmt = this.prepareStatement(sql);
			stmt.setInt(1, studyFk);
			stmt.setString(2, uid);
			stmt.setString(3, series.description);
			stmt.setInt(4, series.number);
			stmt.setString(5, series.modality);
			stmt.setDouble(6, series.time);
			stmt.execute();
			rs = stmt.getGeneratedKeys();
			seriesPk = rs.getInt(1);
			rs.close();
			stmt.close();
			this.logger.trace(@() sprintf('Series UID %s inserted with PK %i', ...
				uid, seriesPk));
		end

		%-------------------------------------------------------------------------
		function studyPk = insertStudy(this, study, patFk)
			import ether.dicom.*;
			uid = study.instanceUid;
			sql = ['INSERT INTO ',this.STUDY,'(', ...
				this.STUDY_PATIENTFK,',', ...
				this.STUDY_UID,',', ...
				this.STUDY_ID,',', ...
				this.STUDY_DATE,',', ...
				this.STUDY_DESC,',', ...
				this.STUDY_ACCESSION,') ', ...
				'VALUES (?,?,?,?,?,?)'];
			stmt = this.prepareStatement(sql);
			stmt.setInt(1, patFk);
			stmt.setString(2, uid);
			stmt.setString(3, study.id);
			stmt.setInt(4, Utils.dateToInt(study.date));
			stmt.setString(5, study.description);
			stmt.setString(6, study.accession);
			stmt.execute();
			rs = stmt.getGeneratedKeys();
			studyPk = rs.getInt(1);
			rs.close();
			stmt.close();
			this.logger.debug(@() sprintf('Study UID %s inserted with PK %i', ...
				uid, studyPk));
		end

		%-------------------------------------------------------------------------
		function prepareStatements(this)
			sql = ['INSERT INTO ',this.INSTANCE,'(', ...
				this.INSTANCE_SERIESFK,',',this.INSTANCE_UID,',', ...
				this.INSTANCE_PATH,',',this.INSTANCE_FRAMES,',', ...
				this.INSTANCE_MODALITY,',',this.INSTANCE_SOPCLASSUID,',', ...
				this.INSTANCE_NUMBER,') ', ...
				'VALUES (?,?,?,?,?,?,?)'];
			this.insertInstStmt = this.prepareStatement(sql);
			sql = ['SELECT ',this.INSTANCE_PK,' FROM ', ...
				this.INSTANCE,' WHERE ', ...
				this.INSTANCE_UID,'=(?)'];
			this.selectInstPkStmt = this.prepareStatement(sql);
			sql = ['SELECT ',this.INSTANCE_UID,',',this.INSTANCE_PATH,',', ...
				this.INSTANCE_FRAMES,',',this.INSTANCE_MODALITY,',', ...
				this.INSTANCE_SOPCLASSUID,',',this.INSTANCE_NUMBER, ...
				' FROM ',this.INSTANCE, ...
				' WHERE ',this.INSTANCE_SERIESFK,'=(?)'];
			this.selectInstStmt = this.prepareStatement(sql);
			sql = ['SELECT ',this.PATIENT_PK,' FROM ', this.PATIENT,' WHERE ', ...
				this.PATIENT_KEY,'=(?)'];
			this.selectPatPkStmt = this.prepareStatement(sql);
			sql = ['SELECT ',this.STUDY_PK,' FROM ', this.STUDY,' WHERE ', ...
				this.STUDY_UID,'=(?)'];
			this.selectStudyPkStmt = this.prepareStatement(sql);
			sql = ['SELECT ',this.SERIES_PK,' FROM ', this.SERIES,' WHERE ', ...
				this.SERIES_UID,'=(?)'];
			this.selectSeriesPkStmt = this.prepareStatement(sql);
		end

		%-------------------------------------------------------------------------
		function processBuffer(this)
			import ether.dicom.*;
			try
				stmt = this.createStatement();
				stmt.executeUpdate('BEGIN TRANSACTION');
				for i=1:this.sopInstBuffer.size()
					sopInst = this.sopInstBuffer.get(i);
					sopInstPk = this.getInstancePk(sopInst.instanceUid);
					if sopInstPk ~= 0
						continue;
					end
					patPk = this.getPatientPk(Patient.makeKey(sopInst));
					if patPk == 0
						patient = this.toolkit.createPatient(sopInst);
						patPk = this.insertPatient(patient);
					end
					studyPk = this.getStudyPk(sopInst.studyUid);
					if studyPk == 0
						study = this.toolkit.createStudy(sopInst);
						studyPk = this.insertStudy(study, patPk);
					end
					seriesPk = this.getSeriesPk(sopInst.seriesUid);
					if seriesPk == 0
						series = this.toolkit.createSeries(sopInst);
						seriesPk = this.insertSeries(series, studyPk);
					end
					this.insertInstance(sopInst, seriesPk);
				end
				stmt.executeUpdate('COMMIT TRANSACTION');
				stmt.close();
				this.sopInstBuffer.clear();
			catch ex
				this.logger.error(ether.formatException(ex));
				try
 					this.logger.debug('Rolling back transaction');
 					stmt.executeUpdate('ROLLBACK TRANSACTION');
					this.closeStatement(stmt);
				catch exRoll
					this.logger.error(ether.formatException(exRoll));
				end
			end
		end

	end
	
end

