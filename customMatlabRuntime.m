classdef (Abstract) customMatlabRuntime

    %---------------------------------------------------------------------%
    % customMatlabRuntime.m
    %---------------------------------------------------------------------%
    % The customMatlabRuntime abstract class was designed to facilitate the 
    % creation of a customized runtime environment. It selects only the essential 
    % products and toolboxes required by one or a set of MATLAB files. 
    % 
    % Syntax of main method:
    %   zipFileFullPath = customMatlabRuntime.CreateZipFile('File', pwd);
    %   zipFileFullPath = customMatlabRuntime.CreateZipFile('File', {'D:\apps\MyFirstApp', 'D:\apps\MySecondApp', 'D:\apps\General\Config.m'});
    %   zipFileFullPath = customMatlabRuntime.CreateZipFile('IDList', [35000, 35002, 35003, 35010, 35108, 35162]);
    %
    % Or...
    %   fileList1 = customMatlabRuntime.MATLABFileList({'D:\apps\MyFirstApp'});
    %   IDList1   = customMatlabRuntime.GetIDList(fileList1);
    %
    %   fileList2 = customMatlabRuntime.MATLABFileList({'D:\apps\MySecondApp'});
    %   IDList2   = customMatlabRuntime.GetIDList(fileList2);
    %
    %   fileList3 = customMatlabRuntime.MATLABFileList({'D:\apps\General\Config.m'});
    %   IDList4   = customMatlabRuntime.GetIDList(fileList4);
    %
    %   zipFileFullPath = customMatlabRuntime.CreateZipFile('IDList', cell2mat([IDList1, IDList2, IDList3]));
    %---------------------------------------------------------------------%

    methods (Static)
        %-----------------------------------------------------------------%
        function zipFileFullPath = CreateZipFile(varargin)
            if nargin ~= 2
                error('customMatlabRuntime:CreateZipFile', 'InvalidNumberOfInputArguments')

            else
                validatestring(varargin{1}, {'File', 'IDList'});
    
                switch varargin{1}
                    case 'File'
                        if iscell(varargin{2})
                            cellfun(@(x) validateattributes(x, {'char', 'string'}, {'scalartext'}), varargin{2});                            
                        else
                            validateattributes(varargin{2}, {'char', 'string'}, {'vector'});
                            varargin{2} = cellstr(varargin{2});
                        end

                        fileList = customMatlabRuntime.MATLABFileList(varargin{2});
                        IDList   = customMatlabRuntime.GetIDList(fileList);
    
                    case 'IDList'
                        validateattributes(varargin{2}, {'numeric'}, {'vector'});
                        varargin{2} = unique(varargin{2});

                        customMatlabRuntime.ValidateIDList(varargin{2})
                        IDList   = num2cell(varargin{2});
                end
            end
        
            zipFileFullPath = compiler.internal.buildinstallagent(IDList{:});
        end


        %-----------------------------------------------------------------%
        function zipFileTable = SearchZipFiles
            zipFileTable  = table('Size', [0, 3],                            ...
                                  'VariableTypes', {'cell', 'cell', 'cell'}, ...
                                  'VariableNames', {'filename', 'hexIDList', 'IDList'});

            zipFileFolder = fullfile(replace(mcrcachedir, 'mcrCache', 'installAgent'), computer('arch'));
            if isfolder(zipFileFolder)
                dirData     = dir(zipFileFolder);
                dirFileList = {dirData.name};
                dirFileFlag = cellfun(@(x) ~isempty(regexp(x, '^InstallAgent_[0-9a-f]{18}.zip$', 'once')), dirFileList);
                dirFileList = dirFileList(dirFileFlag);

                for ii = 1:numel(dirFileList)
                    hexIDList = extractBetween(dirFileList{ii}, 'InstallAgent_', '.zip');
                    IDList    = strjoin(string(compiler.internal.utils.hexString2RuntimeProducts(hexIDList{1})), ', ');

                    zipFileTable(end+1,:) = {fullfile(zipFileFolder, dirFileList{ii}), hexIDList{1}, char(IDList)};
                end
            end
        end
        
        
        %-----------------------------------------------------------------%
        function fileList = MATLABFileList(rawList)
            arguments
                rawList cell {mustBeText, mustBeVector}
            end

            fileList = {};
            for ii = 1:numel(rawList)
                if isfolder(rawList{ii})
                    dirData      = dir(rawList{ii});
                    dirData(ismember({dirData.name}, {'.', '..'})) = [];
                    
                    dirFullPath  = cellstr(string({dirData.folder}) + filesep + string({dirData.name}));
                    dirIndex     = [dirData.isdir];
                    
                    fileList     = [fileList, dirFullPath(~dirIndex)];
                    subDirList   = dirFullPath(dirIndex);
                    
                    for jj = 1:numel(subDirList)
                        fileList = [fileList, customMatlabRuntime.MATLABFileList(subDirList(jj))];
                    end

                elseif isfile(rawList{ii})
                    fileList     = [fileList, rawList{ii}];
                end
            end

            fileList = unique(fileList);
            [~, ~, fileExt] = fileparts(fileList);
            fileList(~ismember(fileExt, matlab.depfun.internal.requirementsConstants.executableMatlabFileExt)) = [];
        end
        
        
        %-----------------------------------------------------------------%
        function IDList = GetIDList(fileList)
            arguments
                fileList cell {mustBeText, mustBeVector}
            end

            [~, resources] = matlab.depfun.internal.mcc_call_requirements(fileList, 'MCR');
            IDList = {resources.products.ProductNumber};
            IDList = num2cell(unique(cell2mat([IDList, matlab.depfun.internal.requirementsConstants.base_runtimes])));
        end


        %-----------------------------------------------------------------%
        function IDFullList = GetIDFullList
            resources  = matlab.depfun.internal.ProductComponentModuleNavigator();
            platform   = computer('arch'); % 'win64' | 'glnxa64' | 'maci64' | 'maca64'

            IDFullList = struct2table(MatlabRuntimeProductsOnPlatform(resources, platform));
            IDFullList = sortrows(IDFullList, 'extPID');
        end
        
        
        %-----------------------------------------------------------------%
        function ValidateIDList(IDList)
            arguments
                IDList {mustBeNumeric, mustBeVector}
            end

            IDFullList  = customMatlabRuntime.GetIDFullList;        
            IDListIndex = find(~ismember(IDList, IDFullList.extPID));
            
            if ~isempty(IDListIndex)
                error('customMatlabRuntime:ValidateIDList', 'Invalid ID values: %s', strjoin(string(IDList(IDListIndex)), ', '))
            end
        end
    end
end