classdef Logger < ether.log4m.AppenderAttachable & ether.log4m.Loggable
	%LOGGER Principal class of and interface to Log4M.
	%
	%Heirarchies of Loggers may be defined using dotsin the name property to
	%separate levels. E.g. the Logger named "x.y" is the parent of one named
	%"x.y.z"
	%
	%Best practice when using classes is to assign a Logger with the fully
	%qualified class name as a Constant, private property of the class.

	properties
		% The level of the Logger (default: UNSET).
		level = ether.log4m.Level.UNSET;
	end

	properties(Access=private)
		aai;
		repo;
	end

	properties(SetAccess=private)
		% The name of the Logger.
		name;
		% The parent of the Logger.
		parent;
	end

	%----------------------------------------------------------------------------
	%	Public static methods
	methods(Static)
		%-------------------------------------------------------------------------
		function logger = getLogger(name)
			% Return the named Logger from the LoggerRepository.
			%
			% If no name is supplied the default Logger is returned.
			if nargin == 1
				logger = ether.log4m.LogManager.getLoggerRepository.getLogger(name);
			else
				logger = ether.log4m.LogManager.getLoggerRepository.getLogger;
			end
		end
	end

	%----------------------------------------------------------------------------
	%	Public methods
	methods
		%-------------------------------------------------------------------------
		function this = Logger(name)
			% Construct an instance of Logger with the specified name.
			this.name = name;
		end

		%-------------------------------------------------------------------------
		function value = get.level(this)
			value = this.level;
		end

		%-------------------------------------------------------------------------
		function value = get.name(this)
			value = this.name;
		end

		%-------------------------------------------------------------------------
		function value = get.parent(this)
			value = this.parent;
		end

		%-------------------------------------------------------------------------
		function set.level(this, value)
			import ether.log4m.*;
			if ((value < Level.TRACE) || (value > Level.NONE))
				Log4M.warn(['Invalid log level: ',value])
			else
				this.level = value;
			end
		end

		%-------------------------------------------------------------------------
		function bool = addAppender(this, appender)
			import ether.log4m.*;
			if (isempty(this.aai) || ~isvalid(this.aai))
				this.aai = AppenderAttachableImpl();
			end
			Log4M.debug(['Adding appender(',appender.name,') to logger(',this.name,')']);
			bool = this.aai.addAppender(appender);
		end

		%-------------------------------------------------------------------------
		function closeAppenders(this, repo)
			% Close all attached Appenders.
			if (nargin == 1)
				ether.log4m.Log4M.error('No owner repository supplied!');
				return;				
			end
			if (~isempty(this.repo) && isvalid(this.repo) && (repo ~= this.repo))
				ether.log4m.Log4M.error(...
					'Attempted closeAppenders() by non-owner repository!');
				return;
			end
			ether.log4m.Log4M.debug(sprintf('Closing appenders for %s', this.name));
			if (isempty(this.aai) || ~isvalid(this.aai))
				return;
			end
			appenders = this.aai.getAllAppenders;
			nAppenders = numel(appenders);
			ether.log4m.Log4M.debug(sprintf(' * %i appenders', nAppenders));
			for i=1:nAppenders
				appenders(i).close;
			end
		end

		%-------------------------------------------------------------------------
		function debug(this, message)
			this.log(ether.log4m.Level.DEBUG, message);
		end

		%-------------------------------------------------------------------------
		function error(this, message)
			this.log(ether.log4m.Level.ERROR, message);
		end

		%-------------------------------------------------------------------------
		function fatal(this, message)
			this.log(ether.log4m.Level.FATAL, message);
		end

		%-------------------------------------------------------------------------
		function appenders = getAllAppenders(this)
			if (isempty(this.aai) || ~isvalid(this.aai))
				appenders = [];
				return;
			end
			appenders = this.aai.getAllAppenders;
		end

		%-------------------------------------------------------------------------
		function appender = getAppender(this, name)
			if (isempty(this.aai) || ~isvalid(this.aai))
				appender = [];
				return;
			end
			appender = this.aai.getAppender(name);
		end

		%-------------------------------------------------------------------------
		function repo = getLoggerRepository(this)
			% Return the LoggerRepository this Logger belongs to.
			repo = this.repo;
		end

		%-------------------------------------------------------------------------
		function info(this, message)
			this.log(ether.log4m.Level.INFO, message);
		end

		%-------------------------------------------------------------------------
		function bool = isEnabled(this, level)
			bool = ~((this.repo.threshold > level) || ...
				(this.getEffectiveLevel > level));
		end

		%-------------------------------------------------------------------------
		function appenders = removeAllAppenders(this)
			if (isempty(this.aai) || ~isvalid(this.aai))
				appenders = [];
				return;
			end
			appenders = this.aai.removeAllAppenders;
		end

		%-------------------------------------------------------------------------
		function appender = removeAppender(this, appender)
			if (isempty(this.aai) || ~isvalid(this.aai))
				appender = [];
				return;
			end
			appender = this.aai.removeAppender(appender);
		end

		%-------------------------------------------------------------------------
		function appender = removeAppenderByName(this, name)
			if (isempty(this.aai) || ~isvalid(this.aai))
				appender = [];
				return;
			end
			appender = this.aai.removeAppenderByName(name);
		end

		%-------------------------------------------------------------------------
		function setLoggerRepository(this, repo)
			% Set the LoggerRepository this Logger belongs to.
			%
			% This operation will only succeed if this Logger has no
			% LoggerRepository currently set. Normally called immediately after
			% construction by the constructing LoggerRepository.
			import ether.log4m.Log4M;
			if (isempty(this.repo) || ~isvalid(this.repo))
				this.repo = repo;
			else
				Log4M.error('Attempted replacement of LoggerRepository!');
			end
		end

		%-------------------------------------------------------------------------
		function setParent(this, parent, repo)
			% Set the parent Logger.
			%
			% The guard paramater "repo" is required to prevent arbitrary
			% reassignment of the parent outside the LoggerRepository this Logger
			% belongs to.
			import ether.log4m.Log4M;
			if (~isempty(this.repo) && isvalid(this.repo) && (repo ~= this.repo))
				Log4M.error('Attempted setParent() by non-owner repository!');
				return;
			end
			this.parent = parent;
		end

		%-------------------------------------------------------------------------
		function trace(this, message)
			this.log(ether.log4m.Level.TRACE, message);
		end

		%-------------------------------------------------------------------------
		function warn(this, message)
			this.log(ether.log4m.Level.WARN, message);
		end

	end

	%----------------------------------------------------------------------------
	%	Protected methods
	methods(Access=protected)
		%-------------------------------------------------------------------------
		function value = getEffectiveLevel(this)
			% Starting at this Logger, search the heirarchy for a level which is not UNSET.
			import ether.log4m.*;
			logger = this;
			while (~isempty(logger) && isvalid(logger))
				if (logger.level ~= Level.UNSET)
					value = logger.level;
					return;
				end
				logger = logger.parent;
			end
			% This should never be reached, RootLogger must have a valid level set
			value = [];
			Log4M.error(['No effective level found for ',this.name]);
		end
	end

	%----------------------------------------------------------------------------
	%	Private methods
	methods(Access=private)
		%-------------------------------------------------------------------------
		function callAppenders(this, message)
			import ether.log4m.Log4M;
			logger = this;
			while (~isempty(logger) && isvalid(logger))
				if (~isempty(logger.aai) && isvalid(logger.aai))
					logger.aai.callAppenders(message);
				end
				logger = logger.parent;
			end
		end

		%-------------------------------------------------------------------------
		function prefix = getPrefix(~, logLevel)
			import ether.log4m.Level;
			prefix = sprintf('%s %s %i ', ...
				datestr(clock(),'dd-mmm-yyyy HH:MM:SS.FFF'), ...
				Level.getName(logLevel), feature('GetPid'));
			if ~ismcc()
				stack = dbstack(1);
				if ~strcmp(stack(3).file, '')
					prefix = [prefix,'[',stack(3).file,']'];
				end
				prefix = sprintf('%s(%s:%i) ', prefix, stack(3).name, stack(3).line);
			end
			prefix = [prefix,'- '];
		end

		%-------------------------------------------------------------------------
		function log(this, level, message)
			if ~this.isEnabled(level)
				return
			end
			output = [this.getPrefix(level),message()];
			this.callAppenders(output);
		end
	end

end

