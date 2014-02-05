classdef PathScanner < handle
	%PATHSCANNER Summary of this class goes here
	%   Detailed explanation goes here
	
	properties(Constant,Access=private)
		logger = ether.log4m.Logger.getLogger('ether.dicom.io.PathScanner');
	end

	events
		SopInstanceFound
	end

	methods
		%-------------------------------------------------------------------------
		function addPathScanListener(this, listeners)
			for ii=1:numel(listeners)
				listener = listeners(ii);
				this.addlistener('SopInstanceFound', @listener.sopInstanceFound);
			end
		end

		%-------------------------------------------------------------------------
		function removePathScanListener(this, listeners)
			for ii=1:numel(listeners)
				this.delete(listeners(ii));
			end
		end

		%-------------------------------------------------------------------------
		function [validCount,fileCount] = scan(this, path, recurse)
			this.logger.info(@() sprintf('Scanning %s', path));
			tic;
			fileList = ether.collect.CellArrayList('ether.String');
			this.buildFileList(path, fileList, recurse);
			fileCount = fileList.size;
			validCount = 0;
			for ii=1:fileList.size
				validCount = validCount + this.scanFile(fileList.get(ii).value);
			end
			elapsed = toc;
			this.logger.info(...
				@() sprintf('Scan complete in %.1fs. %d SOP instances found', ...
				elapsed, validCount));
		end
	end

	methods(Access=private)
		%-------------------------------------------------------------------------
		function buildFileList(this, path, fileList, recurse)
			import ether.String;
			this.logger.debug(@() sprintf('Building file list for: %s', path));
			contents = dir(path);
			names = arrayfun(@(x) x.name, contents, 'UniformOutput', false);
			validIdx = ~(strcmp('.', names) | strcmp('..', names));
			contents = contents(validIdx);
			fileIdx = arrayfun(@(x) ~x.isdir, contents);
			files = contents(fileIdx);
			fileFn = @(x) fileList.add(String(fullfile(path, x.name)));
			arrayfun(fileFn, files);
			if ~recurse
				return;
			end
			dirs = contents(~fileIdx);
			dirFn = @(x) this.buildFileList(fullfile(path, x.name), fileList, ...
				recurse);
			arrayfun(dirFn, dirs);
		end

		%-------------------------------------------------------------------------
		function valid = scanFile(this, file)
			this.logger.trace(@() sprintf('Reading: %s', file));
			valid = 0;
			sopInst = ether.dicom.Toolkit.getToolkit().createSopInstance();
			[bool,msg] = sopInst.read(file);
			if bool
				event = ether.dicom.io.SopInstanceFoundEvent(sopInst);
				this.notify('SopInstanceFound', event);
				valid = 1;
			else
				this.logger.info(@() sprintf('Cannot read %s: %s', file, msg));
			end
		end
	end
	
end

