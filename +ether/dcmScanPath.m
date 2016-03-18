function result = dcmScanPath(directory, recurse)
%DCMSCANPATH Summary of this function goes here
%   Detailed explanation goes here

	if (~isdir(directory))
		throw(MException('Ether:DICOM', ...
			sprintf('No such directory: %s', directory)));
	end
	if ((nargin == 1) || ~(islogical(recurse) && isscalar(recurse)))
		recurse = true;
	end

	jDcmKit = etherj.dicom.DicomToolkit.getToolkit();
	pathScan = jDcmKit.createPathScan();
	rx = etherj.dicom.DicomReceiver();
	pathScan.addContext(rx);
	pathScan.scan(directory, recurse);
	etherDcmKit = ether.dicom.Toolkit.getToolkit();
	result = etherDcmKit.createPatientRoot(rx.getPatientRoot()).getAllPatients();

end

