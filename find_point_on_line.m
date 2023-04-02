function coords = find_point_on_line(coords0,coords1,dist,disttype)

% This function finds the coordinates of a point on a line specified by the
% start point and end point. This point is either defined as a set distance 
% or as a ratio from the start point (default). The coordinates of the
% start and endpoints can be in any number of dimensions

% Inputs:   
%                                           coords0 = a n-by-m matrix of
%                                           n start points in m dimensions
%                                           coords1 = a n-by-m matrix of
%                                           n end points in m dimensions
%                                           dist = the distance or ratio
%                                           (default) to calculate on the
%                                           line
%                                           disttype = 'ratio' (default) or
%                                           'distance'. Specifies how to
%                                           calculate the distance along
%                                           the line
%
% Output:
%                                           coords = the coordinates of the
%                                           point on the line
%
% Note this code can be run on multiple coordinates with multipe specified
% distances to calculate at once. Just enter multiple start coordinates
% into coords0 and coords1 (1st column is x coords, 2nd is y coords etc).
% Can also enter different distances for each coordinate to calculate

% This is basically just a kind of linear interpolation

if nargin < 4
    disttype = 'ratio';
end

if size(coords0) ~= size(coords1)
    error('Same number of coordinates and dimensions required in coords0 and coords1')
end

if length(dist) ~= 1 && size(dist,1) ~= size(coords0,1)
    error('dist needs to be a scalar or have a value for each pair of coordinates')  
end

switch disttype
    case 'ratio'
        % when 0 < t < 1 the coordinate is between those defined by coords0
        % and coords 1, when t < 0 the coordinate is closer to coords0, and 
        % when t > 1 the coordinate is closer to coords1
        t = dist;
    case 'distance'
        d = sqrt(sum((coords0 - coords1).^2,2));
        t = dist./d;
    otherwise
        error('Unrecognised entry for disttype')
end

coords = (1-t).*coords0 + t.*coords1;

end
