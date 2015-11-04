classdef (Abstract) DicomDatabase < handle
	%DICOMDATABASE Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
	end
	
	methods
		%-------------------------------------------------------------------------
		importDirectory(this, path, recurse)

		%-------------------------------------------------------------------------
		sopInst = searchInstance(this, uid)

		%-------------------------------------------------------------------------
		storeInstance(this, sopInst)

		%-------------------------------------------------------------------------
		storePatient(this, patient)
	end
	
end
