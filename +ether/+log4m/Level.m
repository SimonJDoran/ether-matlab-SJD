classdef Level < handle
	%LEVEL Specification of logging levels in Log4M.
	%
	% A log level includes all levels less than itself:
	%
	% TRACE < DEBUG < INFO < WARN < ERROR < FATAL < NONE
	
	%----------------------------------------------------------------------------
	%	Public constant properties
	properties(Constant)
		% Log detailed trace information on execution.
		TRACE = 1;

		% Log debug information, typically internal state updates and data.
		DEBUG = 2;

		% Log information useful to a user.
		INFO = 3;

		% Log warning information.
		WARN = 4;

		% Log serious but usually recoverable errors.
		ERROR = 5;

		% Log errors that cannot be recovered from.
		FATAL = 6;

		% Turn off all logging.
		NONE = 7;

		% Unspecified log level.
		UNSET = 2^16;
	end

	%----------------------------------------------------------------------------
	%	Public static methods
	methods(Static)
		function value = getName(logLevel)
			% Return the name of the log level.
			%
			% Throws an exception if the log level is unknown.
			import ether.log4m.Level;
			persistent levelNames;
			if isempty(levelNames)
				levelNames = {'TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL', 'NONE'};
			end
			if logLevel == Level.UNSET
				value = 'UNSET';
				return;
			else
				if ((logLevel < Level.TRACE) || (logLevel > Level.NONE))
					me = MException('Ether:Log4M:IllegalArgument', ...
						sprintf('Unknown log level: %i', logLevel));
					throw(me);
				end
			end
			value = levelNames{logLevel};
		end
	end

end

