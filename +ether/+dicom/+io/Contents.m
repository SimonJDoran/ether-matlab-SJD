% +IO
%
% Files
%   ConsoleDumpScanListener - Prints SOP class and file name of each SopInstance
%   DicomReceiver           - Builds PatientRoot from SopInstances
%   PathScanListener        - Interface: Listens to SopInstanceFound events emitted by PathScanner
%   PathScanner             - Searches a directory heirarchy for DICOM files (SopInstances)
%   SopInstanceFoundEvent   - Event emitted by PathScanner, wraps SopInstance
