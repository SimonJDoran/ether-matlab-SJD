function dcmDbImport(directory, recurse)
%DCMDBIMPORT Import any DICOM files in the directory to the local database.
%   Detailed explanation goes here

	if (~isdir(directory))
		throw(MException('Ether:DICOM', ...
			sprintf('No such directory: %s', directory)));
	end
	if ((nargin == 1) || ~(islogical(recurse) && isscalar(recurse)))
		recurse = true;
	end

	jDcmKit = icr.etherj.dicom.DicomToolkit.getToolkit();
	dcmDb = jDcmKit.createDicomDatabase();
	dcmDb.importDirectory(directory, recurse);
	dcmDb.shutdown();

end

