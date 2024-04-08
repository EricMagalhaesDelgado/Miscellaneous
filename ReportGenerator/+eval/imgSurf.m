function imgFullPath = imgSurf(reportInfo, analyzedData, componentSettings)
    % FIGURA
    fg = uifigure;
    gl = uigridlayout(fg, [1 1], 'BackgroundColor', 'white'); 
    ax = uiaxes(gl); 

    % PLOT
    [X,Y,Z] = peaks(25);
    CO(:,:,1) = zeros(25); % red
    CO(:,:,2) = ones(25).*linspace(0.5,0.6,25); % green
    CO(:,:,3) = ones(25).*linspace(0,1,25); % blue
    surf(ax, X,Y,Z,CO);

    % ARQUIVO
    imgFullPath = fullfile(fileparts(fileparts(mfilename("fullpath"))), 'img_internal', 'Surf.png');
    if ~isfile(imgFullPath)
        exportgraphics(ax, imgFullPath)
    end
end