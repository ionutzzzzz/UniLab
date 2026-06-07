function obj = setGroups(obj, groups, group_min, group_max)
    % SETGROUPS Adds group constraints
    
    obj.Constraints.Groups = groups;
    obj.Constraints.GroupMin = group_min;
    obj.Constraints.GroupMax = group_max;
end
