%% A tutorial covering precision functional mapping using an example dataset. 
% Reproducibility variant: this version reproduces the functional network
% size estimates using author-provided intermediate PFM outputs.

%% Before you begin.

% add dependencies to matlab search path
addpath(genpath('/Users/eu/Documents/GitHub/PFM-Depression/PFM-Tutorial/Utilities'));

% add cifti-matlab (v2) utilities to path
addpath(genpath('/Users/eu/Documents/MATLAB/cifti-matlab'));

% define path to some software packages that will be needed
InfoMapBinary   = '/Users/eu/tools/infomap/Infomap';                          % not used here
WorkbenchBinary = '/Users/eu/Downloads/workbench/bin_macosxub/wb_command';    % not used here

% number of workers (kept for consistency with original script)
nWorkers = 6;

%% Step 1: Temporal Concatenation of fMRI data from all sessions.

% in the original workflow, data from all sessions were temporally concatenated
% and written to the file:
%       sub-ME01_task-rest_concatenated_32k_fsLR.dtseries.nii
%
% for this reproducibility workflow, we reuse the author-provided file.

Subdir  = '/Users/eu/Documents/GitHub/ds005118/derivatives/sub-ME01/';
Subject = 'ME01';
PfmDir  = [Subdir '/pfm/'];

ConcFile = [PfmDir '/sub-ME01_task-rest_concatenated_32k_fsLR.dtseries.nii'];

if ~isfile(ConcFile)
    error('concatenated CIFTI file not found: %s', ConcFile);
end

fprintf('Step 1: Found author-provided concatenated dtseries.\n');
ConcatenatedCifti = ft_read_cifti_mod(ConcFile); %#ok<NASGU>

%% Step 2: Make a distance matrix.

% the original pipeline generated a distance matrix using geodesic and euclidean
% distances between cortical and subcortical points.
%
% for this reproducibility workflow, we reuse the author-provided distance matrix.

DistFile = [PfmDir '/DistanceMatrix.mat'];
if ~isfile(DistFile)
    error('distance matrix not found: %s', DistFile);
end

fprintf('Step 2: Using author-provided distance matrix.\n');

%% Step 3: Apply spatial smoothing.

% the original workflow applied gaussian geodesic smoothing to the concatenated data.
% for this reproducibility workflow, we use the author-provided smoothed file
% corresponding to sigma = 2.55 mm, which is used downstream.

SmoothFile = [PfmDir '/sub-ME01_task-rest_concatenated_smoothed2.55_32k_fsLR.dtseries.nii'];

if ~isfile(SmoothFile)
    error('smoothed dtseries not found: %s', SmoothFile);
end

fprintf('Step 3: Found author-provided smoothed dtseries.\n');
SmoothedCifti = ft_read_cifti_mod(SmoothFile); %#ok<NASGU>

%% Step 4: Run infomap.

% in the original tutorial, infomap communities are computed from the smoothed
% data and distance matrix. this step requires legacy cifti fields and a full
% infomap installation.
%
% for the reproducibility workflow, we rely on the author-provided infomap output.

InfomapDT = [PfmDir '/Bipartite_PhysicalCommunities.dtseries.nii'];
if ~isfile(InfomapDT)
    error('infomap community dtseries not found: %s', InfomapDT);
end

fprintf('Step 4: Using author-provided Infomap community assignments.\n');
InfomapCifti = ft_read_cifti_mod(InfomapDT); %#ok<NASGU>

%% Step 5: Algorithmic assignment of network identities.

% the original workflow spatially filters infomap outputs and assigns network
% identities using a set of priors.
%
% for reproduction, we use the spatially filtered community assignments provided
% by the authors.

SpatialFilt = [PfmDir '/Bipartite_PhysicalCommunities+SpatialFiltering.dtseries.nii'];
if ~isfile(SpatialFilt)
    error('spatial filtering dtseries not found: %s', SpatialFilt);
end

Ic = ft_read_cifti_mod(SpatialFilt);
fprintf('Step 5: Loaded spatially filtered communities.\n');

%% Step 6: Review algorithmic network assignments.

% in the original workflow, manual decisions regarding the assignment of networks
% were parsed and saved into a final labeling file.
%
% here we reuse the final labeling file prepared by the authors.

FinalLabel = [PfmDir '/Bipartite_PhysicalCommunities+FinalLabeling.dlabel.nii'];
if ~isfile(FinalLabel)
    error('final labeling dlabel not found: %s', FinalLabel);
end

fprintf('Step 6: Using author-provided final network labeling.\n');

% for the final step, we will use cifti_read (v2) to get the data and metadata
FN = cifti_read(FinalLabel);

%% Step 7: Calculate size of each functional brain network.

% load vertex area map (surface area per vertex, in mm^2)
VAFile = [Subdir '/fs_LR/fsaverage_LR32k/' Subject '.midthickness_va.32k_fs_LR.dscalar.nii'];

if ~isfile(VAFile)
    error('vertex area file not found: %s', VAFile);
end

VA = cifti_read(VAFile);

% extract data vectors
labels_all = FN.cdata(:);    % integer network labels at each grayordinate
area_all   = VA.cdata(:);    % vertex/voxel area (mm^2)

% restrict to cortical surface; midthickness_va is > 0 for cortical vertices
cortex_mask = area_all > 0;
labels_cx   = labels_all(cortex_mask);
area_cx     = area_all(cortex_mask);

% exclude unlabeled vertices (label == 0)
valid_mask  = labels_cx > 0;
labels_cx   = labels_cx(valid_mask);
area_cx     = area_cx(valid_mask);

% unique functional networks (ids) present in cortex
uCi = unique(labels_cx);

% load priors (network labels and colors)
load('priors.mat');  % expects Priors.NetworkLabels and Priors.NetworkColors

% preallocate network sizes as percent of cortical surface
NetworkSize = nan(1, length(Priors.NetworkLabels));

total_area = sum(area_cx);

% sweep through the networks; assume network ids correspond to rows in Priors
for i = 1:length(uCi)
    net_id = uCi(i);
    if net_id <= length(Priors.NetworkLabels)
        this_area = sum(area_cx(labels_cx == net_id));
        NetworkSize(net_id) = (this_area / total_area) * 100;
    end
end

fprintf('Step 7: Recomputed network sizes from final labeling and vertex areas.\n');

%% Plot functional network sizes.

close all; % blank slate
H = figure; % preallocate parent figure
set(H,'position',[1 1 325 400]); hold on;

for i = 1:length(Priors.NetworkLabels)
    Tmp = nan(1,length(Priors.NetworkLabels));
    Tmp(i) = NetworkSize(i);
    barh(Tmp,'FaceColor',Priors.NetworkColors(i,:));
    if ~isnan(NetworkSize(i))
        text((NetworkSize(i)+0.1), i, [num2str(NetworkSize(i),3) '%']);
    end
end

yticklabels(Priors.NetworkLabels);
yticks(1:length(Priors.NetworkLabels));
ylim([0 length(Priors.NetworkLabels)+1]);
xlim([0 20]);
xticks(0:5:20);
set(gca,'fontname','arial','fontsize',10,'TickLength',[0 0],'TickLabelInterpreter','none');
xlabel('% of Cortical Surface');

outfig = [PfmDir '/FunctionalNetworkSizes_repro'];
print(gcf, outfig, '-dpdf');

fprintf('Functional network size figure written to:\n  %s.pdf\n', outfig);
fprintf('Reproducibility workflow complete (final network-size stage).\n');