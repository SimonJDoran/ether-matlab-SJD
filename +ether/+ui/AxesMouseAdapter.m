classdef AxesMouseAdapter < ether.ui.MouseListener
	%AXESMOUSEHANDLER Summary of this class goes here
	%   Detailed explanation goes here

	properties(SetAccess=private)
		axes;
		currentPoint;
	end

	properties(Access=private)
		mouseInside;
	end

	events
		MouseEntered;
		MouseExited;
		MouseMoved;
	end

	methods
		function this = AxesMouseAdapter(targetAxes)
			this.axes = targetAxes;
		end

		function bool = contains(this, pt)
			xLim = get(this.axes, 'XLim');
			yLim = get(this.axes, 'YLim');
			bool = (pt(1,1) >= xLim(1)) && (pt(1,2) >= yLim(1)) && ...
				(pt(1,1) <= xLim(2)) && (pt(1,2) <= yLim(2));
		end

		function mouseMoved(this)
			this.currentPoint = get(this.axes, 'CurrentPoint');
			inside = this.contains(this.currentPoint);
			this.notify('MouseMoved');
			if inside ~= this.mouseInside
				this.mouseInside = inside;
				if inside
					this.notify('MouseEntered');
				else
					this.notify('MouseExited');
				end
			end
		end
	end

end

