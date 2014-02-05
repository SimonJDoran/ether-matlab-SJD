function bool = startsWith(str, prefix)
%STARTSWITH Summary of this function goes here
%   Detailed explanation goes here

	found = strfind(str, prefix);
	bool = (numel(found) == 1) && (found == 1);

end

