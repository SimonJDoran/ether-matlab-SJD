classdef RootLogger < ether.log4m.Logger
	%ROOTLOGGER RootLogger sits at the top of the Logger heirarchy.
	
	% Empty properties list to make doc work
	properties
	end

	methods
		function this = RootLogger(level)
			% Construct a new RootLogger with the specified level.
			%
			% Throws an exception if the level is UNSET.
			import ether.log4m.*
			this@ether.log4m.Logger('root');
			% Fetching level name will trigger an exception if level is invalid
			levelName = Level.getName(level);
			if (level == Level.UNSET)
				me = MException('Ether:Log4M:IllegalArgument', ...
					'RootLogger level UNSET not permitted');
				throw(me);
			end
			Log4M.debug(['RootLogger level: ', levelName]);
			this.level = level;
		end

	end

	methods(Access=protected)
		function level = getEffectiveLevel(this)
			level = this.level;
		end
	end
	
end

