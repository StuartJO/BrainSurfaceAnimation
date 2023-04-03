function SurfMorphAnimation(verts,faces,varargin)
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
%       'NInterpPoints' - The number of points to interpolate 
%                            between each surface. Default is 30.
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
%                     to a side view of the surface.
%
%       'camlights' - An Nx2 matrix where each row creates a light at
%                     the specified azimuth (first column) and elevation 
%                     (second column) with respect to the camera position. 
%                     The camera target is the center of rotation and
%                     azimuth and elevation are in degrees. By default
%                     positons two lights at [80,-10] and [-80,-10]
%
%       'climits' - A 1x2 vector [min, max] of colormap limits. By default
%                   this will set to the min and max values of 'vertData'
%
%       'varyClimits' - A logical indicating if set the colormap limits to
%                       the range of vertex data at the current iteration. 
%                       Default is false. Note this will override 'climits' 
%
%       'cmapInterpType' - A character of either 'RGB' or 'HSV', indicates
%                          the color space in which interpolation takes 
%                          place. Defaults to 'HSV' (HSV space is used for
%                          interpolation as it tends to look nicer,
%                          interpolating in RGB space can make things look
%                          a yucky grey at times)
%
%       'outdir' - The directory to save the PNG images of the animation 
%                  frames to. If empty, frames will not be saved to disk. 
%                  Default is empty.
%
%       'outgif' - A file name to save as a gif to. If empty no gif will be
%                  saved. Default is empty.
%
%       'gifoptions' - a structure containing fields for each gif option,
%                      as specified below (see the 'gif' function for what 
%                      they do) Note that these do not all need to be
%                      specified:
%
%                       gifoptions = struct('DelayTime', 1/30,...
%                           'DitherOption', 'nodither',...
%                           'LoopCount', inf,...
%                           'frame', gcf,...
%                           'resolution', 0,...
%                           'overwrite',true);
%       'freezeFirstFrame' - an integer >= 1, which indicates how many
%                            times to 'freeze' the first frame of the 
%                            animation. Useful for pausing on the initial
%                            frame. Default is 1
%
%       'freezeLastFrame' - an integer >= 1, which indicates how many times
%                            to 'freeze' the last frame of the animation.
%                            Useful for pausing on the final frame. Default
%                            is 1
%
%       'saveLastFrame' - a logical indicating whether to save the last
%                         frame. If trying to create a perfect loop, this
%                         this should be set to false. Note this will
%                         override 'freezeLastFrame' if it is set. Default
%                          is true. 
% 
%   Returns:
%
%   None. The function creates an animation of the surface changing over 
%   time, and can optionally save the animation frames to disk as PNG 
%   images or directly to a .gif
%
%   Example:
%
%   verts = {rand(100,3), rand(100,3)};
%   faces = randi([1 100], 100, 3);
%   ExampleAnimationFunc(verts, faces, 'NInterpPoints', 60, 'outdir', './my_animation')
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
validCmap = @(x) (isnumeric(x) && size(x,2) == 3) || iscell(x);
validAngle = @(x) isnumeric(x) && size(x,1) == 1 && size(x,2) == 2;
validCamlights = @(x) isnumeric(x) && size(x,2) == 2;
validFreezeFrame = @(x) isnumeric(x) && isscalar(x) && isinteger(x) && (x >= 1);
validMatOrCell = @(x) (isnumeric(x) && ismatrix(x) && (size(x,1) == 1 || size(x,2) == 1)) || iscell(x);

% Get the number of vertices in the first surface
Nverts = size(verts{1},1);

% Set default values for optional input arguments
default_Cmap = turbo(256);
default_vertData = nan(Nverts,1);
default_vertParc = ones(Nverts,1);
default_NInterpPoints = 30;
default_viewAngle = [-90 0];
default_camlights = [80,-10;-80,-10];


default_gifoptions = struct('DelayTime', 1/30,...
                    'DitherOption', 'nodither',...
                    'LoopCount', inf,...
                    'frame', gcf,...
                    'resolution', 0,...
                    'overwrite',true);

% Add the required and optional input arguments to the input parser object
addRequired(p,'verts',validCell)
addRequired(p,'faces',validFaces)
addOptional(p,'plotBoundary',true,validLogical);
addOptional(p,'boundaryWidth',2,validScalarPosNum);
addOptional(p,'NInterpPoints',default_NInterpPoints,validScalarPosNum);
addOptional(p,'vertData',default_vertData,validMatOrCell);
addOptional(p,'vertParc',default_vertParc,validMatrix);
addOptional(p,'colormap',default_Cmap,validCmap);
addOptional(p,'viewAngle',default_viewAngle,validAngle);
addOptional(p,'outdir',[],@ischar);
addOptional(p,'camlights',default_camlights,validCamlights);
addOptional(p,'outgif',[],@ischar);
addOptional(p,'gifoptions',default_gifoptions,@isstruct);
addOptional(p,'climits',[],validAngle);
addOptional(p,'varyClimits',false,validLogical);
addOptional(p,'saveLastFrame',true,validLogical);
addOptional(p,'cmapInterpType','HSV',@ischar);
addOptional(p,'freezeFirstFrame',1,validFreezeFrame);
addOptional(p,'freezeLastFrame',1,validFreezeFrame);


% Parse the inputs
parse(p,verts,faces,varargin{:})

%% Set the default gif options

gifoptions = p.Results.gifoptions;

% Check for the existence of each field and replace with defaults if missing
if ~isfield(gifoptions, 'DelayTime')
    gifoptions.DelayTime = 1/30;
end

if ~isfield(gifoptions, 'DitherOption')
    gifoptions.DitherOption = 'nodither';
end

if ~isfield(gifoptions, 'LoopCount')
    gifoptions.LoopCount = inf;
end

if ~isfield(gifoptions, 'frame')
    gifoptions.frame = gcf;
end

if ~isfield(gifoptions, 'resolution')
    gifoptions.resolution = 0;
end

if ~isfield(gifoptions, 'overwrite')
    gifoptions.overwrite = true;
end

%% Check if the vertex data is morphing as well

Nsurfaces = length(verts);

vertData = p.Results.vertData;
if iscell(p.Results.vertData)
    if length(p.Results.vertData) ~= Nsurfaces
        error('if ''vertData'' is a cell, it must be the same length as ''verts''')
    end
    % Get the climits
    if isempty(p.Results.climits) 
        climits_ = zeros(Nsurfaces,2);
        for i = 1:Nsurfaces
            climits_(i,:) = [nanmin(vertData{i}), nanmax(vertData{i})];
        end
        climits = [nanmin(climits_(:,1)), nanmax(climits_(:,2))];
    else
       climits = p.Results.climits;
    end
    current_vertData = vertData{1};
    vary_vertData = true;
else   
    if isempty(p.Results.climits)
        climits = [nanmin(vertData), nanmax(vertData)];
    else
        climits = p.Results.climits;
    end
    current_vertData = vertData;
    vary_vertData = false;
end

% Avoid climits having a nan in them
climits(isnan(climits)) = 0;

% Format the colormaps

if iscell(p.Results.colormap)
    if length(p.Results.colormap) ~= Nsurfaces
        error('if ''colormap'' is a cell, it must be the same length as ''verts''')
    end
      all_colormaps = p.Results.colormap;
        switch p.Results.cmapInterpType
            case 'RGB'
                % Do nothing because everything is done
            case 'HSV' 
                for i = 1:Nsurfaces
                    all_colormaps{i} = rgb2hsv(p.Results.colormap{i});
                end
        end

    current_colormap = p.Results.colormap{1};
    varyCmap = true;
else

    current_colormap = p.Results.colormap;
    varyCmap = false;
end

%% Actually make the animation

% Create a surface structure
surface.vertices = verts{Nsurfaces};
surface.faces = faces;

% Determine whether to plot the boundary and set the vertex data and
% parcellation values
plotBoundary = p.Results.plotBoundary;

% Get the climits to use
if p.Results.varyClimits
    current_climits = [nanmin(current_vertData) nanmax(current_vertData)];
else
    current_climits = climits;
end

vertParc = p.Results.vertParc;

current_climits(isnan(current_climits)) = 0;

% If the boundary is not plotted or the vertex parcellation is uniform,
% plot the surface without the boundary
if ~p.Results.plotBoundary || length(unique(p.Results.vertParc)) == 1
    plotBoundary = false;
    [surf_patch,b] = plotSurfaceROIBoundary(surface,vertParc,current_vertData,'none',current_colormap,1,current_climits);
   
% Otherwise, plot the surface with the boundary
else
    [surf_patch,b] = plotSurfaceROIBoundary(surface,vertParc,current_vertData,'midpoint',current_colormap,p.Results.boundaryWidth,current_climits);  
end

% Add two camlights to the plot and set the view angle, axis properties
for i = 1:size(p.Results.camlights,1)
   camlight(p.Results.camlights(i,1),p.Results.camlights(i,2)) 
end

view(p.Results.viewAngle)
axis off
axis vis3d
axis tight
axis equal

% Freeze the axis limits
xlim manual
ylim manual
zlim manual

% Set the number of "frames" and create the output directory (if specified)
F = p.Results.NInterpPoints;

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

for i = 1:p.Results.freezeFirstFrame

    % If an output directory is provided, save the first frame
    if ~isempty(p.Results.outdir)
        print([outdir,'/Frame',num2str(Iter),'.png'],'-dpng')
    end

    if ~isempty(p.Results.outgif)
        if i == 1
        gif(p.Results.outgif,'DelayTime',gifoptions.DelayTime,'DitherOption',gifoptions.DitherOption,'LoopCount',gifoptions.LoopCount,...
        'frame',gifoptions.frame,'resolution',gifoptions.resolution,'overwrite',gifoptions.overwrite);
        else
            gif
        end
    end

    Iter = Iter + 1;

end

% Loop through each pair of surface vertices and interpolate between them
for i = 1:Nsurfaces-1

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
        
        if varyCmap
            switch p.Results.cmapInterpType
            case 'RGB'
                % Do nothing because everything is done
                current_colormap = find_point_on_line(all_colormaps{i},all_colormaps{i+1},r(j+1));
            case 'HSV' 
                current_colormap = hsv2rgb(find_point_on_line(all_colormaps{i},all_colormaps{i+1},r(j+1)));
            end
        end

        if vary_vertData
            
            current_vertData = find_point_on_line(p.Results.vertData{i},p.Results.vertData{i+1},r(j+1));
            if p.Results.varyClimits
                current_climits = [nanmin(current_vertData) nanmax(current_vertData)];
            else
                current_climits = climits;
            end

            % Avoid cases of climits having a nan in them
            current_climits(isnan(current_climits)) = 0;
                   
        end

        if vary_vertData || varyCmap
            FaceVertexCData = makeFaceVertexCData(newVerts,surface.faces,vertParc,current_vertData,current_colormap,current_climits,0);
            surf_patch.FaceVertexCData = FaceVertexCData;
        end
        % Pause for a short time to ensure that the frame is generated so
        % it can be appropriately saved
        pause(.1)
        % If an output directory is provided, save the current frame

        if ~(i == Nsurfaces-1 && j == F-1 && p.Results.saveLastFrame)

        if ~isempty(p.Results.outdir)
            print([outdir,'/Frame',num2str(Iter),'.png'],'-dpng')
        end
        
        if ~isempty(p.Results.outgif)
           gif 
        end

        end
        % Increment the iteration counter
        Iter = Iter + 1;
    end

end

% Freeze the last frame if needed
if  p.Results.freezeLastFrame > 1 && p.Results.saveLastFrame
    for i = 1:p.Results.FreezeFirstFrame-1
        if ~isempty(p.Results.outdir)
            print([outdir,'/Frame',num2str(Iter),'.png'],'-dpng')
        end
        
        if ~isempty(p.Results.outgif)
           gif 
        end 
        % Increment the iteration counter
        Iter = Iter + 1;
    end   
end