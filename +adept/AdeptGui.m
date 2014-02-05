classdef AdeptGui < ether.app.AbstractGuiApplication
	%ADEPTGUI Summary of this class goes here
	%   Detailed explanation goes here

	properties(Constant,Access=private)
		logger = ether.log4m.Logger.getLogger('adept.AdeptGui');
	end

	properties(Access=private)
		drawAdapter@ether.ui.AxesMouseAdapter;
		drawAxes;
		exitItem;
		exportDescItem;
		importDataItem;
		importDescItem;
		ivListBox;
		plotAxes;
		posLabel;
		resultListBox;
		runProcessItem;
		usePool = true;
		valueLabel;
		volSlider;
		zSlider;
		currProcess@ether.process.Process;
		ivs = {};
		currentIv;
		results = {};
		isResult = false;
	end

	methods
		%-------------------------------------------------------------------------
		function this = AdeptGui()
			this.productName = 'ADEPT';
			this.productTag = 'adeptm';
		end

		%-------------------------------------------------------------------------
		function run(this)
			this.logger.debug('Starting UI');
			run@ether.app.AbstractGuiApplication(this);
		end
	end

	methods(Access=protected)
		%-------------------------------------------------------------------------
		function initComponents(this)
			this.initMenuBar;
			gbl = layout.GridBagLayout(this.frame, 'HorizontalGap', 2, ...
				'VerticalGap', 2);
			ivHeight = 80;
			ivWidth = 150;
			drawWidth = 512;
			drawHeight = 512;
			plotWidth = 640;
			sliderHeight = 20;
			frameWidth = ivWidth+drawWidth+plotWidth+4*2;
			frameHeight = drawHeight+2*sliderHeight+4*2;
			set(this.frame, 'Position', [0,0,frameWidth,frameHeight]);
			movegui(this.frame, 'center');
			% Left panel - needed as GridBagLayout ignores max size
			leftPanel = uipanel(this.frame);
			gbl.add(leftPanel, 1, 1, 'Fill', 'Both', 'MinimumWidth', ivWidth);
			lpGBL = layout.GridBagLayout(leftPanel, 'HorizontalGap', 2, ...
				'VerticalGap', 2);
			% ImageVolume list
			ivLabel = uicontrol(leftPanel, 'Style', 'text', ...
				'String', 'ImageVolumes');
			lpGBL.add(ivLabel, 1, 1, 'Fill', 'Horizontal', 'PreferredHeight', sliderHeight);
			this.ivListBox = uicontrol(leftPanel, 'Style', 'listbox', ...
				'Value', [], 'Callback', @this.onIvListBox);
			lpGBL.add(this.ivListBox, 2, 1, 'MinimumWidth', ivWidth, ...
				'MinimumHeight', ivHeight, 'Fill', 'Both');
			% ProblemResult list
			prLabel = uicontrol(leftPanel, 'Style', 'text', ...
				'String', 'ProblemResult');
			lpGBL.add(prLabel, 3, 1, 'Fill', 'Horizontal');
			this.resultListBox = uicontrol(leftPanel, 'Style', 'listbox', ...
				'Value', [], 'Callback', @this.onResultListBox);
			lpGBL.add(this.resultListBox, 4, 1, 'MinimumWidth', ivWidth, ...
				'MinimumHeight', ivHeight, 'Fill', 'Both');
			% Image display
 			this.drawAxes = axes('Parent', this.frame, 'Units', 'pixels', ...
				'DataAspectRatio', [1,1,1], 'ActivePositionProperty', 'position');
			gbl.add(this.drawAxes, 1, 2, 'MinimumWidth', drawWidth, ...
				'MinimumHeight', drawHeight, 'Fill', 'None', 'Anchor', 'NorthWest');
			this.drawAdapter = ether.ui.AxesMouseAdapter(this.drawAxes);
			this.addMouseListener(this.drawAdapter);
			addlistener(this.drawAdapter, 'MouseMoved', @this.onMouseMoved);
			colormap(ether.radiological(256));
			set(this.drawAxes, 'XLim', [0.5,drawWidth+0.5], 'YLim', [0.5,drawHeight+0.5]);
			this.paintImage();
			% Plot area
			plotPanel = uipanel(this.frame);
 			this.plotAxes = axes('Parent', plotPanel);
			gbl.add(plotPanel, 1, 3, 'MinimumWidth', plotWidth, ...
				'MinimumHeight', drawHeight, 'Fill', 'Both');
			% Status
			this.posLabel = uicontrol(this.frame, 'Style', 'text', 'String', '');
			gbl.add(this.posLabel, 2, 1, 'Fill', 'Horizontal');
			this.valueLabel = uicontrol(this.frame, 'Style', 'text', 'String', '');
			gbl.add(this.valueLabel, 3, 1, 'Fill', 'Horizontal');
			% Sliders
			nZ = 100;
			this.zSlider = uicontrol(this.frame, 'Style', 'slider', 'Min', 1, ...
				'Max', nZ, 'Value', nZ/2, ...
				'SliderStep', [1/nZ,1/nZ], ...
				'Callback', @(src,ev)this.onZSlider);
			jZSlider = findjobj(this.zSlider);
			jZSlider.AdjustmentValueChangedCallback = @this.onZSlider;
			gbl.add(this.zSlider, 2, 2, 'MinimumHeight', sliderHeight, ...
				'MaximumWidth', drawWidth, 'Fill', 'Horizontal');
			this.volSlider = uicontrol(this.frame, 'Style', 'slider', 'Min', 1, ...
				'Max', nZ, 'Value', 1, ...
				'SliderStep', [1/nZ,1/nZ], ...
				'Callback', @(src,ev)this.onVolSlider);
			jVolSlider = findjobj(this.volSlider);
			jVolSlider.AdjustmentValueChangedCallback = @this.onVolSlider;
			gbl.add(this.volSlider, 3, 2, 'MinimumHeight', sliderHeight, ...
				'MaximumWidth', drawWidth, 'Fill', 'Horizontal');
			gbl.HorizontalWeights = [1,0,1];
			gbl.VerticalWeights = [1,0,0];
		end

		%-------------------------------------------------------------------------
		function onEvent(this, source, event)
			this.logger.debug(@() sprintf('Unhandled event'));
			event
		end

		%-------------------------------------------------------------------------
		function onMenuEvent(this, source, event)
			switch source
				case this.importDataItem
					this.onImportData;

				case this.importDescItem
					this.onImportDescriptor;

				case this.exportDescItem
					this.onExportDescriptor;

				case this.runProcessItem
					this.onRunProcess;

				case this.exitItem
					this.onExit;

				otherwise
			end
		end
	end

	methods(Access=private)
		%-------------------------------------------------------------------------
		function initMenuBar(this)
			fileMenu = uimenu(this.frame, 'Label', '&File');
			this.importDataItem = uimenu(fileMenu, 'Label', '&Import Data...', ...
				'Accelerator', 'I', 'Callback', @this.onMenuEvent);
			this.importDescItem = uimenu(fileMenu, 'Label', 'Import &Descriptor...', ...
				'Accelerator', 'D', 'Separator', 'on', 'Callback', @this.onMenuEvent);
			this.exportDescItem = uimenu(fileMenu, 'Label', '&Export Descriptor...', ...
				'Accelerator', 'E', 'Enable', 'off', 'Callback', @this.onMenuEvent);
			this.exitItem = uimenu(fileMenu, 'Label', 'E&xit', 'Separator', 'on', ...
				'Callback', @this.onMenuEvent);
			processMenu = uimenu(this.frame, 'Label', '&Process');
			this.runProcessItem = uimenu(processMenu, 'Label', '&Run', ...
				'Accelerator', 'R', 'Enable', 'off', 'Callback', @this.onMenuEvent);
		end

		%-------------------------------------------------------------------------
		function onDrawMouseMoved(this)
			import ether.optim.*;
			pt = this.drawAdapter.currentPoint;
			if ~this.drawAdapter.contains(pt)
				set(this.posLabel, 'String', '');
				set(this.valueLabel, 'String', '');
				return;
			end
			x = pt(1,1);
			y = pt(1,2);
			set(this.posLabel, 'String', sprintf('(%.1f,%.1f)', x, y));
			if isempty(this.currentIv)
				set(this.valueLabel, 'String', '');
				return;
			end
			nX = this.currentIv.dimensions(1).length;
			nY = this.currentIv.dimensions(2).length;
			nZ = this.currentIv.dimensions(3).length;
			nVol = this.currentIv.dimensions(4).length;
			xLim = get(this.drawAxes, 'XLim');
			yLim = get(this.drawAxes, 'YLim');
			xIdx = round(x*(xLim(2)-xLim(1))/nX);
			yIdx = round(y*(yLim(2)-yLim(1))/nY);
			zIdx = min(round(get(this.zSlider, 'Value')), nZ);
			volIdx = min(round(get(this.volSlider, 'Value')), nVol);
			value = this.currentIv.pixelData(yIdx,xIdx,zIdx,volIdx);
			set(this.posLabel, 'String', sprintf('(%i,%i)', xIdx, yIdx));
			set(this.valueLabel, 'String', sprintf('%.3f', value));
			% Simple plot
			if ~this.isResult
				data = squeeze(this.currentIv.pixelData(yIdx,xIdx,zIdx,:));
				if isvector(data)
					plot(this.plotAxes, 1:nVol, data, '+', 'MarkerSize', 3);
					return;
				end
				% ToDo: Erase plot
				return;
			end
			% Results plot
			pr = this.currProcess.getProblemResults{1};
			data = squeeze(pr.source.pixelData(yIdx,xIdx,zIdx,:));
			dim = pr.source.dimensions(4);
			abscissa = dim.values{2};
			plotAx = abscissa*pr.problem.abscissaScale;
			if ~isa(pr.problem, 'ether.optim.Evaluable') || ...
					pr.code(yIdx,xIdx,zIdx) == Solver.NeverEvaluated
				plot(this.plotAxes, plotAx, data, '+', 'MarkerSize', 3);
				set(this.plotAxes, 'YLim', [-0.1,1.0]);
				return
			end
			nParams = pr.problem.parameterCount;
			params = zeros(nParams, 1);
			for ii=1:nParams
				params(ii) = this.results{ii}.pixelData(yIdx,xIdx,zIdx);
			end
			curve = pr.problem.evaluate(abscissa, params);
			plot(this.plotAxes, plotAx, data, '+', plotAx, curve, 'g', ...
				'MarkerSize', 3);
			set(this.plotAxes, 'YLim', [-0.1,1.0]);
		end

		%-------------------------------------------------------------------------
		function onExit(this)
			close(this.frame);
		end

		%-------------------------------------------------------------------------
		function onExportDescriptor(this)
		end

		%-------------------------------------------------------------------------
		function onImportData(this)
			import ether.dicom.io.*;
			title = 'Import Data';
			path = uigetdir('', title);
			if ~isa(path, 'char')
				return;
			end
			scanner = PathScanner();
			dcmRcvr = DicomReceiver();
			scanner.addPathScanListener(dcmRcvr);
			scanner.scan(path);
			scanner.removePathScanListener(dcmRcvr);
		end

		%-------------------------------------------------------------------------
		function onImportDescriptor(this)
			filterSpec = {...
				'*.xml;*.xep','XML Ether Process files'; ...
				'*.xml','XML files'; ...
				'*.*','All Files'; ...
				};
			title = 'Import Process Descriptor';
			defaultName = 'ether-process.xml';
			[filename,path] = uigetfile(filterSpec, title, defaultName);
			if ~isa(filename, 'char')
				return;
			end
			filepath = fullfile(path, filename);
			reader = ether.process.XmlProcessReader();
			process = reader.read(filepath);
			this.currProcess = process;
			set(this.runProcessItem, 'Enable', 'on');
		end

		%-------------------------------------------------------------------------
		function onIvListBox(this, source, event)
			idx = get(this.ivListBox, 'Value');
			if ~isempty(idx)
				this.selectImageVolume(idx);
			end
		end

		%-------------------------------------------------------------------------
		function onMouseMoved(this, source, event)
			if source == this.drawAdapter
				this.onDrawMouseMoved();
			end
		end

		%-------------------------------------------------------------------------
		function onResultListBox(this, source, event)
			idx = get(this.resultListBox, 'Value');
			if ~isempty(idx)
				this.selectResultVolume(idx);
			end
		end

		%-------------------------------------------------------------------------
		function onRunProcess(this)
			this.currProcess.run;
			% Image volumes
			this.ivs = this.currProcess.getImageVolumes;
			ivNames = cellfun(@(iv) iv.label, this.ivs, 'UniformOutput', false);
			set(this.ivListBox, 'String', ivNames, 'Value', 1);
			% Problem results
			this.results = [];
			prs = this.currProcess.getProblemResults;
			hasResults = ~isempty(prs);
			if hasResults
				nPrs = numel(prs);
				for ii=1:nPrs
					this.results = [this.results, arrayfun(@(x) {x}, prs{ii}.parameters)];
					this.results = [this.results, arrayfun(@(x) {x}, prs{ii}.derived)];
					if prs{ii}.sigmaType ~= ether.optim.Solver.NA
						this.results = [this.results, arrayfun(@(x) {x}, prs{ii}.sigma)];
					end
				end
			end
			resultNames = cellfun(@(iv) iv.label, this.results, 'UniformOutput', false);
			set(this.resultListBox, 'String', resultNames, 'Value', 1);
			if hasResults
				this.selectResultVolume(1);
			else
				this.selectImageVolume(1);
			end
		end

		%-------------------------------------------------------------------------
		function onVolSlider(this, source, event)
			this.paintImage();
		end

		%-------------------------------------------------------------------------
		function onZSlider(this, source, event)
			this.paintImage();
		end

		%-------------------------------------------------------------------------
		function paintImage(this)
			set(this.frame, 'CurrentAxes', this.drawAxes);
			drawPos = get(this.drawAxes, 'Position');
			if isempty(this.currentIv)
				imagesc(zeros(drawPos(3),drawPos(4)), [0,1]);
				axis off;
				axis image;
				return;
			end
			nZ = this.currentIv.dimensions(3).length;
			nVol = this.currentIv.dimensions(4).length;
			zIdx = min(round(get(this.zSlider, 'Value')), nZ);
			volIdx = min(round(get(this.volSlider, 'Value')), nVol);
			currImage = squeeze(this.currentIv.pixelData(:,:,zIdx,volIdx));
			if this.currentIv.hasValidDisplayLimits
				limits = [this.currentIv.displayMin,this.currentIv.displayMax];
				imagesc(currImage, limits);
			else
				imagesc(currImage);
			end
			axis off;
			axis image;
			set(this.zSlider, 'Value', zIdx);
			set(this.volSlider, 'Value', volIdx);
		end

		%-------------------------------------------------------------------------
		function selectImageVolume(this, idx)
			this.currentIv = this.ivs{idx};
			this.isResult = false;
			this.selectVolume(this.currentIv);
		end

		%-------------------------------------------------------------------------
		function selectResultVolume(this, idx)
			this.currentIv = this.results{idx};
			this.isResult = true;
			this.selectVolume(this.currentIv);
		end

		%-------------------------------------------------------------------------
		function selectVolume(this, volume)
			nZ = volume.dimensions(3).length;
			currZ = get(this.zSlider, 'Value');
			if nZ > 1
				if currZ <= nZ
					targetZ = currZ;
				else
					targetZ = floor(nZ/2);
				end
				set(this.zSlider, 'Max', nZ, ...
					'Value', targetZ, ...
					'SliderStep', [1/nZ,1/nZ], ...
					'Enable', 'on');
			else
				set(this.zSlider, 'Value', 1, 'Enable', 'inactive');
			end
			nVol = volume.dimensions(4).length;
			currVol = get(this.volSlider, 'Value');
			if nVol > 1
				if currVol <= nVol
					targetVol = currVol;
				else
					targetVol = 1;
				end
				set(this.volSlider, 'Max', nVol, ...
					'Value', targetVol, ...
					'SliderStep', [1/nVol,1/nVol], ...
					'Enable', 'on');
			else
				set(this.volSlider, 'Value', 1, 'Enable', 'inactive');
			end
			this.paintImage();
		end

	end

end

