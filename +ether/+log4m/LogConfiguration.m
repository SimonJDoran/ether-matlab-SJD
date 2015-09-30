classdef (Sealed) LogConfiguration < handle
	%LOGCONFIGURATION The LogConfiguration holds the configuration for Log4M.
	%
	% No details.
	properties
		debug = false;
	end

	properties(Access=private)
		loggerMap;
		appenderList;
	end

	%----------------------------------------------------------------------------
	%	Public methods
	methods
		%-------------------------------------------------------------------------
		function this = LogConfiguration(debug)
			% Constructor
			if exist('debug', 'var')
				this.debug = debug;
			end
			this.loggerMap('root') = ether.log4m.Level.INFO;
			this.loggerMap = containers.Map();
			this.appenderList = ether.collect.CellArrayList('ether.log4m.AppenderConfiguration');
		end

		%-------------------------------------------------------------------------
		function set.debug(this, bool)
			if islogical(bool)
				this.debug = bool;
			end
		end

		%-------------------------------------------------------------------------
		function addAppender(this, config)
			if ~isa(config, 'ether.log4m.AppenderConfiguration')
				return;
			end
			this.appenderList.add(config);
		end

		%-------------------------------------------------------------------------
		function addLogger(this, name, level)
			if ~(ischar(name) && isnumeric(level))
				return;
			end
			this.loggerMap(name) = level;
		end

		%-------------------------------------------------------------------------
		function appenders = getAppenders(this, name)
			% Returns an array of ether.log4m.AppenderConfigurations matching
			% supplied Logger name.
			if ~ischar(name)
				appenders = [];
				return;
			end
			idx = cellfun(@(c) strcmp(c.loggerName, name), ...
				this.appenderList.toCellArray());
			appenders = this.appenderList.get(idx);
		end

		%-------------------------------------------------------------------------
		function names = getLoggerNames(this)
			names = this.loggerMap.keys();
		end

		%-------------------------------------------------------------------------
		function level = getLoggerLevel(this, key)
			if ~this.loggerMap.isKey(key)
				level = ether.log4m.Level.ERROR;
				return;
			end
			level = this.loggerMap(key);
		end
	end % end public methods

end
