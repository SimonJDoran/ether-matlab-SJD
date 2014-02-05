function [gradient,intercept] = regress(x, y)
%regress Linear regression over N-dimensional array.
%
%Auto-detects the sample dimension of the array for regression.

	if ~isvector(x)
		throw(MException('Ether:Optim:regress', 'x must be a vector'));
	end
	nX = numel(x);
	nY = numel(y);
	if isvector(y)
		if (nY ~= nX)
			throw(MException('Ether:Optim:regress', 'Sample count mismatch'));
		end
		% Simple case of two vectors
		[gradient,intercept] = regress1D(x, y);
		return;
	end

	% Find dimension that equals the number of samples
	dims = size(y);
	xIdx = find(dims == nX, 1, 'first');
	if isempty(xIdx)
		throw(MException('Ether:Optim:regress', ...
			'Sample count mismatch'));
	end
	% Set target dimensions to be same as y but without the sample dimension
	resultDims = circshift(dims, [0,-xIdx]);
	targetDims = resultDims(1:end-1);
	if (numel(targetDims) == 1)
		targetDims = [1,targetDims];
	end
	% Ensure sample dimension is first dimension for CPU cache efficiency
	if (xIdx ~= 1)
		y = shiftdim(y, xIdx);
	end
	y = reshape(y, nX, nY/nX);
	[gradient,intercept] = regress2D(x, y);

	%----------------------------------------------------------------------------
	function [gradient,intercept] = regress1D(x, y)
		x = x(:);
		if ~iscolumn(y)
			y = y';
		end
		G = [ones(size(x)) x];	% linear design matrix
		b = (G'*G)\(G'*y);		% linear algebra solution to least-squares
		intercept = b(1,:);
		gradient = b(2,:);
	end

	%----------------------------------------------------------------------------
	function [gradient,intercept] = regress2D(x, y)
		x = x(:);
		G = [ones(size(x)) x];	% linear design matrix 
		b = (G'*G)\(G'*y);		% linear algebra solution to least-squares
		intercept = reshape(b(1,:), targetDims);
		gradient = reshape(b(2,:), targetDims);
	end

end

