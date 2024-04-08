function imgFullPath = imgPumpkin(reportInfo, analyzedData, componentSettings)
    % FIGURA
    fg = uifigure;
    gl = uigridlayout(fg, [1 1], 'BackgroundColor', 'white'); 
    ax = uiaxes(gl); 

    % PLOT
    % https://blogs.mathworks.com/graphics-and-apps/2023/10/31/gourds-to-graphics-the-matlab-pumpkin/
    numPrimaryBumps = 10;
    totalBumps = numPrimaryBumps*2; % Add in-between creases.
    vertsPerBump = 10;
    numVerts = totalBumps*vertsPerBump+1;
    
    rPrimary = linspace(0,numPrimaryBumps*2,numVerts);
    rSecondary = linspace(0,totalBumps*2,numVerts);
    
    crease_depth = .04;
    crease_depth2 = .01;
    Rxy_primary = 0 - (1-mod(rPrimary,2)).^2*crease_depth;
    Rxy_secondary = 0 - (1-mod(rSecondary,2)).^2*crease_depth2;
    Rxy = Rxy_primary + Rxy_secondary;
    
    [ Xsphere, Ysphere, Zsphere ] = sphere(numVerts-1); % Sphere creates +1 verts
    Xpunkin = (1+Rxy).*Xsphere;
    Ypunkin = (1+Rxy).*Ysphere;

    dimple = .2; % Fraction to dimple into top/bottom
    rho = linspace(-1,1,numVerts)';
    Rz_dimple = (0-rho.^4)*dimple;
    heightratio = .8;
    Zpunkin = (1+Rxy).*Zsphere.*(heightratio+Rz_dimple);

    Rstem = (1-(1-mod(rPrimary+1,2)).^2)*.05;
    thetac = linspace(0,2,numVerts);
    Xcyl = cospi(thetac);
    Ycyl = sinpi(thetac);
    Zcyl = linspace(0,1,11)'; % column vector
    Rstemz = .7+(1-Zcyl).^2*.6;

    Xstem = (.1+Rstem).*Xcyl.*Rstemz;
    Ystem = (.1+Rstem).*Ycyl.*Rstemz;
    Zstem = repmat(Zcyl*.15,1,numVerts);

    Spunkin = surf(ax, Xpunkin,Ypunkin,Zpunkin,'FaceColor','interp','EdgeColor','none');
    colormap(ax, validatecolor({'#da8e26' '#dfc727'},'multiple'));
    Sstem = surface(ax, Xstem,Ystem,Zstem+heightratio^2,'FaceColor','#3d6766','EdgeColor','none');
    Pstem = patch(ax, 'Vertices', [Xstem(end,:)' Ystem(end,:)' Zstem(end,:)'+heightratio^2],...
                'Faces', 1:numVerts, ...
                'FaceColor','#b1cab5','EdgeColor','none');
    daspect(ax, [1 1 1])
    camlight(ax)

    Cpunkin = hypot(hypot(Xpunkin,Ypunkin),(1+Rxy).*Zsphere); % As if pumpkin were round with no dimples
    set(Spunkin,'CData',Cpunkin); % Pumpkin CData
    set(Sstem,'CData',[]); % Make sure the stem doesn't contribute to auto Color Limits

    set(Spunkin,'CData',Cpunkin+randn(numVerts)*0.015);

    axis(ax, 'off')
    camzoom(ax, 1.8)
    lighting(ax, "gouraud")
    material([Spunkin Sstem Pstem],[ .6 .9 .3 2 .6 ])

    % ARQUIVO
    imgFullPath = fullfile(fileparts(fileparts(mfilename("fullpath"))), 'img_internal', 'Pumpkin.png');
    if ~isfile(imgFullPath)
        exportgraphics(ax, imgFullPath)
    end
end