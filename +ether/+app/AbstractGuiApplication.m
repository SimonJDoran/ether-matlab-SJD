classdef AbstractGuiApplication < ether.app.AbstractApplication
	%ABSTRACTGUIAPPLICATION Base class for GUI applications
	%   Subclasses AbstractApplication adding minimum GUI functionality.
	%   Automatically deletes itself when frame closes.

	%----------------------------------------------------------------------------
	properties(SetAccess=private)
		frame;
		mouseListeners = {};
	end

	%----------------------------------------------------------------------------
	methods
		%-------------------------------------------------------------------------
		function run(this)
			run@ether.app.AbstractApplication(this);
			function onKill(~, ~)
				delete(this.frame);
				this.exit;
			end
			this.frame = figure(...
				'Visible', 'off', ...
				'MenuBar', 'none', ...
				'Name', this.productName, ...
				'NumberTitle', 'off', ...
				'DockControls', 'off', ...
				'CloseRequestFcn', @onKill, ...
				'WindowButtonMotionFcn', @this.onMouseMoved);
			this.initComponents();
			this.frame.Visible = 'on';
		end

	end

	%----------------------------------------------------------------------------
	methods(Sealed)
		%-------------------------------------------------------------------------
		function added = addMouseListener(this, listeners)
			added = [];
			for ii=1:numel(listeners)
				listener = listeners(ii);
				if ~isa(listener, 'ether.ui.MouseListener')
					continue;
				end
				if any(this.mouseListeners == listener)
					continue;
				end
				this.mouseListeners = [this.mouseListeners, {listener}];
				added = [added;listener];
			end
		end
		
	end

	%----------------------------------------------------------------------------
	methods(Abstract,Access=protected)
		%-------------------------------------------------------------------------
		initComponents(this);

		%-------------------------------------------------------------------------
		onEvent(this, source, event);

		%-------------------------------------------------------------------------
		onMenuEvent(this, source, event);
	end

	%----------------------------------------------------------------------------
	methods(Access=private)
		%-------------------------------------------------------------------------
		function onMouseMoved(this, source, event)
			cellfun(@(listener) listener.mouseMoved, this.mouseListeners);
		end
		
	end
end

