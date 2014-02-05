classdef DicomImageLoadSpecification < ether.process.LoadSpecification
	%DICOMIMAGELOADSPECIFICATION Summary of this class goes here
	%   Detailed explanation goes here

	properties
		patient = [];
	end

	properties(Access=private)
		overrideMap;
	end

	methods
		%-------------------------------------------------------------------------
		function this = DicomImageLoadSpecification(id, loaderId, targetId)
			this@ether.process.LoadSpecification(id, loaderId, targetId);
			this.type = ether.process.Xml.IMAGE;
			this.overrideMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
		end

		%-------------------------------------------------------------------------
		function addOverride(this, key, value)
			this.overrideMap(key) = value;
		end

		%-------------------------------------------------------------------------
		function value = getOverride(this, key)
			if this.overrideMap.isKey(key)
				value = this.overrideMap(key);
			else
				value = [];
			end
		end

		%-------------------------------------------------------------------------
		function map = getOverrides(this)
			if this.overrideMap.size > 0
				map = containers.Map(this.overrideMap.keys, this.overrideMap.values);
			else
				map = containers.Map('KeyType', 'char', 'ValueType', 'any');
			end
		end

		%-------------------------------------------------------------------------
		function keys = getOverrideKeys(this)
			keys = this.overrideMap.keys();
		end

	end

end

