function CM = radiological(N)

if nargin==0, N = 64; end

% basic colorscale
cm = [0 0 0 0
29 26 16 63
42 45 24 84
55 70 29 103
69 98 33 119
83 128 37 132
98 160 41 140
114 195 48 141
130 223 65 136
147 244 93 120
164 254 126 104
181 255 159 96
199 253 190 104
217 246 218 133
236 246 240 188
255 255 255 255];

% interpolate using splines for rgb
x = 1:length(cm(:,1));
xx = linspace(x(1),x(end),N)';
y = cm(:,2:4);

pR = spline(x,y(:,1));
pG = spline(x,y(:,2));
pB = spline(x,y(:,3));

yR = ppval(pR,xx);
yG = ppval(pG,xx);
yB = ppval(pB,xx);

% rescale and put ceiling at 1
CM = [yR yG yB]/255;
CM(CM>1) = 1;