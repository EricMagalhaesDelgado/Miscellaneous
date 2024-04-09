function htmlReport = Controller(varargin)

    [reportInfo, dataOverview, callingApp] = report.inputParser(varargin{:});
    internalFcn_counterCreation()
    
    % HTML header (style)    
    htmlReport = '';
    if strcmp(reportInfo.Model.Version, 'preview')
        htmlReport = sprintf('%s\n\n', fileread(fullfile(reportInfo.Path.rootFolder, 'Template', 'html_DocumentStyle.txt')));
    end
    tableStyleFlag = 1;

    % HTML body
    Template = reportInfo.Model.Raw;
    for ii = 1:numel(Template)
        if strcmp(Template(ii).Type, 'ItemN1') && ~isempty(Template(ii).Data.Children)
            htmlReport = [htmlReport, report.sourceCode.htmlCreation(Template(ii))];

            if tableStyleFlag
                htmlReport = sprintf('%s%s\n\n', htmlReport, fileread(fullfile(reportInfo.Path.rootFolder, 'Template', 'html_DocumentTableStyle.txt')));
                tableStyleFlag = 0;
            end

            NN = 1;
            if Template(ii).Recurrence
                NN = numel(dataOverview);
            end
    
            for jj = 1:NN
                reportInfo.Function.var_Index = num2str(jj);
                analyzedData = dataOverview(jj);
    
                % Insere uma quebra de linha, caso exista recorrência no
                % item.
                if jj > 1
                    htmlReport = [htmlReport, report.sourceCode.LineBreak];
                end
    
                for kk = 1:numel(Template(ii).Data.Children)
                    % Children é uma estrutura com os campos "Type" e "Data". Se o 
                    % campo "Type" for igual a "Image" ou "Table" e ocorrer um erro 
                    % na leitura de uma imagem ou tabela externa, por exemplo, o erro 
                    % retornado terá o formato "Configuration file error message: %s". 
                    % Esse "%s" é uma mensagem JSON (e por isso deve ser deserializada) 
                    % de um componente HTML textual ("ItemN2" ou "Paragraph", por 
                    % exemplo).
                    Children = Template(ii).Data.Children(kk);
                    componentType = Children.Type;
    
                    try
                        switch componentType
                            case {'ItemN2', 'ItemN3', 'Paragraph', 'List', 'Footnote'}
                                for ll = 1:numel(Children.Data)
                                    if ~isempty(Children.Data(ll).Settings)
                                        Children.Data(ll).String = internalFcn_FillWords(reportInfo, analyzedData, callingApp, Children);
                                    end
                                end
                                vararginArgument = [];
    
                            case {'Image', 'Table'}
                                vararginArgument = eval(sprintf('internalFcn_%s(reportInfo, analyzedData, callingApp, Children.Data)', componentType));
    
                            otherwise
                                error('Unexpected type "%s"', componentType)
                        end
    
                        htmlReport = [htmlReport, report.sourceCode.htmlCreation(Children, vararginArgument)];
    
                    catch ME
                        msgError = extractAfter(ME.message, 'Configuration file error message: ');

                        if ~isempty(msgError)
                            htmlReport = report.sourceCode.AuxiliarHTMLBlock(htmlReport, 'Error', msgError);
                        end
                    end
                end
            end
        end
    end

    % HTML footnotes
    FootnoteList = fields(reportInfo.Version);
    FootnoteText = '';
        
    for ii = 1:numel(FootnoteList)
        FootnoteVersion = reportInfo.Version.(FootnoteList{ii});

        if ~isempty(FootnoteVersion)
            FootnoteFields = fields(FootnoteVersion);
            
            FootnoteFieldsText = {};
            for jj = 1:numel(FootnoteFields)
                switch FootnoteFields{jj}
                    case 'name'
                        FootnoteFieldsText{end+1} = sprintf('<b>__%s</b>', FootnoteVersion.(FootnoteFields{jj}));
                    otherwise
                        FootnoteFieldsText{end+1} = sprintf('<b>%s</b>: %s', FootnoteFields{jj}, FootnoteVersion.(FootnoteFields{jj}));
                end
            end
            FootnoteFieldsText = strjoin(FootnoteFieldsText, ', ');
            FootnoteText       = [FootnoteText, report.sourceCode.htmlCreation(struct('Type', 'Footnote', 'Data', struct('Editable', 'false', 'String', FootnoteFieldsText)))];
        end
    end
    htmlReport = [htmlReport, report.sourceCode.LineBreak, report.sourceCode.Separator, FootnoteText, report.sourceCode.LineBreak];

    % HTML trailer
    if strcmp(reportInfo.Model.Version, 'preview')
        htmlReport = sprintf('%s</body>\n</html>', htmlReport);
    end
end


%-------------------------------------------------------------------------%
function internalFcn_counterCreation()
    global ID_img
    global ID_tab

    ID_img = 0;
    ID_tab = 0;
end


%-------------------------------------------------------------------------%
function String = internalFcn_FillWords(reportInfo, analyzedData, callingApp, Children)

    numberWords = numel(Children.Data.Settings);
    formatWords = repmat({''}, numberWords, 1);

    for ii = 1:numberWords
        try
            Precision  = Children.Data.Settings(ii).Precision;
            Source     = Children.Data.Settings(ii).Source;
            Multiplier = Children.Data.Settings(ii).Multiplier;

            if isfield(reportInfo.Function, Source)
                try
                    Value = eval(reportInfo.Function.(Source));
                catch
                    Value = reportInfo.Function.(Source);
                end

                if isnumeric(Value)
                    Value = Value * Multiplier;
                end
        
                formatWords{ii} = Value;
            end
        catch
        end
    end

    String = sprintf(Children.Data.String, formatWords{:});
end


%-------------------------------------------------------------------------%
function imgFullPath = internalFcn_Image(reportInfo, analyzedData, callingApp, imgSettings)
    imgFullPath = '';
    imgOrigin   = imgSettings.Origin;
    imgSource   = imgSettings.Source;
    imgError    = imgSettings.Error;
    
    switch imgOrigin
        case 'FunctionEvaluation'
            imgIndex = any(strcmp(fields(reportInfo.Function), imgSource));
            if imgIndex
                imgFullPath = eval(reportInfo.Function.(imgSource));
            end

        case 'DataProperty'
            imgIndex = find(strcmp({analyzedData.HTML.Component}, 'Image') & strcmp({analyzedData.HTML.Source}, imgSource), 1);
            if ~isempty(imgIndex)
                imgFullPath = analyzedData.HTML(imgIndex).Value;
            end
    end

    if ~isfile(imgFullPath)
        error('Configuration file error message: %s', imgError)
    end
end


%-------------------------------------------------------------------------%
function Table = internalFcn_Table(reportInfo, analyzedData, callingApp, tableSettings)
    Table        = [];
    tableOrigin  = tableSettings.Origin;
    tableSource  = tableSettings.Source;
    tableColumns = tableSettings.Columns;
    tableError   = tableSettings.Error;
    
    switch tableOrigin
        case 'FunctionEvaluation'
            tableIndex = any(strcmp(fields(reportInfo.Function), tableSource));
            if tableIndex
                Table = eval(reportInfo.Function.(tableSource));
                Table = Table(:, tableColumns);
            end

        case 'DataProperty'
            tableIndex = find(strcmp({analyzedData.HTML.Component}, 'Table') & strcmp({analyzedData.HTML.Source}, tableSource), 1);
            if ~isempty(tableIndex)
                tableInfo = analyzedData.HTML(tableIndex).Value;

                if istable(tableInfo)
                    Table = tableInfo;

                else
                    tableFullFile = tableInfo.Path;
                    tableSheetID  = tableInfo.SheetID;
        
                    [~,~,fileExt] = fileparts(tableFullFile);
                    switch lower(fileExt)
                        case '.json'
                            Table = struct2table(jsondecode(fileread(tableFullFile)));
        
                        case {'.xls', '.xlsx'}
                            Table = readtable(tableFullFile, "VariableNamingRule", "preserve", "Sheet", tableSheetID);
        
                        otherwise
                            Table = readtable(tableFullFile, "VariableNamingRule", "preserve");
                    end    
                    Table = Table(:, tableColumns);
                end
            end
    end

    if isempty(Table)
        error('Configuration file error message: %s', tableError)
    end
end