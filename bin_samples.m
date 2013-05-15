function [edges, y_mu, y_s, nn ] = bin_samples(x, y, edges)
% [nX, muY , sY, nSamples] = bin_samples(X, Y, EDGES)
% Returns new X and new Y points given the scattered X and Y points.
% muY is obtain by simple averaging accross points.
% sY is the standard deviation of each NX and 

if ~exist('edges','var')
    disp('Using default for EDGES.')
    edges = (min(X)-2:1:max(X)+2); % assuming X is in (ms).
end

x=x(:);
y=y(:);

[~, bin] = histc(x, edges);
edges = edges(1:end-1)+diff([edges(1),edges(2)])/2;
N = length(edges);
for j = 1:N, 
    nn(j) = sum(bin==j);
    y_s(j) = std(y(bin==j));
    y_mu(j) = nanmean(y(bin==j));
end
 
% muY         = nan(size(N));
% sY          = nan(size(N));
% nSamples    = nan(size(N));
% size(N)
% for jj=1 : length(N)
%     idx = (BIN==jj-1);
%     muY(jj) = nanmean(Y(idx));
%     sY(jj) = nanstd(Y(idx))
%     jj
% end
end