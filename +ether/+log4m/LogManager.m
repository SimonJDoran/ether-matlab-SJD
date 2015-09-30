classdef (Sealed) LogManager < handle
	%LOGMANAGER The LogManager maintains the current LoggerRepository.
	%
	% The LogManager is used to retrieve Logger instances and operate on the
	% current LoggerRepository.
	properties(Access=private)
		loggerRepo;
	end

	%----------------------------------------------------------------------------
	%	Public static methods
	methods(Static)
		%-------------------------------------------------------------------------
		function logger = getLogger(name)
			% Return the named Logger.
			if (nargin == 0)
				name = 'root';
			end
			logger = ether.log4m.LogManager.getLogManager.loggerRepo.getLogger(name);
		end

		%-------------------------------------------------------------------------
		function repo = getLoggerRepository()
			% Return the current LoggerRepository.
			repo = ether.log4m.LogManager.getLogManager.loggerRepo;
		end

		%-------------------------------------------------------------------------
		function mgr = getLogManager(pattern)
			% Return the LogManager instance.
			persistent logManager
			if (isempty(logManager) || ~isvalid(logManager))
				if (nargin == 0)
					logManager = ether.log4m.LogManager();
				else
					logManager = ether.log4m.LogManager(pattern);
				end
			end
			mgr = logManager;
		end

		%-------------------------------------------------------------------------
		function resetConfiguration()
			% Reset the logging system to its original configuration
			import ether.log4m.*;
			Log4M.debug('LogManager::reset()');
			log4M = Log4M.getLog4M;
			Log4M.configure(log4M.pattern);
			LogManager.getLoggerRepository.configure(log4M.configuration);
		end

		%-------------------------------------------------------------------------
		function shutdown()
			import ether.log4m.*;
			Log4M.debug('LogManager::shutdown()');
			LogManager.getLoggerRepository.shutdown;
		end

	end

	%----------------------------------------------------------------------------
	%	Public methods
	methods
		%-------------------------------------------------------------------------
		function delete(this)
			ether.log4m.Log4M.debug(@() sprintf('LogManager deleted for PID=%i', ...
				feature('GetPid')));
			% Can't use static method as the persistent variable in
			% getLogManager() is empty at this point
			this.shutdownInternal();
		end
	end

	%----------------------------------------------------------------------------
	%	Private methods
	methods(Access=private)
		%-------------------------------------------------------------------------
		function this = LogManager(pattern)
			import ether.log4m.*;
			Log4M.debug('LogManager initialising...');
			this.loggerRepo = LoggerRepository(RootLogger(Level.DEBUG));
			if (nargin == 0)
				this.configureRepo('ether');
			else
				this.configureRepo(pattern);
			end
		end

		%-------------------------------------------------------------------------
		function configureRepo(this, pattern)
			import ether.log4m.*;
			Log4M.debug(['LogManager::configureRepo(',pattern,')']);
			log4m = Log4M.getLog4M();
			if ~strcmp(log4m.pattern, pattern)
				Log4M.configure(pattern);
			end
			this.loggerRepo.configure(log4m.configuration);
		end

		%-------------------------------------------------------------------------
		function shutdownInternal(this)
			import ether.log4m.Log4M;
			Log4M.debug('LogManager::shutdown()');
			this.loggerRepo.shutdown;
		end

	end

end

