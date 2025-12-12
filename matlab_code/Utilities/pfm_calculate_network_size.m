function NetworkSize = pfm_calculate_network_size(FunctionalNetworks, VA, Structures)
% simplified network size calculation for the pfm tutorial
% uses vertex-wise labels and vertex areas only
% returns % of cortical surface for each network (in the order of unique labels)

% get label vector (network id per vertex/greyordinate)
if isfield(FunctionalNetworks, 'data')
    labels = FunctionalNetworks.data;
elseif isfield(FunctionalNetworks, 'cdata')
    labels = FunctionalNetworks.cdata;
else
    error('could not find .data or .cdata in FunctionalNetworks');
end

labels = labels(:);

% get vertex areas
if isfield(VA, 'data')
    va = VA.data;
elseif isfield(VA, 'cdata')
    va = VA.cdata;
else
    error('could not find .data or .cdata in VA');
end

va = va(:);

% crude cortex mask: positive area only
cortex_mask = va > 0;

labels = labels(cortex_mask);
va     = va(cortex_mask);

% total cortical surface area
total_area = sum(va);

% unique network ids (ignore 0 / unlabeled)
uCi = unique(labels);
uCi(uCi == 0) = [];

NetworkSize = zeros(1, numel(uCi));

for i = 1:numel(uCi)
    this_label = uCi(i);
    idx = labels == this_label;
    NetworkSize(i) = 100 * sum(va(idx)) / total_area;
end
end