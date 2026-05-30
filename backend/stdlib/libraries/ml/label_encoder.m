function [encoded, classes] = label_encoder(labels)
    % LABEL_ENCODER Encode target labels with value between 1 and n_classes
    classes = unique(labels);
    encoded = zeros(size(labels));
    for i = 1:length(classes)
        encoded(labels == classes(i)) = i;
    end
end
