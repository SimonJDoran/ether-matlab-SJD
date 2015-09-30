classdef RollingFileAppender < ether.log4m.Appender
	%ROLLINGFILEAPPENDER Summary of this class goes here
	%   Detailed explanation goes here
	
	%----------------------------------------------------------------------------
	properties
		% The maximum index of files to retain.
		maxBackupIndex = 9;
		% The maximum size of a file in bytes before rollover is triggered.
		maxFileSize = 10*2^20;
	end

	%----------------------------------------------------------------------------
	properties(SetAccess=private)
		% The filename to log to.
		filename;
	end

	%----------------------------------------------------------------------------
	properties(Access=private)
		count = 0;
		fileID = -1;
	end

	%----------------------------------------------------------------------------
	%	Public methods
	methods
		%-------------------------------------------------------------------------
		function this = RollingFileAppender(filename)
			this.name = 'RollingFile';
			if ~ether.isAbsolutePath(filename)
				absPath = fullfile(ether.getUserDir(), filename);
			else
				absPath = filename;
			end
			this.filename = absPath;
			ether.log4m.Log4M.debug(...
				sprintf('RollingFileAppender: %s', this.filename));
			this.open('a');
			this.count = 0;
		end

		%-------------------------------------------------------------------------
		function set.maxBackupIndex(this, maxBackupIndex)
			if ~isinteger(maxBackupIndex) || maxBackupIndex < 0 || maxBackupIndex > 99
				return;
			end
			this.maxBackupIndex = maxBackupIndex;
		end

		%-------------------------------------------------------------------------
		function set.maxFileSize(this, maxFileSize)
			if ~isinteger(maxFileSize) || maxFileSize < 1024 || maxFileSize > 2^30
				return;
			end
			this.maxFileSize = maxFileSize;
		end

		%-------------------------------------------------------------------------
		function append(this, message)
			if (this.fileID == -1)
				ether.log4m.Log4M.error(...
					sprintf('Cannot write to %s', this.filename));
				return;
			end
			fprintf(this.fileID, [message,'\n']);
			this.count = this.count+1;
			if this.count > 10
				this.count = 0;
				fileDir = dir(this.filename);
				if fileDir.bytes > this.maxFileSize
					this.rollOver();
				end
			end
		end

		%-------------------------------------------------------------------------
		function close(this)
			if (this.fileID == -1)
				return;
			end
			fclose(this.fileID);
			this.fileID = -1;
		end

		%-------------------------------------------------------------------------
		function delete(this)
			this.close;
		end
	end

	%----------------------------------------------------------------------------
	%	Private methods
	methods(Access=private)
		%-------------------------------------------------------------------------
		function open(this, mode)
			dirName = fileparts(this.filename);
			% Ensure parent directory exists
			if ~(exist(dirName, 'dir'))
				[fOk,error] = mkdir(dirName);
				if ~fOk
					ether.log4m.Log4M.error(...
						sprintf('Cannot create %s: %s', dirName, error));
					return;
				end
			end
			[id,error] = fopen(this.filename, mode, 'native', 'UTF-8');
			if (id == -1)
				ether.log4m.Log4M.error(...
					sprintf('Error opening %s: %s', this.filename, error));
			end
			this.fileID = id;
		end

		%-------------------------------------------------------------------------
		function rollOver(this)
			import ether.log4m.*;
			Log4M.debug(...
				@() sprintf('Rollover triggered for %s', this.filename));
			status = fclose(this.fileID);
			if status ~= 0
				Log4M.error(sprintf('Failed to close file %s with ID %i', ...
					this.filename, this.fileID));
				return;
			end

			% Backups disabled if maxBackupIndex is zero
			if this.maxBackupIndex == 0
				this.open('w');
				return;
			end

			% Shuffle the files along one index
			[path,name,ext] = fileparts(this.filename);
			stub = [path,filesep,name];
			fileList = arrayfun(@(int) {sprintf('%s.%i%s', stub, int, ext)}, ...
				1:this.maxBackupIndex);
			fileList = {this.filename, fileList{:}};
			if (exist(fileList{end}, 'file') == 2)
				delete(fileList{end});
			end
			for idx = numel(fileList):-1:2
				if ~(exist(fileList{idx-1}, 'file') == 2)
					continue
				end
				[fOk,message] = movefile(fileList{idx-1}, fileList{idx});
				if ~fOk
					ether.log4m.Log4M.error(sprintf('Failed to move file (%s): %s', ...
						this.filename, message));
				end
			end
			this.open('w');
		end
	end
	
end

