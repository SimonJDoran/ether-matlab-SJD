classdef String
	%STRING Summary of this class goes here
	%   Detailed explanation goes here
	
	properties(SetAccess=private)
		value;
		length;
	end
	
	methods
		function this = String(value)
			dims = size(value);
			if ~(all(isa(value, 'char')) && (dims(1) == 1))
				throw(MException('Ether:String', ...
					'Constructor argument must be of type "char"'));
			end
			this.value = value;
			this.length = numel(value);
		end
	end
	
end

