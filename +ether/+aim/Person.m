classdef Person < handle
	%PERSON Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
		birthDate = '00000000';
		ethnicGroup = '';
		id = '';
		name = '';
		sex = '';
	end

	properties(Access=private)
		javaPerson = [];
	end
	
	methods
		function this = Person(jPerson)
			if (numel(jPerson) ~= 1) || ~isa(jPerson, 'icr.etherj.aim.Person')
				return;
			end
			this.javaPerson = jPerson;
			this.birthDate = char(jPerson.getBirthDate());
			this.ethnicGroup = char(jPerson.getEthnicGroup());
			this.id = char(jPerson.getId());
			this.name = char(jPerson.getName());
			this.sex = char(jPerson.getSex());
		end
	end
	
end

