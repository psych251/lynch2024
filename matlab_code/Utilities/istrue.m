function tf = istrue(x)
% simple helper to interpret input as a boolean
% lightweight replacement for fieldtrip's istrue

% if already logical
if islogical(x)
    tf = x;
    return;
end

% numeric: non-zero = true
if isnumeric(x)
    tf = (x ~= 0);
    return;
end

% char or string: typical "true" strings
if ischar(x) || (isstring(x) && isscalar(x))
    s = lower(strtrim(char(x)));
    tf = any(strcmp(s, {'yes','true','on','y'}));
    return;
end

% anything else: non-empty = true
tf = ~isempty(x);
end