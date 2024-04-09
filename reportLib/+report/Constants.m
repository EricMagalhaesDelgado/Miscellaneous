classdef (Abstract) Constants

    properties (Constant)
        %-----------------------------------------------------------------%
        libName       = 'reportLib'
        libRelease    = 'R2024a'
        libVersion    = '0.01'
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
    end
end