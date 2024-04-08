prjName  = 'appAnaliseV2';                                                  % 'appAnalise' | 'appAnaliseV2' | 'appColeta' | 'appColetaV2'
prjPath  = fullfile(pwd, prjName);
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
    case {'appAnalise', 'appAnaliseV2'}
        codeRepo    = 'https://github.com/InovaFiscaliza/appAnalise'; 
    case {'appColeta',  'appColetaV2'}
        codeRepo    = 'https://github.com/InovaFiscaliza/appColeta'; 
end

switch prjName
    case 'appAnalise';   customFiles = {'GeneralSettings.json', 'mask.csv'};
    case 'appAnaliseV2'; customFiles = {'GeneralSettings.json'};
    case 'appColeta';    customFiles = {'GeneralSettings.json', 'rfeyeList.cfg', 'scpiList.json', 'mask.csv', 'taskList.json'};
    case 'appColetaV2';  customFiles = {'GeneralSettings.json', 'EMSatLib.json', 'GPSLib.json', 'instrumentList.json', 'mask.csv', 'taskList.json'};
end

%% path rename
oldPath = fullfile(prjPath, [prjName '_CompilerProject'], 'for_redistribution_files_only');
newPath = fullfile(prjPath, [prjName '_CompilerProject'], 'application');

movefile(oldPath, newPath);

%% splash.png delete
cd(newPath)
delete('splash.png')

%% Executable file hash
[~, cmdout] = system(sprintf('certUtil -hashfile %s.exe SHA256', appName));
cmdout = strsplit(cmdout, '\n');
exeHash = cmdout{2};

%% Executable file size
fileObj = dir(fileName);    
exeSize = uint32(fileObj.bytes);

%% appIntegrity.json
appIntegrity = struct('appName',     appName,       ...
                      'appRelease',  appRelease,    ...
                      'appVersion',  appVersion,    ...
                      'codeRepo',    codeRepo,      ...
                      'customFiles', {customFiles}, ...
                      'fileName',    fileName,      ...
                      'fileHash',    exeHash,       ...
                      'fileSize',    exeSize);

writematrix(jsonencode(appIntegrity, 'PrettyPrint', true), fullfile(newPath, 'Settings', 'appIntegrity.json'), 'FileType', 'text', 'QuoteStrings', 'none')

%% zip file
zipObj = struct2table(dir);
zipObj = zipObj.name(3:end)';

zip(sprintf('%s_Matlab.zip', appName), zipObj)
movefile(sprintf('%s_Matlab.zip', appName), fileparts(pwd));

cd(fileparts(pwd))