classdef MapSet < ether.collect.Set
	%MAPSET Implementation of Set using containers.Map
	%   Detailed explanation goes here
	
	%----------------------------------------------------------------------------
	properties(Access=private)
		map;
	end
	
	%----------------------------------------------------------------------------
	methods
		%-------------------------------------------------------------------------
		function this = MapSet()
			this.map = containers.Map();
		end

		%-------------------------------------------------------------------------
		function bool = add(this, item)
			bool = true;
			this.map(item) = [];
		end

		%-------------------------------------------------------------------------
		function items = clear(this)
			items = this.map.keys;
			this.map.remove(items);
		end

		%-------------------------------------------------------------------------
		function bool = contains(this, item)
			bool = this.map.isKey(item);
		end

		%-------------------------------------------------------------------------
		function bool = isEmpty(this)
			bool = this.map.length == 0;
		end

		%-------------------------------------------------------------------------
		function bool = remove(this, item)
			bool = this.map.isKey(item);
			if bool
				this.map.remove(item);
			end
		end

		%-------------------------------------------------------------------------
		function value = size(this)
			value = this.map.length;
		end

		%-------------------------------------------------------------------------
		function items = toArray(this)
			items = this.map.keys;
		end

	end
	
end

