function path = getUserDir()
%GETUSERDIR Summary of this function goes here
%   Detailed explanation goes here

	if ispc()
		path = getenv('USERPROFILE');
	else
		path = getenv('HOME');
	end

end

