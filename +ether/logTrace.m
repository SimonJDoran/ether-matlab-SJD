function logTrace(message)
%LOGTRACE Convenience function for simple logging
%   Detailed explanation goes here

	logger = ether.log4m.Logger.getLogger('root');
	logger.trace(message, true);

end

