classdef ImageInfo
    properties
        Path
        Name
        Category
    end
    
    methods
        function obj = ImageInfo(path, category)
            obj.Path = char(path);
            obj.Name = Path.GetFileName(path);
            obj.Category = char(category);
        end
        
        function indentifier = GetIndentifier(obj)
            indentifier = strcat(obj.Category, "    ", obj.Name);
        end

        function image = GetImage(obj)
            image = imread(obj.Path);
        end

        function image = GetImageGray(obj)
            image = obj.GetImage();
            % change to grayscale for JPG
            if Path.IsJpgFile(obj.Path)
                image = rgb2gray(image);
            end
        end
    end
end

