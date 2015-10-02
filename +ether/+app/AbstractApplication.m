classdef AbstractApplication < handle
	%ABSTRACTAPPLICATION Base class for applications
	% Simple infrastructure ensures application specific data directory exists in
	% user's home directory. Automatically deletes itself on subclasses calling
	% exit().

	%----------------------------------------------------------------------------
	properties(Constant,Access=private)
		logger = ether.log4m.Logger.getLogger('ether.app.AbstractApplication');
	end

	%----------------------------------------------------------------------------
	properties(SetAccess=protected)
		productName = 'EtherAbstractApplication';
		productTag = 'ether';
	end

	%----------------------------------------------------------------------------
	methods
		%-------------------------------------------------------------------------
		function run(this)
			this.logger.info(@() sprintf('%s startup', this.productName));
			path = [ether.getUserDir,filesep,'.',this.productTag];
			if (exist(path, 'dir') ~= 7)
				[status,message,messageId] = mkdir(path);
				if ~status
					this.logger.warn(@() sprintf('%s not created. %s - %s', ...
						path, messageId, message));
				else
					this.logger.info(@() sprintf('%s created', path));
				end
			end
				
		end
	end

	%----------------------------------------------------------------------------
	methods(Access=protected)
		%-------------------------------------------------------------------------
		function exit(this)
			this.logger.info(@() sprintf('%s shutdown', this.productName));
			this.delete;
		end

	end

end

