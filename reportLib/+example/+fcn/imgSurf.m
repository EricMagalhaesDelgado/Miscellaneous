function imgFullPath = imgSurf(reportInfo, analyzedData, callingApp, imgSettings)
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
    drawnow

    % ARQUIVO
    if isfield(reportInfo, 'userPath')
        userPath = reportInfo.userPath;
    else
        userPath = tempname;
        mkdir(userPath)
    end

    imgFullPath = fullfile(userPath, 'Surf.png');
    exportgraphics(ax, imgFullPath)
end