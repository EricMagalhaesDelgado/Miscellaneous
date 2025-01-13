function apps_EXE_Post(projectName, rootProjectFolders, rootCompiledVersions, matlabRuntimeCache)

    % Trata-se de script a ser executado posteriormente à compilação das
    % versões desktop e webapp de aplicativos construídos no MATLAB.

    % Release: MATLAB R2024a Update6
    % Data...: 13/01/2025
    
    arguments
        projectName          char {mustBeMember(projectName, {'appAnalise', 'appColeta', 'SCH', 'monitorRNI'})} = 'monitorRNI'
        rootProjectFolders   char = 'D:\InovaFiscaliza'
        rootCompiledVersions char = 'D:\_Versões Compiladas dos Apps'
        matlabRuntimeCache   char = 'E:\MATLAB Runtime\MATLAB Runtime (Custom)\R2024a'        
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % MAPEAMENTO DE PASTAS                                                %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    initFolder = pwd;

    prjPath    = fullfile(rootProjectFolders, projectName);
    cd(prjPath)
    
    appName    = class.Constants.appName;
    appRelease = class.Constants.appRelease;
    appVersion = class.Constants.appVersion;

    % No processo de compilação da versão desktop, o MATLAB cria as pastas 
    % "for_redistribution", "for_redistribution_files_only" e "for_testing", 
    % além do arquivo "PackagingLog.html"    
    desktopCompilerFolder = fullfile(prjPath, [projectName '_desktopCompiler']);
    desktopCompilerOld    = fullfile(desktopCompilerFolder, 'for_redistribution_files_only');
    desktopCompilerTest   = fullfile(desktopCompilerFolder, 'for_testing');
    desktopCompilerNew    = fullfile(desktopCompilerFolder, 'application');

    % No processo de compilação da versão webapp, o MATLAB cria os arquivos
    % "includedSupportPackages.txt", "mccExcludedFiles.log", "monitorRNI.ctf" 
    % (no caso do monitorRNI), "PackagingLog.html", "requiredMCRProducts.txt" 
    % e "unresolvedSymbols.txt".
    webappCompilerFolder  = fullfile(prjPath, [projectName '_webappCompiler']);

    % Pastas p/ as quais serão movidos os arquivos compilados que irão compor
    % as versões de distribuição dos apps:
    appCompiledVersions   = fullfile(rootCompiledVersions, projectName);
    desktopFinalFolder    = fullfile(appCompiledVersions, 'Desktop');
    webappFinalFolder     = fullfile(appCompiledVersions, 'Webapp');
    

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % VERSÃO DESKTOP                                                      %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 1/7: CONFIRMA SE A VERSÃO CUSTOMIZADA DO MATLAB RUNTIME CONTÉM TODOS OS 
    % MÓDULOS NECESSÁRIOS P/ CORRETA EXECUÇÃO DO APP.    
    fileContent  = strsplit(strtrim(fileread(fullfile(desktopCompilerTest, 'requiredMCRProducts.txt'))), '\t');
    mcrProducts  = cellfun(@(x) int64(str2double(x)), fileContent);

    cacheContent = dir(fullfile(matlabRuntimeCache, '*.zip'));
    for ii = 1:numel(cacheContent)
        cacheFileString  = char(extractBetween(cacheContent(ii).name, 'InstallAgent_', '.zip'));
        cacheFileProduts = compiler.internal.utils.hexString2RuntimeProducts(cacheFileString);

        if any(~ismember(mcrProducts, cacheFileProduts))
            warning('Necessário atualizar a versão customizada do MATLAB Runtime.')
        end
    end

    % 2/7: TROCA O NOME DA PASTA DE "for_redistribution_files_only" PARA "application"    
    movefile(desktopCompilerOld, desktopCompilerNew, 'f');

    % 3/7: ATUALIZA BASES DE DADOS QUE SUPORTAM O APP, CASO APLICÁVEL.
    switch projectName
        case 'appAnalise'
            % ... (pendente "RFDataHub")
        case 'appColeta'
            % ...
        case 'SCH'
            databaseFile = 'D:\OneDrive - ANATEL\DataHub - GET\SCH\SCHData.mat';
            if isfile(databaseFile)
                copyfile(databaseFile, fullfile(desktopCompilerNew, 'DataBase', 'SCHData.mat'), 'f');
            end
        case 'monitorRNI'
            databaseFile = 'C:\ProgramData\ANATEL\monitorRNI\RFDataHub.mat';
            if isfile(databaseFile)
                copyfile(databaseFile, fullfile(desktopCompilerNew, 'Settings', 'RFDataHub.mat'), 'f');
            end            
    end

    % 4/7: EXCLUI ARQUIVO GERADO NA COMPILAÇÃO "splash.png".
    cd(desktopCompilerNew)
    delete('splash.png')    

    % 5/7: CRIA ARQUIVO DE INTEGRIDADE "appIntegrity.json", O QUAL SERÁ INSPECIONADO 
    % PELO SPLASHSCREEN.
    fileName = [appName '.exe'];
    codeRepo = ['https://github.com/InovaFiscaliza/' projectName]; 
    
    switch projectName
        case 'appColeta'
            customFiles = {'switchList.json', 'EMSatLib.json', 'GPSLib.json', 'instrumentList.json', 'mask.csv', 'taskList.json'};
        otherwise
            customFiles = {};
    end
    
    % Executable file hash
    [~, cmdout] = system(sprintf('certUtil -hashfile %s.exe SHA256', appName));
    cmdout = strsplit(cmdout, '\n');
    exeHash = cmdout{2};
    
    % Executable file size
    fileObj = dir(fileName);    
    exeSize = uint32(fileObj.bytes);
    
    % appIntegrity.json
    appIntegrity = struct('appName',     appName,       ...
                          'appRelease',  appRelease,    ...
                          'appVersion',  appVersion,    ...
                          'codeRepo',    codeRepo,      ...
                          'customFiles', {customFiles}, ...
                          'fileName',    fileName,      ...
                          'fileHash',    exeHash,       ...
                          'fileSize',    exeSize);
    
    writematrix(jsonencode(appIntegrity, 'PrettyPrint', true), fullfile(desktopCompilerNew, 'Settings', 'appIntegrity.json'), 'FileType', 'text', 'QuoteStrings', 'none')

    % 6/7: CRIA ARQUIVO ZIPADO QUE POSSIBILITARÁ A ATUALIZAÇÃO DO APLICATIVO
    %          POR MEIO DO SPLASHSCREEN.
    zipProcess(desktopCompilerNew, sprintf('%s_Matlab.zip', appName))

    % 7/7: ORGANIZA PASTA LOCAL QUE ARMAZENA VERSÕES COMPILADAS DO APLICATIVO.
    if isfolder(fullfile(desktopFinalFolder, 'application'))
        rmdir(fullfile(desktopFinalFolder, 'application'), 's')
    end
    
    delete(fullfile(appCompiledVersions, sprintf('%s.zip', appName)))
    delete(fullfile(appCompiledVersions, sprintf('%s_Matlab.zip', appName)))

    movefile(fullfile(desktopCompilerFolder, sprintf('%s_Matlab.zip', appName)), appCompiledVersions, 'f')
    movefile(desktopCompilerNew, fullfile(desktopFinalFolder, 'application'), 'f')
    zipProcess(desktopFinalFolder, sprintf('%s.zip', appName))    


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % VERSÃO WEBAPP                                                       %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if isfolder(webappCompilerFolder)
        copyfile(webappCompilerFolder, webappFinalFolder, 'f')
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % EXCLUI ARQUIVOS NÃO MAIS NECESSÁRIOS                                %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    deleteTrash(desktopCompilerFolder)
    if isfolder(webappCompilerFolder)
        deleteTrash(webappCompilerFolder)
    end

    cd(initFolder)
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