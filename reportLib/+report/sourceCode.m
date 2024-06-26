classdef (Abstract) sourceCode

    %TODO
    % (a) HTML link element
    % ...

    methods (Static = true)
        %-----------------------------------------------------------------%
        function htmlContent = htmlCreation(reportTemplate, varargin)
            [componentType, componentData, componentIntro, componentError, componentLineBreak] = report.sourceCode.TemplateParser(reportTemplate);
            report.sourceCode.ComponentTypeCheck(componentType)
            [txtClass, txtStyle, tableStyle] = report.sourceCode.Style(componentType);
            
            htmlContent = '';
            switch componentType
                %---------------------------------------------------------%
                case {'ItemN1', 'ItemN2', 'ItemN3', 'Paragraph', 'Footnote'}                    
                    htmlContent = sprintf('<p class="%s" contenteditable="%s"%s>%s</p>\n\n', txtClass, componentData.Editable, txtStyle, componentData.String);        
        
                %---------------------------------------------------------%
                case 'List'
                    htmlContent = '<ul style="margin-left: 80px;">';
                    for ii = 1:numel(componentData)
                        htmlContent = sprintf(['%s\n'                                            ...
                                               '\t<li>\n'                                        ...
                                               '\t\t<p class="%s" contenteditable="%s">%s</p>\n' ...
                                               '\t</li>'], htmlContent, txtClass, componentData(ii).Editable, componentData(ii).String);
                    end
                    htmlContent = sprintf('%s\n</ul>\n\n', htmlContent);        
        
                %---------------------------------------------------------%
                case 'Image'
                    imgFullPath = varargin{1};
                    
                    if ~isempty(imgFullPath)
                        global ID_img
                        ID_img = ID_img+1;

                        [imgExt, imgString] = report.sourceCode.img2base64(imgFullPath);
                        
                        htmlContent = report.sourceCode.AuxiliarHTMLBlock(htmlContent, 'Introduction', componentIntro);                        
                        htmlContent = sprintf(['%s<figure id="image_%.0f">\n'                                                                             ...
                                               '\t<p class="Texto_Centralizado"><img src="data:image/%s;base64,%s" style="width:%s; height:%s;" /></p>\n' ...
                                               '\t<figcaption>\n'                                                                                         ...
                                               '\t\t<p class="%s"><strong>Imagem %.0f. %s</strong></p>\n'                                                 ...
                                               '\t</figcaption>\n'                                                                                        ...
                                               '</figure>\n\n'], htmlContent, ID_img, imgExt, imgString, componentData.Settings.Width, componentData.Settings.Height, txtClass, ID_img, componentData.Caption);
        
                        htmlContent = report.sourceCode.AuxiliarHTMLBlock(htmlContent, 'LineBreak', componentLineBreak);
        
                    else
                        htmlContent = report.sourceCode.AuxiliarHTMLBlock(htmlContent, 'Error', componentError);
                    end        
        
                %---------------------------------------------------------%
                case 'Table'
                    Table = varargin{1};
        
                    if ~isempty(Table)
                        global ID_tab
                        ID_tab  = ID_tab+1;

                        ROWS    = height(Table);
                        COLUMNS = width(Table);
                        
                        % INTRODUCTION
                        htmlContent = report.sourceCode.AuxiliarHTMLBlock(htmlContent, 'Introduction', componentIntro);

                        % HEADER
                        htmlContent = sprintf(['%s<table class="%s" id="table_%.0f">\n'                 ...
                                             '\t<caption>\n'                                            ...
                                             '\t\t<p class="%s"><strong>Tabela %.0f. %s</strong></p>\n' ...
                                             '\t</caption>\n'                                           ...
                                             '\t<thead>\n'                                              ...
                                             '\t\t<tr>'], htmlContent, tableStyle, ID_tab, txtClass, ID_tab, componentData.Caption);
                    
                        rowTemplate = {};
                        for jj = 1:COLUMNS
                            value = '';
                            if componentData.Settings(jj).Width ~= "auto"
                                value = sprintf(' style="width: %s;"', componentData.Settings(jj).Width);
                            end

                            columnName = componentData.Settings(jj).String;
                            if isempty(columnName)
                                columnName = Table.Properties.VariableNames{jj};
                            end
                    
                            htmlContent = sprintf(['%s\n'                                              ...
                                                 '\t\t\t<th scope="col"%s>\n'                          ...
                                                 '\t\t\t\t<p class="%s" contenteditable="%s">%s</p>\n' ...
                                                 '\t\t\t</th>'], htmlContent, value, txtClass, componentData.Settings(jj).Editable, columnName);
                    
                            rowTemplate{jj} = sprintf(['\t\t\t<td>\n'                                        ...
                                                       '\t\t\t\t<p class="%s" contenteditable="%s">%s</p>\n' ...
                                                       '\t\t\t</td>'], txtClass, componentData.Settings(jj).Editable, componentData.Settings(jj).Precision);
                        end                    
                        htmlContent = sprintf(['%s\n'       ...
                                             '\t\t</tr>\n'  ...
                                             '\t</thead>\n' ...
                                             '\t<tbody>'], htmlContent);
                    
                        % BODY
                        for ii = 1:ROWS
                            htmlContent = sprintf('%s\n\t\t<tr>', htmlContent);

                            for jj = 1:COLUMNS
                                cellValue   = report.sourceCode.TableCellValue(Table{ii, jj}, componentData.Settings(jj), txtClass, 1);
                                htmlContent = sprintf('%s\n%s', htmlContent, sprintf(rowTemplate{jj}, cellValue));
                            end
                    
                            htmlContent = sprintf('%s\n\t\t</tr>', htmlContent);
                        end
                    
                        htmlContent = sprintf('%s\n\t</tbody>\n</table>\n\n', htmlContent);        
                        htmlContent = report.sourceCode.AuxiliarHTMLBlock(htmlContent, 'LineBreak', componentLineBreak);
        
                    else
                        htmlContent = report.sourceCode.AuxiliarHTMLBlock(htmlContent, 'Error', componentError);
                    end
            end
        end
    end


    methods (Static = true)
        %-----------------------------------------------------------------%
        function ComponentTypeCheck(componentType)
            if ~ismember(componentType, {'ItemN1', 'ItemN2', 'ItemN3', 'Paragraph', 'Footnote', 'List', 'Image', 'Table'})
                error('report:sourceCode:ComponentTypeCheck', 'Lib supports only "ItemN1", "ItemN2", "ItemN3", "Paragraph", "Footnote", "List", "Image" and "Table" HTML components.')
            end
        end


        %-----------------------------------------------------------------%
        function [txtClass, txtStyle, tableStyle] = Style(componentType)
            txtStyle   = '';
            tableStyle = '';

            switch componentType
                case 'ItemN1';    txtClass = 'Item_Nivel1';
                case 'ItemN2';    txtClass = 'Item_Nivel2';
                case 'ItemN3';    txtClass = 'Item_Nivel3';
                case 'Paragraph'; txtClass = 'Texto_Justificado';
                case 'Footnote';  txtClass = 'Tabela_Texto_8';    txtStyle = ' style="color: #808080;"';
                case 'List';      txtClass = 'Texto_Justificado';
                case 'Image';     txtClass = 'Tabela_Texto_8';
                case 'Table';     txtClass = 'Tabela_Texto_8';    tableStyle = 'tabela_corpo';
            end        
        end


        %-----------------------------------------------------------------%
        function [componentType, componentData, componentIntro, componentError, componentLineBreak] = TemplateParser(reportTemplate)
            componentType      = reportTemplate.Type;
            componentData      = reportTemplate.Data;
            componentIntro     = '';
            componentError     = '';
            componentLineBreak = 0;

            if isfield(reportTemplate.Data, 'Intro')
                componentIntro = reportTemplate.Data.Intro;
            end

            if isfield(reportTemplate.Data, 'Error')
                componentError = reportTemplate.Data.Error;
            end

            if isfield(reportTemplate.Data, 'LineBreak')
                componentLineBreak = reportTemplate.Data.LineBreak;
            end
        end
        
        
        %-----------------------------------------------------------------%
        function htmlContent = AuxiliarHTMLBlock(htmlContent, controlType, controlRawData)
            % - "Introduction"
            %   "Intro": ""
            %   "Intro": "{\"Type\":\"ItemN2\",\"String\":\"Uma informação qualquer antes de renderização de um componente imagem ou tabela...\"}"
            %
            % - "LineBreak"
            %   "LineBreak": 0
            %   "LineBreak": 1
            %
            % - "Error"
            %   "Error": ""
            %   "Error": "{\"Type\":\"Paragraph\",\"String\":\"Uma informação qualquer caso ocorra erro na renderização de um componente imagem ou tabela...\"}"
        
            if isempty(controlRawData) || ...
                    (isnumeric(controlRawData) && (~controlRawData || ~isvector(controlRawData)))
                return
            end
        
            switch controlType
                case {'Introduction', 'Error'}
                    if ~isempty(controlRawData)
                        controlStruct     = jsondecode(controlRawData);
        
                        htmlComponentType = controlStruct.Type;
                        htmlComponentText = controlStruct.String;
                    end
        
                case 'LineBreak'
                    if controlRawData
                        htmlComponentType = 'Paragraph';
                        htmlComponentText = '&nbsp;';
                    end
            end
        
            htmlContent = sprintf('%s%s', htmlContent, report.sourceCode.htmlCreation(struct('Type', htmlComponentType, 'Data', struct('Editable', 'false', 'String', htmlComponentText))));
        end


        %-----------------------------------------------------------------%
        function htmlLineBreak = LineBreak()
            htmlLineBreak = report.sourceCode.htmlCreation(struct('Type', 'Paragraph', 'Data', struct('Editable', 'false', 'String', '&nbsp;')));
        end
    
    
        %-----------------------------------------------------------------%
        function htmlSeparator = Separator()
            htmlSeparator = report.sourceCode.htmlCreation(struct('Type', 'Footnote',  'Data', struct('Editable', 'false', 'String', repmat('_', 1, 45))));
        end


        %-----------------------------------------------------------------%
        function [imgExt, imgString] = img2base64(imgFullPath)
            fileID = -1;
            while fileID == -1
                fileID = fopen(imgFullPath, 'r');
                pause(1)                
            end
            
            [~, ~, imgExt] = fileparts(imgFullPath);
            switch lower(imgExt)
                case '.png';            imgExt = 'png';
                case {'.jpg', '.jpeg'}; imgExt = 'jpeg';
                case '.gif';            imgExt = 'gif';
                case '.svg';            imgExt = 'svg+xml';
                otherwise;              error('report:sourceCode:img2base64', 'Image file format must be "JPEG", "PNG", "GIF", or "SVG".')
            end
            
            imgArray  = fread(fileID, 'uint8=>uint8');
            imgString = matlab.net.base64encode(imgArray);
            fclose(fileID);        
        end


        %-----------------------------------------------------------------%
        function editedCellValue = TableCellValue(cellValue, componentSettings, txtClass, recorrenceIndex)            
            editedCellValue = '';

            if isnumeric(cellValue) || islogical(cellValue)
                if recorrenceIndex == 1
                    if isscalar(cellValue)
                        editedCellValue = double(cellValue) * componentSettings.Multiplier;
                        
                        if isnan(editedCellValue)
                            editedCellValue = '';
                        end
                    end
                else
                    editedCellValue = num2str(cellValue);
                end

            else                
                cellClass = class(cellValue);
                switch cellClass
                    case {'char', 'string', 'categorical'}
                        editedCellValue = strjoin(cellstr(cellValue), '<br>');

                    case 'datetime'
                        editedCellValue = strjoin(cellstr(datestr(cellValue, 'dd/mm/yyyy HH:MM:SS')), '<br>');

                    case 'cell'
                        for ii = 1:numel(cellValue)
                            subCellValue = report.sourceCode.TableCellValue(cellValue{ii}, componentSettings, txtClass, recorrenceIndex+1);
                            if ~isempty(subCellValue)
                                if isempty(editedCellValue)
                                    editedCellValue = subCellValue;
                                else
                                    editedCellValue = strjoin({editedCellValue, subCellValue}, '<br>');
                                end
                            end
                        end
                end
            end
        end
    end
end