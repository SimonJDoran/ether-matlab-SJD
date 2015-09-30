classdef Utils < handle
	%UTILS Summary of this class goes here
	%   Detailed explanation goes here

	properties
	end

	methods(Static)
		%-------------------------------------------------------------------------
		function vec = daToDateVector(da)
			if ~(ischar(da) && isvector(da) && (numel(da) == 8))
				throw(MException('Ether:Dicom:daToDateVector', ...
					'DA element must be 8 characters'));
			end
			vec = [str2double(da(1:4)),str2double(da(5:6)),str2double(da(7:8)),0,0,0];
		end

		%-------------------------------------------------------------------------
		function name = pnToString(pn)
			name = pn.FamilyName;
			if (isfield(pn, 'GivenName') && (numel(pn.GivenName) > 0))
				name = sprintf('%s, %s', name, pn.GivenName);
			end
		end

		%-------------------------------------------------------------------------
		function time = tmToSeconds(tm)
			if ~(ischar(tm) && isvector(tm) && (numel(tm) >= 2))
				throw(MException('Ether:Dicom:Utils:tmToSeconds', ...
					'TM element invalid'));
			end
			nTM = numel(tm);
			hh = 3600*str2double(tm(1:2));
			mm = 0;
			ss = 0;
			if nTM > 4
				ss = str2double(tm(5:end));
				mm = 60*str2double(tm(3:4));
			else
				if nTM ~= 4
					mm = NaN;
				else
					mm = 60*str2double(tm(3:4));
				end
			end
			if (isnan(mm) || isnan(ss))
				throw(MException('Ether:Dicom:Utils:tmToSeconds', ...
					sprintf('TM element invalid: "%s"', tm)));
			end
			time = hh+mm+ss;
		end

		%-------------------------------------------------------------------------
		function data = createTimingData(image)
			import ether.dicom.*;
			sopInst = image.sopInstance;
			data = TimingData();

			% GE CT scanners use private field (0x0019, 0x1024)
			if (strcmp(sopInst.get('Modality'), Modality.CT) == 0) && ...
				(~isempty(strfind(lower(sopInst.get('Manufacturer')), 'ge medical')))
				geCtTime = sopInst.get('Private_0019_1024');
				if ~isempty(geCtTime)
					data.geCtTime = geCtTime;
					return;
				end
			end
			% Siemens use AcquisitionTime (0x0008, 0x0032)
			acqTime = sopInst.get('AcquisitionTime');
			if ~isempty(acqTime)
				data.acqTime = Utils.tmToSeconds(acqTime);
			end
			% ContentTime (0x0008, 0x0033)
			contentTime = sopInst.get('ContentTime');
			if ~isempty(contentTime)
				data.contentTime = Utils.tmToSeconds(contentTime);
			end
			% Toshiba provide TemporalPositionIdentifier in ms (0x0020, 0x0100)
			tempPosId = sopInst.get('TemporalPositionIdentifier');
			if ~isempty(tempPosId)
				data.tempPosId = str2double(tempPosId)/1000;
			end
			% GE provide Trigger Time (0x0018, 0x1060)
			triggerTime = sopInst.get('TriggerTime');
			if ~isempty(triggerTime)
				data.triggerTime = str2double(triggerTime);
			end
		end

	end

	methods(Access=private)
		function this = Utils()
		end
	end

end
