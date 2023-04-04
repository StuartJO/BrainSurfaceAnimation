% This shows an example of how to use this script

addpath ./export_fig
addpath ./plotSurfaceROIBoundary

% Read in dHCP surface data
load('./data/example_fetal_data.mat')

% Create a parcellation with N parcels
N = 100;

% Parcellate the sphere using k-means clustering
parc_orig = parcellate_surface(fetal36_sphere_verts, N);

% Make the parcellation pretty
% Order ROI IDs by their dorsal-ventral position.
parc_z = zeros(N,1);

for i = 1:N
    parc_z(i) = min(fetal36_sphere_verts(parc_orig==i,3));
end
newparcval = 1:N;
[~,ordered_parc] = sort(parc_z);
parc = parc_orig;
for k = 1:numel(ordered_parc)
    parc(parc_orig == ordered_parc(k)) = newparcval(k);
end

% Just plot the brain 'growing' with no parcellation/data on it
figure
SurfMorphAnimation(fetal_verts,fetal_faces,'NInterpPoints',10,'outgif','./outputs/GrowingBrain.gif')

% Plot the brain now with the borders of the parcellation
figure
SurfMorphAnimation(fetal_verts,fetal_faces,'NInterpPoints',10,'vertParc',parc,'colormap',[.5 .5 .5],'outgif','./outputs/GrowingBrain_border.gif')

% Plot the brain now with the colours/borders of the parcellation 
figure
SurfMorphAnimation(fetal_verts,fetal_faces,'NInterpPoints',10,'vertParc',parc,'vertData',parc,'outgif','./outputs/GrowingBrain_parc+border.gif')

% The commented code below will do exactly the same as above, however it
% uses the plotSurfaceROIBoundary code to assign values to each parcel
% rather than directly specifying each vertex
%SurfMorphAnimation(fetal_verts,fetal_faces,'frames',10,'vertParc',parc,'vertData',1:N)

% Plot the brain with the colours of the parcellation and no border
figure
SurfMorphAnimation(fetal_verts,fetal_faces,'NInterpPoints',10,'vertParc',parc,'vertData',1:N,'plotBoundary',false,'outgif','./outputs/GrowingBrain_parc.gif')

% Plot the brain now with the borders of the parcellation and coloured by
% sulcal depth at the final timepoint
figure
SurfMorphAnimation(fetal_verts,fetal_faces,'NInterpPoints',10,'vertParc',parc,'vertData',fetal_sulc{16},'colormap',parula(100),'outgif','./outputs/GrowingBrain_border+sulc36.gif')

% Plot the brain now with the borders of the parcellation and coloured by
% sulcal depth at each timepoint (color range is set to the min/max across 
% all timepoints
figure
SurfMorphAnimation(fetal_verts,fetal_faces,'NInterpPoints',10,'vertParc',parc,'vertData',fetal_sulc,'colormap',parula(100),'outgif','./outputs/GrowingBrain_border+sulcAll.gif')

% Plot the brain now with the borders of the parcellation and coloured by
% sulcal depth at each timepoint (color range is set to the min/max at each 
% timepoint
figure
SurfMorphAnimation(fetal_verts,fetal_faces,'NInterpPoints',10,'vertParc',parc,'vertData',fetal_sulc,'varyClimits',true,'colormap',parula(100),'outgif','./outputs/GrowingBrain_border+sulcAll2.gif')

% Plot the brain on an inflated surface, and show the changes in sulcal
% depth across the time points on it
figure
% For this to work, need to repeat the vertices
fetal_verts_inflated_ = cell(1,length(fetal_sulc));
for i = 1:length(fetal_sulc)
fetal_verts_inflated_{i} = fetal_verts_inflated{length(fetal_sulc)};
end
SurfMorphAnimation(fetal_verts_inflated_,fetal_faces,'NInterpPoints',10,'freezeLastFrame',15,'vertData',fetal_sulc,'colormap',parula(100),'outgif','./outputs/StaticBrain_border+sulcAll.gif')

% For fun, show the surface inflation to a sphere and back again
figure
SurfMorphAnimation({fetal_verts{16},fetal36_sphere_verts*.4,fetal_verts{16}},fetal_faces,'NInterpPoints',90,'vertParc',parc,'vertData',parc,'outgif','./outputs/Sphere_inflation.gif')

% For more fun, show the surface inflation to a sphere and back again,
% while morphing from sulcal depth to parcel ID AND changing the colormap! 

figure
SurfMorphAnimation({fetal_verts{16},fetal36_sphere_verts*.4,fetal_verts{16}},fetal_faces,'NInterpPoints',90,'vertParc',parc,'vertData',{fetal_sulc{16},parc,fetal_sulc{16}},...
'colormap',{parula(N),turbo(N),parula(N)},'varyClimits',true,'outgif','./outputs/Sphere_inflation_vartCmap_sulc_parc.gif')

% Finally we can create a funky psychedelic looking animation where colours
% ripple across the brains surface

%R = randperm(size(fetal36_sphere_verts,1),5);
% Some random points I liked
R = [20666       17077        8436        1663       23780];

% To make it look like colours ripple across the surface, we just give the
% surface some 'sinks' (i.e., points to converge on), and calculate the
% distance to them. To make it look like bands of colour are moving across
% the brain, we essentilly assign a vertex two values
% ('vert_dist2randpoints' and 'vert_dist2randpoints2') and double up the
% colourmap. The colourmap is set up so this looping will work (notice the
% first value is not repeated). As the interpolation occurs for the vertex
% data, the values of the vertex will be assigned a new colour, and because
% of the way the colormap is orders, the colours will ripple on the surface

% For it to loop, we need each vertex to get back to its
% original colour. So what we can do is add a duplicate of the colormap to
% itself (in this case we quadruple it to avoid it looking too fat), and
% then we rescale the vert_dist2randpoints to a set of new values. This
% essentially means each vert_dist2randpoints is mapped 
% 
dist2randpoints = pdist2(fetal36_sphere_verts(R,:),fetal36_sphere_verts);

% For this to work the rescaling needs to be done so it is exactly half the
% size of the colormap
vert_dist2randpoints = rescale(min(dist2randpoints),1,16);
vert_dist2randpoints2 = vert_dist2randpoints+16;

trippy_cmap = [99,45,143;...
    0,125,254;...
    120,224,60;...
    255,222,61;...
    255,59,148;...
    255,222,61;...
    120,224,60;...
    0,125,254]./255;

figure
SurfMorphAnimation({fetal_verts{16},fetal_verts{16}},fetal_faces,'NInterpPoints',119,'vertParc',parc,'vertData',{vert_dist2randpoints,vert_dist2randpoints2},...
'colormap',[trippy_cmap;trippy_cmap;trippy_cmap;trippy_cmap],'outgif','./outputs/psychedelic_brain.gif','saveLastFrame',false)
