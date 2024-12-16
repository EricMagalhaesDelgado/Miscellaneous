function apps_EXE_Post(prjName, rootFolder, matlabRuntimeCache, spashscreenFolder)

    arguments
        prjName            char {mustBeMember(prjName, {'appAnalise', 'appColeta', 'SCH'})} = 'appColeta'
        rootFolder         char = 'D:\InovaFiscaliza'
        matlabRuntimeCache char = 'E:\MATLAB Runtime\MATLAB Runtime (Custom)\R2024a'
        spashscreenFolder  char = 'D:\_Versões Compiladas dos Apps\%appName%\Desktop'
    end

    % !! COMPILAÇÃO !!
    % Release: MATLAB R2024a Update6
    % Data...: 06/10/2024
    
    % appAnalise: 35000	35002 35003 35010 35108 35111 35117 35119 35136       35180       (Compilado no MATLAB R2024a em 04/10/2024)
    % appColeta.: 35000	35002 35003	35010 35108	35111       35119 35136 35162 35180	      (Compilado no MATLAB R2024a em 09/12/2024)
    % SCH.......: 35000	35002 35003	35010 35108	35111       35119 35136       35180 35256 (Compilado no MATLAB R2024a em 04/10/2024)

    % IDList =   [35000 35002 35003 35010 35108 35111 35117 35119 35136 35162 35180 35256]

    initialFolder = pwd;

    prjPath  = fullfile(rootFolder, prjName);
    cd(prjPath)
    
    appName     = class.Constants.appName;
    appRelease  = class.Constants.appRelease;
    appVersion  = class.Constants.appVersion;
    
    fileName = [appName '.exe'];
    codeRepo = ['https://github.com/InovaFiscaliza/' prjName]; 
    
    switch prjName
        case 'appColeta'
            customFiles = {'switchList.json', 'EMSatLib.json', 'GPSLib.json', 'instrumentList.json', 'mask.csv', 'taskList.json'};
        otherwise
            customFiles = {};
    end
    
    % % path rename
    oldPath  = fullfile(prjPath, [prjName '_desktopCompiler'], 'for_redistribution_files_only');
    testPath = fullfile(prjPath, [prjName '_desktopCompiler'], 'for_testing');
    newPath  = fullfile(prjPath, [prjName '_desktopCompiler'], 'application');

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
    movefile(oldPath, newPath, 'f');

    switch prjName
        case 'SCH'
            if isfile('D:\OneDrive - ANATEL\DataHub - GET\SCH\SCHData.mat')
                copyfile('D:\OneDrive - ANATEL\DataHub - GET\SCH\SCHData.mat', fullfile(newPath, 'DataBase', 'SCHData.mat'), 'f');
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
    zipProcess(newPath, sprintf('%s_Matlab.zip', appName))

    % % Mescla com o splashscreen, criando as versões finais.
    spashscreenFolder = replace(spashscreenFolder, '%appName%', prjName);

    if isfolder(fullfile(spashscreenFolder, 'application'))
        rmdir(fullfile(spashscreenFolder, 'application'), 's')
    end
    
    delete(fullfile(fileparts(spashscreenFolder), sprintf('%s.zip', appName)))
    delete(fullfile(fileparts(spashscreenFolder), sprintf('%s_Matlab.zip', appName)))

    movefile(fullfile(fileparts(newPath), sprintf('%s_Matlab.zip', appName)), fileparts(spashscreenFolder), 'f')
    movefile(newPath, fullfile(spashscreenFolder, 'application'), 'f')
    zipProcess(spashscreenFolder, sprintf('%s.zip', appName))    

    % % Apaga arquivos gerados pelo MATLAB, no processo de compilação, mas
    % que não são úteis neste contexto. Evita ter que exclui-los no GitHub.
    deleteTrash(fileparts(newPath))

    % % Finaliza na pasta onde estarão os arquivos zipados...
    cd(initialFolder)
end


%-------------------------------------------------------------------------%
function zipProcess(zipFolder, zipFileName)
    cd(zipFolder)

    zipObj = struct2table(dir);
    zipObj = zipObj.name(3:end)';
    
    zip(zipFileName, zipObj)
    movefile(zipFileName, fileparts(zipFolder), 'f');
end


%-------------------------------------------------------------------------%
function deleteTrash(trashFolder)
    cd(trashFolder)
    files2Delete = struct2table(dir);
    files2Delete = files2Delete.name(3:end)';

    cellfun(@(x) rmdir(x, 's'), files2Delete( isfolder(files2Delete)));
    cellfun(@(x) delete(x),     files2Delete(~isfolder(files2Delete)));
end