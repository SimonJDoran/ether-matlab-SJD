function bool = startsWith(str, prefix)
%STARTSWITH Determine if one string starts with another
%   Detailed explanation goes here

	found = strfind(str, prefix);
	bool = (numel(found) == 1) && (found == 1);

end

