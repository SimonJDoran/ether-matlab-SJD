function logDebug(message)
%LOGDEBUG Convenience function for simple logging
%   Detailed explanation goes here

	logger = ether.log4m.Logger.getLogger('root');
	logger.debug(message, true);

end

