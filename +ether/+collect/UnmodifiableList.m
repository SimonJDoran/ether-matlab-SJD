classdef UnmodifiableList < ether.collect.List
	%UNMODIFIABLELIST Summary of this class goes here
	%   Detailed explanation goes here

	properties(Access=private)
		list;
	end

	%----------------------------------------------------------------------------
	%	Public methods
	methods
		%-------------------------------------------------------------------------
		function this = UnmodifiableList(listIn)
			this@ether.collect.List(listIn.type());
			if (~isa(listIn, 'ether.collect.List'))
				throw(MException('Ether:List:IllegalArgument', ...
					'Argument is not a valid List'));
			end
			this.list = listIn;
		end

		%-------------------------------------------------------------------------
		function bool = add(this, items)
			bool = false;
			throw(MException('Ether:List:Unmodifiable', ...
				'Attempt to modify UnmodifiableList'));
		end

		%-------------------------------------------------------------------------
		function items = clear(this)
			items = [];
			throw(MException('Ether:List:Unmodifiable', ...
				'Attempt to modify UnmodifiableList'));
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
			items = this.list.get(idx);
		end

		%-------------------------------------------------------------------------
		function idx = indexOf(this, item)
			idx = this.list.indexOf(item);
		end

		%-------------------------------------------------------------------------
		function bool = isEmpty(this)
			bool = this.list.isEmpty();
		end

		%-------------------------------------------------------------------------
		function items = remove(this, idx)
			items = [];
			throw(MException('Ether:List:Unmodifiable', ...
				'Attempt to modify UnmodifiableList'));
		end

		%-------------------------------------------------------------------------
		function value = size(this)
			value = this.list.size();
		end

		%-------------------------------------------------------------------------
		function items = toArray(this)
			if strcmp(this.class, 'char')
				throw(MException('Ether:Collect:List', ...
					'Cannot create regular array of type "char" without concatenation. Use toCellArray()'));
			end
			items = [this.array{1:this.nCell}];
		end

		%-------------------------------------------------------------------------
		function items = toCellArray(this)
			items = {this.array{1:this.nCell}};
		end

	end

end

