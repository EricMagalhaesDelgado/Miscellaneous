function apps_EXE_Post(prjName, rootFolder, matlabRuntimeCache)

    arguments
        prjName            char {mustBeMember(prjName, {'appAnalise', 'appAnaliseV2', 'appColeta', 'appColetaV2', 'SCH'})} = 'SCH'
        rootFolder         char = 'D:\InovaFiscaliza'
        matlabRuntimeCache char = 'E:\MATLAB Runtime\MATLAB Runtime (Custom)\R2024a'
    end

    % !! COMPILAÇÃO !!
    % Release: MATLAB R2024a Update6
    % Data...: 05/08/2024
    
    % appAnalise: 35000 35002 35003 35010 35108 35111 35117 35119 35136
    % appColeta.: 35000 35002 35003 35010 35108 35162
    % SCH.......: 35000 35002 35003 35010 35119 35180 35256

    % IDList = [35000 35002 35003 35010 35108 35111 35117 35119 35136 35162 35180 35256]

    prjPath  = fullfile(rootFolder, prjName);
    cd(prjPath)
    
    switch prjName
        case 'appColeta'
            appName     = 'appColeta';
            appRelease  = 'R2022a';
            appVersion  = '1.12';    
        otherwise
            appName     = class.Constants.appName;
            appRelease  = class.Constants.appRelease;
            appVersion  = class.Constants.appVersion;
    end
    
    fileName = [appName '.exe'];
    switch prjName
        case 'appAnaliseV2'
            codeRepo = 'https://github.com/InovaFiscaliza/appAnalise'; 
        otherwise
            codeRepo = ['https://github.com/InovaFiscaliza/' prjName]; 
    end
    
    switch prjName
        case 'appAnalise';   customFiles = {'GeneralSettings.json', 'mask.csv'};
        case 'appAnaliseV2'; customFiles = {'GeneralSettings.json'};
        case 'appColeta';    customFiles = {'GeneralSettings.json', 'rfeyeList.cfg', 'scpiList.json', 'mask.csv', 'taskList.json'};
        case 'appColetaV2';  customFiles = {'GeneralSettings.json', 'EMSatLib.json', 'GPSLib.json', 'instrumentList.json', 'mask.csv', 'taskList.json'};
        otherwise;           customFiles = {};
    end
    
    % % path rename
    switch prjName
        case 'SCH'
            oldPath  = fullfile(prjPath, ['win' prjName '_desktopCompiler'], 'for_redistribution_files_only');
            testPath = fullfile(prjPath, ['win' prjName '_desktopCompiler'], 'for_testing');
            newPath  = fullfile(prjPath, ['win' prjName '_desktopCompiler'], 'application');
        otherwise
            oldPath  = fullfile(prjPath, [prjName '_CompilerProject'], 'for_redistribution_files_only');
            testPath = fullfile(prjPath, [prjName '_CompilerProject'], 'for_testing');
            newPath  = fullfile(prjPath, [prjName '_CompilerProject'], 'application');           
    end

    % É necessário gerar uma nova versão customizada do MATLAB Runtime?!
    fileContent  = strsplit(strtrim(fileread(fullfile(testPath, 'requiredMCRProducts.txt'))), '\t');
    mcrProducts  = cellfun(@(x) int64(str2double(x)), fileContent);

    cacheContent = dir(fullfile(matlabRuntimeCache, '*.zip'));
    for ii = 1:numel(cacheContent)
        cacheFileString  = char(extractBetween(cacheContent(ii).name, 'InstallAgent_', '.zip'));
        cacheFileProduts = compiler.internal.utils.hexString2RuntimeProducts(cacheFileString);

        if any(~ismember(mcrProducts, cacheFileProduts))
            warning('Necessário atualizar a versão customizada do MATLAB Runtime.')
        end
    end

    % Aqui continua...
    movefile(oldPath, newPath);

    switch prjName
        case 'SCH'
            if isfile('D:\OneDrive - ANATEL\DataHub - GET\SCH\SCHData.mat')
                movefile('D:\OneDrive - ANATEL\DataHub - GET\SCH\SCHData.mat', fullfile(newPath, 'DataBase', 'SCHData.mat'), 'f');
            end
        otherwise
            % Pendente
    end
    
    % % splash.png delete
    cd(newPath)
    delete('splash.png')
    
    % % Executable file hash
    [~, cmdout] = system(sprintf('certUtil -hashfile %s.exe SHA256', appName));
    cmdout = strsplit(cmdout, '\n');
    exeHash = cmdout{2};
    
    % % Executable file size
    fileObj = dir(fileName);    
    exeSize = uint32(fileObj.bytes);
    
    % % appIntegrity.json
    appIntegrity = struct('appName',     appName,       ...
                          'appRelease',  appRelease,    ...
                          'appVersion',  appVersion,    ...
                          'codeRepo',    codeRepo,      ...
                          'customFiles', {customFiles}, ...
                          'fileName',    fileName,      ...
                          'fileHash',    exeHash,       ...
                          'fileSize',    exeSize);
    
    writematrix(jsonencode(appIntegrity, 'PrettyPrint', true), fullfile(newPath, 'Settings', 'appIntegrity.json'), 'FileType', 'text', 'QuoteStrings', 'none')
    
    % % zip file
    zipObj = struct2table(dir);
    zipObj = zipObj.name(3:end)';
    
    zip(sprintf('%s_Matlab.zip', appName), zipObj)
    movefile(sprintf('%s_Matlab.zip', appName), fileparts(pwd));
    
    cd(fileparts(pwd))
end