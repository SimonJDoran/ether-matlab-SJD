classdef ConsoleDumpScanListener < ether.dicom.io.PathScanListener
	%CONSOLEDUMPSCANLISTENER Summary of this class goes here
	%   Detailed explanation goes here

	properties
	end

	methods
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

