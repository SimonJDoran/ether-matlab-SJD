classdef JavaDicomDatabase < ether.dicom.DicomDatabase
	%JAVADICOMDATABASE Summary of this class goes here
	%   Detailed explanation goes here
	
	properties(Access=private)
		jdb = [];
	end
	
	methods
		function this = JavaDicomDatabase()
			this.jdb = etherj.dicom.Toolkit.getDefaultToolkit().createDicomDatabase();
		end

		%-------------------------------------------------------------------------
		function delete(this)
			if ~isempty(this.jdb)
				this.jdb.shutdown();
			end
		end

		%-------------------------------------------------------------------------
		function importDirectory(this, path, recurse)
			if ~ischar(path)
				throw(MException('Ether:DICOM:Database', 'Invalid path'));
			end
			if nargin == 2
				recurse = true;
			end
			this.jdb.importDirectory(path, recurse);
		end

		%-------------------------------------------------------------------------
		function sopInst = searchInstance(this, uid)
			jSopInst = this.jdb.searchInstance(uid);
			sopInst = ether.dicom.Toolkit.getToolkit().createSopInstance();
			sopInst.filename = char(jSopInst.getFile().getPath());
			sopInst.sopClassUid = char(jSopInst.getSopClassUid());
			sopInst.numberOfFrames = jSopInst.getNumberOfFrames();
			sopInst.instanceUid = char(jSopInst.getUid());
			sopInst.instanceNumber = jSopInst.getInstanceNumber();
			sopInst.modality = char(jSopInst.getModality());
			sopInst.seriesUid = char(jSopInst.getSeriesUid());
			sopInst.studyUid = char(jSopInst.getStudyUid());
		end

		%-------------------------------------------------------------------------
		function storeInstance(this, sopInst)
			throw(MException('Ether:DICOM:Database', 'Unsupported operation'));
		end

		%-------------------------------------------------------------------------
		function storePatient(this, patient)
			throw(MException('Ether:DICOM:Database', 'Unsupported operation'));
		end
	end
	
end
