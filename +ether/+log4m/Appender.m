classdef (Abstract) Appender < handle
	%APPENDER Interface for performing output of log messages.
	%
	% Appender implementations perform the actual output of log messages. New
	% output strategies must implement this interface.
	
	properties
		% The name of the Appender.
		name = 'Undefined';
	end
	
	methods(Abstract)
		% Write the log message to the end of the log.
		append(this, message);

		% Release and clean up any resources held by the Appender.
		close(this);

	end

	methods
		function value = get.name(this)
			value = this.name;
		end
		
		function set.name(this, name)
			this.name = name;
		end
	end
	
end

