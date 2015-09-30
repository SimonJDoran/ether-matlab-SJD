classdef (Sealed) AppenderConfiguration
	%APPENDERCONFIGURATION Configuration of an ether.log4m.Appender
	%   Immutable to prevent accidents
	
	%----------------------------------------------------------------------------
	properties(SetAccess=private)
		loggerName = '';
		class = '';
		keyValues;
	end
	
	%----------------------------------------------------------------------------
	%	Public methods
	methods
		%-------------------------------------------------------------------------
		function this = AppenderConfiguration(loggerName, class, keyValues)
			this.loggerName = loggerName;
			this.class = class;
			if (exist('keyValues', 'var') && isa(keyValues, 'containers.Map'))
				this.keyValues = keyValues;
			else
				this.keyValues = containers.Map();
			end
		end
	end
	
end

