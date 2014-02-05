classdef Process < ether.parallel.PoolUser
	%PROCESSOR Summary of this class goes here
	%   Detailed explanation goes here

	properties(Constant,Access=private)
		logger = ether.log4m.Logger.getLogger('ether.process.Process');
	end

	properties
		label = [];
	end

	properties(SetAccess=private)
		loaded@logical = false;
		processed@logical = false;
	end

	properties(Access=private)
		entityMap;
		ivMap;
		loaderMap;
		loadSpecMap;
		loadSpecTargetMap;
		probResultMap;
		procMap;
	end

	methods
		%-------------------------------------------------------------------------
		function this = Process()
			this.entityMap = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
			this.ivMap = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
			this.loaderMap = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
			this.loadSpecMap = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
			this.loadSpecTargetMap = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
			this.probResultMap = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
			this.procMap = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
		end

		%-------------------------------------------------------------------------
		function entityIds = addEntities(this, entities)
			entityIds = [];
			for ii=1:numel(entities)
				entity = entities(ii);
				if ~isa(entity, 'ether.process.Entity')
					continue;
				end
				if (this.entityMap.isKey(entity.id))
					prevEntity = this.entityMap(entity.id);
					this.logger.warn(...
						@() sprintf('Process replacing existing Entity with id=%i: %s (%s)', ...
							entity.id, class(prevEntity), class(prevEntity.entity)));
				end
				this.entityMap(entity.id) = entity;
				entityIds = [entityIds;entity.id];
			end
		end

		%-------------------------------------------------------------------------
		function ivIds = addImageVolumes(this, ivs)
			ivIds = [];
			for ii=1:numel(ivs)
				iv = ivs(ii);
				if ~isa(iv, 'ether.process.ImageVolume')
					continue;
				end
				this.ivMap(iv.id) = iv;
				ivIds = [ivIds;iv.id];
			end
		end

		%-------------------------------------------------------------------------
		function loaderIds = addLoaders(this, loaders)
			loaderIds = [];
			for ii=1:numel(loaders)
				loader = loaders(ii);
				if ~isa(loader, 'ether.process.Loader')
					continue;
				end
				this.loaderMap(loader.id) = loader;
				loaderIds = [loaderIds;loader.id];
			end
		end

		%-------------------------------------------------------------------------
		function loadSpecIds = addLoadSpecifications(this, loadSpecs)
			loadSpecIds = [];
			for ii=1:numel(loadSpecs)
				loadSpec = loadSpecs(ii);
				if ~isa(loadSpec, 'ether.process.LoadSpecification')
					continue;
				end
				this.loadSpecMap(loadSpec.id) = loadSpec;
				this.loadSpecTargetMap(loadSpec.targetId) = loadSpec;
				loadSpecIds = [loadSpecIds;loadSpec.id];
			end
		end

		%-------------------------------------------------------------------------
		function resultIds = addProblemResults(this, results)
			resultIds = [];
			for ii=1:numel(results)
				result = results(ii);
				if ~isa(result, 'ether.process.ProblemResult')
					continue;
				end
				this.probResultMap(result.id) = result;
				resultIds = [resultIds;result.id];
			end
		end

		%-------------------------------------------------------------------------
		function procIds = addProcessors(this, processors)
			procIds = [];
			for ii=1:numel(processors)
				proc = processors(ii);
				if ~isa(proc, 'ether.process.Processor')
					continue;
				end
				this.procMap(proc.id) = proc;
				procIds = [procIds;proc.id];
			end
		end

		%-------------------------------------------------------------------------
		function ivs = getImageVolumes(this)
			if ~this.processed
				ivs = {};
			end
			ivs = this.ivMap.values;
		end

		%-------------------------------------------------------------------------
		function prs = getProblemResults(this)
			if ~this.processed
				prs = {};
			end
			prs = this.probResultMap.values;
		end

		%-------------------------------------------------------------------------
		function bool = load(this)
			if this.loaded
				this.logger.info(@() 'Process already loaded.');
				bool = this.loaded;
				return;
			end
			ivKeys = this.ivMap.keys();
			for ii=1:this.ivMap.Count
				iv = this.ivMap(ivKeys{ii});
				if ~isa(iv, 'ether.process.Loadable')
					continue;
				end
				if ~this.loadSpecTargetMap.isKey(iv.id)
					this.logger.warn(@() ...
						sprintf('No matching LoadSpecification found for ImageVolume ID=%i\n', ...
							iv.id));
					bool = false;
					return;
				end
				loadSpec = this.loadSpecTargetMap(iv.id);
				if ~this.loaderMap.isKey(loadSpec.loaderId)
					this.logger.warn(@() ...
						sprintf('No matching Loader found for LoadSpecification ID=%i\n', ...
							loadSpec.loaderId));
					bool = false;
					return;
				end
				loader = this.loaderMap(loadSpec.loaderId);
				iv.load(loader, loadSpec);
			end
			this.loaded = true;
			bool = this.loaded;
		end

		%-------------------------------------------------------------------------
		function bool = run(this)
			this.processed = false;
			if ~this.loaded
				loadOk = this.load;
			else
				loadOk = true;
			end
			bool = loadOk;
			procKeys = this.procMap.keys();
			for ii=1:this.procMap.Count
				proc = this.procMap(procKeys{ii});
				inputs = this.getProcessorInputs(proc);
				entities = this.getProcessorEntities(proc);
				target = this.getProcessorTarget(proc);
				this.checkPool(entities);
				procOk = proc.process(inputs, target, entities);
			end
			this.processed = true;
			bool = this.processed;
		end

	end

	methods(Access=protected)
		%-------------------------------------------------------------------------
		function checkPool(this, entities)
			import ether.parallel.*;
			if Pool.isEnabled && (Pool.size == 0)
				poolUserIdx = find(...
					arrayfun(@(x) isa(x.entity, 'ether.parallel.PoolUser'), entities));
				if ~isempty(poolUserIdx)
					poolUsers = entities(poolUserIdx);
					if any(arrayfun(@(x) x.entity.needPool, poolUsers))
						Pool.start;
					end
				end
			end
		end

		%-------------------------------------------------------------------------
		function values = fetch(this, map, ids)
			nIDs = numel(ids);
			cells = cell(nIDs, 1);
			for ii=1:nIDs
				cells{ii} = map(ids(ii));
			end
			values = [cells{:}]';
		end

		%-------------------------------------------------------------------------
		function entities = getProcessorEntities(this, proc)
			if ~all(arrayfun(@(id) this.entityMap.isKey(id), proc.entityIDs))
				throw(MException('Ether:Process:Process', ...
					sprintf('Missing entities for Processor ID=%i\n', proc.id)));
			end
			entities = this.fetch(this.entityMap, proc.entityIDs);
		end

		%-------------------------------------------------------------------------
		function inputs = getProcessorInputs(this, proc)
			if ~all(arrayfun(@(id) this.ivMap.isKey(id), proc.inputIDs))
				throw(MException('Ether:Process:Process', ...
					sprintf('Missing inputs for Processor ID=%i\n', proc.id)));
			end
			inputs = this.fetch(this.ivMap, proc.inputIDs);
		end

		%-------------------------------------------------------------------------
		function target = getProcessorTarget(this, proc)
			import ether.process.*;
			switch proc.targetType
				case Processor.ImageVolume
					if ~this.ivMap.isKey(proc.targetID)
						throw(MException('Ether:Process:Process', ...
							sprintf('Missing ImageVolume target for Processor ID=%i\n', ...
								proc.id)));
					end
					target = this.ivMap(proc.targetID);

				case Processor.ProblemResult
					if ~this.probResultMap.isKey(proc.targetID)
						throw(MException('Ether:Process:Process', ...
							sprintf('Missing ProblemResult target for Processor ID=%i\n', ...
								proc.id)));
					end
					target = this.probResultMap(proc.targetID);

				otherwise
					throw(MException('Ether:Process:Process', ...
						sprintf('Unknown target type for Processor ID=%i\n', proc.id)));
			end
		end

	end
	
end

