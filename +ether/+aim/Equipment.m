classdef Equipment < handle
	%EQUIPMENT Summary of this class goes here
	%   Detailed explanation goes here
	
	%----------------------------------------------------------------------------
	properties
		deviceSerialNumber = '';
		manufacturerName = '';
		manufacturerModelName = '';
		softwareVersion = '';
	end
	

	%----------------------------------------------------------------------------
	methods
		function this = Equipment(jEquipment)
			this.deviceSerialNumber = char(jEquipment.getDeviceSerialNumber());
			this.manufacturerName = char(jEquipment.getManufacturerName());
			this.manufacturerModelName = char(jEquipment.getManufacturerModelName());
			this.softwareVersion = char(jEquipment.getSoftwareVersion());
		end
	end
	
end

