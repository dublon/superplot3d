function varargout = superplot3d(varargin)
% SUPERPLOT3D M-file for superplot3d.fig
%      SUPERPLOT3D, by itself, creates a new SUPERPLOT3D or raises the existing
%      singleton*.
%
%      H = SUPERPLOT3D returns the handle to a new SUPERPLOT3D or the handle to
%      the existing singleton*.
%
%      SUPERPLOT3D('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SUPERPLOT3D.M with the given input arguments.
%
%      SUPERPLOT3D('Property','Value',...) creates a new SUPERPLOT3D or raises the
%      existing singleton*.  Starting from the left, property value pairs
%      are
%      applied to the GUI before superplot3d_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property
%      application
%      stop.  All inputs are passed to superplot3d_OpeningFcn via
%      varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help
% superplot3d

% Last Modified by GUIDE v2.5 03-Apr-2013 18:38:48

% Begin initialization code - DO NOT EDIT

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @superplot3d_OpeningFcn, ...
    'gui_OutputFcn',  @superplot3d_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before superplot3d is made visible.

function superplot3d_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to superplot3d (see VARARGIN)

% Choose default command line output for superplot3d
handles.output = hObject;

%% load in icons

[iconA map] = imread(fullfile('iconcuttraces.gif'));
global cut_traces_icon
cut_traces_icon = ind2rgb(iconA,map);

global export_icon_pdf
[iconB map] = imread(fullfile('iconexportPDF.gif'));
export_icon_pdf = ind2rgb(iconB,map);

[iconC map] = imread(fullfile('iconthripshead.gif'));
global thrips_icon
thrips_icon = ind2rgb(iconC,map);

[iconD map] = imread(fullfile('iconinfo.gif'));
global info_icon
info_icon = ind2rgb(iconD,map);

[iconE map] = imread(fullfile('iconexportCSV.gif'));
global export_icon_csv
export_icon_csv = ind2rgb(iconE,map);

[iconF map] = imread(fullfile('icontable.gif'));
global table_icon
table_icon = ind2rgb(iconF,map);

[iconG map] = imread(fullfile('iconexportTXT.gif'));
global export_icon_txt
export_icon_txt = ind2rgb(iconG,map);

guidata(hObject, handles);
global clear_button_message;

clear_button_message = true;
clearvars -global processed_data
loadedstring = 'superplot3d v.1.0.1 (build 20170220) 2017 Sveriges lantbruksuniversitet';
set(handles.filenametext,'String', loadedstring);

% --- Outputs from this function are returned to the command line.
function varargout = superplot3d_OutputFcn(~, ~, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function rval = process(rdata, name)

file_col_length= length(rdata);
DataX = rdata(:,1);
DataY = rdata(:,2);
DataZ = rdata(:,3);
DataT = rdata(:,4);
for i=1:size(rdata,2)-1
    if sum(isnan(rdata(:,i))) ~= sum(isnan(rdata(:,i+1)))
        %waitfor(helpdlg(sprintf('NB: discrepency found in number of NaNs between columns %i and %i, there may be more and this will adversely affect further processing.', i, i+1),'Potentially irregular data'))
        AutoWarnDlg(sprintf('NB: discrepancy found in number of NaNs between columns %i and %i, there may be more and this will adversely affect further processing.', i, i+1),'Potentially irregular data',struct('Delay', 3))
        break
    end
end
%%  map NaN's
NaN_pos = ~isnan(DataX(:)); % true and false locations of NaN's: 0 = NaN 1 = real int
NaN_pos_inv = isnan(DataX(:));
first_or_preceeded_by_NaN = [true; NaN_pos_inv(1:end-1)];
extra_NaN = NaN_pos_inv & first_or_preceeded_by_NaN;
how_many_segments = sum(~NaN_pos,1);% returns sum of NaNs column 1


% Remove delinquent extra NaNs in all rows if they are there
DataX(extra_NaN) = [];
DataY(extra_NaN) = [];
DataZ(extra_NaN) = [];
DataT(extra_NaN) = [];
% Remove errant NaNs at start and end if there
if isnan(DataX(1))||isnan(DataY(1))||isnan(DataZ(1));
    DataX(1) = [];
    DataY(1) = [];
    DataZ(1) = [];
    DataT(1) = [];
end
if isnan(DataX(end))||isnan(DataY(end))||isnan(DataZ(end));
    DataX(end) = [];
    DataY(end) = [];
    DataZ(end) = [];
    DataT(end) = [];
end
Datag = [DataX DataY DataZ];
how_many_segments = sum(isnan(DataX))+1; % now we have stripped extra NaN's we get the correct number of NaNs
FileColLengthChoppedNaN= length(DataX);
Loc= find(isnan(DataX(:)));

% offsetting happens here-----------------------
offset1DataX = DataX(2:end) - DataX(1:end-1); %DataX starting row 2
offset1DataY = DataY(2:end) - DataY(1:end-1); %DataY starting row 2
offset1DataZ = DataZ(2:end) - DataZ(1:end-1); %DataZ starting row 2
deltaT = DataT(2:end) - DataT(1:end-1); %DataT starting row 2

offset2DataX = DataX(3:end) - DataX(1:end-2); %DataX starting row 3
offset2DataY = DataY(3:end) - DataY(1:end-2); %DataY starting row 3
offset2DataZ = DataZ(3:end) - DataZ(1:end-2); %DataZ starting row 3

dist1 = sqrt((offset1DataY).^2+(offset1DataX).^2+(offset1DataZ).^2);
dist2 = sqrt((offset2DataY).^2+(offset2DataX).^2+(offset2DataZ).^2);

% real part as there seems to be some issues with acos sometimes
% returning complex numbers indicating some issue with the input
part1b = real(acos((dist1(1:end-1).^2 + dist1(2:end).^2 - dist2(1:end).^2)./(2.*dist1(1:end-1).*dist1(2:end))));
%cannot account for signed angle currently.
Corrected3dAngle = 180-(part1b.*180)/pi;

try
    load ('points.mat');
catch err
    origin_ctr = [2 0 0];
    %     helpdlg('Using default origin coordinates. See Preferences.','Origin not defined in preferences')
    %     return
end

distance_to_origin_ctr = sqrt((DataZ-origin_ctr(3)).^2+(DataY-origin_ctr(2)).^2+(DataX-origin_ctr(1)).^2);
mean_distance_to_origin_ctr= nanmean(distance_to_origin_ctr);

try
    load ('framerate.mat');
catch err2
    choiceframerate = 0.02;
end
theoretical_speed = dist1./choiceframerate;
actual_speed = dist1./deltaT;
ActualTrackDuration = (length(DataX)-how_many_segments)*choiceframerate;
ActualTrackDurationMin = ActualTrackDuration/60;
TrackingPeriod = (length(DataX)*choiceframerate);
TrackingPeriod_min=TrackingPeriod/60;

meanX = nanmean(DataX);
meanY = nanmean(DataY);
meanZ = nanmean(DataZ);
stdX= nanstd(DataX);
stdY= nanstd(DataY);
stdZ= nanstd(DataZ);
EstVelocityDist1=nansum(dist1)/TrackingPeriod;
name = [];
ext = [];
data_format = [];

try
    load ('vectors.mat');
catch err3
    rotationsign = '';
    vec = [0 0 1];
end

ptvec = Datag(2:end,:) - Datag(1:end-1,:);

pt_len = sqrt(ptvec(:,1).^2 + ptvec(:,2).^2 + ptvec(:,3).^2);
norm = bsxfun(@rdivide, ptvec, pt_len);
tvec =rad2deg(real(acos(sum(norm .* repmat(vec, [length(norm) 1] ), 2))));

if rotationsign == '+';
    tvec = (tvec.*-1);
end

names = {};
for i=1:length(tvec)
    names{end+1} = rotationsign;
end

rval.name = name;
rval.ext = ext;
rval.data_format = data_format;
rval.x = DataX;
rval.y = DataY;
rval.z = DataZ;
rval.t = DataT;
rval.distance_to_origin_ctr = distance_to_origin_ctr;
rval.mean_distance_to_origin_ctr = mean_distance_to_origin_ctr;
rval.ActualTrackDuration = ActualTrackDuration;
rval.ActualTrackDurationMin = ActualTrackDurationMin;
rval.TrackingPeriod = TrackingPeriod;
rval.TrackingPeriod_min = TrackingPeriod_min;
rval.meanX = meanX;
rval.meanY = meanY;
rval.meanZ = meanZ;
rval.stdX = stdX;
rval.stdY = stdY;
rval.stdZ = stdZ;
rval.EstVelocityDist1 = EstVelocityDist1;
rval.file_col_length = file_col_length;
rval.FileColLengthChoppedNaN = FileColLengthChoppedNaN;
rval.ptvec = ptvec;
rval.pt_len = pt_len;
rval.names = names;
rval.NaN_pos =NaN_pos;
rval.NaN_pos_inv = NaN_pos_inv;
rval.first_or_preceeded_by_NaN = first_or_preceeded_by_NaN;
rval.how_many_segments = how_many_segments;
rval.Loc = Loc;
rval.tvec = padarray(tvec,[1],NaN,'post'); %pad the array so the dimensions match that of the original data
rval.Corrected3dAngle =  padarray(Corrected3dAngle,[1],NaN);
rval.dist1 = padarray(dist1,[1],NaN,'pre');
rval.dist2 = padarray(dist2,[2],NaN,'pre');
rval.actual_speed = padarray(actual_speed,[1],NaN,'pre');


%% open button press
% --- Executes on button press in open_button.
function open_button_Callback(hObject, eventdata, handles)

[Filename,PathName] = uigetfile( ...
    {'*.dat;*.txt;*.out;','TrackIt3d output files (*.dat,*.txt,*.out)';
    '*.dat', 'Tab delimited .dat files (*.dat)'; ...
    '*.csv', 'Comma delimited .csv files (*.csv)'; ...
    '*.txt', 'Text tab delimited (*.txt)'; ...
    '*.*', 'All Files (*.*)'}, ...
    'Open data file');

if isequal(Filename,0)
    helpdlg('Load cancelled','Load');
    
else
    loadedstring = char(sprintf('Loaded: %s' , Filename));
    set(handles.filenametext,'String', loadedstring);
    try
        load ('datarange.mat');
    catch err
        datarangedefaults = 'A2..D2(count)';
        answer = {'1', '1', '2', '3', '4'};
        errorstring = 'NB: No data import preferences found. Things may be wrong. Check Superplot3d> Preferences> Data Import...';
        set(handles.filenametext,'String', errorstring);
    end
    [pathstr, name, ext] = fileparts(Filename); % decide which extension we have
    if ext =='.csv';
        separator = ',';
        data_format = 'comma separated';
    else
        separator = '\t';
        data_format = 'tab delimited';
    end
    rdata = dlmread([PathName,Filename], separator, [datarangedefaults]);
    
    rdata= [rdata(:,str2num(answer{2})) rdata(:,str2num(answer{3})) rdata(:,str2num(answer{4})) rdata(:,str2num(answer{5}))];
    global processed_data;
    
    processed_data = process(rdata, Filename);
    processed_data.pathstr = pathstr;
    processed_data.name = name;
    processed_data.ext = ext;
    processed_data.data_format = data_format;
    
    generated_windows= get(0,'Children');% close all other windows as they will now have invalid data
    
    for i = 1:length(generated_windows)
        if generated_windows(i) ~= gcf
            delete(generated_windows(i))
        end
    end
end


function clear_button_Callback(hObject, eventdata, handles)

clearvars -global processed_data
cla
set(gca, 'visible', 'off');
loadedstring = 'Variables cleared';
set(handles.filenametext,'String', loadedstring);
set(findall(gca, 'type', 'text'), 'visible', 'off')
global clear_button_message;
clear_button_message = false;
initial_plot_button_Callback;
clear_button_message = true;

% --- Executes on button press in select_traces_button.
function select_traces_button_Callback(hObject, eventdata, handles)
global processed_data
global cut_traces_icon
global export_icon_pdf
global export_icon_csv
global export_icon_txt
global table_icon
global info_icon

if isfield (processed_data, 'x')
    if length(processed_data.x) == 0
        errordlg('Structure present, but without X data. Aborting.','Data formatting problems')
        return
    end
else
    helpdlg('No variables loaded just yet','Load data first')
    return
end

try load('axis.mat')
catch err
    choiceXaxis = [-0.5 0.5];
    choiceYaxis = [-0.2 0.3];
    choiceZaxis = [0.1 0.3];
end

try load('view.mat')
catch err2
    choiceviewangle = [-37.5 30];
    choicemagnitude = 5;
end
try
    load('points.mat');
catch err
    pointdefaults = [2 0 0];
    origin_ctr = [2 0 0];
    
end
try
    load('overlay.mat')
catch
    %     choiceoverlay1 = [[0,0,0.05]];
    %     choiceoverlay2 =
    msgbox('Select overlay first')
end
% -----------------------------------------------------Create dialog and axes
global sel_figure
sel_figure = figure('Name', 'Interactive plotting','NumberTitle','off');
defaultend = num2str(processed_data.FileColLengthChoppedNaN);
dlg_title = 'Interactive plotting';

num_lines = 1;
matstartrow{1} = 'Enter matrix start row: ';
matstartrow{2} = 'Enter matrix end row: ';
defStartStop = {'1',defaultend};

answer = inputdlg(matstartrow,dlg_title,num_lines,defStartStop);
if isequal(answer,{})
    helpdlg('Interactive plot cancelled','Interactive plot')
    close(figureInt)
    return
end
choiceXYZs = str2double(answer{1});
choiceXYZe = str2double(answer{2});

datacursormode
global selected_processed_data;
selected_processed_data = process([processed_data.x(choiceXYZs:choiceXYZe)...
    processed_data.y(choiceXYZs:choiceXYZe)...
    processed_data.z(choiceXYZs:choiceXYZe)...
    processed_data.t(choiceXYZs:choiceXYZe)],...
    sprintf('selected_%s', processed_data.name));
selected_processed_data.ext = processed_data.ext;
selected_processed_data.data_format = processed_data.data_format;
selected_processed_data.name = processed_data.name;

set(sel_figure,'Name',['Displaying ',answer{1},' to ', answer{2}])
axes('Parent',sel_figure,'OuterPosition',[0 0 1 1]);
plot3(selected_processed_data.x, selected_processed_data.y, selected_processed_data.z,'*-','markersize',2, 'linewidth',1);
xlabel('x'); ylabel('y'); zlabel('z');
axis([choiceXaxis choiceYaxis choiceZaxis])
view([choiceviewangle])
titlestring= strrep(selected_processed_data.name,'_','\_');
title([titlestring, selected_processed_data.ext,' ', num2str(choiceXYZs),' - ', num2str(choiceXYZe)]);
grid('on');
% ---------------------------------------Create custom toolbar and populate
custom_toolbar = uitoolbar(sel_figure);

toolbarbutton1 = uipushtool(custom_toolbar,'CData',cut_traces_icon,...
    'TooltipString','Cut tracks in between selected Data Tips',...
    'ClickedCallback',@datatipmode);
toolbarbutton2 = uipushtool(custom_toolbar,'CData',table_icon,...
    'TooltipString','View matrix for this section',...
    'ClickedCallback',@choicetabulate);
toolbarbutton3 = uipushtool(custom_toolbar,'CData',info_icon,...
    'TooltipString','Get info',...
    'ClickedCallback',@get_info_selected);
toolbarbutton4 = uipushtool(custom_toolbar,'CData',export_icon_txt,...
    'TooltipString','Write info summary',...
    'ClickedCallback',@write_info_selected);
toolbarbutton5 = uipushtool(custom_toolbar,'CData',export_icon_pdf,...
    'TooltipString','Create .pdf figure',...
    'ClickedCallback',@export_figcalled);
toolbarbutton6 = uipushtool(custom_toolbar,'CData',export_icon_csv,...
    'TooltipString','Output flight info as .csv',...
    'ClickedCallback',@write_selectedflight_info_button_Callback);

% ------------- Executes on button press in entire_file_button. Split breaks at tracking
function entire_file_button_Callback(hObject, eventdata, handles)
global processed_data
global cut_traces_icon
global export_icon_pdf
global export_icon_csv
global table_icon

if ~isequal(processed_data,[])
    try load('view.mat')
    catch err2
        choiceviewangle = [-37.5 30];
        choicemagnitude = 5;
    end
    try load('axis.mat')
    catch err
        choiceXaxis = [-0.5 0.5];
        choiceYaxis = [-0.2 0.3];
        choiceZaxis = [0.1 0.3];
    end
    
else
    helpdlg('No variables loaded just yet','Load data first')
    return
end
% plot-----------------------
figureInt = figure('Name', 'Split at breaks in tracking','NumberTitle','off', 'PaperSize',[30.98 29.68]);

%  Create dialog-----------------------
dlg_title = 'Split at breaks in tracking...';
defaultfullplotend = num2str(processed_data.how_many_segments);
num_lines = 1;
splitat{1} = 'Split at breaks in tracking. First segment to plot: ';
splitat{2} = 'Until segment:';
defSplit = {'1', defaultfullplotend};

answer = inputdlg(splitat,dlg_title,num_lines,defSplit);
if isequal(answer,{})
    helpdlg('Split at breaks plot cancelled','Split at breaks in plot')
    close(figureInt)
    return
end
choiceXYZs = str2num(answer{1});
choiceXYZe = min(str2num(defaultfullplotend),str2num(answer{2}));

axes('Parent',figureInt,'OuterPosition',[0 0 1 1]);
plotme=1;

% split tracks loop and plot-----------------------
lenLoc=length(processed_data.Loc(choiceXYZs:choiceXYZe-1));
Loc2=(processed_data.Loc(choiceXYZs:choiceXYZe-1));

star=1;
fin=2;
fcount=1;
for fcount = choiceXYZs:choiceXYZe
    
    if fcount > lenLoc
        fin = length(processed_data.x);
    else
        fin = processed_data.Loc(fcount);
    end
    
    subplot(ceil(sqrt(choiceXYZe)), ceil(sqrt(choiceXYZe)), fcount);
    plotme = plot3(processed_data.x(star:fin),processed_data.y(star:fin),processed_data.z(star:fin),'*-','markersize',1, 'linewidth',1);
    
    axis([choiceXaxis choiceYaxis choiceZaxis]);
    view([choiceviewangle]);
    grid('on');
    
    star = fin;
    
end
%set(figureInt, 'WindowStyle','docked')

% ---------------------------------------Create custom toolbar and populate
custom_toolbar = uitoolbar(figureInt);
toolbarbutton1 = uipushtool(custom_toolbar,'CData',cut_traces_icon,...
    'TooltipString','Cut tracks in between selected Data Tips',...
    'ClickedCallback',@datatipmode);


toolbarbutton2 = uipushtool(custom_toolbar,'CData',export_icon_pdf,...
    'TooltipString','Create .pdf figure',...
    'ClickedCallback',@export_figcalled);


function generate_info(info_data)
if ~isequal(info_data,[])
    try
        load ('points.mat');
    catch err
        origin_ctr = [2 0 0];
    end
    fileinfostr = [sprintf('%s%s', info_data.name, info_data.ext),...
        sprintf('\n'),sprintf('Data is %s ', info_data.data_format),...
        sprintf('\n \n'),...
        sprintf('File length (rows): %d ', info_data.file_col_length),...
        sprintf('\n'), sprintf('File length when extraneous gaps between tracking (NaN''s) are removed (rows): %d ', info_data.FileColLengthChoppedNaN),...
        sprintf('\n'),sprintf('Consisting of %d segments' , info_data.how_many_segments),...
        sprintf('\n \n'),...
        sprintf('Tracking period: %g sec.', info_data.TrackingPeriod),sprintf('\n'),...
        sprintf('Actual track duration: %g sec ', info_data.ActualTrackDuration),sprintf('(%g min)',...
        info_data.ActualTrackDurationMin), sprintf('\n \n'),sprintf('Mean track Z: %g m ', info_data.meanZ(1)),...
        sprintf('(sd %g)', info_data.stdZ(1)),sprintf('\n'),sprintf('Mean track X: %g m ', info_data.meanX(1)),...
        sprintf('(sd %g)', info_data.stdX(1)),sprintf('\n'),sprintf('Mean track Y: %g m ', info_data.meanY(1)),...
        sprintf('(sd %g)', info_data.stdY(1)),...
        sprintf('\n \n'),...
        sprintf('Est. Velocity across all tracks: %g m/s.', info_data.EstVelocityDist1),...
        sprintf('\n'),...
        sprintf('Origin centre defined as: x %g y %g z %g \n', origin_ctr(1), origin_ctr(2), origin_ctr(3)),...
        sprintf('Mean distance from origin: %g m.', info_data.mean_distance_to_origin_ctr)];
    
    helpdlg(fileinfostr, 'File and track parameters')
else
    helpdlg('No variables loaded just yet','Load data first')
end

% Get info button press-----------------------
% --- Executes on button press in get_info_button.
function get_info_button_Callback(hObject, eventdata, handles)
global processed_data
generate_info(processed_data)

function get_info_selected(hObject, eventdata, handles)
global selected_processed_data
generate_info(selected_processed_data)

% Get info button from within datatip cut mode-----------------------
function get_info_datatip(hObject, eventdata, handles)
global cut_processed_data
generate_info(cut_processed_data)

% Diary write info summary-----------------------
function writeinfo(info_data)
if isfield (info_data, 'x')
    if length(info_data.x) == 0
        errordlg('Data structure present, but without X data. Aborting.','Data formatting problems')
        return
    end
    [file,path] = uiputfile('*.txt','Save flight info',sprintf('Info_for_%s.txt', info_data.name));
    fp = [path file];
    
    
    
    if isequal(file,0)
        helpdlg('Save as .txt cancelled','Save')
        %msgbox('Save as .txt cancelled','modal');
        
    else
        %struct2File(info_data, fp )
        diary(fp)%sprintf('%s', fp))
        info_data
        diary off
    end
end
function write_info_button_Callback(hObject, eventdata, handles)
global processed_data
writeinfo(processed_data)

function write_info_selected(hObject, eventdata, handles)
global selected_processed_data
writeinfo(selected_processed_data)

% Get info button from within datatip cut mode-----------------------
function write_info_datatip(hObject, eventdata, handles)
global cut_processed_data
writeinfo(cut_processed_data)

% cartesian to polar pushbutton -----------------------
% --- Executes on button press in car2pol_button.
function car2pol_button_Callback(hObject, eventdata, handles)
global processed_data
global cut_traces_icon
global export_icon_pdf
global export_icon_csv

if ~isequal(processed_data,[])
    try
        load ('points.mat');
    catch err
        origin_ctr = [2 0 0];
    end
    try load('axis.mat')
    catch err
        choiceXaxis = [-0.5 0.5];
        choiceYaxis = [-0.2 0.3];
        choiceZaxis = [0.1 0.3];
    end
    
else
    helpdlg('No variables loaded just yet','Load data first')
    return
end

%------------------------------------------------------plot
figureInt = figure('Name', 'Cartesian and cylindrical polar','NumberTitle','off', 'PaperSize',[30.98 29.68]);

%-----------------------------------------------------------dialog
dlg_title = 'Interactive cylindrical plotting...';
defaultend = num2str(processed_data.FileColLengthChoppedNaN);
num_lines = 1;
matstartrow{1} = 'Enter matrix start row: ';
matstartrow{2} = 'Enter matrix end row: ';
matstartrow{3} = 'Cell range for moving average smooth:';
defStartStop = {'1',defaultend,'16'};

answer = inputdlg(matstartrow,dlg_title,num_lines,defStartStop);
if isequal(answer,{})
    helpdlg('Cartesian to Cylindrical Polar conversion cancelled','Cartesian to Polar')
    close(figureInt)
    return
end
choiceXYZs = str2double(answer{1});
choiceXYZe = str2double(answer{2});
spread = str2double(answer{3});

%% convert selection to cylindrical coords
%offset data coords to get marker at origin
[sel_Datag] = [processed_data.x(choiceXYZs:choiceXYZe) processed_data.y(choiceXYZs:choiceXYZe) processed_data.z(choiceXYZs:choiceXYZe)];
sel_offset_data = sel_Datag - repmat(origin_ctr,length(sel_Datag),1);
n = length(sel_offset_data);

%check to make sure there is enough data to smooth
if n - spread<1
    msgbox('Insufficient data points for smoothing. Aborting')
    delete(figureInt)
    return
end
%moving average to smooth data-----------------------
for counter=spread:n-spread
    for col = 1:3
        avg_data(counter-spread+1,col) = nanmean(sel_offset_data(counter-spread+1:counter+spread, col));
    end
end
[sel_ctheta, sel_cr, sel_ch] = cart2pol(sel_offset_data(:,1), sel_offset_data(:,2), sel_offset_data(:,2));
global pol;
pol.ctheta = sel_ctheta;
pol.cr = sel_cr;
pol.ch = sel_ch;
[ave_sel_ctheta, ave_sel_cr, ave_sel_ch] = cart2pol(avg_data(:,1), avg_data(:,2), avg_data(:,3));
pol.mean_ctheta = ave_sel_ctheta;
pol.mean_cr = ave_sel_cr;
pol.mean_ch = ave_sel_ch;

%    ctheta(THETA) is a counterclockwise angular displacement in radians from the positive x-axis,
%    cr(RHO/radius) is the distance from the origin to a point in the x-y plane
%    ch (Z) is the height above the x-y plane. Arrays X, Y, and Z must be the same size (or any can be scalar).
%% Create UI panels
hpancyl = uipanel('Title','Cylindrical polar components ','FontSize',8,...
    'Position',[0.45 0.33 0.53 0.65]);
hpancyl2 = uipanel('Title','Smoothed cylindrical polar components ','FontSize',8,...
    'Position',[0.05 0.03 0.93 0.30]);
% main plot-----------------------
axes('OuterPosition',[0 0.4 0.45 0.55]);
% firstplot
datacursormode
view([-37.5 30]);
plot3(processed_data.x(choiceXYZs:choiceXYZe),processed_data.y(choiceXYZs:choiceXYZe),processed_data.z(choiceXYZs:choiceXYZe),'*-','markersize',2, 'linewidth',1)
xlabel('x'); ylabel('y'); zlabel('z');
axis([choiceXaxis choiceYaxis choiceZaxis]);
title([num2str(processed_data.name, processed_data.ext),' ', num2str(choiceXYZs),' - ', num2str(choiceXYZe)]);
grid('on');


% theta plot-----------------------
axes('OuterPosition',[0.48 0.70 0.25 0.25]);
title([processed_data.name, processed_data.ext])
grid('on');
hold on
plot(sel_ctheta, 'linewidth',1)
%hi = findobj(gca, 'Type', 'patch');
%set (hi, 'FaceAlpha', 0.7);
title('theta')

% radius plot-----------------------
axes('OuterPosition',[0.73 0.70 0.25 0.25]);
title([processed_data.name, processed_data.ext])
grid('on');
hold on
plot(sel_cr, 'linewidth',1)
%hi = findobj(gca, 'Type', 'patch');
%set (hi, 'FaceAlpha', 0.7);
title('radius')

% height plot-----------------------
axes('OuterPosition',[0.48 0.40 0.25 0.25]);
grid('on');
hold on
plot(sel_ch, 'linewidth',1)
%hi = findobj(gca, 'Type', 'patch');
%set (hi, 'FaceAlpha', 0.7);
title('height')

% smoothed theta plot-----------------------
axes('OuterPosition',[0.10 0.05 0.25 0.25]);
plot(ave_sel_ctheta, 'linewidth',1)
grid('on');
title('smoothed theta')

% smoothed radius plot-----------------------
axes('OuterPosition',[0.40 0.05 0.25 0.25]);
plot(ave_sel_cr, 'linewidth',1)
grid('on');
title('smoothed radius')

% smoothed height plot-----------------------
axes('OuterPosition',[0.70 0.05 0.25 0.25]);
plot(ave_sel_ch, 'linewidth',1)
grid('on');
title('smoothed height')

% Custom toolbar for this window-----------------------
custom_toolbar = uitoolbar(figureInt);
toolbarbutton1 = uipushtool(custom_toolbar,'CData',cut_traces_icon,...
    'TooltipString','Cut tracks in between selected Data Tips',...
    'ClickedCallback',@datatipmode);
toolbarbutton2 = uipushtool(custom_toolbar,'CData',export_icon_pdf,...
    'TooltipString','Create .pdf figure',...
    'ClickedCallback',@export_figcalled);
toolbarbutton3 = uipushtool(custom_toolbar,'CData',export_icon_csv,...
    'TooltipString','Output selected polar coordinates',...
    'ClickedCallback',@outputpolar);

% outputs a csv with given data
function csvgenerate(csv_data)
try
    load ('vectors.mat');
catch err
    rotationsign = '';
    vec = [0 0 1];
end
if isfield (csv_data, 'x')
    if length(csv_data.x) == 0
        errordlg('Data structure present, but without X data. Aborting.','Data formatting problems')
        return
    end
    
    %wlength = length(csv_data.dist2);
    %dist1 distance between 2 adjacent points on the track
    %dist2 distance between a point and the next but one
    
    %toWrite=[csv_data.x(1:wlength) csv_data.y(1:wlength) csv_data.z(1:wlength) csv_data.dist1(1:wlength) csv_data.dist2 csv_data.Corrected3dAngle(1:wlength) csv_data.tvec(1:wlength)];
    toWrite= [csv_data.x csv_data.y csv_data.z csv_data.t csv_data.dist1 csv_data.dist2 csv_data.actual_speed csv_data.Corrected3dAngle csv_data.tvec];
    header = {'%x', 'y', 'z', 'time' 'dist1', 'dist2', 'speed','idiothetic turning angle', 'three-dimensional angle'};
    
    [file,path] = uiputfile('*.csv','Save flight parameters file',sprintf('Processed_%s.csv', csv_data.name));
    
    if isequal(file,0)
        helpdlg('Save as .csv cancelled','Save as .csv');
        
    else
        csvwrite_with_headers([path file], toWrite,header,0,0);
        
    end
    
end

%% write file parameters out as .csv
% --- Executes on button press in write_flight_info_button.
function write_flight_info_button_Callback(hObject, eventdata, handles)
global processed_data
if isfield (processed_data, 'x')
    if length(processed_data.x) == 0
        errordlg('Structure present, but without X data. Aborting.','Data formatting problems')
        return
    end
else
    helpdlg('No variables loaded just yet','Load data first')
    return
end
csvgenerate(processed_data)

function write_selectedflight_info_button_Callback(hObject, eventdata, handles)
global selected_processed_data
csvgenerate(selected_processed_data)

function write_cutflight_info_button_Callback(hObject, eventdata, handles)
global cut_processed_data
csvgenerate(cut_processed_data)


%% object overlay
% --- Executes on button press in object_overlay_checkbox.
function object_overlay_checkbox_Callback(hObject, eventdata, handles)
button_state = get(hObject,'Value');
% Toggle button is pressed, take appropriate action
if button_state == get(hObject,'Max')
    try
        load overlay
    catch
        helpdlg('No octet coordinate defined. Check Superplot3d> Preferences> Coordinates for octet...', 'No octet coordinates defined')
        return
    end
    
    hold on
    plot3(choiceoverlay1(1),choiceoverlay1(2),choiceoverlay1(3),'-.ob','markersize',4)
    plot3(choiceoverlay2(1),choiceoverlay2(2),choiceoverlay2(3),'-.ob','markersize',4)
    plot3(choiceoverlay3(1),choiceoverlay3(2),choiceoverlay3(3),'-.ob','markersize',4)
    plot3(choiceoverlay4(1),choiceoverlay4(2),choiceoverlay4(3),'-.ob','markersize',4)
    plot3(choiceoverlay5(1),choiceoverlay5(2),choiceoverlay5(3),'-.ob','markersize',4)
    plot3(choiceoverlay6(1),choiceoverlay6(2),choiceoverlay6(3),'-.ob','markersize',4)
    plot3(choiceoverlay7(1),choiceoverlay7(2),choiceoverlay7(3),'-.ob','markersize',4)
    plot3(choiceoverlay8(1),choiceoverlay8(2),choiceoverlay8(3),'-.ob','markersize',4)
elseif button_state == get(hObject,'Min')
    % Toggle button is not pressed, take appropriate action
    hold off
    cla
    global clear_button_message;
    clear_button_message == true;
    initial_plot_button_Callback
end
%% - instant visualisation plot button

% --- Executes on button press in initial_plot_button.
function initial_plot_button_Callback(hObject, eventdata, handles)
% get our read in data
global processed_data;
try load('view.mat')
catch err
    choiceviewangle = [-37.5 30];
    choicemagnitude = 5;
end
try load('axis.mat')
catch err
    choiceXaxis = [-0.5 0.5];
    choiceYaxis = [-0.2 0.3];
    choiceZaxis = [0.1 0.3];
end
if ~isequal(processed_data,[])
    
    set(gca, 'visible', 'on')
    xlabel('x'); ylabel('y'); %zlabel('z');
    axis([choiceXaxis choiceYaxis choiceZaxis]);
    axis(gca,'vis3d'); % sets the default axis style to fixed aspect ratio
    view([choiceviewangle])
    title([(strrep(processed_data.name,'_','\_')),processed_data.ext]); % stops underscores in filename making text subscript
    grid('on');
    hold on
    
    colors = [0 1 0; 0 .75 0; 0 0 1; 0 .75 .75; .75 0 .75; .75 .75 0; 0 0 0];
    csize = length(colors);
    fileCol = 1;
    color = 1;
    
    while fileCol < processed_data.FileColLengthChoppedNaN
        % get magnitude of current line
        mag = floor(log10(fileCol));
        div = double(floor(max(1, (10^mag) / choicemagnitude)));
        fileColUpper = min(processed_data.FileColLengthChoppedNaN, fileCol + div);
        if fileCol==1
            cla
            plot3(processed_data.x(1),processed_data.y(1),processed_data.z(1),'-.ob',...
                'MarkerFaceColor',[0 0 0],'markersize',6);
        end
        if isnan(processed_data.x(fileCol))
            plot3(processed_data.x(fileColUpper),processed_data.y(fileColUpper),processed_data.z(fileColUpper),'-.ob',...
                'MarkerFaceColor',[0 0 0],'markersize',6);
        else
            plot3(processed_data.x(fileCol : fileColUpper), ...
                processed_data.y(fileCol : fileColUpper), ...
                processed_data.z(fileCol : fileColUpper),'linewidth',1, 'Color', colors(color + 1, : ) );
        end
        
        fileCol = fileCol + div;
        color = mod(color + 1, csize);
        
    end
else
    global clear_button_message;
    if clear_button_message == true;
        helpdlg('No variables loaded just yet','Load data first')
    end
end

% --- Executes on button press in datatable.
function datatable_Callback(hObject, eventdata, handles)
global processed_data
tabulate(processed_data)

%% Datatip function
function datatipmode(hObject, eventdata)
global processed_data
global cut_processed_data
global sel_figure

global thrips_icon
global cut_traces_icon
global export_icon_pdf
global info_icon
global export_icon_csv
global export_icon_txt
global table_icon

try
    load view
catch
    choicemagnitude = 5
    choiceviewangle = [-37.5 30]
end
dcmObj = datacursormode(sel_figure);

cinfo = getCursorInfo(dcmObj);

if length(cinfo)<2  % Have we cursorinfo present as a variable??
    
    msgbox({'Please select two data points to cut between and try again:','',...
        'Select the Data Cursor icon (if not already selected)','',...
        'Select trajectory point 1 and Alt click on trajectory point 2'},'Datatips required first','custom',thrips_icon);
    return
elseif length(cinfo)>2
    AutoWarnDlg('There are more than two data points selected; only the first two will be used','Too many datapoints',struct('Delay', 5))
end

figureInt = figure('Name', 'DataTip interactive plotting','NumberTitle','off', 'PaperSize',[30.98 29.68]);
axes('Parent',figureInt,'OuterPosition',[0 0 1 1]);
view([choiceviewangle])

cistart= cinfo(1,1).DataIndex;
cistop= cinfo(1,2).DataIndex;
cutrange = [cistart:cistop];
if isempty(cutrange)
    cutrange = [cistop:cistart];
end

Strcutrange = [num2str(min(cistop, cistart)),'_to_',num2str(max(cistart, cistop))];

CutDataX = processed_data.x(cutrange);
CutDataY = processed_data.y(cutrange);
CutDataZ = processed_data.z(cutrange);
CutDataT = processed_data.t(cutrange);
CutDatag = [processed_data.x(cutrange) processed_data.y(cutrange) processed_data.z(cutrange)];

cut_processed_data = process([CutDataX, CutDataY, CutDataZ, CutDataT], sprintf('Cut_%s_%s', processed_data.name, Strcutrange));
cut_processed_data.Strcutrange = Strcutrange;
cut_processed_data.data_format = processed_data.data_format;
cut_processed_data.name = processed_data.name;
plot3(processed_data.x(cutrange), processed_data.y(cutrange), processed_data.z(cutrange),'*-','markersize',2, 'linewidth',1)

try
    load framerate
catch err
    choiceframerate = 0.02;
    helpdlg('Using default framerate. See Preferences.','Framerate not defined in preferences')
end
try
    load ('points.mat');
catch err
    origin_ctr = [2 0 0];
    helpdlg('Using default origin coordinates. See Preferences.','Origin not defined in preferences')
end
try load('axis.mat')
catch err
    choiceXaxis = [-0.5 0.5];
    choiceYaxis = [-0.2 0.3];
    choiceZaxis = [0.1 0.3];
end

xlabel('x'); ylabel('y'); zlabel('z');
axis([choiceXaxis choiceYaxis choiceZaxis])
titlestring= strrep(processed_data.name,'_','\_');
title(sprintf('Cut %s %s', processed_data.name, Strcutrange),'Interpreter','none');
grid('on');

% toolbar ------------------------------------------------------------

custom_toolbar2 = uitoolbar(figureInt);
toolbarbutton1 = uipushtool(custom_toolbar2,'CData',table_icon,...
    'TooltipString','View matrix for this section',...
    'ClickedCallback',@cuttabulate);
toolbarbutton2 = uipushtool(custom_toolbar2,'CData',info_icon,...
    'TooltipString','Get info',...
    'ClickedCallback',@get_info_datatip);
toolbarbutton3 = uipushtool(custom_toolbar2,'CData',export_icon_txt,...
    'TooltipString','Write info summary',...
    'ClickedCallback',@write_info_selected);
toolbarbutton4 = uipushtool(custom_toolbar2,'CData',export_icon_pdf,...
    'TooltipString','Create .pdf figure',...
    'ClickedCallback',@export_figcalled);
toolbarbutton5 = uipushtool(custom_toolbar2,'CData',export_icon_csv,...
    'TooltipString','Output flight info as .csv',...
    'ClickedCallback',@write_cutflight_info_button_Callback);


function choicetabulate(hObject, eventdata, handles)
global selected_processed_data
tabulate(selected_processed_data)


function cuttabulate(hObject, eventdata, handles)
global cut_processed_data
tabulate(cut_processed_data)

% shows a uitable with given data
function tabulate(tab_data)

if isfield (tab_data, 'x')
    if length(tab_data.x) == 0
        errordlg('Data structure present, but without X data. Aborting.','Data formatting problems')
        return
    end
    
    figureInt2 = figure('Name', 'Data table for selected points','NumberTitle','off');
    datatable = uitable;
    tableheader= {'X','Y','Z', 'Time'};
    set(datatable,'Data', [tab_data.x tab_data.y tab_data.z tab_data.t],'ColumnName',tableheader,'RowStriping','on','ColumnWidth',{60})
    
else
    helpdlg('No variables loaded just yet','Load data first')
    return
end


% --- Executes on button press in autoscale.
function autoscale_Callback(hObject, eventdata, handles)
% hObject    handle to autoscale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global processed_data
if ~isequal(processed_data,[])
    try load('view.mat')
    catch err
        choiceviewangle = [-37.5 30];
        choicemagnitude = 5;
    end
    try load('axis.mat')
    catch err
        choiceXaxis = [-0.5 0.5];
        choiceYaxis = [-0.2 0.3];
        choiceZaxis = [0.1 0.3];
    end
else
    helpdlg('No variables loaded just yet','Load data first')
    return
end
scaled_axis = [min(processed_data.x),max(processed_data.x),...
    min(processed_data.y),max(processed_data.y),...
    min(processed_data.z),max(processed_data.z)];

x_buffer = (scaled_axis(2)-scaled_axis(1))*0.05; % here we assign an extra 5% buffer to the edge
y_buffer = (scaled_axis(4)-scaled_axis(3))*0.05;
z_buffer = (scaled_axis(6)-scaled_axis(5))*0.05;
if x_buffer == 0
    x_buffer = 1;
end
if y_buffer == 0
    y_buffer = 1;
end
if z_buffer == 0
    z_buffer = 1;
end
choiceXaxis = [scaled_axis(1) - x_buffer scaled_axis(2) + x_buffer];
choiceYaxis = [scaled_axis(3) - y_buffer scaled_axis(4) + y_buffer];
choiceZaxis = [scaled_axis(5) - z_buffer scaled_axis(6) + z_buffer];
save axis.mat choiceXaxis choiceYaxis choiceZaxis
axis([choiceXaxis choiceYaxis choiceZaxis]);
refresh

function export_figcalled(hObject, eventdata, handles)
global processed_data
set(gcf, 'Color', 'white'); % Sets figure background
set(gca, 'Color', 'white'); % Sets axes background

[file path] = uiputfile('*.pdf','Save As',sprintf('%s.pdf', processed_data.name));
if isequal(file,0)
    helpdlg('Figure .pdf export cancelled');
else
    set(gcf, 'Color', 'w');
    export_fig([path file],'-m2'); % Here we utilise export_fig.m from Oliver Woodhead
end
function outputpolar(hObject, eventdata, handles)
global processed_data
global pol
toWrite = [pol.ctheta, pol.cr, pol.ch processed_data.t];

header = {'theta', 'radius', 'height', 'time'};

[file,path] = uiputfile('*.csv','Save cylindrical polar data',sprintf('CylPol_%s.csv', processed_data.name));

if isequal(file,0)
    helpdlg('Save as .csv cancelled','Save as .csv');
    
else
    csvwrite_with_headers([path file], toWrite,header,0,0);
    
end

%% menubar callbacks
% --------------------------------------------------------------------
function main_menu_Callback(hObject, eventdata, handles)
% --------------------------------------------------------------------
function file_menu_info_Callback(hObject, eventdata, handles)
get_info_button_Callback

% --------------------------------------------------------------------
function about_menu_Callback(hObject, eventdata, handles)

msgbox({'Superplot3d','v.1.0.1 (build 20170220)',...
    'A freeware graphic visualiser for trajectory output containing X,Y,Z and Time.','',...
    'Luke Whitehorn, Frances M. Hawkes and Ian A.N. Dublon.','2013',...,'',...,'',...
    'Some code adapted from Stephen Young and ported by the authors.',...
    'Reference: Hardie, J. and Young, S. (1997) Aphid flight track analysis in three dimensions using video techniques. Physiol. Ent. 22, 116 - 122.','',...
    'Program developed with Mathworks Matlab 7.11.0 (R2010a)',...
    'This program uses some 3rd party freeware components; please see the License menu item for more information.','',...
    'ian.dublon@slu.se',...
    'Source code: http://www.superplot3d.slu.se'},'About');
% --------------------------------------------------------------------
function Prefs_master_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function prefs_reference_vector_Callback(hObject, eventdata, handles)
dlg_title = 'Reference vectors';
num_lines = 1;
prompt{1} = 'X coordinates (m): ';
prompt{2} = 'Y coordinates (m): ';
prompt{3} = 'Z coordinates (m): ';
prompt{4} = 'Rotation sign (blank, + or -):';
try
    load ('vectors.mat', 'answer');
end
if exist ('answer');
    vector_defaults = answer;
else
    vector_defaults = {'0.00', '0.00', '1.00','+'};
end
options.Resize='off';
answer = inputdlg(prompt,dlg_title,num_lines,vector_defaults,options);

vec = [str2double(answer{1}),str2double(answer{2}),str2double(answer{3})];
if isequal(vec,[0 0 0])
    msgbox('Reference vector is invalid at 0,0,0. Defaulting to 0,0,1')
    vec = str2double(vector_defaults)
    answer = {'0.00', '0.00', '1.00','+'};
end
rotationsign = answer{4};
global thrips_icon
restartmessage = msgbox('Please restart superplot3d before continuing data processing','Restart required','custom',thrips_icon);
save vectors

% --------------------------------------------------------------------
function prefs_datarange_Callback(hObject, eventdata, handles)
try
    load ('datarange.mat','answer');
end
global thrips_icon
dlg_title = 'Data location';
num_lines = 1;

prompt{1} = 'Please select number of header lines to ignore: ';
prompt{2} = 'Please select column for X: ';
prompt{3} = 'Please select column for Y: ';
prompt{4} = 'Please select column for Z: ';
prompt{5} = 'Please select column for T: ';

if exist ('answer')
    datarangedefaults = answer;
else
    
    datarangedefaults = {'1','1','2','3','4'};
end
restartmessage = msgbox('Please restart superplot3d before continuing data processing','Restart required','custom',thrips_icon);
answer = inputdlg(prompt,dlg_title,num_lines,datarangedefaults);

datarangedefaults= char(strcat(sprintf('A%i..D%i',1+ str2num(answer{1}),1+str2num(answer{1})),{'(count)'}));

save datarange

function prefs_axis_menu_Callback(hObject, eventdata, handles)
try
    load ('axis.mat', 'answer')
end
dlg_title = 'Preferences';
num_lines = 1;
prompt{1} = 'Minimum value (m) for X axis: ';
prompt{2} = 'Maximum value (m) for X axis: ';
prompt{3} = 'Minimum value (m) for Y axis: ';
prompt{4} = 'Maximum value (m) for Y axis: ';
prompt{5} = 'Minimum value (m) for Z axis: ';
prompt{6} = 'Maximum value (m) for Z axis: ';
if exist('answer')
    axisdefaults = answer;
else
    axisdefaults = {'-0.1', '0.50','-0.1', '0.50','-0.1', '0.50'};
end

answer = inputdlg(prompt,dlg_title,num_lines,axisdefaults);
choiceXaxis = [str2double(answer{1}),str2double(answer{2})];
choiceYaxis = [str2double(answer{3}),str2double(answer{4})];
choiceZaxis = [str2double(answer{5}),str2double(answer{6})];
save axis

% --------------------------------------------------------------------
function prefs_angle_menu_Callback(hObject, eventdata, handles)
try
    load ('view1.mat','answer');
    viewangledefaults = answer;
catch err
    viewangledefaults = {'-37.5','30','5'};
end
dlg_title = 'Default view angles';
num_lines = 1;
prompt{1} = 'Default heading (degrees): ';
prompt{2} = 'Default pitch (degrees): ';
prompt{3} = 'Initial trajectory visualiser magnitude:';

answer = inputdlg(prompt,dlg_title,num_lines,viewangledefaults);
choiceviewangle = [str2double(answer{1}),str2double(answer{2})];
choicemagnitude = str2double(answer{3});
save view.mat choiceviewangle choicemagnitude

% --------------------------------------------------------------------
function prefs_time_Callback(hObject, eventdata, handles)
try
    load ('framerate','answer');
end
global thrips_icon
dlg_title = 'Time preferences';
num_lines = 1;
prompt{1} = 'Interval between time measurements (s): ';
if exist ('answer')
    frameratedefaults = answer;
else
    frameratedefaults = {'0.02'};
end

restartmessage = msgbox('Please restart superplot3d before continuing data processing','Restart required','custom',thrips_icon);
answer = inputdlg(prompt,dlg_title,num_lines,frameratedefaults);
choiceframerate = [str2double(answer{1})];
save framerate.mat
% --------------------------------------------------------------------
function prefs_overlay_menu_Callback(hObject, eventdata, handles)
try
    load ('overlay.mat','answer');
end
dlg_title = 'Overlay octet, X,Y,Z (m):';
num_lines = 1;
prompt{1} = 'Coordinate 1(0 0 0): ';
prompt{2} = 'Coordinate 2(1 0 0): ';
prompt{3} = 'Coordinate 3(1 1 0): ';
prompt{4} = 'Coordinate 4(0 1 0): ';
prompt{5} = 'Coordinate 5(0 0 1): ';
prompt{6} = 'Coordinate 6(1 0 1): ';
prompt{7} = 'Coordinate 7(1 1 1): ';
prompt{8} = 'Coordinate 8(0 1 1): ';

if exist ('answer');
    overlaydefaultsCell = answer;
else
    overlaydefaultsCell =     {'0.00 0.00 0.00'
        '0.20 0.00 0.00'
        '0.20 0.20 0.00'
        '0.00 0.20 0.00'
        '0.00 0.00 0.20'
        '0.20 0.00 0.20'
        '0.20 0.20 0.20'
        '0.00 0.20 0.20'};
end
overlaydefaults = cellstr(overlaydefaultsCell);

options.Resize='on';
answer = inputdlg(prompt,dlg_title,num_lines,overlaydefaults,options);
choiceoverlay1 = str2num(answer{1});
choiceoverlay2 = str2num(answer{2});
choiceoverlay3 = str2num(answer{3});
choiceoverlay4 = str2num(answer{4});
choiceoverlay5 = str2num(answer{5});
choiceoverlay6 = str2num(answer{6});
choiceoverlay7 = str2num(answer{7});
choiceoverlay8 = str2num(answer{8});
save overlay

% --------------------------------------------------------------------
function prefs_origin_menu_Callback(hObject, eventdata, handles)
try
    load ('points','answer');
end
global thrips_icon
dlg_title = 'Enter origin central point:';
num_lines = 1;
prompt{1} = 'X coordinates (m): ';
prompt{2} = 'Y coordinates (m): ';
prompt{3} = 'Z coordinates (m): ';
if exist ('answer');
    pointdefaults = answer;
else
    pointdefaults = {'0.098', '0.197', '-0.034'};
end

restartmessage = msgbox('Please restart superplot3d before continuing data processing','Restart required','custom',thrips_icon);
options.Resize='off';
answer = inputdlg(prompt,dlg_title,num_lines,pointdefaults,options);

origin_ctr= [str2double(answer{1}),str2double(answer{2}),str2double(answer{3})];
save points

% --------------------------------------------------------------------
function license_menu_Callback(hObject, eventdata, handles)
licensedialog = msgbox({'This product is released "as is", with absolutely no warranty.','',...
    'Licensed under the terms of the Creative Commons Attribution 3.0 license.',...
    'http://creativecommons.org/licenses/by/3.0/','', 'Source formerly hosted by Sveriges lantbruksuniversitet (SLU).'...
    'http://www.superplot3d.slu.se',...
    '',...
    'We gratefully acknowledge the following authors for their freeware functions, used herein:','',...
    'AutoWarnDlg.m (C) Jan Simon (http://www.mathworks.com/matlabcentral/fileexchange/24871)',...
    '',...
    'export_fig.m (C) Oliver Woodford (http://sites.google.com/site/oliverwoodford/home)',...
    '',...
    'rad2deg.m (C) Keith Brady (http://www.mathworks.com/matlabcentral/fileexchange/28503)',...
    'csvwrite_with_headers.m (http://www.mathworks.com/matlabcentral/fileexchange/29933)',...
    '',...
    'nanmean.m (C) Jan Glaescher (https://se.mathworks.com/matlabcentral/fileexchange/6837-nan-suite/content/nansuite/nanmean.m)',...
    'nanstd.m',...
    'nansum.m'},'Licensing');

% --------------------------------------------------------------------
function refresh_menu_Callback(hObject, eventdata, handles)
clear all
clc
close(gcbf)
superplot3d
% --------------------------------------------------------------------
function help_menu_Callback(hObject, eventdata, handles)
whatplatform = ispc;
if whatplatform>0
    winopen('superplot3dhelp.pdf');
else
    open('superplot3dhelp.pdf');
end
% --------------------------------------------------------------------
function quit_menu_Callback(hObject, eventdata, handles)
close all
clear all
delete(get(0,'Children'));

% --------------------------------------------------------------------
function file_menu_Callback(hObject, eventdata, handles)

% File Panel  -------------------------------------------------------
function file_panel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to file_panel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% filenametext box callback
% --- Executes during object creation, after setting all properties.
function filenametext_CreateFcn(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function rootaxes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rootaxes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
set(gca, 'visible', 'off');
% Hint: place code in OpeningFcn to populate rootaxes
