function testLib(modelName)

    arguments
        modelName = 'Template 001/2024'
    end

    % reportInfo
    reportInfo = struct('Model',    struct('Version',       'preview',                                                                      ...
                                           'Name',          modelName),                                                                     ...
                        'Function', struct('var_Issue',     '123456',                                                                       ...
                                           'var_Receiver',  'analyzedData.InfoSet.Receiver',                                                ...
                                           'var_FreqStart', 'analyzedData.InfoSet.FreqStart',                                               ...
                                           'var_FreqStop',  'analyzedData.InfoSet.FreqStop',                                                ...
                                           'var_Samples',   'numel(analyzedData.InfoSet.Array)',                                            ...
                                           'var_Location',  'strjoin(analyzedData.InfoSet.Location, '', '')',                               ...
                                           'img_Pumpkin',   'example.fcn.imgPumpkin(reportInfo, analyzedData, callingApp, imgSettings)',    ...
                                           'img_Surf',      'example.fcn.imgSurf(reportInfo, analyzedData, callingApp, imgSettings)',       ...
                                           'img_Ordinary1', 'example.fcn.imgOrdinary(reportInfo, analyzedData, callingApp, imgSettings)',   ...
                                           'tbl_Ordinary1', 'example.fcn.tableOrdinary(reportInfo, analyzedData, callingApp, tableSettings)'));
    
    % dataOverview
    specData    = struct('Receiver', 'R&S FSL30',  'FreqStart',  88e+6,  'FreqStop',  108e+6, 'Array', [1 10 100], 'Location', {{'Salvador/BA', 'Recife/PE'}});
    specData(2) = struct('Receiver', 'R&S FSVR',   'FreqStart', 470e+6,  'FreqStop',  698e+6, 'Array', 1:10:100,   'Location', {{'Rio de Janeiro/RJ', 'Blumenau/SC'}});
    specData(3) = struct('Receiver', 'CRFS RFeye', 'FreqStart', 1000e+6, 'FreqStop', 1140e+6, 'Array', 1:100,      'Location', 'Itacaré/BA');
    
    T11 = table({{'Sanchez','Carlos','John'};["Johnson","Marcus","Andre"];100;[10,20,30];'Brown'}, [1;2;3;4;5], logical([0;0;0;0;0]), [1;2;3;4;5], [1;2;3;4;5], [1;2;3;4;5], ["1";"2";"3";"4";"5"]);
    I11 = fullfile(report.Path, '+example', 'externalImage_mosaic.png');
    
    T21 = table({'TJ';"Sabrina"; 100;10;{'Anna','Olivia'}}, [5;4;3;2;1], logical([1;0;1;0;1]), [5;4;3;2;1], [5;4;3;2;1], [5;4;3;2;1], ["5";"4";"3";"2";"1"]);
    T22 = struct('Path', fullfile(report.Path, '+example', 'externalTable_RFDataHubSample.xlsx'), 'SheetID', 1);
    I21 = fullfile(report.Path, '+example', 'externalImage_redmine.png');
    
    dataOverview(1).ID      = 'Faixa 1: 88.000 - 108.000 MHz';
    dataOverview(1).InfoSet = specData(1);
    dataOverview(1).HTML(1) = struct('Component', 'Table', 'Source', 'tbl_Ordinary1', 'Value', T11);
    dataOverview(1).HTML(2) = struct('Component', 'Image', 'Source', 'img_Ordinary1', 'Value', I11);
    
    dataOverview(2).ID      = 'Faixa 2: 470.000 - 698.000 MHz';
    dataOverview(2).InfoSet = specData(2);
    dataOverview(2).HTML(1) = struct('Component', 'Table', 'Source', 'tbl_Ordinary1', 'Value', T21);
    dataOverview(2).HTML(2) = struct('Component', 'Image', 'Source', 'img_Ordinary1', 'Value', I21);
    dataOverview(2).HTML(3) = struct('Component', 'Table', 'Source', 'tbl_Ordinary2', 'Value', T22);
    
    % reportLib
    htmlReport   = report.Controller(reportInfo, dataOverview);
    
    htmlTempFile = fullfile(tempdir, 'testLib.html');
    writematrix(htmlReport, htmlTempFile, 'QuoteStrings', 'none', 'FileType', 'text')
    web(htmlTempFile)
end
