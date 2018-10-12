classdef ImageStudy < handle
	%IMAGESTUDY Summary of this class goes here
	%   Detailed explanation goes here
	
	properties(SetAccess=private)
		imageSeries = [];
		instanceUid = '';
		startDate = '';
		startTime = '';
	end
	
	%----------------------------------------------------------------------------
	properties(Access=private)
		javaStudy = [];
	end

	methods
		function this = ImageStudy(jStudy)
			if (numel(jStudy) ~= 1) || ~isa(jStudy, 'icr.etherj.aim.ImageStudy')
				return;
			end
			this.javaStudy = jStudy;
			this.instanceUid = char(jStudy.getInstanceUid());
			this.startDate = char(jStudy.getStartDate());
			this.startTime = char(jStudy.getStartTime());
			jSeries = jStudy.getSeries();
			this.imageSeries = ether.aim.ImageSeries(jSeries);
		end
	end
	
end

