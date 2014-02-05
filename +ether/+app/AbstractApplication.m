classdef AbstractApplication < handle
	%ABSTRACTAPPLICATION Summary of this class goes here
	% Detailed explanation goes here

	properties(Constant,Access=private)
		logger = ether.log4m.Logger.getLogger('ether.app.AbstractApplication');
	end

	properties(SetAccess=protected)
		productName = 'EtherAbstractApplication';
		productTag = 'ether';
	end

	methods
		%-------------------------------------------------------------------------
		function run(this)
			this.logger.info(@() sprintf('%s startup', this.productName));
		end
	end

	methods(Access=protected)
		%-------------------------------------------------------------------------
		function exit(this)
			this.logger.info(@() sprintf('%s shutdown', this.productName));
			this.delete;
		end

	end

end

