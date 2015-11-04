classdef ConsoleDumpScanListener < ether.dicom.PathScanListener
	%CONSOLEDUMPSCANLISTENER Prints SOP class and file name of each SopInstance
	%   Detailed explanation goes here

	%----------------------------------------------------------------------------
	properties
	end

	%----------------------------------------------------------------------------
	methods
		%-------------------------------------------------------------------------
		function sopInstanceFound(~, ~, data)
			sopInst = data.sopInstance;
			sopClass = ether.dicom.UID.nameOf(sopInst.sopClassUid);
			if isempty(sopClass)
				sopClass = sprintf('Unknown SOP Class UID: %s', sopInst.sopClassUid);
			end
			fprintf('SOP Instance (%s): %s\n', sopClass, sopInst.filename);
		end
	end

end
