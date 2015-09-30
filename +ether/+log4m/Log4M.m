classdef Log4M < handle
	%LOG4M Internal logging for ether.log4m package.
	%
	% Log4M provides a method of outputting log messages that originate from
	% within the ether.log4m package itself rather than from clients. Output is
	% sent to stdout/stderr and all messages are prefixed "Log4M:".
	%
	% Internal debugging output can be enabled (default: false).
	% All output can be suppressed in quiet mode (default: false).
	%
	% This class is not intended for logging in client code.

	%----------------------------------------------------------------------------
	%	Readonly properties
	properties(SetAccess=private)
		configuration = ether.log4m.LogConfiguration();
		enableDebug = false;
		pattern = 'ether';
		quietMode = false;
	end

	properties(Constant,Access=private)
		ATTR_CLASS = 'class';
		ATTR_DEBUG = 'debug';
		ATTR_KEY = 'key';
		ATTR_LEVEL = 'level';
		ATTR_NAME = 'name';
		ATTR_VALUE = 'value';
		NODE_APPENDER = 'appender';
		NODE_DOC = 'log4m';
		NODE_KEYVALUE = 'key-value';
		NODE_LOGGER = 'logger';
		XML_FILE = 'log4m.xml';
	end

	%----------------------------------------------------------------------------
	%	Public static methods
	methods(Static)
		%-------------------------------------------------------------------------
		function configure(pattern)
			import ether.log4m.*;
			log4m = Log4M.getLog4M();
			if (nargin == 1) && (ischar(pattern))
				log4m.pattern = pattern;
			end
			fprintf(2, '%sConfiguring for pattern: %s\n', ...
				Log4M.getPrefix(Level.DEBUG), log4m.pattern);
			config = [];
			if ~strcmp(log4m.pattern, 'ether')
				config = Log4M.readConfig(log4m.pattern);
			end
			if isempty(config)
				config = Log4M.getDefaultConfig();
			end
			log4m.enableDebug = config.debug;
			log4m.configuration = config;
		end

		%-------------------------------------------------------------------------
		function debug(message)
			% Send message to stdout with DEBUG level if internal debugging is enabled.
			import ether.log4m.*;
			if (~Log4M.isDebugEnabled || Log4M.isQuietMode)
				return;
			end
			fprintf(2, '%s%s\n', Log4M.getPrefix(Level.DEBUG), message());
		end

		%-------------------------------------------------------------------------
		function error(message)
			% Send message to stderr with ERROR level.
			import ether.log4m.*;
			if (Log4M.isQuietMode)
				return;
			end
			fprintf(2, '%s%s\n', Log4M.getPrefix(Level.ERROR), message());
		end

		%-------------------------------------------------------------------------
		function log4m = getLog4M
			persistent log4M
			if (isempty(log4M) || ~isvalid(log4M))
				log4M = ether.log4m.Log4M();
			end
			log4m = log4M;
		end

		%-------------------------------------------------------------------------
		function info(message)
			% Send message to stderr with INFO level.
			import ether.log4m.*;
			if (Log4M.isQuietMode)
				return;
			end
			fprintf(2, '%s%s\n', Log4M.getPrefix(Level.INFO), message());
		end

		%-------------------------------------------------------------------------
		function setDebugEnabled(bool)
			% Enable or disable internal debugging.
			import ether.log4m.Log4M;
			if (~isscalar(bool) || ~islogical(bool))
				log4M.error('Invalid flag passed to Log4M::setDebugEnabled()!');
				return;
			end
			log4m = Log4M.getLog4M;
			if bool
				log4m.enableDebug = bool;
				Log4M.debug('Internal debugging enabled');
			else
				Log4M.debug('Internal debugging disabled');
				log4m.enableDebug = bool;
			end
		end

		%-------------------------------------------------------------------------
		function setQuietMode(bool)
			% Enable or disable quiet mode.
			import ether.log4m.Log4M;
			if (~isscalar(bool) || ~islogical(bool))
				log4M.error('Invalid flag passed to Log4M::setQuietMode()!');
				return;
			end
			log4m = Log4M.getLog4M();
			log4m.quietMode = bool;
		end

		%-------------------------------------------------------------------------
		function warn(message)
			% Send message to stderr with WARN level.
			import ether.log4m.*;
			if (Log4M.isQuietMode)
				return;
			end
			fprintf(2, '%s%s\n', Log4M.getPrefix(Level.WARN), message());
		end

	end
	
	%----------------------------------------------------------------------------
	%	Private static methods
	methods(Static, Access=private)
		%-------------------------------------------------------------------------
		function config = getDefaultConfig()
			import ether.log4m.*;
			config = Log4M.readConfig('ether');
			if isempty(config)
				config = LogConfiguration();
				config.addAppender(...
					AppenderConfiguration('root', 'ether.log4m.ConsoleAppender'));
			end
		end

		%-------------------------------------------------------------------------
		function prefix = getPrefix(logLevel, internal)
			import ether.log4m.Level;
			frames = 1;
			if exist('internal', 'var') && internal
				frames = 0;
			end
			prefix = sprintf('Log4M: %s %i ', ...
				Level.getName(logLevel), feature('GetPid'));
			if ~ismcc
				stack = dbstack(frames);
				if ~strcmp(stack(2).file, '')
					prefix = [prefix,'[',stack(2).file,']'];
				end
				prefix = sprintf('%s(%s:%i) ', prefix, stack(2).name, stack(2).line);
			end
			prefix = [prefix,'- '];
		end

		%-------------------------------------------------------------------------
		function bool = isDebugEnabled
			bool = ether.log4m.Log4M.getLog4M.enableDebug;
		end

		%-------------------------------------------------------------------------
		function bool = isQuietMode
			bool = ether.log4m.Log4M.getLog4M.quietMode;
		end

		%-------------------------------------------------------------------------
		function config = readConfig(pattern)
			import ether.log4m.*;
			configFile = [ether.getUserDir,filesep,'.',pattern,filesep,Log4M.XML_FILE];
			try
				doc = xmlread(configFile);
				fprintf(2, '%sConfiguration file read - %s\n', ...
					Log4M.getPrefix(Level.INFO, true), configFile);
				config = Log4M.parseDoc(doc);
			catch me
				fprintf(2, '%sError reading configuration - %s\n', ...
					Log4M.getPrefix(Level.ERROR, true), me.message);
				config = [];
			end
		end

		%-------------------------------------------------------------------------
		function parseAppender(node, config, loggerName)
			import ether.Xml;
			import ether.log4m.*;
			appAttrs = node.getAttributes();
			appClass = Xml.getAttrStr(appAttrs, Log4M.ATTR_CLASS);
			fprintf(2, '%s  * Appender: %s\n', ...
				Log4M.getPrefix(Level.INFO, true), appClass);
			appProps = containers.Map();
			keyValueList = node.getElementsByTagName(Log4M.NODE_KEYVALUE);
			for i=0:keyValueList.getLength-1
				kvNode = keyValueList.item(i);
				kvAttrs = kvNode.getAttributes();
				key = Xml.getAttrStr(kvAttrs, Log4M.ATTR_KEY);
				value = Xml.getAttrStr(kvAttrs, Log4M.ATTR_VALUE);
				fprintf(2, '%s    * Key: %s Value: %s\n', ...
					Log4M.getPrefix(Level.INFO, true), key, value);
				appProps(key) = value;
			end
			config.addAppender(...
				AppenderConfiguration(loggerName, appClass, appProps));
		end

		%-------------------------------------------------------------------------
		function config = parseDoc(document)
			import ether.Xml;
			import ether.log4m.*;
			rootNode = document.getDocumentElement();
			if (~strcmp(rootNode.getNodeName(), Log4M.NODE_DOC))
				throw(MException('XmlProcess', 'Incorrect document type'));
			end
			config = LogConfiguration();
			attrs = rootNode.getAttributes();
			config.debug = strcmp('true', Xml.getAttrStr(attrs, Log4M.ATTR_DEBUG));

			loggerList = rootNode.getElementsByTagName(Log4M.NODE_LOGGER);
			for i=0:loggerList.getLength-1
				Log4M.parseLogger(loggerList.item(i), config);
			end
		end

		%-------------------------------------------------------------------------
		function parseLogger(node, config)
			import ether.Xml;
			import ether.log4m.*;
			attrs = node.getAttributes();
			loggerName = Xml.getAttrStr(attrs, Log4M.ATTR_NAME);
			levelStr = Xml.getAttrStr(attrs, Log4M.ATTR_LEVEL);
			fprintf(2, '%s* Logger: %s (%s)\n', ...
				Log4M.getPrefix(Level.INFO, true), loggerName, levelStr);
			switch lower(levelStr)
				case 'trace'
					level = Level.TRACE;
				case 'debug'
					level = Level.DEBUG;
				case 'info'
					level = Level.INFO;
				case 'warn'
					level = Level.WARN;
				case 'error'
					level = Level.ERROR;
				case 'fatal'
					level = Level.FATAL;
				otherwise
					level = Level.NONE;
			end
			config.addLogger(loggerName, level);
			appenderList = node.getElementsByTagName(Log4M.NODE_APPENDER);
			for i=0:appenderList.getLength-1
				Log4M.parseAppender(appenderList.item(i), config, loggerName);
			end
		end

	end

	%----------------------------------------------------------------------------
	%	Private methods
	methods(Access=private)
		%-------------------------------------------------------------------------
		function this = Log4M()
			config = ether.log4m.Log4M.getDefaultConfig();
			this.enableDebug = config.debug;
			this.configuration = config;
		end

	end

end

