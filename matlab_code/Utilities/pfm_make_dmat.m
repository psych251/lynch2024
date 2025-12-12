function pfm_make_dmat(RefCifti,MidthickSurfs,OutDir,nWorkers,WorkbenchBinary)
% cjl2007@med.cornell.edu
% serial version without parallel computing toolbox

% make tmp directory if needed
try
    mkdir([OutDir '/tmp/']);
catch
end

% load reference cifti if a filename was passed
if ischar(RefCifti)
    RefCifti = ft_read_cifti_mod(RefCifti);
end

% remove data (not needed for distance matrix)
if isfield(RefCifti,'data')
    RefCifti.data = [];
end

% load midthickness surfaces
LH = gifti(MidthickSurfs{1});
RH = gifti(MidthickSurfs{2});

% find cortical vertices on surface cortex (exclude medial wall)
% note: assumes field 'brainstructure' exists in RefCifti, with
%   1/2 = cortex, -1 = medial wall, >2 = subcortical / cerebellum
lh_idx = RefCifti.brainstructure(1:length(LH.vertices)) ~= -1;
rh_idx = RefCifti.brainstructure((length(LH.vertices)+1):(length(LH.vertices)+length(RH.vertices))) ~= -1;

% reference vertex indices on each surface
LH_verts = 1:length(LH.vertices);
RH_verts = 1:length(RH.vertices);

% keep cortex-only vertices
LH_verts = LH_verts(lh_idx);
RH_verts = RH_verts(rh_idx);

% preallocate distance matrices for each hemisphere
nLH = sum(lh_idx);
nRH = sum(rh_idx);

lh = zeros(nLH, length(LH_verts), 'single');
rh = zeros(nRH, length(RH_verts), 'single');

%% sweep through left-hemisphere vertices (geodesic distance)

for i = 1:length(LH_verts)

    % compute geodesic distances from vertex i on left surface
    cmd = [WorkbenchBinary ' -surface-geodesic-distance ' ...
           MidthickSurfs{1} ' ' num2str(LH_verts(i)-1) ' ' ...
           OutDir '/tmp/temp_' num2str(i) '.shape.gii'];
    system(cmd);

    temp = gifti([OutDir '/tmp/temp_' num2str(i) '.shape.gii']);

    % clean up temp file
    system(['rm ' OutDir '/tmp/temp_' num2str(i) '.shape.gii']);

    % store distances for cortex-only vertices
    lh(:,i) = single(temp.cdata(lh_idx));
end

% convert to uint8
lh = uint8(lh);

%% sweep through right-hemisphere vertices (geodesic distance)

for i = 1:length(RH_verts)

    % compute geodesic distances from vertex i on right surface
    cmd = [WorkbenchBinary ' -surface-geodesic-distance ' ...
           MidthickSurfs{2} ' ' num2str(RH_verts(i)-1) ' ' ...
           OutDir '/tmp/temp_' num2str(i) '.shape.gii'];
    system(cmd);

    temp = gifti([OutDir '/tmp/temp_' num2str(i) '.shape.gii']);

    % clean up temp file
    system(['rm ' OutDir '/tmp/temp_' num2str(i) '.shape.gii']);

    % store distances for cortex-only vertices
    rh(:,i) = single(temp.cdata(rh_idx));
end

% convert to uint8
rh = uint8(rh);

% remove temp dir
[~,~] = system(['rm -rf ' OutDir '/tmp/']);

%% combine hemispheric geodesic distances

% 999 marks inter-hemispheric distances in the geodesic-only matrix
top    = [lh, uint8(ones(size(lh,1), size(rh,2)) * 999)];
bottom = [uint8(ones(size(rh,1), size(lh,2)) * 999), rh];

% cortical surface only so far
D = uint8([top; bottom]);

% save cortex-only distance matrix
save([OutDir '/DistanceMatrixCortexOnly'],'D','-v7.3');

%% add subcortex using euclidean distances

% concatenate cortical coordinates (lh + rh)
coords_surf = [LH.vertices; RH.vertices];

% indices of surface vertices in cifti brainstructure
surf_indices_incifti = RefCifti.brainstructure > 0 & RefCifti.brainstructure < 3;
surf_indices_incifti = surf_indices_incifti(1:size(coords_surf,1));

% keep only vertices that are present in cifti
coords_surf = coords_surf(surf_indices_incifti,:);

% subcortical coordinates
coords_subcort = RefCifti.pos(RefCifti.brainstructure > 2, :);

% combined coordinates: cortical then subcortical
coords = [coords_surf; coords_subcort];

% full euclidean distance matrix (all vertices / voxels)
D2 = uint8(pdist2(coords, coords));

% integrate euclidean distances into full matrix:
%   - first keep existing cortical–cortical geodesic distances (D)
%   - then fill rows/cols for subcortical with euclidean distances

% add new rows: distances from subcortical to cortical vertices
D = [D; D2(size(D,1)+1:end, 1:size(D,2))];

% add new columns: distances from cortical vertices to subcortical
D = [D, D2(1:size(D,1), size(D,2)+1:end)];

% save full distance matrix (cortex + subcortex)
save([OutDir '/DistanceMatrix'],'D','-v7.3');

% clear to free memory
clear D;

end