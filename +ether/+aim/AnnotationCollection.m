classdef (Abstract) AnnotationCollection < handle
	%ANNOTATIONCOLLECTION Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
		aimVersion = '';
		dateTime = '';
		equipment = [];
		uniqueIdentifier = '';
		user = [];
	end
	
	methods(Abstract)
		bool = addAnnotation(this, annotation);
		annotations = getAllAnnotations(this)
		annotation = getAnnotation(this, uid);
		count = getAnnotationCount(this);
		annotation = removeAnnotation(this, uid);
	end
	
end

