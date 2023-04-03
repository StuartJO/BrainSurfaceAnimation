function parc = parcellate_surface(vertices, n_clusters,ignore_verts)

% This function takes in a set of vertices from a surface mesh, clusters them
% into a specified number of parcels using k-means clustering, and returns
% a parcellation map of the surface with each vertex assigned to a parcel.
%
% Inputs:
% - vertices: a Nx3 matrix containing the x,y,z coordinates of each vertex
% in the surface mesh
% - n_clusters: an integer specifying the desired number of parcels
% - ignore_verts (optional): a vector containing indices of vertices to be
% ignored in the clustering process (e.g. vertices from a specific region)
%
% Outputs:
% - parc: a Nx1 vector containing the parcel number assigned to each vertex
% in the surface mesh
%
% Notes:
% - The k-means clustering algorithm used has a maximum iteration of 1000
% and is repeated 5 times to increase robustness of results.
% - If no vertices are specified to be ignored, the function assigns the
% parcel numbers to all vertices in the mesh. Otherwise, it only assigns
% parcel numbers to non-ignored vertices.

% If ignore_verts is not provided, initialize parc with zeros
% (default behavior when all vertices are included in clustering)

    if nargin < 3
        ignore_verts = [];
        parc = zeros(size(vertices,1),1);
    end

    % Remove ignored vertices from the vertices matrix
    vertices(ignore_verts,:) = [];
    
    % Perform k-means clustering on the remaining vertices
    label = kmeans(vertices, n_clusters, 'MaxIter', 1000,'Replicates', 5);

    % Assign cluster labels to the appropriate vertices in parc
    if isempty(ignore_verts)
        parc = label;
    else
        parc(~ignore_verts) = label; 
    end
    
end