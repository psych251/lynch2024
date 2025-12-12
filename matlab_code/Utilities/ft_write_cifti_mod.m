function ft_write_cifti_mod(filename, CiftiTemplate)
% minimal wrapper for writing cifti files for pfm
% uses cifti_write from cifti-matlab

    % we expect CiftiTemplate.data as vertices x time
    data = CiftiTemplate.data;

    if ~isfield(CiftiTemplate,'hdr') || ~isfield(CiftiTemplate.hdr,'filename')
        error('ft_write_cifti_mod: missing hdr.filename to use as cifti template.');
    end

    % load original cifti as template
    c = cifti_read(CiftiTemplate.hdr.filename);

    % try to match orientation
    if isequal(size(data), fliplr(size(c.cdata)))
        % transpose if needed
        c.cdata = data.';
    else
        c.cdata = data;
    end

    % write out new cifti
    cifti_write(c, filename);
end