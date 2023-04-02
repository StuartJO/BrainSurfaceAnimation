
Nparc = 100;

parc_orig = parcellate_surface(fetal36_sphere_verts, Nparc);

% Make the parcellation pretty
% Order ROI IDs by their dorsal-ventral position.
parc_z = zeros(Nparc,1);

for i = 1:Nparc
    parc_z(i) = min(fetal36_sphere_verts(parc_orig==i,3));
end
newparcval = 1:Nparc;
[~,ordered_parc] = sort(parc_z);
parc = parc_orig;
for k = 1:numel(ordered_parc)
    parc(parc_orig == ordered_parc(k)) = newparcval(k);
end

ExampleAnimationFunc(fetal_verts,fetal_faces)

ExampleAnimationFunc(fetal_verts,fetal_faces,'frames',5,'vertParc',parc,'colormap',[.5 .5 .5])

ExampleAnimationFunc(fetal_verts,fetal_faces,'frames',5,'vertParc',parc,'vertData',parc)

ExampleAnimationFunc(fetal_verts,fetal_faces,'frames',5,'vertParc',parc,'vertData',1:100)

ExampleAnimationFunc(fetal_verts,fetal_faces,'frames',5,'vertParc',parc,'vertData',1:100,'plotBoundary',false)

ExampleAnimationFunc(fetal_verts,fetal_faces,'frames',5,'vertData',parc)