classdef (Abstract) Loggable < handle
	%LOGGABLE Interface defining logging calls.
	%
	% Logging calls, one per log level as defined in ether.log4m.Level.

	% Empty properties list to make doc work
	properties
	end

	methods(Abstract)
		% Log a message with the DEBUG level.
		debug(this, message);

		% Log a message with the ERROR level.
		error(this, message);

		% Log a message with the FATAL level.
		fatal(this, message);

		% Log a message with the INFO level.
		info(this, message);

		% Log a message with the TRACE level.
		trace(this, message);

		% Log a message with the WARN level.
		warn(this, message);

	end
	
end

