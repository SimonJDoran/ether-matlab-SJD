classdef DicomObject < handle
	%DICOMOBJECT Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
	end
	
	methods(Abstract)
		%-------------------------------------------------------------------------
		[item,error,message] = getSequenceItem(this, seqPath, idx)
		% Returns the item at index idx for the SQ given by seqPath
		%   seqPath must be pairs of (sequence tag,index) finishing with an SQ tag

		%-------------------------------------------------------------------------
		[value,error,message] = getSequenceItemCount(this, seqPath)
		% Returns the item count for the SQ given by seqPath
		%   seqPath must be odd length array of pairs of (sequence tag,index)
		%   finishing with an SQ tag

		%-------------------------------------------------------------------------
		[value,error,message] = getSequenceValue(this, seqPath, tag)
		% Returns the item count for the SQ given by seqPath
		%   seqPath must be even length array of pairs of (sequence tag,index)

		%-------------------------------------------------------------------------
		[value,error,message] = getValue(this, tag)

		%-------------------------------------------------------------------------
		[vm,error,message] = getVM(this, tag)

		%-------------------------------------------------------------------------
		[vr,error,message] = getVR(this, tag)

	end
	
end

