classdef Log4M < handle
	%LOG4M Internal logging for ether.log4m package.
	%
	% Log4M provides a method of outputting log messages that originate from
	% within the ether.log4m package itself rather than from clients. Output is
	% sent to stdout/stderr and all messages are prefixed "Log4M:".
	%
	% Internal debugging output can be enabled (default: false).
	% All output can be suppressed in quiet mode (default: false).
	%
	% This class is not intended for logging in client code.

	%----------------------------------------------------------------------------
	%	Private properties
	properties(Access=private)
		enableDebug = false;
		quietMode = false;
	end

	%----------------------------------------------------------------------------
	%	Public static methods
	methods(Static)
		%-------------------------------------------------------------------------
		function debug(message)
			% Send message to stdout with DEBUG level if internal debugging is enabled.
			import ether.log4m.*;
			if (~Log4M.isDebugEnabled || Log4M.isQuietMode)
				return;
			end
			fprintf('%s%s\n', Log4M.getPrefix(Level.DEBUG), message());
		end

		%-------------------------------------------------------------------------
		function error(message)
			% Send message to stderr with ERROR level.
			import ether.log4m.*;
			if (Log4M.isQuietMode)
				return;
			end
			fprintf(2, '%s%s\n', Log4M.getPrefix(Level.ERROR), message());
		end

		%-------------------------------------------------------------------------
		function setDebugEnabled(bool)
			% Enable or disable internal debugging.
			import ether.log4m.Log4M;
			if (~isscalar(bool) || ~islogical(bool))
				log4M.error('Invalid flag passed to Log4M::setDebugEnabled()!');
				return;
			end
			log4m = Log4M.getLog4M;
			if bool
				log4m.enableDebug = bool;
				Log4M.debug('Internal debugging enabled');
			else
				Log4M.debug('Internal debugging disabled');
				log4m.enableDebug = bool;
			end
		end

		%-------------------------------------------------------------------------
		function setQuietMode(bool)
			% Enable or disable quiet mode.
			import ether.log4m.Log4M;
			if (~isscalar(bool) || ~islogical(bool))
				log4M.error('Invalid flag passed to Log4M::setQuietMode()!');
				return;
			end
			log4m = Log4M.getLog4M();
			log4m.quietMode = bool;
		end

		%-------------------------------------------------------------------------
		function warn(message)
			% Send message to stderr with WARN level.
			import ether.log4m.*;
			if (Log4M.isQuietMode)
				return;
			end
			fprintf(2, '%s%s\n', Log4M.getPrefix(Level.WARN), message());
		end

	end
	
	%----------------------------------------------------------------------------
	%	Private static methods
	methods(Static, Access=private)
		%-------------------------------------------------------------------------
		function prefix = getPrefix(logLevel)
			import ether.log4m.Level;
			prefix = sprintf('Log4M: %s %i ', ...
				Level.getName(logLevel), feature('GetPid'));
			if ~ismcc
				stack = dbstack(1);
				if ~strcmp(stack(2).file, '')
					prefix = [prefix,'[',stack(2).file,']'];
				end
				prefix = sprintf('%s(%s:%i) ', prefix, stack(2).name, stack(2).line);
			end
			prefix = [prefix,'- '];
		end

		%-------------------------------------------------------------------------
		function log4m = getLog4M
			persistent log4M
			if (isempty(log4M) || ~isvalid(log4M))
				log4M = ether.log4m.Log4M();
			end
			log4m = log4M;
		end

		%-------------------------------------------------------------------------
		function bool = isDebugEnabled
			bool = ether.log4m.Log4M.getLog4M.enableDebug;
		end

		%-------------------------------------------------------------------------
		function bool = isQuietMode
			bool = ether.log4m.Log4M.getLog4M.quietMode;
		end

	end

	%----------------------------------------------------------------------------
	%	Private methods
	methods(Access=private)
		%-------------------------------------------------------------------------
		function this = Log4M()
		end

	end

end

