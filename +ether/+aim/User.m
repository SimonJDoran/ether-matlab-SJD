classdef User < handle
	%USER Summary of this class goes here
	%   Detailed explanation goes here
	
	%----------------------------------------------------------------------------
	properties
		name = '';
		loginName = '';
		numberWithinRoleOfClinicalTrial = 0;
		roleInTrial = '';
	end
	
	%----------------------------------------------------------------------------
	methods
		function this = User(jUser)
			this.name = char(jUser.getName());
			this.loginName = char(jUser.getLoginName());
			this.numberWithinRoleOfClinicalTrial = ...
				jUser.getNumberWithinRoleOfClinicalTrial();
			this.roleInTrial = char(jUser.getRoleInTrial());
		end
	end
	
end

