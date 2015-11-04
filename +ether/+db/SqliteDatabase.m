classdef SqliteDatabase < handle
	%SQLITEDATABASE Summary of this class goes here
	%   Detailed explanation goes here

	%----------------------------------------------------------------------------
	properties(Constant,Access=private)
		logger = ether.log4m.Logger.getLogger('ether.db.SqliteDatabase');
	end

	%----------------------------------------------------------------------------
	properties(SetAccess=private)
		filename = '';
		requireFk = true;
	end

	%----------------------------------------------------------------------------
	properties(Access=protected)
		connection = [];
		% List of table names in order of construction
		tableNameList = [];
	end

	%----------------------------------------------------------------------------
	properties(Access=private)
		indexSqlMap = [];
		tableSqlMap = [];
	end

	%----------------------------------------------------------------------------
	methods
		%-------------------------------------------------------------------------
		function this = SqliteDatabase(filename, requireFk)
			import ether.*;
			if isAbsolutePath(filename);
				this.filename = filename;
			else
				this.filename = fullfile(getEtherDir, filename);
			end
			if (nargin == 2) && islogical(requireFk)
				this.requireFk = requireFk;
			end
			this.connection = database('','','','org.sqlite.JDBC', ...
				['jdbc:sqlite:',this.filename]);
			if ~(isjava(this.connection.Handle) && isempty(this.connection.Message))
				me = MException('Ether:DB:Sqlite', this.connection.Message);
				throw(me);
			end
			this.checkForeignKeys;
			this.tableNameList = ether.collect.CellArrayList('ether.String');
			this.tableSqlMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
			this.indexSqlMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
		end

		%-------------------------------------------------------------------------
		function delete(this)
			close(this.connection);
			this.logger.debug(@() sprintf('SqliteDatabase closed for PID=%i', ...
				feature('GetPid')));
		end
	end

	%----------------------------------------------------------------------------
	methods(Access=protected)
		%-------------------------------------------------------------------------
		function checkTables(this)
			stmt = this.createStatement();
			for i=1:this.tableNameList.size
				tableName = this.tableNameList.get(i).value;
				sql = ['SELECT sql FROM sqlite_master WHERE type=''table'' AND name=''', ...
					tableName,''';'];
				rs = stmt.executeQuery(sql);
				if rs.isAfterLast()
					this.logger.info(...
						sprintf('Missing table: %s. Recreating database', tableName));
					rs.close();
					this.dropAndRecreateAllTables();
					break;
				end
				requiredSql = this.getTableSql(tableName);
				tableSql = char(rs.getString(1));
				if ~strcmp(requiredSql, tableSql)
					this.logger.info(...
						sprintf('SQL mismatch for table: %s. Recreating database', ...
							tableName));
					rs.close();
					this.dropAndRecreateAllTables();
					break;
				end
				rs.close();
			end
			stmt.close();
			this.checkIndices();
		end

		%-------------------------------------------------------------------------
		function closeStatement(~, stmt)
			if ~isempty(stmt)
				stmt.close();
			end
		end

		%-------------------------------------------------------------------------
		function stmt = createStatement(this)
			jConn = this.connection.Handle;
			stmt = jConn.createStatement();
		end

		%-------------------------------------------------------------------------
		function addIndexSql(this, table, column)
			idxName = [column,'Idx'];
			sql = ['CREATE INDEX "',idxName,'" ON "',table,'" ("',column,'")'];
			this.indexSqlMap(idxName) = sql;
		end

		%-------------------------------------------------------------------------
		function addTableSql(this, table, sql)
			this.tableSqlMap(table) = sql;
		end

		%-------------------------------------------------------------------------
		function sql = getIndexSql(this, index)
			sql = '';
			if ~this.indexSqlMap.isKey(index)
				return;
			end
			sql = this.indexSqlMap(index);
		end

		%-------------------------------------------------------------------------
		function sql = getTableSql(this, table)
			sql = '';
			if ~this.tableSqlMap.isKey(table)
				return;
			end
			sql = this.tableSqlMap(table);
		end

		%-------------------------------------------------------------------------
		function stmt = prepareStatement(this, sql)
			jConn = this.connection.Handle;
			stmt = jConn.prepareStatement(sql);
		end

		%-------------------------------------------------------------------------
		function rollback(this)
			jConn = this.connection.Handle;
			jConn.rollback();
		end

		%-------------------------------------------------------------------------
		function setAutoCommit(this, bool)
			jConn = this.connection.Handle;
			jConn.setAutoCommit(bool);
		end

	end

	%----------------------------------------------------------------------------
	methods(Access=private)
		%-------------------------------------------------------------------------
		function checkForeignKeys(this)
			if ~this.requireFk
				return;
			end
			stmt = this.createStatement();
			stmt.executeUpdate('PRAGMA foreign_keys=ON');
			rs = stmt.executeQuery('PRAGMA foreign_keys');
			if ~(strcmp(rs.getColumnName(1), 'foreign_keys') && rs.getBoolean(1))
				throw(MException('Ether:DB:Sqlite', ...
					'Required foreign key support not present'));
			end
			rs.close();
			stmt.close();
		end

		%-------------------------------------------------------------------------
		function checkIndices(this)
			stmt = this.createStatement();
			keys = this.indexSqlMap.keys();
			for i=1:this.indexSqlMap.length
				indexName = keys{i};
				sql = ['SELECT sql FROM sqlite_master WHERE type=''index'' AND name=''', ...
					indexName,''';'];
				rs = stmt.executeQuery(sql);
				if rs.isAfterLast
					rs.close();
					this.logger.info(...
						sprintf('Missing index: %s. Recreating index', indexName));
					this.dropAndRecreateIndex(indexName);
					continue;
				end
				requiredSql = this.getIndexSql(indexName);
				indexSql = char(rs.getString(1));
				if ~strcmp(requiredSql, indexSql)
					rs.close();
					this.logger.info(...
						sprintf('SQL mismatch for index: %s. Recreating index', ...
							indexName));
					this.dropAndRecreateIndex(indexName);
					continue;
				end
				rs.close();
			end
			stmt.close();
		end

		%-------------------------------------------------------------------------
		function dropAndRecreateIndex(this, indexName)
			stmt = this.createStatement();
			% Drop
			sql = ['DROP INDEX IF EXISTS ',indexName,';'];
			stmt.executeUpdate(sql);
			% Create
		 	sql = this.getIndexSql(indexName);
			if isempty(sql)
				me = MException('Ether:DB:Sqlite', ...
					['No SQL found for index: ',indexName]);
				throw(me);
			end
			stmt.executeUpdate(sql);
			this.logger.debug(@() sprintf('Index creation SQL: %s', sql));
		end

		%-------------------------------------------------------------------------
		function dropAndRecreateAllTables(this)
			stmt = this.createStatement();
			% Disable foreign keys to prevent foreign key constraint violations
			if this.requireFk
				stmt.executeUpdate('PRAGMA foreign_keys=OFF');
			end
			% Drop
			for i=1:this.tableNameList.size
				tableName = this.tableNameList.get(i).value;
				sql = ['DROP TABLE IF EXISTS ',tableName,';'];
				stmt.executeUpdate(sql);
			end
			% Re-enable foreign keys
			if this.requireFk
				stmt.executeUpdate('PRAGMA foreign_keys=ON');
			end
			% Creation
			for i=1:this.tableNameList.size
				tableName = this.tableNameList.get(i).value;
				sql = this.getTableSql(tableName);
				if isempty(sql)
					me = MException('Ether:DB:Sqlite', ...
						['No SQL found for table: ',tableName]);
					throw(me);
				end
				stmt.executeUpdate(sql);
				this.logger.debug(@() sprintf('Table creation SQL: %s', sql));
			end
		end

	end

end

