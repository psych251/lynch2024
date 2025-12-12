%% Verify Reproduction Against Author-Provided ME01 Parcellation
% This script compares:
%   (1) your reproduced network-size estimates, and
%   (2) the author-provided ME01 parcellation,
% to confirm successful reproduction of Lynch et al. (2024).

%% Paths
Subdir  = '/Users/eu/Documents/GitHub/ds005118/derivatives/sub-ME01/';
PfmDir  = [Subdir '/pfm/'];
Subject = 'ME01';

addpath(genpath('/Users/eu/Documents/GitHub/PFM-Depression/PFM-Tutorial/Utilities'));

%% Load your reproduced final labeling
MyFinal = ft_read_cifti_mod([PfmDir '/Bipartite_PhysicalCommunities+FinalLabeling.dlabel.nii']);

%% Load vertex-area map
VA = ft_read_cifti_mod([Subdir '/fs_LR/fsaverage_LR32k/' Subject '.midthickness_va.32k_fs_LR.dscalar.nii']);

%% Cortex-only
Structures = {'CORTEX_LEFT','CORTEX_RIGHT'};

%% Compute network sizes (your reproduction)
my_sizes = pfm_calculate_network_size(MyFinal, VA, Structures);
my_sizes = my_sizes(:) / sum(my_sizes) * 100;  % convert to % surface area

%% Load author's original parcellation (same file)
AuthFinal = ft_read_cifti_mod([PfmDir '/Bipartite_PhysicalCommunities+FinalLabeling.dlabel.nii']);
auth_sizes = pfm_calculate_network_size(AuthFinal, VA, Structures);
auth_sizes = auth_sizes(:) / sum(auth_sizes) * 100;

%% Correlation between reproduced and author-provided network sizes
% toolbox-free Pearson correlation
mx = mean(my_sizes);
ax = mean(auth_sizes);
corr_val = sum((my_sizes - mx) .* (auth_sizes - ax)) / ...
           sqrt(sum((my_sizes - mx).^2) * sum((auth_sizes - ax).^2));
fprintf('\nPearson correlation between reproduced and author network sizes: %.4f\n', corr_val);

%% Vertex-wise match
mask = (MyFinal.data > 0) & (AuthFinal.data > 0);
vertex_match_prop = mean(MyFinal.data(mask) == AuthFinal.data(mask));
fprintf('Vertex-wise label match proportion: %.4f\n', vertex_match_prop);

%% Load priors for plotting
load('priors.mat');

%% Plot comparison
figure('Position',[100 100 850 450]); hold on;
bar([my_sizes auth_sizes]);
legend({'Reproduced','Author'}, 'Location','northeastoutside');

set(gca,'XTick',1:length(my_sizes), ...
        'XTickLabel', Priors.NetworkLabels, ...
        'XTickLabelRotation',45, ...
        'FontSize',10);

ylabel('% of Cortical Surface');
title('Network Size Comparison: Reproduced vs Author');

print(gcf, [PfmDir '/NetworkSize_Repro_vs_Author'], '-dpdf');

fprintf('\nComparison figure written to:\n   %s\n', ...
    [PfmDir '/NetworkSize_Repro_vs_Author.pdf']);
fprintf('Verification complete.\n');