classdef (Abstract) Set < handle
	%SET Interface defining a Set
	%   A collection that contains no more than one of any item
	
	properties
	end
	
	methods
		% Insert item into the Set
		%
		% Returns true if items added successfully
		bool = add(this, item);

		% Clears all items from the Set
		%
		% Returns array of cleared items
		items = clear(this);

		% Determine if item is in Set
		%
		% Returns true if item is in Set
		bool = contains(item);

		% Determine if the Set is empty
		bool = isEmpty(this);

		% Remove item from the Set
		%
		% Returns true if item removed
		bool = remove(this, item);

		% Determine size of Set
		%
		% Returns number of items in the Set
		value = size(this);

		% Convert Set to array
		%
		% Returns all items in the Set as an array
		items = toArray(this);
	end
	
end

