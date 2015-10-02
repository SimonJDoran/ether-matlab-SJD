function varargout = rundemogui(varargin)
%RUNDEMOGUI Launch the demonstration GUI application
%   Detailed explanation goes here

	varargout = {};

	app = ether.app.DemoGui();
	app.run;

end
