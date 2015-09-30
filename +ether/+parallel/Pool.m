classdef Pool < handle
	%POOL Summary of this class goes here
	%   Detailed explanation goes here

	properties(Constant,Access=private)
		pool = ether.parallel.Pool();
		logger = ether.log4m.Logger.getLogger('ether.parallel.Pool');
	end

	properties(Access=private)
		enabled = true;
	end

	methods(Static)
		function disable()
			ether.parallel.Pool.pool.enabled = false;
		end

		function enable()
			ether.parallel.Pool.pool.enabled = true;
		end

		function bool = isEnabled()
			bool = ether.parallel.Pool.pool.enabled;
		end

		function poolSize = size()
			poolSize = 0;
			currPool = gcp('nocreate');
			if ~isempty(currPool)
				poolSize = currPool.NumWorkers;
			end
		end

		function [poolSize,enabled] = start()
			enabled = ether.parallel.Pool.pool.enabled;
			poolSize = 0;
			if ~enabled
				return;
			end
			% Launch the default local pool if no pool found.
			currPool = gcp();
			if ~isempty(currPool)
				poolSize = currPool.NumWorkers;
			end
		end

		function stop()
			delete(gcp('nocreate'));
		end
	end
	
end

