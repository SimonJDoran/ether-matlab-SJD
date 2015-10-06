function string = formatException(ex)
%FORMATEXCEPTION Formats exception as string
%   Detailed explanation goes here
	string = sprintf('%s: %s', ex.identifier, ex.message);
	for ii=1:numel(ex.stack)
		string = sprintf('%s\n  at %s (%s:%d)', string, ex.stack(ii).name, ...
			strrep(ex.stack(ii).file, '\', '/'), ex.stack(ii).line);
	end

end

