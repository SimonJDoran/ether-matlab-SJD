function logError(message)
%LOGERROR Convenience function for simple logging
%   Detailed explanation goes here

	logger = ether.log4m.Logger.getLogger('root');
	logger.error(message, true);

end

