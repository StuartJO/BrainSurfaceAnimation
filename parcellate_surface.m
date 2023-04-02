function parc = parcellate_surface(vertices, n_clusters,ignore_verts)
   
    if nargin < 3
        ignore_verts = [];
        parc = zeros(size(vertices,1),1);
    end

    vertices(ignore_verts,:) = [];
    
    label = kmeans(vertices, n_clusters, 'MaxIter', 1000,'Replicates', 5);

    if isempty(ignore_verts)
        parc = label;
    else
        parc(~ignore_verts) = label; 
    end
    
end