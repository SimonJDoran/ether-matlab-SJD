function bool = endsWith(str, suffix)
%ENDSWITH Determine if one string ends with another
%   Detailed explanation goes here

	found = strfind(str, suffix);
	bool = (numel(found) == 1) && (found == numel(str)-numel(suffix)+1);

end

