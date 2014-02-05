classdef PoolUser < handle
	%POOLUSER Summary of this class goes here
	%   Detailed explanation goes here

	properties(SetObservable)
		autoStartPool = true;
		usePool = true;
	end

	methods
		%-------------------------------------------------------------------------
		function bool = needPool(this)
			bool = this.usePool;
		end

	end

	methods(Access=protected)
		%-------------------------------------------------------------------------
		function poolSize = initPool(this)
			if ~this.usePool
				poolSize = 0;
				return;
			end
			poolSize = ether.parallel.Pool.start;
		end
	end

end

