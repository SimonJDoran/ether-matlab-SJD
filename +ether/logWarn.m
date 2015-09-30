function logWarn(message)
%LOGWARN Convenience function for simple logging
%   Detailed explanation goes here

	logger = ether.log4m.Logger.getLogger('root');
	logger.warn(message, true);

end

