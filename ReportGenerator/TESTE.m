cd 'D:\InovaFiscaliza\Miscellaneous\ReportGenerator'
[callingApp, reportInfo, dataOverview] = InputArguments(pwd, pwd);
htmlReport = report.Controller(callingApp, reportInfo, dataOverview);
uihtml(uigridlayout(uifigure, [1 1], 'BackgroundColor', 'white'), 'HTMLSource', htmlReport);