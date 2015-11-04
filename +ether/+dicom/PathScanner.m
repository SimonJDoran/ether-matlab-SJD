classdef PathScanner < handle
	%PATHSCANNER Searches a directory heirarchy for DICOM files (SopInstances)
	%   Detailed explanation goes here
	
	%----------------------------------------------------------------------------
	properties(Constant,Access=private)
		logger = ether.log4m.Logger.getLogger('ether.dicom.PathScanner');
	end

	%----------------------------------------------------------------------------
	events
		ScanFinish
		ScanStart
		SopInstanceFound
	end

	%----------------------------------------------------------------------------
	methods
		%-------------------------------------------------------------------------
		function addPathScanListener(this, listeners)
			for ii=1:numel(listeners)
				listener = listeners(ii);
				this.addlistener('ScanStart', @listener.scanStart);
				this.addlistener('SopInstanceFound', @listener.sopInstanceFound);
				this.addlistener('ScanFinish', @listener.scanFinish);
			end
		end

		%-------------------------------------------------------------------------
		function removePathScanListener(this, listeners)
			for ii=1:numel(listeners)
				delete(listeners(ii));
			end
		end

		%-------------------------------------------------------------------------
		function [validCount,fileCount] = scan(this, pathIn, recurse)
			path = strrep(pathIn, '\', '/');
			this.logger.info(@() sprintf('Scanning %s', path));
			tic;
			fileList = ether.collect.CellArrayList('ether.String');
			if exist('recurse', 'var') ~= 1
				recurse = false;
			end
			this.buildFileList(path, fileList, recurse);
			fileCount = fileList.size;
			validCount = 0;
			this.notify('ScanStart', ether.dicom.ScanStartEvent);
			for ii=1:fileList.size
				validCount = validCount + this.scanFile(fileList.get(ii).value);
			end
			this.notify('ScanFinish', ether.dicom.ScanFinishEvent);
			elapsed = toc;
			this.logger.info(...
				@() sprintf('Scan complete in %.1fs. %d SOP instances found', ...
				elapsed, validCount));
		end
	end

	%----------------------------------------------------------------------------
	methods(Access=private)
		%-------------------------------------------------------------------------
		function buildFileList(this, path, fileList, recurse)
			import ether.File;
			import ether.String;
			this.logger.debug(@() sprintf('Building file list for: %s', path));
			contents = dir(path);
			names = arrayfun(@(x) x.name, contents, 'UniformOutput', false);
			validIdx = ~(strcmp('.', names) | strcmp('..', names));
			contents = contents(validIdx);
			fileIdx = arrayfun(@(x) ~x.isdir, contents);
			files = contents(fileIdx);
			fileFn = @(x) fileList.add(String(File.fullFile(path, x.name)));
			arrayfun(fileFn, files);
			if ~recurse
				return;
			end
			dirs = contents(~fileIdx);
			dirFn = @(x) this.buildFileList(File.fullFile(path, x.name), ...
				fileList, recurse);
			arrayfun(dirFn, dirs);
		end

		%-------------------------------------------------------------------------
		function valid = scanFile(this, file)
			this.logger.trace(@() sprintf('Reading: %s', file));
			valid = 0;
			sopInst = ether.dicom.Toolkit.getToolkit().createSopInstance();
			[bool,msg] = sopInst.read(file);
			if bool
				event = ether.dicom.SopInstanceFoundEvent(sopInst);
				this.notify('SopInstanceFound', event);
				valid = 1;
				sopInst.unload;
			else
				this.logger.info(@() sprintf('Cannot read %s: %s', file, msg));
			end
		end
	end
	
end

