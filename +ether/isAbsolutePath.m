function [bool, hasDrive] = isAbsolutePath(path)
%ISABSOLUTEPATH Determine if the supplied path is absolute
%   Absolute path: /some/dir/file, relative path: some/dir/file. Windows
%   absolute paths may start with a drive specification: C:\some\dir\file

	if ~ispc()
		bool = ether.startsWith(path, filesep);
		hasDrive = false;
		return;
	end

	driveSearch = regexpi(path, '^[a-z]:[\\//]');
	hasDrive = (numel(driveSearch) == 1) && (driveSearch == 1);
	if hasDrive
		bool = true;
		return;
	end
	bool = ether.startsWith(path, filesep);

end

