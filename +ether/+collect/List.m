classdef List < handle
	%LIST Typesafe list of handle objects
	
	properties(SetAccess=private)
		class;
	end

	%----------------------------------------------------------------------------
	%	Public abstract methods
	methods(Abstract)
		% Insert items into the List
		%
		% Returns true if items added successfully, false otherwise.
		bool = add(this, items);

		% Clears all items from the List
		%
		% Returns array of cleared items.
		items = clear(this);

		% Retrieve items from the List
		items = get(this, idx);

		% Return the index of the item in the List
		idx = indexOf(this, items);

		% Return whether the List is empty.
		bool = isEmpty(this);

		% Remove items from the List
		%
		% Returns array of items removed.
		items = remove(this, idx);

		% Return number of items in the List
		value = size(this);

		% Return all items in the List as an array.
		items = toArray(this);

	end

	%----------------------------------------------------------------------------
	%	Public methods
	methods
		%-------------------------------------------------------------------------
		function this = List(class)
			% Construct a new List<class>.
			%
			% Throws an exception if the definition of the specified class cannot
			% be found.
			m = meta.class.fromName(class);
			if (numel(m) ~= 1)
				me = MException('Ether:List:InvalidClass', ...
					'Invalid class specification supplied: "%s"' , class);
				throw(me);
			end
			this.class = class;
		end

		%-------------------------------------------------------------------------
		function bool = addAll(this, list)
			% Add all elements of supplied list to this List.
			%
			% Returns true if elements successfully added, false otherwise.
			bool = this.add(list.toArray);
		end

		% Return type of List
		function value = type(this)
			value = this.class;
		end
	end

end

