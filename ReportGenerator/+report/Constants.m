classdef (Abstract) Constants

    properties (Constant)
        %-----------------------------------------------------------------%
        libName       = 'reportLib'
        libRelease    = 'R2024a'
        libVersion    = '1.00'
    end


    methods (Static=true)
        %-----------------------------------------------------------------%
        function reportLib = ReportLib
            reportLib = struct('name', report.Constants.libName,       ...
                               'release', report.Constants.libRelease, ...
                               'version', report.Constants.libVersion);
        end


        %-----------------------------------------------------------------%
        function matlabVersion = MatlabVersion
            matVersion    = version;    
            matProducts   = struct2table(ver);

            matlabVersion = struct('name',        'MATLAB',                                   ...
                                   'release',     char(extractBetween(matVersion, '(', ')')), ...
                                   'version',     extractBefore(matVersion, ' '),             ...
                                   'path',        matlabroot,                                 ...
                                   'productList', char(strjoin(matProducts.Name + " v. " + matProducts.Version, ', ')));
        end


        %-----------------------------------------------------------------%
        function fileName = DefaultFileName(userPath, Prefix, Issue)
            fileName = fullfile(userPath, sprintf('%s_%s', Prefix, datestr(now,'yyyy.mm.dd_THH.MM.SS')));

            if Issue > 0
                fileName = sprintf('%s_%d', fileName, Issue);
            end
        end
    end
end