function Cifti = ft_read_cifti_mod(filename, varargin)
% minimal wrapper for reading cifti files for pfm
% uses cifti_read from cifti-matlab and exposes .data

    % read cifti with cifti-matlab
    c = cifti_read(filename);

    % initialize output struct
    Cifti = struct();

    % cifti-matlab uses .cdata
    data = c.cdata;

    % simple orientation check
    % we want vertices x time
    if size(data,1) > size(data,2)
        % data is likely time x vertices -> transpose
        data = data.';
    end

    Cifti.data = data;

    % brainstructure labels (if available)
    Cifti.brainstructurelabel = {};

    if numel(c.diminfo) >= 1 && strcmp(c.diminfo{1}.type,'brain_models')
        bm = c.diminfo{1}.models;
        labels = cell(numel(bm),1);
        for i = 1:numel(bm)
            labels{i} = bm{i}.brainstructure;
        end
        Cifti.brainstructurelabel = labels;
    end

    % store filename for use by writer
    Cifti.hdr = struct();
    Cifti.hdr.filename = filename;
end