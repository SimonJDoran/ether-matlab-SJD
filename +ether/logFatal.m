function logFatal(message)
%LOGFATAL Convenience function for simple logging
%   Detailed explanation goes here

	logger = ether.log4m.Logger.getLogger('root');
	logger.fatal(message, true);

end

