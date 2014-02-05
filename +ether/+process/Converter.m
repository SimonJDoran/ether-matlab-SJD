classdef Converter < ether.parallel.PoolUser
	%CONVERTER Summary of this class goes here
	%   Detailed explanation goes here

	properties(SetObservable)
		useVectors = false;
	end

	properties(SetAccess=protected)
		name = 'Undefined';
		description = 'Undefined';
		inputCountMax = 0;
		inputCountMin = 0;
		inputDescriptions = {};
		inputTypes = {};
		outputType = 'Undefined';
		outputDisplayMax = 0;
		outputDisplayMin = 0;
		requiredKeys = {};
		units = '';
	end

	properties(Access=private)
		outputMap;
	end

	events
		VectorUseChanged
	end

	methods(Abstract)
		%-------------------------------------------------------------------------
		result = convert(this, varargin);

	end

	methods
		%-------------------------------------------------------------------------
		function this = Converter()
			this.outputMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
		end

		%-------------------------------------------------------------------------
		function bool = needPool(this)
			bool = this.usePool && this.useVectors;
		end

	end

	methods(Sealed)
		%-------------------------------------------------------------------------
		function types = getOutputTypes(this)
			if this.outputMap.Count > 0
				keys = this.outputMap.keys;
				types = {this.outputType, keys{:}};
			else
				types = {this.outputType};
			end
		end

		%-------------------------------------------------------------------------
		function converter = getConverterForType(this, type)
			converter = [];
			if strcmp(type, this.outputType)
				converter = this;
			elseif this.outputMap.isKey(type)
				converter = this.outputMap(type);
			end
		end
	end

	methods(Sealed,Access=protected)
		%-------------------------------------------------------------------------
		function register(this, converter)
			if ~isa(converter.outputType, 'char') || ...
				~isa(converter, 'ether.process.Converter')
				throw(MException('Ether:Process:Converter', ...
					'Invalid input arguments'));
			end
			this.outputMap(converter.outputType) = converter;
		end

		%-------------------------------------------------------------------------
		function registerAll(this, converter)
			if ~isa(converter.outputType, 'char') || ...
				~isa(converter, 'ether.process.Converter')
				throw(MException('Ether:Process:Converter', ...
					'Invalid input arguments'));
			end
			types = converter.getOutputTypes;
			for ii=1:numel(types)
				this.register(types{ii}, converter.getConverterForType(types{ii}));
			end
		end

		%-------------------------------------------------------------------------
		function [gradient,intercept] = regressBulk(~, x, y)
			% y = dependent data reshaped as previously
			% x = independent data reshaped to match y
			% will perform linear regression between columns of y and columns of x
			[m,n] = size(y);

			g1g1 = m*ones(1,n);
			g2g2 = sum(x.^2);
			g1g2 = sum(x);

			g1y = sum(y);
			g2y = sum(x.*y);

			den = g1g1.*g2g2 - g1g2.^2;
			intercept = (g2g2.*g1y - g1g2.*g2y)./den;
			gradient = (g1g1.*g2y - g1g2.*g1y)./den;
		end

	end

end

