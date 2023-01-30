function padImg = padImageCenter_f(img, imgSize, padVal)
% Bonheur et al., 2022
%
% Use this to pad cell images to the correct size for auto segmentation.
    targetSize = [imgSize, imgSize];
    imgP = padarray(img, targetSize, padVal);
    win = centerCropWindow2d(size(imgP, [1 2]), targetSize);
    padImg = imcrop(imgP, win);

end
