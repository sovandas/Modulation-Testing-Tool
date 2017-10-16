function varargout = parameterEdit(varargin)
% PARAMETEREDIT MATLAB code for parameterEdit.fig
%      PARAMETEREDIT, by itself, creates a new PARAMETEREDIT or raises the existing
%      singleton*.
%
%      H = PARAMETEREDIT returns the handle to a new PARAMETEREDIT or the handle to
%      the existing singleton*.
%
%      PARAMETEREDIT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PARAMETEREDIT.M with the given input arguments.
%
%      PARAMETEREDIT('Property','Value',...) creates a new PARAMETEREDIT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before parameterEdit_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to parameterEdit_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help parameterEdit

% Last Modified by GUIDE v2.5 11-Nov-2013 23:20:17

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @parameterEdit_OpeningFcn, ...
                   'gui_OutputFcn',  @parameterEdit_OutputFcn, ...
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


% --- Executes just before parameterEdit is made visible.
function parameterEdit_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to parameterEdit (see VARARGIN)

% Choose default command line output for parameterEdit
handles.output = hObject;

% Display Input
variableNames = whos('-file',varargin{2}); % get variable names
variableValues = load(varargin{2}); % load varaibles
tableData = {}; % initialize table 
for i = 1:length(variableNames), % iterate over variables
    tableData{i,1} = variableNames(i).name; % get variable name
    if strcmp(variableNames(i).class, 'double'),
        if length(size(variableValues.(variableNames(i).name))) > 1, % handle arrays
            tableData{i,2} = num2str(variableValues.(variableNames(i).name)); % get variable value
        else
            tableData{i,2} = variableValues.(variableNames(i).name);
        end
    elseif strcmp(variableNames(i).class, 'char'),
        tableData{i,2} = variableValues.(variableNames(i).name);
    end
end
set(handles.uitable1,'Data',tableData); % set table to display parameters

% Update handles structure
handles.parameterFile = varargin{2}; % save file location
handles.variableNames = variableNames; % save variable data
guidata(hObject, handles);

% UIWAIT makes parameterEdit wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = parameterEdit_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in save.
function save_Callback(hObject, eventdata, handles)
% hObject    handle to save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = guidata(handles.figure1); % 

parameterData = load(data.parameterFile);
tableData = get(handles.uitable1,'Data');

for i = 1:size(tableData,1),
    if strcmp(data.variableNames(i).class,'double'),
        parameterData.(tableData{i,1}) = str2num(tableData{i,2});
    elseif strcmp(data.variableNames(i).class,'char'),
        parameterData.(tableData{i,1}) = tableData{i,2};
    end
end

save(data.parameterFile, '-struct', 'parameterData');
