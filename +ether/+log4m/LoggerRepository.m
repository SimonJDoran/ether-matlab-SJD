classdef LoggerRepository < handle
	%LOGGERREPOSITORY Create and retrieve Loggers.
	%
	% Loggers are maintained in a named heirarchy. Heirarchy levels are denoted
	% by dots in the Logger's name e.g. "x.y.z"

	properties
		% The log level below which logging should be disabled.
		threshold;
	end

	properties(Access=private)
		rootLogger;
		loggerMap;
	end

	%----------------------------------------------------------------------------
	%	Public methods
	methods
		%-------------------------------------------------------------------------
		function this = LoggerRepository(rootLogger)
			% Construct a new LoggerRepository with the specified RootLogger.
			this.rootLogger = rootLogger;
			rootLogger.setLoggerRepository(this);
			this.loggerMap = containers.Map();
			this.threshold = ether.log4m.Level.TRACE;
		end

		%-------------------------------------------------------------------------
		function configure(this, config)
			import ether.log4m.*;
			Log4M.debug('Configuring repository');
			this.clearAllAppenders();
			this.rootLogger.level = config.getLoggerLevel('root');
			this.processAppenders(this.rootLogger, config.getAppenders('root'));
			loggerNames = config.getLoggerNames();
			nonRoot = {loggerNames{~strcmp(loggerNames, 'root')}};
			for i=1:numel(nonRoot)
				this.addLogger(nonRoot{i}, config);
			end
		end

		%-------------------------------------------------------------------------
		function loggers = getCurrentLoggers(this)
			% Return an array of all the available Loggers in the LoggerRepository.
			allCells = this.loggerMap.values;
			nCells = numel(allCells);
			loggerCells = cell(1, nCells);
			nLoggers = 0;
			for i=1:nCells
				if (isa(allCells{i}, 'ether.log4m.Logger'))
					nLoggers = nLoggers+1;
					loggerCells{nLoggers} = allCells{i};
				end
			end
			if (nLoggers == 0)
				loggers = [];
			else
				loggers = [loggerCells{1:nLoggers}];
			end
		end

		%-------------------------------------------------------------------------
		function logger = getLogger(this, name)
			% Return the named Logger or the RootLogger.
			%
			% If the named Logger is not found it will be constructed then
			% returned. If no name is specified the RootLogger is returned.
			if (nargin == 1)
				logger = this.rootLogger;
			else
				logger = this.getNamedLogger(name);
			end
		end

		%-------------------------------------------------------------------------
		function logger = getRootLogger(this)
			% Return the RootLogger
			logger = this.rootLogger;
		end

		%-------------------------------------------------------------------------
		function bool = isDisabled(this, level)
			% Return true if the log level is disabled for the whole LoggerRepository.
			bool = level < this.threshold;
		end

		%-------------------------------------------------------------------------
		function shutdown(this)
			% Shut down the LoggerRepository, releasing all resources.
			ether.log4m.Log4M.debug('LoggerRepository::shutdown()');
			this.clearAllAppenders();
			this.rootLogger = [];
			this.loggerMap = [];
		end

	end

	%----------------------------------------------------------------------------
	%	Private methods
	methods(Access=private)
		%-------------------------------------------------------------------------
		function logger = addLogger(this, name, config)
			import ether.log4m.*;
			% Get the logger, created if necessary
			logger = this.getNamedLogger(name);
			logger.level = config.getLoggerLevel(name);
			if exist('config', 'var')
				this.processAppenders(logger, config.getAppenders(name));
			end
		end

		%-------------------------------------------------------------------------
		function clearAllAppenders(this)
			this.rootLogger.closeAppenders(this);
			loggers = this.getCurrentLoggers();
			for i=1:numel(this.getCurrentLoggers)
				loggers(i).closeAppenders(this);
			end

			this.rootLogger.removeAllAppenders;
			for i=1:numel(this.getCurrentLoggers)
				loggers(i).removeAllAppenders;
			end
		end

		%-------------------------------------------------------------------------
		function appender = createRollingFileAppender(this, config)
			import ether.log4m.*;
			import ether.*;
			% Default filename
			filename = [ether.getEtherDir(),'ether.log'];
			kv = config.keyValues;
			if kv.isKey('File')
				filename = kv('File');
			end
			appender = ether.log4m.RollingFileAppender(filename);
			if kv.isKey('MaxFileSize')
				fileSize = kv('MaxFileSize');
				unitScale = 1;
				suffix = '';
				if endsWith(fileSize, 'M')
					unitScale = 2^20;
					fileSize = fileSize(1:numel(fileSize)-1);
					suffix = 'M';
				end
				if endsWith(fileSize, 'k')
					unitScale = 2^10;
					fileSize = fileSize(1:numel(fileSize)-1);
					suffix = 'k';
				end
				bytes = str2double(fileSize);
				if ~isnan(bytes) && (bytes > 0)
					bytes = bytes*unitScale;
					if bytes < 2^30
						Log4M.debug(@() sprintf('MaxFileSize: %s%s', fileSize, suffix));
						appender.maxFileSize = uint32(bytes);
					end
				end
			end
			if kv.isKey('MaxBackupIndex')
				maxBackup = str2double(kv('MaxBackupIndex'));
				if ~isnan(maxBackup) && (maxBackup >= 0)
					Log4M.debug(@() sprintf('MaxBackupIndex: %i', maxBackup));
					appender.maxBackupIndex = uint32(maxBackup);
				end
			end
		end

		%-------------------------------------------------------------------------
		function logger = getNamedLogger(this, name)
			import ether.log4m.*;
			Log4M.debug(@() sprintf('Requested: %s', name));
			if strcmp(name, 'root')
				logger = this.rootLogger;
				return;
			end
			if (this.loggerMap.isKey(name))
				logger = this.loggerMap(name);
				% Return Logger if we have one
				if (isa(logger, 'Logger'))
					return;
				end
				% Create and return a Logger if we've hit a placeholder node
				if (isa(logger, 'LoggerNode'))
					Log4M.debug(@() sprintf('Replacing placeholder node for: %s', name));
					node = logger;
					logger = Logger(name);
					logger.setLoggerRepository(this);
					this.loggerMap(name) = logger;
					this.updateChildren(node, logger);
					this.updateParents(logger);
					return;
				end
				loggerType = whos('logger');
				message = sprintf('Unexpected type in Logger map: %s', ...
					loggerType.class);
				Log4M.error(message);
				me = MException('Ether:Log4M:IllegalState', message);
				throw(me);
			end
			% Create a new Logger
			logger = Logger(name);
			logger.setLoggerRepository(this);
			this.loggerMap(name) = logger;
			this.updateParents(logger);
		end

		%-------------------------------------------------------------------------
		function processAppenders(this, logger, configs)
			import ether.log4m.*;
			for i=1:numel(configs)
				switch configs(i).class
					case 'ether.log4m.ConsoleAppender'
						logger.addAppender(ether.log4m.ConsoleAppender());
					case 'ether.log4m.RollingFileAppender'
						logger.addAppender(this.createRollingFileAppender(configs(i)));
					otherwise
				end
			end
		end

		%-------------------------------------------------------------------------
		function updateChildren(this, node, logger)
			import ether.log4m.*;
			Log4M.debug(@() sprintf('Updating children for %s', logger.name));
			nNodes = node.size();
			for i=1:nNodes
				child = node.get(i);
				if ~ether.startsWith(child.parent.name, logger.name)
					logger.setParent(child.parent, this);
					child.setParent(logger, this);
				end
			end
		end

		%-------------------------------------------------------------------------
		function updateParents(this, logger)
			import ether.log4m.*;
			parentFound = false;
			name = logger.name;
			dotIdx = strfind(name, '.');
			nDots = numel(dotIdx);
			Log4M.debug(@() sprintf('Updating parents for %s', name));
			for i=1:nDots
				key = name(1:dotIdx(nDots-i+1)-1);
				Log4M.debug(@() sprintf('Searching repository for %s', key));
				if (~this.loggerMap.isKey(key))
					Log4M.debug(@() sprintf('No parent %s found, creating LoggerNode', ...
						key));
					this.loggerMap(key) = LoggerNode(logger);
				else
					ancestor = this.loggerMap(key);
					if isa(ancestor, 'Logger')
						Log4M.debug(@() sprintf('Linking %s -> %s', name, key));
						parentFound = true;
						logger.setParent(ancestor, this);
						break;
					end
					if isa(ancestor, 'LoggerNode')
						ancestor.add(logger);
						break;
					end
					ancestorType = whos('ancestor');
					message = sprintf('Unexpected type in Logger map: %s', ...
						ancestorType.class);
					Log4M.error(message);
					me = MException('Ether:Log4M:IllegalState', message);
					throw(me);
				end
			end
			if ~parentFound
				logger.setParent(this.getRootLogger, this);
			end
			Log4M.debug(@() sprintf('Logger %s has parent %s', logger.name, ...
				logger.parent.name));
		end
	end
	
end

