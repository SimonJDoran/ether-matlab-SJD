classdef CellArrayList < ether.collect.List
	%CELLARRAYLIST List implemented with a CellArray
	
	%----------------------------------------------------------------------------
	%	Private constant properties
	properties(Constant)
		INITIAL_SIZE = 10;
	end

	%----------------------------------------------------------------------------
	%	Private properties
	properties(Access=private)
		array;
		nCell = 0;
		capacity = 0;
	end

	%----------------------------------------------------------------------------
	%	Public methods
	methods
		%-------------------------------------------------------------------------
		function this = CellArrayList(class)
			if strcmp(class, 'char')
				throw(MException('Ether:Collect:List', ...
					'Incompatible class. Use ether.String instead of class "char"'));
			end
			% Construct a new CellArrayList<class>.
			this@ether.collect.List(class);
			this.array = cell(ether.collect.CellArrayList.INITIAL_SIZE, 1);
			this.capacity = numel(this.array);
		end

		%-------------------------------------------------------------------------
		function add(this, items)
			if isempty(items)
				return;
			end
			if ~(all(isa(items, this.class)))
				me = MException('Ether:List:InvalidClass', ...
					'Supplied items do not match specified content class for List');
				throw(me);
			end
			nItems = numel(items);
			if (this.nCell+nItems > this.capacity)
				this.resize(nItems);
			end
			startIdx = this.nCell;
			for i=1:nItems
				this.array{startIdx+i} = items(i);
			end
			this.nCell = this.nCell + nItems;
		end

		%-------------------------------------------------------------------------
		function items = clear(this)
			items = [this.array{:}];
			this.array = cell(ether.collect.CellArrayList.INITIAL_SIZE, 1);
			this.capacity = numel(this.array);
			this.nCell = 0;
		end

		%-------------------------------------------------------------------------
		function display(this)
			if (isempty(this))
				fprintf('0x0 CellArrayList<?>\n');
				return;
			end
			fprintf('List<%s>\n', this.type);
			for i=1:this.nCell
				fprintf('  [%i] - ', i);
				display(this.array{i});
			end
		end

		%-------------------------------------------------------------------------
		function items = get(this, idx)
			if all(isnumeric(idx))
				if ~(all(idx > 0) && all(idx <= this.nCell))
					me = MException('Ether:List:IndexOutOfBounds', ...
						'Indices must be 1 < idx < List.size()');
					throw(me);
				end
			else
				if all(islogical(idx))
					if numel(idx) ~= this.nCell
						me = MException('Ether:List:InvalidIndex', ...
							'Logical indices must match list length');
						throw(me);
					end
				else
					me = MException('Ether:List:InvalidIndex', ...
						'Indices non-numeric');
					throw(me);
				end
			end
			cells = this.array(idx);
			% Return non-cell array as all items known to be of type
			% this.class
			items = [cells{:}];
		end

		%-------------------------------------------------------------------------
		function idx = indexOf(this, item)
			idx = find(cellfun(@(c) isequal(c, item), this.array));
		end

		%-------------------------------------------------------------------------
		function bool = isEmpty(this)
			bool = this.nCell == 0;
		end

		%-------------------------------------------------------------------------
		function items = remove(this, idx)
			items = this.get(idx);
			uniqIdx = unique(idx);
			nIdx = numel(uniqIdx);
			for i=1:nIdx
				fprintf('CellArrayList::remove() - idx=%i\n', uniqIdx(i));
				this.array{uniqIdx(i)} = [];
				this.array(uniqIdx(i):this.nCell) = ...
					circshift(this.array(uniqIdx(i):this.nCell), -1);
				uniqIdx = uniqIdx - 1;
				this.nCell = this.nCell - 1;
			end
		end

		%-------------------------------------------------------------------------
		function value = size(this)
			value = this.nCell;
		end

		%-------------------------------------------------------------------------
		function items = toArray(this)
			items = [this.array{1:this.nCell}];
		end

		%-------------------------------------------------------------------------
		function items = toCellArray(this)
			items = {this.array{1:this.nCell}};
		end

	end

	%----------------------------------------------------------------------------
	%	Private methods
	methods(Access=private)
		function resize(this, nItems)
			% Add sufficient multiples of current capacity to accomodate
			% nItems
			nExtra = ceil(nItems/this.capacity)*this.capacity;
			this.array = [this.array;cell(nExtra,1)];
			this.capacity = this.capacity+nExtra;
		end
	end
end

