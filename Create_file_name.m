function [result_file_name] = Create_file_name(file_name, suffix)

    splits2 = split(file_name, '/');
    
    if length(splits2) == 1
        splits2 = split(file_name, '\')';
    end
    
    name = splits2(1);
    
    for i = 2 : length(splits2)
        if splits2(i) == "Images"
            name = name + "\" + 'Results';    
        else
            name = name + "\" + splits2(i);
        end
    end
    
    splits = split(name, '.');
    result_file_name = splits(1) + "_" + suffix + ".png";
end

