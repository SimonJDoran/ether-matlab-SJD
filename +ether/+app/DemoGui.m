classdef DemoGui < ether.app.AbstractGuiApplication
	%DEMOGUI Example class showing usage of Ether classes
	%   Simple GUI to parse and display Images in DICOM heirarchies

	properties(Constant,Access=private)
		logger = ether.log4m.Logger.getLogger('ether.app.DemoGui', 'demogui');
	end

	properties(Access=private)
		dcmSeriesList;
		dcmStudyList;
		drawAdapter@ether.ui.AxesMouseAdapter;
		drawAxes;
		exitItem;
		importDataItem;
		ivListBox;
		patRoot@ether.dicom.PatientRoot;
		plotAxes;
		posLabel;
		valueLabel;
		volSlider;
		zSlider;
		ivs = {};
		currentIv;
	end

	methods
		%-------------------------------------------------------------------------
		function this = DemoGui()
			this.productName = 'DemoGui';
			this.productTag = 'demogui';
			toolkit = ether.dicom.Toolkit.getToolkit();
			this.patRoot = toolkit.createPatientRoot();
		end

		%-------------------------------------------------------------------------
		function run(this)
			this.logger.trace('DemoGui::run()');
			this.logger.info('DemoGui starting UI');
			run@ether.app.AbstractGuiApplication(this);
		end
	end

	methods(Access=protected)
		%-------------------------------------------------------------------------
		function initComponents(this)
			this.initMenuBar;
			pad = 2;
			xPad = pad;
			yPad = pad;
			drawWidth = 512;
			drawHeight = 512;
			listWidth = 256;
			dcmWidth = 2*listWidth+pad+xPad*2;
			dcmHeight = drawHeight+2*yPad;
			dcmPanel = uipanel('Parent', this.frame, ...
				'Units', 'pixels', ...
				'BorderType', 'none', ...
				'BorderWidth', 0, ...
				'Position', [0,0,dcmWidth,dcmHeight]);
			this.dcmStudyList = uicontrol('Style', 'listbox', ...
				'Parent', dcmPanel, ...
				'Units', 'pixels', ...
				'Position', [xPad,yPad,listWidth,drawHeight]);
			this.dcmSeriesList = uicontrol('Style', 'listbox', ...
				'Parent', dcmPanel, ...
				'Units', 'pixels', ...
				'Position', [xPad+listWidth+pad,yPad,listWidth,drawHeight], ...
				'Callback', @this.onDcmSeriesList);
			% Image display
			panelPos = dcmPanel.Position;
 			this.drawAxes = axes('Parent', this.frame, ...
				'Units', 'pixels', ...
				'DataAspectRatioMode', 'manual', ...
				'DataAspectRatio', [1,1,1], ...
				'ActivePositionProperty', 'position', ...
				'Position', [panelPos(3)+pad,yPad,drawWidth,drawHeight]);
			this.drawAdapter = ether.ui.AxesMouseAdapter(this.drawAxes);
			this.addMouseListener(this.drawAdapter);
			addlistener(this.drawAdapter, 'MouseMoved', @this.onMouseMoved);
			colormap(ether.radiological(256));
			set(this.drawAxes, 'XLim', [0.5,drawWidth+0.5], 'YLim', [0.5,drawHeight+0.5]);
			this.paintImage();
			% Sliders
% 			nZ = 100;
% 			this.zSlider = uicontrol(this.frame, 'Style', 'slider', 'Min', 1, ...
% 				'Max', nZ, 'Value', nZ/2, ...
% 				'SliderStep', [1/nZ,1/nZ], ...
% 				'Callback', @(src,ev)this.onZSlider);
% 			this.volSlider = uicontrol(this.frame, 'Style', 'slider', 'Min', 1, ...
% 				'Max', nZ, 'Value', 1, ...
% 				'SliderStep', [1/nZ,1/nZ], ...
% 				'Callback', @(src,ev)this.onVolSlider);
			this.frame.Position = [0,0,dcmWidth+pad+drawWidth,drawHeight];
			this.frame.Units = 'normalized';
			this.dcmStudyList.Units = 'normalized';
			this.dcmSeriesList.Units = 'normalized';
			dcmPanel.Units = 'normalized';
			this.drawAxes.Units = 'normalized';
			movegui(this.frame, 'center');
		end

		%-------------------------------------------------------------------------
		function onEvent(this, source, event)
			this.logger.debug(@() sprintf('Unhandled event'));
			event
		end

 		%-------------------------------------------------------------------------
 		function onMenuEvent(this, source, event)
% 			switch source
% 				case this.importDataItem
% 					this.onImportData;
% 
% 				case this.exitItem
% 					this.onExit;
% 
% 				otherwise
% 			end
 		end
 	end

	methods(Access=private)
		%-------------------------------------------------------------------------
		function initMenuBar(this)
			fileMenu = uimenu(this.frame, 'Label', '&File');
			this.importDataItem = uimenu(fileMenu, 'Label', '&Import Data...', ...
				'Accelerator', 'I', 'Callback', @this.onImportData);
			this.exitItem = uimenu(fileMenu, 'Label', 'E&xit', 'Separator', 'on', ...
				'Callback', @this.onExit);
		end

		%-------------------------------------------------------------------------
		function onDcmSeriesList(this, source, event)
			event
		end

		%-------------------------------------------------------------------------
		function onDcmStudyList(this, source, event)
			event
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
		end

		%-------------------------------------------------------------------------
		function onExit(this, source, event)
			this.logger.info('DemoGui exiting');
			close(this.frame);
		end

		%-------------------------------------------------------------------------
		function onImportData(this, source, event)
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
			patList = dcmRcvr.getPatientRoot().getPatientList();
			for idx=1:patList.size()
				this.patRoot.addPatient(patList.get(idx));
			end
			this.populateStudyList();
			this.populateSeriesList(this.dcmStudyList.Value());
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
		function nSeries = populateSeriesList(this, idx)
			nSeries = 0;
			studyList = getappdata(this.dcmStudyList, 'StudyList');
			if studyList.isEmpty()
				this.dcmSeriesList.String = '';
				setappdata(this.dcmSeriesList, 'SeriesList', ...
					ether.collect.CellArrayList('ether.dicom.Series'));
				return;
			end
			study = studyList.get(idx);
			seriesList = study.getSeriesList();
			seriesNameList = ether.collect.CellArrayList('ether.String');
			for i=1:seriesList.size()
				series = seriesList.get(i);
				name = ether.String(@() sprintf('%d %s (%d)', series.number, ...
					series.description, series.getImageCount()));
				seriesNameList.add(name);
			end
			names = cellfun(@(c) c.value, seriesNameList.toCellArray(), ...
				'UniformOutput', false);
			this.dcmSeriesList.String = names;
			setappdata(this.dcmSeriesList, 'SeriesList', seriesList);
			nSeries = seriesList.size();
		end

		%-------------------------------------------------------------------------
		function nStudies = populateStudyList(this)
			nStudies = 0;
			studyList = ether.collect.CellArrayList('ether.dicom.Study');
			setappdata(this.dcmStudyList, 'StudyList', studyList);
			patList = this.patRoot.getPatientList();
			if patList.isEmpty()
				this.dcmStudyList.String = '';
				return;
			end
			studyNameList = ether.collect.CellArrayList('ether.String');
			for i=1:patList.size()
				patient = patList.get(i);
				currStudyList = patient.getStudyList();
				for j=1:currStudyList.size()
					study = currStudyList.get(j);
					name = ether.String(@() sprintf('%s (%s) - %s', patient.name, ...
						patient.id, datestr(study.date)));
					studyNameList.add(name);
					studyList.add(study);
				end
			end
			studyArr = studyNameList.toArray();
			this.dcmStudyList.String = studyArr.value;
			nStudies = studyList.size();
		end

		%-------------------------------------------------------------------------
		function selectImageVolume(this, idx)
			this.currentIv = this.ivs{idx};
			this.isResult = false;
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
