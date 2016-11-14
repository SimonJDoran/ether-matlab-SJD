classdef Code < handle
	%CODE Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
		code = '';
		codeSystem = '';
		codeSystemName = '';
		codeSystemVersion = '';
	end
	
	methods
		function this = Code(jCode)
			this.code = char(jCode.getCode());
			this.codeSystem = char(jCode.getCodeSystem());
			this.codeSystemName = char(jCode.getCodeSystemName());
			this.codeSystemVersion = char(jCode.getCodeSystemVersion());
		end
	end
	
end

