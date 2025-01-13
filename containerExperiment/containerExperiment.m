function hApp = containerExperiment(varargin)

    warning('off', 'MATLAB:structOnObject')

    hApp = getappdata(groot, 'containerExperimentApp');
    
    isStartUp = isempty(hApp) || ~isa(hApp, 'handle') || ~isvalid(hApp) || ~struct(hApp.Container).Window.isWindowValid;
    if isStartUp
        hApp = containerExperimentApp(varargin{:});
    else
        hApp.Container.bringToFront()
    end
end