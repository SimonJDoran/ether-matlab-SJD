classdef (Abstract) AppenderAttachable < handle
	%APPENDERATTACHABLE Interface for attaching Appenders to objects.

	% Empty properties list to make doc work
	properties
	end

	methods(Abstract)
		% Add an Appender
		%
		% Returns true if the Appender was successfully attached, otherwise false.
		bool = addAppender(this, appender);

		% Get all attached Appenders as an array.
		appenders = getAllAppenders(this);

		% Get the named Appender.
		appender = getAppender(this, name);

		% Remove and detach all attached Appenders.
		%
		% Returns removed Appenders as an array
		appenders = removeAllAppenders(this);

		% Remove an Appender.
		%
		% Returns the removed Appender.
		appender = removeAppender(this, appender);

		% Remove the named Appender.
		%
		% Returns the removed Appender.
		appender = removeAppenderByName(this, name);

	end
	
end

