function logInfo(message)
%LOGINFO Convenience function for simple logging
%   Detailed explanation goes here

	logger = ether.log4m.Logger.getLogger('root');
	logger.info(message, true);

end

