function ExampleAnimationFunc(verts,faces,varargin)
%   This function takes in the vertices and faces of one or more surfaces,
%   along with optional parameters for creating an animation of the surface
%   changing over time. The animation is created by linearly interpolating
%   between the vertices of the surfaces at different points in time, and
%   generating a series of frames which can be saved to disk as PNG images.
%
%   Arguments:
%
%   verts - A cell array containing the vertices of one or more surfaces. 
%           Each element of the cell array should be an Nx3 matrix of 
%           vertices, where N is the number of vertices in the surface.
%
%   faces - A matrix representing the faces of the surface(s). This should
%           be an Mx3 matrix where each row contains the indices of the 
%           three vertices which make up a triangular face of the surface.
%
%   varargin - Optional arguments which can be used to customize the 
%              animation. These can include the following:
%
%       'plotBoundary' - A logical value indicating whether or not to 
%                        display the boundary of the surface(s) in the 
%                        animation. Default is true.
%
%       'boundaryWidth' - The width of the boundary lines in the animation. 
%                         Default is 2.
%
%       'frames' - The number of frames to include in the animation. 
%                  Default is 30.
%
%       'vertData' - A matrix of data values associated with each vertex of 
%                    the surface(s), which can be used to color the 
%                    vertices in the animation. Default is a matrix of 
%                    zeros.
%
%       'vertParc' - A matrix of integers indicating which region or parcel 
%                    each vertex of the surface(s) belongs to. This can be 
%                    used to group vertices together and color them 
%                    differently in the animation. Default is a vector of 
%                    ones.
%
%       'colormap' - A colormap to use for coloring the vertices based on 
%                    their data values. Default is the 'turbo' colormap.
%
%       'viewAngle' - A 1x2 vector specifying the azimuth and elevation 
%                     angles of the camera used to view the surface(s) in 
%                     the animation. Default is [-90 0], which corresponds 
%                     to a side view of the surface(s).
%
%       'outdir' - The directory to save the PNG images of the animation 
%                  frames to. If empty, frames will not be saved to disk. 
%                  Default is empty.
%
%   Returns:
%
%   None. The function creates an animation of the surface changing over 
%   time, and can optionally save the animation frames to disk as PNG 
%   images.
%
%   Example:
%
%   verts = {rand(100,3), rand(100,3)};
%   faces = randi([1 100], 100, 3);
%   ExampleAnimationFunc(verts, faces, 'frames', 60, 'outdir', './my_animation')
%
%   This will create an animation with 60 frames, and save the frames as 
%   PNG images in the 'my_animation' directory.
%

% Create an input parser object to validate and parse inputs
p = inputParser;

% Define custom validation functions for the inputs
validCell = @(x) iscell(x);
validFaces = @(x) ismatrix(x);
validScalarPosNum = @(x) isnumeric(x) && isscalar(x) && (x > 0);
validMatrix = @(x) isnumeric(x) && ismatrix(x) && (size(x,1) == 1 || size(x,2) == 1);
validLogical = @(x) islogical(x);
validCmap = @(x) isnumeric(x) && size(x,2) == 3;
validAngle = @(x) isnumeric(x) && size(x,1) == 1 && size(x,2) == 2;

% Get the number of vertices in the first surface
Nverts = size(verts{1},1);

% Set default values for optional input arguments
defaultCmap = turbo(256);
default_vertData = zeros(Nverts,1);
default_vertParc = ones(Nverts,1);
default_frames = 5;
default_viewAngle = [-90 0];

% Add the required and optional input arguments to the input parser object
addRequired(p,'verts',validCell)
addRequired(p,'faces',validFaces)
addOptional(p,'plotBoundary',true,validLogical);
addOptional(p,'boundaryWidth',2,validScalarPosNum);
addOptional(p,'frames',default_frames,validScalarPosNum);
addOptional(p,'vertData',default_vertData,validMatrix);
addOptional(p,'vertParc',default_vertParc,validMatrix);
addOptional(p,'colormap',defaultCmap,validCmap);
addOptional(p,'viewAngle',default_viewAngle,validAngle);
addOptional(p,'outdir',[],@isstring);

% Parse the inputs
parse(p,verts,faces,varargin{:})

% Get the number of surfaces
Nsurfaces = length(verts);

% Create a surface structure
surface.vertices = verts{Nsurfaces};
surface.faces = faces;

% Determine whether to plot the boundary and set the vertex data and
% parcellation values
plotBoundary = p.Results.plotBoundary;
vertData = p.Results.vertData;

if length(unique(vertData)) == 1 && max(vertData) == 0
    vertParc = zeros(Nverts,1);
else
    vertParc = p.Results.vertParc;
end

% If the boundary is not plotted or the vertex parcellation is uniform,
% plot the surface without the boundary
if ~p.Results.plotBoundary || length(unique(p.Results.vertParc)) == 1
    plotBoundary = false;
    [surf_patch,b] = plotSurfaceROIBoundary(surface,vertParc,vertData,'none',p.Results.colormap);
   
% Otherwise, plot the surface with the boundary
else
    [surf_patch,b] = plotSurfaceROIBoundary(surface,vertParc,vertData,'midpoint',p.Results.colormap,p.Results.boundaryWidth);  
end

% Add two camlights to the plot and set the view angle, axis properties
camlight(80,-10);
camlight(-80,-10);
view(p.Results.viewAngle)
axis off
axis vis3d
axis tight
axis equal

% Freeze the axis limits
xlim manual
ylim manual
zlim manual

% Set the number of frames and create the output directory (if specified)
F = p.Results.frames;

r = linspace(0,1,F);

% If an output directory is provided, create it if it doesn't exist
if ~isempty(p.Results.outdir)
mkdir(p.Results.outdir)
end

% Create the first frame
Iter = 1;

% Set the surface vertices for the first frame
surf_patch.Vertices = verts{1};

% If plotBoundary is true, plot the surface ROI boundary
if plotBoundary
% Delete any existing ROI boundary
delete(b.boundary)
% Find the ROI boundaries for the current surface
BOUNDARY = findROIboundaries(verts{1},surface.faces,p.Results.vertParc,'midpoint');
% Plot the ROI boundary
for jj = 1:length(BOUNDARY)
b.boundary(jj) = plot3(BOUNDARY{jj}(:,1), BOUNDARY{jj}(:,2), BOUNDARY{jj}(:,3), 'Color', 'k', 'LineWidth',p.Results.boundaryWidth,'Clipping','off');
end
end

% If an output directory is provided, save the first frame
if ~isempty(p.Results.outdir)
print([outdir,'/Frame',num2str(Iter),'.png'],'-dpng')
end

% Set the iteration counter to 2, since we've already created the first frame
Iter = 2;

% Loop through each pair of surface vertices and interpolate between them
for i = 1:length(verts)-1

    for j = 1:F-1
        % Interpolate between the two sets of vertices
        newVerts = find_point_on_line(verts{i},verts{i+1},r(j+1));
        % Set the surface vertices for the current frame
        surf_patch.Vertices = newVerts;
        % If plotBoundary is true, plot the surface ROI boundary
        if plotBoundary
            % Delete any existing ROI boundary
            delete(b.boundary)
            % Find the ROI boundaries for the current surface
            BOUNDARY = findROIboundaries(newVerts,surface.faces,p.Results.vertParc,'midpoint');
            % Plot the ROI boundary
            for jj = 1:length(BOUNDARY)
               b.boundary(jj) = plot3(BOUNDARY{jj}(:,1), BOUNDARY{jj}(:,2), BOUNDARY{jj}(:,3), 'Color', 'k', 'LineWidth',p.Results.boundaryWidth,'Clipping','off');
            end
        end
        % Pause for a short time to ensure that the frame is generated so
        % it can be appropriately saved
        pause(.1)
        % If an output directory is provided, save the current frame
        if ~isempty(p.Results.outdir)
            print([outdir,'/Frame',num2str(Iter),'.png'],'-dpng')
        end
        % Increment the iteration counter
        Iter = Iter + 1;
    end

end