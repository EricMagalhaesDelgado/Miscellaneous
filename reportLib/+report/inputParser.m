function [reportInfo, dataOverview, callingApp] = inputParser(varargin)

    % Algumas validações simples... evoluir essa função depois para que a lib
    % não tenha que lidar com dados inusitados, não renderizando os componentes.

    narginchk(2, 3)
    
    reportInfo   = varargin{1};
    dataOverview = varargin{2};
    rootFolder   = report.Path;

    switch nargin
        case 2; callingApp = [];
        case 3; callingApp = varargin{3};
    end
    
    % reportInfo
    if ~isstruct(reportInfo) || any(~ismember({'Model', 'Function'}, fields(reportInfo)))
        error('reportInfo must be a struct with at least the fields "Model" and "Function".')
    end

    reportInfo.Path.rootFolder       = rootFolder;
    reportInfo.Version.reportLib     = report.Constants.ReportLib;
    reportInfo.Version.matlabRelease = report.Constants.MatlabVersion;

    modelFile  = jsondecode(fileread(fullfile(rootFolder, 'Template', 'html_General.cfg')));
    modelName  = reportInfo.Model.Name;
    
    modelIndex = find(strcmp({modelFile.Name}, modelName), 1);
    if isempty(modelIndex)
        error('Informations about the template "%s" must be added to "html_General.cfg"', modelName)
    end

    reportInfo.Model.Config          = modelFile(modelIndex);
    reportInfo.Model.Raw             = jsondecode(fileread(fullfile(rootFolder, 'Template', modelFile(modelIndex).File)));

    reportInfo.Function.var_Index    = '-1';

    % dataOverview
    if ~isstruct(dataOverview) || any(~ismember({'ID', 'InfoSet', 'HTML'}, fields(dataOverview)))
        error('dataOverview must be a struct with at least the fields "ID", "InfoSet" and "HTML".')
    end

end