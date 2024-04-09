function imgFullPath = imgOrdinary(reportInfo, analyzedData, callingApp, imgSettings)
    imgSource = imgSettings.Source;
    imgIndex  = find(strcmp({analyzedData.HTML.Component}, 'Image') & strcmp({analyzedData.HTML.Source}, imgSource), 1);
    if ~isempty(imgIndex)
        imgFullPath = analyzedData.HTML(imgIndex).Value;
    end
end