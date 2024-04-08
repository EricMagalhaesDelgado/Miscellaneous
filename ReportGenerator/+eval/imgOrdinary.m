function imgFullPath = imgOrdinary(reportInfo, analyzedData, imgSettings)
    imgSource = imgSettings.Source;
    imgIndex  = find(strcmp({analyzedData.HTML.Component}, 'Image') & strcmp({analyzedData.HTML.Source}, imgSource), 1);
    if ~isempty(imgIndex)
        imgFullPath = analyzedData.HTML(imgIndex).Value;
    end
end