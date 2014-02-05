classdef LoggerNode < ether.collect.CellArrayList
	%LOGGERNODE Internal class to ether.log4m. Do not use.

	methods
		function this = LoggerNode(logger)
			this@ether.collect.CellArrayList('ether.log4m.Logger');
			this.add(logger);
		end
	end
	
end

