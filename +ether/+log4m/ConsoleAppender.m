classdef ConsoleAppender < ether.log4m.Appender
	%CONSOLEAPPENDER Writes log messages to stdout or stderr.

	properties
		% The target stream for the Appender
		target = 1;
	end

	methods
		function this = ConsoleAppender(target)
			% Construct a new ConsoleAppender with the specified target.
			%
			% Target:
			%   1 - stdout
			%   2 - stderr
			%
			% Throws an exception if the target is not 1 or 2.
			this.name = 'Console';
			if ((nargin == 1) && isscalar(target))
				if ((target < 1) || (target > 2))
					me = MException('Ether:Log4M:IllegalArgument', ...
						'Target must be 1 (stdout) or 2 (stderr)');
					throw(me);
				end
				this.target = target;
			end
		end

		function append(this, message)
			fprintf(this.target, '%s\n', message);
		end

		function close(~)
		end
	end

end

