function [result_img, bin_level] = Watershed(file_name, log, open_radius, sharpen_radius, thresh, sigma, gaussian_sigma, guassian_filter, bin_level)
    I = imread(file_name);

    % open operation
    disk_kernel = Disk_kernel(open_radius);
    opening_img = imopen(I, disk_kernel);

    if log == true
        imwrite(opening_img, Create_file_name(file_name, "open", "Watershed\Steps"));
    end

    % change to grayscale for JPG
    if Check_If_JPG(file_name)
        opening_img = rgb2gray(opening_img);
    end
        
    % sharpening image
    if sharpen_radius ~= 0
        sharpened_img = imsharpen(opening_img, "Radius", sharpen_radius);
    else
        sharpened_img = opening_img;
    end

    % FIRST PARALLEL 
    % START

        % canny detection
        edge_img = edge(sharpened_img,'canny', thresh, sigma);
        if isa(opening_img, 'uint8')
            edge_img = uint8(255 * edge_img);
        else
            edge_img = uint16(65535 * edge_img);
        end

        if log == true
            imwrite(edge_img, Create_file_name(file_name, "edge", "Watershed\Steps"));
        end

        % add edge to sharpened img
        added_img = sharpened_img + edge_img;
        if log == true
            imwrite(added_img, Create_file_name(file_name, "add", "Watershed\Steps"));
        end

        % gradient filtering
        [gmag, ~] = imgradient(added_img);
        gmag = rescale(gmag);

        if log == true
            imwrite(gmag, Create_file_name(file_name, "gradient", "Watershed\Steps"));
        end

    % FIRST PARALLEL 
    % END

    % SECOND PARALLEL 
    % START

        % binarization OTSU threshold
        if nargin < 9
            bin_level = graythresh(sharpened_img);
        end
        binary_img = imbinarize(sharpened_img, bin_level);
        if log == true
            imwrite(binary_img, Create_file_name(file_name, "bin", "Watershed\Steps"));
        end

        % filling holes
        if isa(opening_img, 'uint8')
            binary_img = uint8(255 * binary_img);
        else
            binary_img = uint16(65535 * binary_img);
        end

        filled = imfill(binary_img);
        if log == true
            imwrite(filled, Create_file_name(file_name, "fill", "Watershed\Steps"));
        end

        % distance transform
        distance_img = rescale(bwdist(~filled));

        % gaussian filtering
        gaussian_img = imgaussfilt(distance_img, gaussian_sigma, 'FilterSize', guassian_filter);
        if log == true
            imwrite(gaussian_img, Create_file_name(file_name, "gaussian", "Watershed\Steps"));
        end

        % Finding markers(MS)/ extended maxima detection
        img = imextendedmax(gaussian_img, 0.001);
        if log == true
            imwrite(img, Create_file_name(file_name, "MAX", "Watershed\Steps"));
        end

    % SECOND PARALLEL 
    % END

    % adding two together
    combined_img = imimposemin(gmag, img);
    
    if log == true
        imwrite(combined_img, Create_file_name(file_name, "combined", "Watershed\Steps"));
    end
    
    % watershed
    water_img = watershed(combined_img);
    if isa(opening_img, 'uint8')
        water_img = uint8(255 * water_img);
    else
        water_img = uint16(65535 * water_img);
    end

    % binarization OTSU threshold
    level = graythresh(water_img);
    binary_img = imbinarize(water_img, level);

    % deleting border objects
    result_img = imclearborder(binary_img);

    if isa(opening_img, 'uint8')
        result_img = uint8(255 * result_img);
    else
        result_img = uint16(65535 * result_img);
    end
    result_img = imfill(result_img);

    if log == true
        imwrite(result_img, Create_file_name(file_name, "result", "Watershed\Steps"));
    end

end

