classdef File
	%FILE Collection of static file functions
	%   Detailed explanation goes here

	%----------------------------------------------------------------------------
	properties
	end

	%----------------------------------------------------------------------------
	methods(Static)
		%-------------------------------------------------------------------------
		function out = fixPath(in)
			out = strrep(in, '\', '/');
		end

		%-------------------------------------------------------------------------
		function out = fullFile(varargin)
			out = ether.File.fixPath(fullfile(varargin{:}));
		end

	end

	%----------------------------------------------------------------------------
	methods(Access=private)
		%-------------------------------------------------------------------------
		function this = File()
		end
	end

end

