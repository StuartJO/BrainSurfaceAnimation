% This shows an example of how to use this script

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
SurfMorphAnimation(fetal_verts,fetal_faces,'NInterpPoints',10,'outgif','./outputs/GrowingBrain.gif')

% Plot the brain now with the borders of the parcellation
SurfMorphAnimation(fetal_verts,fetal_faces,'NInterpPoints',10,'vertParc',parc,'colormap',[.5 .5 .5],'outgif','./outputs/GrowingBrain_border.gif')

% Plot the brain now with the colours/borders of the parcellation 
SurfMorphAnimation(fetal_verts,fetal_faces,'NInterpPoints',10,'vertParc',parc,'vertData',parc,'outgif','./outputs/GrowingBrain_parc+border.gif')

% The commented code below will do exactly the same as above, however it
% uses the plotSurfaceROIBoundary code to assign values to each parcel
% rather than directly specifying each vertex
%SurfMorphAnimation(fetal_verts,fetal_faces,'frames',5,'vertParc',parc,'vertData',1:N)

% Plot the brain with the colours of the parcellation and no border
SurfMorphAnimation(fetal_verts,fetal_faces,'NInterpPoints',5,'vertParc',parc,'vertData',1:N,'plotBoundary',false,'outgif','./outputs/GrowingBrain_parc.gif')

% Plot the brain now with the borders of the parcellation and coloured by
% sulcal depth at each timepoint;
SurfMorphAnimation(fetal_verts,fetal_faces,'NInterpPoints',10,'vertParc',parc,'vertData',fetal_sulc{16},'outgif','./outputs/GrowingBrain_border+sulcAll.gif')

% Plot the brain now with the borders of the parcellation and coloured by
% sulcal depth at each timepoint (color range is set to the min/max across 
% all timepoint;
SurfMorphAnimation(fetal_verts,fetal_faces,'NInterpPoints',10,'vertParc',parc,'vertData',fetal_sulc,'outgif','./outputs/GrowingBrain_border+sulc36.gif')

% Plot the brain now with the borders of the parcellation and coloured by
% sulcal depth at each timepoint (color range is set to the min/max across 
% all timepoint;
SurfMorphAnimation(fetal_verts,fetal_faces,'NInterpPoints',10,'vertParc',parc,'vertData',fetal_sulc,'varyClimits',true,'outgif','./outputs/GrowingBrain_border+sulcAll2.gif')

% For fun, show the surface inflates to a sphere and back again
SurfMorphAnimation({fetal_verts{16},fetal36_sphere_verts*.4,fetal_verts{16}},fetal_faces,'NInterpPoints',30,'vertParc',parc,'vertData',parc,'outgif','./outputs/Sphere_inflation.gif')

SurfMorphAnimation({fetal_verts{16},fetal36_sphere_verts*.4,fetal_verts{16}},fetal_faces,'NInterpPoints',30,'vertParc',parc,'vertData',{fetal_sulc{16},parc,fetal_sulc{16}},...
'colormap',{parula(N),turbo(N),parula(N)},'varyClimits',true,'outgif','./outputs/Sphere_inflation_vartCmap_sulc_parc.gif')
