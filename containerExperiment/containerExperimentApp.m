classdef containerExperimentApp < dynamicprops

    properties
        %-----------------------------------------------------------------%
        Container
        hWebWindow
        pathToMFILE        
    end

    properties (Constant)
        %-----------------------------------------------------------------%
        Name = 'containerExperimentApp'
        uuid = char(matlab.lang.internal.uuid())
    end    

    methods
        %-----------------------------------------------------------------%
        function obj = containerExperimentApp(varargin)

            % rootFolder
            obj.pathToMFILE = fileparts(mfilename('fullpath'));

            % AppContainer object
            appContainerOptions = struct('Tag', 'AppContainer', 'Title', obj.Name);
            obj.Container = matlab.ui.container.internal.AppContainer(appContainerOptions);

            % Window size/position, and listener
            [x,y,w,h] = imageslib.internal.apputil.ScreenUtilities.getInitialToolPosition();
            set(obj.Container, 'WindowBounds', [x,y,w,h], 'WindowMinSize', [640, 480]);
            addlistener(obj.Container, 'StateChanged', @obj.appStateChangedCallback);

            % Main containers/components building
            startupBuilding_TabGroup(obj, obj.Name)
            toolstripConfigFile = jsondecode(fileread(fullfile(obj.pathToMFILE, 'toolstripConfigFile.json')));
            TabCreation(obj, 'TAB #1', toolstripConfigFile)

            startupBuilding_DocumentGroup(obj)
            startupBuilding_QuickAccessBar(obj)
            startupBuilding_StatusBar(obj)

            % Visibility
            obj.Container.Visible = true;

            % Register app
            setappdata(groot, obj.Name, obj);

            % App startup (varargin - name of the file or folder to read)
        end


        %-----------------------------------------------------------------%
        function TabCreation(obj, Tag, toolstripConfigFile)

            % Verifica se a aba existe...
            tabGroup = obj.Container.getTabGroup(obj.Name);
            try
                tabGroup.getChildByTag(Tag);
                return
            catch
            end
            
            TabStruct  = toolstripConfigFile.Tab;
            TabFields  = fields(TabStruct);
            
            % TAB and SECTION objects
            objStruct  = struct();
            for ii1 = 1:numel(TabFields)
                objStruct(ii1).Tab = matlab.ui.internal.toolstrip.Tab(TabFields{ii1});
                objStruct(ii1).Tab.Tag = TabFields{ii1};
                
                SectionNames = TabStruct.(TabFields{ii1});
                for jj1 = 1:numel(SectionNames)
                    objStruct(ii1).Section(jj1) = objStruct(ii1).Tab.addSection(SectionNames{jj1});
                end
            end

            CompTable = struct2table(toolstripConfigFile.Components);
            CompTable = sortrows(CompTable, 'PositionID');

            % GROUP objects
            Groups = unique(CompTable.Group);
            GroupTable = table('Size', [0,2], 'VariableTypes', {'cell', 'cell'}, 'VariableNames', {'name', 'handle'});
            for ii2 = 1:numel(Groups)
                if ~isempty(Groups{ii2})
                    GroupTable(end+1,:) = {Groups{ii2}, {matlab.ui.internal.toolstrip.ButtonGroup()}};
                end
            end

            % COLUMN object and GUI components (nowadays limited to BUTTON, 
            % GRIDPICKERBUTTON, LABEL, SPINNER, DROPDOWN, TOGGLEBUTTON, 
            % RADIOBUTTON, and DROPDOWNBUTTON)
            idx1 = fix(CompTable.PositionID/1000);                                      % Tab index
            for ii = 1:numel(TabFields)
                tempTable_TAB = CompTable(idx1==ii,:);
            
                SectionNames = TabStruct.(TabFields{ii});
                for jj = 1:numel(SectionNames)
                    idx2 = fix((tempTable_TAB.PositionID - ii*1000)/100);               % Section index
                    tempTable_SECTION = tempTable_TAB(idx2==jj,:);
            
                    idx3 = fix((tempTable_SECTION.PositionID - ii*1000 - jj*100)/10);   % Column index
                    for kk = 1:numel(unique(idx3))
                        tempTable_COLUMN = tempTable_SECTION(idx3==kk,:);
            
                        % ColumnWidth
                        colWidth = [];
                        if any(~strcmp(unique(tempTable_COLUMN.ColumnWidth), 'auto'))
                            colWidth = tempTable_COLUMN.ColumnWidth(cellfun(@(x) ~isnan(str2double(x)), tempTable_COLUMN.ColumnWidth));
                            colWidth = str2double(colWidth{1});
                        end
        
                        % ColumnHorizontalAlignment
                        colHorAlign = [];
                        if any(~strcmp(unique(tempTable_COLUMN.ColumnAlign), 'auto'))
                            colHorAlign = tempTable_COLUMN.ColumnAlign(cellfun(@(x) ~strcmp(x, 'auto'), tempTable_COLUMN.ColumnAlign));
                            colHorAlign = colHorAlign{1};
                        end

                        if colWidth & colHorAlign; Column = objStruct(ii).Section(jj).addColumn('Width', colWidth, 'HorizontalAlignment', colHorAlign);
                        elseif colWidth;           Column = objStruct(ii).Section(jj).addColumn('Width', colWidth);
                        elseif colHorAlign;        Column = objStruct(ii).Section(jj).addColumn(                   'HorizontalAlignment', colHorAlign);
                        else;                      Column = objStruct(ii).Section(jj).addColumn();
                        end

                        for ll = 1:height(tempTable_COLUMN)
                            Parameters = fields(tempTable_COLUMN.Parameters{ll});

                            switch tempTable_COLUMN.Type{ll}
                                case {'Button', 'Label', 'CheckBox', 'ListItemWithCheckBox', 'Spinner'}
                                    Component = eval(sprintf('matlab.ui.internal.toolstrip.%s()', tempTable_COLUMN.Type{ll}));
                                
                                case 'GridPickerButton'
                                    Component = matlab.ui.internal.toolstrip.GridPickerButton('', tempTable_COLUMN.Parameters{ll}.maxRows, tempTable_COLUMN.Parameters{ll}.maxColumns);
                                
                                case 'DropDown'
                                    Component = matlab.ui.internal.toolstrip.DropDown(tempTable_COLUMN.Parameters{ll}.Items);
                                
                                case 'ToggleButton'
                                    if isempty(tempTable_COLUMN.Group{ll})
                                        Component = matlab.ui.internal.toolstrip.ToggleButton();
                                    else
                                        idx = find(strcmp(GroupTable.name, tempTable_COLUMN.Group{ll}), 1);
                                        Component = matlab.ui.internal.toolstrip.ToggleButton('', GroupTable.handle{idx});
                                    end

                                case {'RadioButton', 'ListItemWithRadioButton'}
                                    idx = find(strcmp(GroupTable.name, tempTable_COLUMN.Group{ll}), 1);
                                    Component = eval(sprintf('matlab.ui.internal.toolstrip.%s(GroupTable.handle{idx})', tempTable_COLUMN.Type{ll}));

                                case {'DropDownButton', 'SplitButton'}
                                    popup = matlab.ui.internal.toolstrip.PopupList();
                                    for mm = 1:numel(tempTable_COLUMN.Parameters{ll}.Children)
                                        childComponent  = eval(sprintf('matlab.ui.internal.toolstrip.%s', tempTable_COLUMN.Parameters{ll}.Children(mm).Type));
                                        childParameters = fields(tempTable_COLUMN.Parameters{ll}.Children(mm).Parameters);
                                        ComponentProperties(obj, tempTable_COLUMN(ll,:), childParameters, childComponent, 'childComponent', mm)

                                        popup.add(childComponent)
                                    end
                                    
                                    Component = eval(sprintf('matlab.ui.internal.toolstrip.%s()', tempTable_COLUMN.Type{ll}));
                                    Component.Popup = popup;

                                case 'Gallery'
                                    popup = matlab.ui.internal.toolstrip.GalleryPopup();

                                    [categoryList, ~, categoryIndex] = unique({tempTable_COLUMN.Parameters{ll}.Children.Group});
                                    for mm = 1:numel(categoryList)
                                        categoryMember = matlab.ui.internal.toolstrip.GalleryCategory(categoryList{mm});

                                        idx = find(categoryIndex == mm)';
                                        for nn = idx
                                            childComponent  = eval(sprintf('matlab.ui.internal.toolstrip.%s', tempTable_COLUMN.Parameters{ll}.Children(nn).Type));
                                            childParameters = fields(tempTable_COLUMN.Parameters{ll}.Children(nn).Parameters);
                                            ComponentProperties(obj, tempTable_COLUMN(ll,:), childParameters, childComponent, 'childComponent', nn)
    
                                            categoryMember.add(childComponent)
                                        end
                                        
                                        popup.add(categoryMember)
                                    end
                                    
                                    Component = matlab.ui.internal.toolstrip.Gallery(popup, 'MaxColumnCount', tempTable_COLUMN.Parameters{ll}.MaxColumnCount);
                            end
                            ComponentProperties(obj, tempTable_COLUMN(ll,:), Parameters, Component, 'Component', -1)
                            Column.add(Component)

                            if tempTable_COLUMN.appProperty(ll)
                                % Registro do componente:
                                registerComponents(obj, tempTable_COLUMN.appPropertyName{ll}, Component)
                            end
                        end
                    end
                end
                tabGroup.add(objStruct(ii).Tab)
            end
        end

        %-----------------------------------------------------------------%
        function PanelCreation(obj, Tag, Position)

            Panel = matlab.ui.internal.FigurePanel(struct('Tag', Tag, 'Title', Tag, 'PermissibleRegions', Position, 'Region', Position, 'Maximizable', false, 'Opened', false));
            createdPanel = eval(sprintf('panel.%s_PanelCreation(obj, Panel.Figure)', Tag));
            
            % Registra componentes do novo painel como propriedade do objeto
            % "ContainerFrame".
            objFields = fields(createdPanel);
            try
            for ii = 1:numel(objFields)
                registerComponents(obj, sprintf('%s_%s', Tag, objFields{ii}), createdPanel.(objFields{ii}))
            end
            catch ME
                pause(1)
            end
            obj.Container.addPanel(Panel)
        end

        %-----------------------------------------------------------------%
        function delete(obj)
            if isappdata(groot, obj.Name)
                rmappdata(groot, obj.Name);
            end

            delete(obj)
        end
    end


    methods (Access = private)
        %-----------------------------------------------------------------%
        % ## STARTUP ##
        %-----------------------------------------------------------------%        
        function startupBuilding_TabGroup(obj, Tag)
            tabGroup = matlab.ui.internal.toolstrip.TabGroup();
            tabGroup.Tag = Tag;
            tabGroup.SelectedTabChangedFcn = {@uniqueCallbackFcn, obj};

            obj.Container.addTabGroup(tabGroup)
        end

        %-----------------------------------------------------------------%
        function startupBuilding_DocumentGroup(obj)
            % C:\Program Files\MATLAB\R2022b\toolbox\matlab\uitools\uicomponents\components\+matlab\+ui\+internal\FigureDocumentGroup.m
            docGroup = matlab.ui.internal.FigureDocumentGroup(struct('Tag', 'Tabs', 'Title', 'Tabs'));
            obj.Container.add(docGroup)
        end


        %-----------------------------------------------------------------%
        function startupBuilding_QuickAccessBar(obj)
            % C:\Program Files\MATLAB\R2022b\toolbox\matlab\toolstrip\+matlab\+ui\+internal\+toolstrip\+qab
            helpButton = matlab.ui.internal.toolstrip.qab.QABHelpButton();
            helpButton.ButtonPushedFcn = {@uniqueCallbackFcn, obj};

            obj.Container.add(helpButton) 
        end


        %-----------------------------------------------------------------%
        function startupBuilding_StatusBar(obj)
            % C:\Program Files\MATLAB\R2022b\toolbox\matlab\appcontainer\+matlab\+ui\+internal\+statusbar\StatusBar.m            
            statusLabel = matlab.ui.internal.statusbar.StatusLabel(struct('Icon', fullfile(obj.pathToMFILE, 'MOSAIC_16.png'), 'Text', 'Status bar...', 'Region', 'left'));
            statusBar   = matlab.ui.internal.statusbar.StatusBar();
            statusBar.add(statusLabel)

            obj.Container.addStatusBar(statusBar)   
        end


        %-----------------------------------------------------------------%
        function appStateChangedCallback(obj, ~, ~)
            % Os estados de um objeto "AppContainer" são definidos por uma
            % enumeração. Fluxo:
            % INITIALIZING >> RUNNING >> TERMINATED
            switch obj.Container.State
                case matlab.ui.container.internal.appcontainer.AppState.RUNNING
                    obj.hWebWindow = struct(obj.Container).Window;

                case matlab.ui.container.internal.appcontainer.AppState.TERMINATED
                    delete(obj);
            end
        end
    end


    methods (Access = private)
        %-----------------------------------------------------------------%
        % ## REGISTER COMPONENTS ##
        %-----------------------------------------------------------------%
        function registerComponents(obj, propName, propObj)
            if ~isprop(obj, propName)
                propHandle = addprop(obj, propName);
                propHandle.Hidden = true;
            end
            obj.(propName) = propObj;
        end

        %-----------------------------------------------------------------%
        % ## PARSING TOOLSTRIP CONFIG FILE (JSON) ##
        %-----------------------------------------------------------------%
        function ComponentProperties(obj, tempTable_COLUMN, Parameters, Component, Tag, idx)
            for ii = 1:numel(Parameters)
                switch Tag
                    case 'Component'
                        parameterValue = tempTable_COLUMN.Parameters{1}.(Parameters{ii});
                    case 'childComponent'
                        parameterValue = tempTable_COLUMN.Parameters{1}.Children(idx).Parameters.(Parameters{ii});
                end

                switch Parameters{ii}
                    case {'ButtonPushedFcn', 'ValueChangedFcn', 'ItemPushedFcn'}
                        parameterValue = {str2func(parameterValue), obj};
                    case 'Icon'
                        if strcmp(parameterValue(1:5), 'Icon.')
                            parameterValue = eval(sprintf('matlab.ui.internal.toolstrip.%s', parameterValue));
                        end
                    case {'Items', 'maxRows', 'maxColumns', 'Children', 'MaxColumnCount'}
                        % Properties that must be passing into the constructor
                        continue
                end
                Component.(Parameters{ii}) = parameterValue;
            end
        end
    end
end