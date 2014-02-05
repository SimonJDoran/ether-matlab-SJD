classdef NoOpAppender < ether.log4m.Appender
	%NOOPAPPENDER Appender that performs no operations
	
	properties
	end
	
	methods
		function this = NoOpAppender()
			this.name = 'NoOp';
		end

		function append(~, ~)
		end

		function close(~)
		end
	end
	
end

