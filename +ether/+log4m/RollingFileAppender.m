classdef RollingFileAppender < ether.log4m.Appender
	%ROLLINGFILEAPPENDER Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
		% The filename to log to.
		filename;
		% The maximum index of files to retain.
		maxBackupIndex = 9;
		% The maximum size of a file in bytes before rollover is triggered.
		maxFileSize = 10*2^20;
	end

	properties(Access=private)
		fileID = -1;
	end

	methods
		function this = RollingFileAppender(filename)
			this.filename = filename;
			this.fileID = fopen(filename, 'a', 'native', 'UTF-8');
			if (this.fileID == -1)
				ether.log4m.Log4M.error(...
					sprintf('Error opening %s', this.filename));
			end
		end

		function set.filename(this, filename)
			this.filename = filename;
		end

		function set.maxBackupIndex(this, maxBackupIndex)
			this.maxBackupIndex = maxBackupIndex;
		end

		function set.maxFileSize(this, maxFileSize)
			this.maxFileSize = maxFileSize;
		end

		function append(this, message)
			if (this.fileID == -1)
				ether.log4m.Log4M.error(...
					sprintf('Cannot write to %s', this.filename));
				return;
			end
			fprintf(this.fileID, message);
		end

		function close(this)
			if (this.fileID == -1)
				return;
			end
			fclose(this.fileID);
			this.fileID = -1;
		end

		function delete(this)
			this.close;
		end
	end

	methods(Access=private)
		function rollOver(this)
			ether.log4m.Log4M.debug(...
				sprintf('Rollover triggered for %s', this.filename));
		end
	end
	
end

