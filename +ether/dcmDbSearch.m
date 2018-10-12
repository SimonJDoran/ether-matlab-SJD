function result = dcmDbSearch(searchStr)
%DCMDBSEARCH Summary of this function goes here
%   Detailed explanation goes here

	if (~ischar(searchStr))
		throw(MException('Ether:DICOM', 'Search input must be a string'));
	end

	jDcmKit = icr.etherj.dicom.DicomToolkit.getToolkit();
	dcmDb = jDcmKit.createDicomDatabase();
	jPatientRoot = dcmDb.search(searchStr);
	etherDcmKit = ether.dicom.Toolkit.getToolkit();
	result = etherDcmKit.createPatientRoot(jPatientRoot).getAllPatients();
	dcmDb.shutdown();
	
end

