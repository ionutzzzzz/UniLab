function obj = setGroups(obj, groups, group_min, group_max)
    % SETGROUPS Adds group constraints
    
    if nargin < 1, obj = []; end
    if nargin < 2, groups = []; end
    if nargin < 3, group_min = []; end
    if nargin < 4, group_max = []; end
    obj.Constraints.Groups = groups;
    obj.Constraints.GroupMin = group_min;
    obj.Constraints.GroupMax = group_max;
end
