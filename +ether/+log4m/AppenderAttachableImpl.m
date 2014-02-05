classdef AppenderAttachableImpl < ether.log4m.AppenderAttachable
	%APPENDERATTACHABLEIMPL Internal class to ether.log4m. Do not use.
	
	properties(Access=private)
		appenders;
		appenderMap;
	end
	
	methods
		%-------------------------------------------------------------------------
		function this = AppenderAttachableImpl()
			this.appenders = ether.collect.CellArrayList('ether.log4m.Appender');
			this.appenderMap = containers.Map();
		end

		%-------------------------------------------------------------------------
		function bool = addAppender(this, appender)
			bool = ~this.appenderMap.isKey(appender.name);
			if bool
				this.appenders.add(appender);
				this.appenderMap(appender.name) = appender;
			end
		end

		%-------------------------------------------------------------------------
		function callAppenders(this, message)
			nAppenders = this.appenders.size();
			for i=1:nAppenders
				appender = this.appenders.get(i);
				appender.append(message);
			end
		end

		%-------------------------------------------------------------------------
		function appenders = getAllAppenders(this)
			appenders = this.appenders.toArray();
		end

		%-------------------------------------------------------------------------
		function appender = getAppender(this, name)
			if (this.appenderMap.isKey(name))
				appender = this.appenderMap(name);
			else
				appender = [];
			end
		end

		%-------------------------------------------------------------------------
		function appenders = removeAllAppenders(this)
			appenders = this.appenders.clear();
			allKeys = this.appenderMap.keys;
			this.appenderMap.remove(allKeys);
		end

		%-------------------------------------------------------------------------
		function appender = removeAppender(this, appender)
			appender = this.appenders.remove(appender);
		end

		%-------------------------------------------------------------------------
		function appender = removeAppenderByName(this, name)
			if (~this.appenderMap.isKey(name))
				appender = [];
				return;
			end
			appender = this.appenderMap(name);
			this.appenderMap.remove(name);
			this.appenders.remove(appender);
		end

	end
	
end

