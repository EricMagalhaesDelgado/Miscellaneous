function SCHDataUpdate()

    % PATH
    appName    = 'SCHDataUpdate';
    MFilePath  = fileparts(mfilename('fullpath'));
    rootFolder = ApplicationMode(appName, MFilePath);

    % LOG
    timeStamp  = datetime('now');
    logFile    = fullfile(rootFolder, 'LOG', sprintf('LOG_%d_%d.txt', year(timeStamp), month(timeStamp)));
    diary(logFile)
    diary on
    fprintf(sprintf('%s\nTentativa de atualização da base de dados "SCHData.mat" iniciada.\n\n', datestr(now)))
    
    try
        [FileURLs, POSTFolder] = initialValidations(rootFolder);

        % REFERENCE TABLE, AND REFERENCE RELEASED DATE
        load(fullfile(POSTFolder, 'SCHData.mat'), 'rawDataTable')
        refTable = rawDataTable;

        % RAW TABLE
        rawData  = struct('Table', {}, 'TableHeight', {}, 'FileSize', {}, 'TimeStamp', {});
        tempName = tempname;
    
        for ii = 1:numel(FileURLs)
            zipFullFile = websave(sprintf('%s_zipFile%d.zip', tempName, ii), FileURLs{ii});
            unzipedFile = char(unzip(zipFullFile, tempdir));
            
            rawTable    = parserFile(unzipedFile, ii);
            FileInfo    = dir(unzipedFile);
    
            rawData(ii) = struct('Table', rawTable, 'TableHeight', height(rawTable), 'FileSize', FileInfo.bytes, 'TimeStamp', datestr(FileInfo.datenum, "dd/mm/yyyy"));
            try
                eval(sprintf('delete %s %s', zipFullFile, unzipedFile))
            catch
            end
        end
    
        rawDataTable = vertcat(rawData.Table);
        rawDataTable = sortrows(rawDataTable, {'Homologação', 'Categoria do Produto', 'Tipo'});
        releasedData = datestr(max(cellfun(@(x) datetime(x, 'InputFormat', 'dd/MM/yyyy'), {rawData.TimeStamp})), 'dd/mm/yyyy');

        % NEW DATA?!
        % Como isequal(NaT, NaT) é FALSO, elimina-se da análise as colunas
        % com informações de data, além das colunas de cache (presentes apenas
        % refTable).
        columnsIndex = setdiff(1:19, [1,6,7]);

        if ~isequal(refTable(:,columnsIndex), rawDataTable(:,columnsIndex))
            % CACHE
            cacheColumns              = {'Homologação', 'Solicitante | Fabricante', 'Modelo | Nome Comercial'};
            [rawDataTable, cacheData] = CacheCreation(rawDataTable, cacheColumns);
        
            % .MAT
            save(fullfile(POSTFolder, 'SCHData.mat'), 'rawDataTable', 'releasedData', 'cacheData')
            fprintf(sprintf('%s\nBase de dados "SCHData.mat" atualizada em %s, sendo composta por %d linhas.\n\n', datestr(now), releasedData, height(rawDataTable)))

        else
            error('Dados idênticos ao da última extração.')
        end

    catch ME
        fprintf(sprintf('%s\n%s\n\n', datestr(now), ME.message))
    end

    if isdeployed
        pidMatlab = feature('getpid');
        system(sprintf('taskkill /F /PID %d', pidMatlab));
    end
end


%-------------------------------------------------------------------------%
function [FileURLs, POSTFolder] = initialValidations(rootFolder)

    publicLinks   = jsondecode(fileread(fullfile(rootFolder, 'Settings', 'PublicLinks.json')));
    FileURLs      = {publicLinks.SCH.Dashboard_File1, publicLinks.SCH.Dashboard_File2};

    generalConfig = jsondecode(fileread(fullfile(rootFolder, 'Settings', 'General.json')));
    POSTFolder    = generalConfig.fileFolder.DataHub_GET;

    if ~isfolder(POSTFolder)
        error('Pendente mapear pasta do Sharepoint, atualizando o arquivo de configuração "Settings.json".')
    end
end


%-------------------------------------------------------------------------%
function rawTable = parserFile(fileFullPath, fileID)

    switch fileID
        % 'Produtos_Homologados_Anatel.csv'
        case 1            
            opts = delimitedTextImportOptions('NumVariables',          21,         ...
                                              'Encoding',              'UTF-8',    ...
                                              'Delimiter',             ';',        ...
                                              'VariableNamingRule',    'preserve', ...
                                              'VariableNamesLine',     1,          ...
                                              'DataLines',             2,          ...
                                              'SelectedVariableNames', [1:7,9,11:21], ...
                                              'VariableTypes',         {'datetime', 'char', 'char', 'char', 'categorical',          ...
                                                                        'datetime', 'datetime', 'categorical', 'categorical',       ...
                                                                        'categorical', 'categorical', 'char', 'char', 'char',       ...
                                                                        'categorical', 'categorical', 'categorical', 'categorical', ...
                                                                        'categorical', 'categorical', 'categorical'});
            opts = setvaropts(opts, 1, 'InputFormat', 'dd/MM/yyyy');
            opts = setvaropts(opts, 6, 'InputFormat', 'dd/MM/yyyy');
            opts = setvaropts(opts, 7, 'InputFormat', 'dd/MM/yyyy HH:mm:ss', 'DatetimeFormat', 'dd/MM/yyyy');
        
            rawColumnNames    = {'Número de Homologação', 'Nome do Solicitante', 'CNPJ do Solicitante', 'Nome do Fabricante', 'Situação do Requerimento', 'Tipo do Produto'};
            editedColumnNames = {'Homologação', 'Solicitante', 'CNPJ/CPF', 'Fabricante', 'Situação', 'Tipo'};            
            newColumnNames    = {};

        % 'Produtos_Homologados_por_Declaração_de_Conformidade.csv'
        case 2
            opts = delimitedTextImportOptions('NumVariables',        8,         ...
                                              'Encoding',           'UTF-8',    ...
                                              'Delimiter',          ';',        ...
                                              'VariableNamingRule', 'preserve', ...
                                              'VariableNamesLine',  1,          ...
                                              'DataLines',          2,          ...
                                              'VariableTypes',      {'char', 'datetime', 'char', 'char', 'categorical', 'char', 'char', 'categorical'});
            opts = setvaropts(opts, 2, 'InputFormat', 'yyyy-MM-dd', 'DatetimeFormat', 'dd/MM/yyyy');
        
            rawColumnNames    = {'NumeroHomologacao', 'DataEmissaoHomologacao', 'Produto', 'NomeComercial', 'StatusRequerimento'};
            editedColumnNames = {'Homologação', 'Data da Homologação', 'Tipo', 'Nome Comercial', 'Situação'};
            newColumnNames    = {'CNPJ/CPF',                                    'char';        ...
                                 'Certificado de Conformidade Técnica',         'categorical'; ...
                                 'Data do Certificado de Conformidade Técnica', 'datetime';    ...
                                 'Data de Validade do Certificado',             'datetime';    ...
                                 'Situação do Certificado',                     'categorical'; ...
                                 'Categoria do Produto',                        'categorical'; ...
                                 'IC_ANTENA',                                   'categorical'; ...
                                 'IC_ATIVO',                                    'categorical'; ...
                                 'País do Fabricante',                          'categorical'; ...
                                 'CodUIT',                                      'categorical'; ...
                                 'CodISO',                                      'categorical'};
    end

    % Leitura do arquivo, trocando nomes de algumas colunas.
    rawTable = readtable(fileFullPath, opts);
    rawTable = renamevars(rawTable, rawColumnNames, editedColumnNames);

    % Formatando a coluna "Homologação" e eliminando os registros
    % que não possuem o nº esperado de caracteres (no caso, 12).
    nHomLogicalIndex = cellfun(@(x) numel(x)~=12, rawTable.("Homologação"));
    if any(nHomLogicalIndex)
        rawTable(nHomLogicalIndex,:) = [];
    end
    rawTable.("Homologação") = regexprep(rawTable.("Homologação"), '(\d{5})(\d{2})(\d{5})', '$1-$2-$3');

    % Formatando a coluna "CNPJ/CPF"
    if ismember('CNPJ/CPF', rawTable.Properties.VariableNames)
        nCharactersCNPJCPF = cellfun(@(x) numel(x), rawTable.("CNPJ/CPF"));
        nCPFLogicalIndex   = nCharactersCNPJCPF == 11;
        nCNPJLogicalIndex  = nCharactersCNPJCPF == 14;
        
        rawTable.("CNPJ/CPF")(nCPFLogicalIndex)  = regexprep(rawTable.("CNPJ/CPF")(nCPFLogicalIndex),  '(\d{3})(\d{3})(\d{3})(\d{2})',        '$1.$2.$3-$4');
        rawTable.("CNPJ/CPF")(nCNPJLogicalIndex) = regexprep(rawTable.("CNPJ/CPF")(nCNPJLogicalIndex), '(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})', '$1.$2.$3/$4-$5');
    end

    % Adicionando novas colunas com valores padrões...
    for ii = 1:height(newColumnNames)
        newColumnName  = newColumnNames{ii,1};
        newColumnClass = newColumnNames{ii,2};

        switch newColumnClass
            case 'char';        newColumnValue = {'-1'};
            case 'categorical'; newColumnValue = categorical(-1);
            case 'datetime';    newColumnValue = NaT;
        end

        rawTable.(newColumnName)(:) = newColumnValue;
    end    
end


%-------------------------------------------------------------------------%
function [rawTable, cacheData] = CacheCreation(rawTable, cacheColumns)

    cacheData = repmat(struct('Column', '', 'uniqueValues', {{}}, 'uniqueTokens', {{}}), numel(cacheColumns), 1);

    for ii = 1:numel(cacheColumns)
        listOfColumns = strsplit(cacheColumns{ii}, ' | ');

        uniqueValues  = {};
        uniqueTokens  = {};

        for jj = 1:numel(listOfColumns)
            cacheColumn        = listOfColumns{jj};
            [uniqueTempValues, ...
                referenceData] = textAnalysis.preProcessedData(rawTable.(cacheColumn));
            tokenizedDoc       = tokenizedDocument(uniqueTempValues);

            uniqueValues       = [uniqueValues; uniqueTempValues];
            uniqueTokens       = [uniqueTokens; cellstr(tokenizedDoc.tokenDetails.Token)];
    
            rawTable.(sprintf('_%s', cacheColumn)) = referenceData;
        end
        uniqueValues  = unique(uniqueValues);

        cacheData(ii) = struct('Column',       cacheColumns{ii},  ...
                               'uniqueValues', {uniqueValues},    ...
                               'uniqueTokens', {unique([uniqueValues; uniqueTokens])});
    end
end