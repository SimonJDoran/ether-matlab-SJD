classdef Thing < handle
	%THING Named entity

	properties
		name;
	end

	methods(Static)
		function array = make(nThings)
			array = ether.Thing.empty(nThings, 0);
			for i=1:nThings
				array(i) = ether.Thing(num2str(i));
			end
		end
	end

	methods
		function this = Thing(name)
			this.name = name;
		end

		function display(this)
			fprintf('Thing: %s\n', this.name);
		end

		function value = toString(this)
			value = sprintf('Thing: %s', this.name);
		end
	end
	
end

