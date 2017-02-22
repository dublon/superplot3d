function [Reply, TimeOut] = AutoWarnDlg(Msg, Name, Opt)
% Self-terminating modal warning dialog
% [Reply, TimeOut] = AutoWarnDlg(Msg, Name, [Opt])
% A warning dialog is displayed with a flashing exclamation mark. The dialog is
% terminated automatically with the default reply, if the user does not press a
% button in a specified period of time.
%
% This can be useful e.g. in functions, which are checked with automated tests,
% because the dialog does not block the execution completely.
%
% INPUT:
%   Msg:     Either a string or a cell string. For cell strings, empty lines
%            are inserted between the strings.
%   Name:    Window title as string.
%   Opt:     Struct to specify some options - all are optional:
%      .Delay: Number of seconds until the dialog closes automatically.
%            Use Inf for infinite waiting. Default: 60.
%      .Interpreter: Text interpreter 'none' or 'tex' (default).
%            In tex-mode use "\\" for a slash, "\_" for an underscore,
%            "\bf<your message>\rm" for bold face, etc.
%      .Wrap: Control wrapping of the Msg text. The width can be determined
%            automatically or manually depending on the different input types:
%            - Logical flag or double 1 or 0: The text is wrapped to get a width
%              of approximately 3/2 of the height.
%            - Double: Width of the textbox in pixels, minimum is 200.
%            - String: The width of this string is used for wrapping.
%            See NOTE below for wrapping TeX formatted strings.
%            Default: TRUE.
%      .Button: Cell string with 0 to 3 strings, which appear as buttons.
%            The 1st string is the rightmost button, which is the default
%            choice, if no button or the [ESC] key is pressed.
%            Default: {'Ok'}.
%
% OUTPUT:
%   Reply:   String of the pressed button, or the default button, if the
%            [Escape] key was pressed, the dialog was closed externally or the
%            timeout was reached.
%   TimeOut: Logical flag, TRUE if the dialog was terminated by a timeout.
%
% The button focus can be moved with [Left] and [Right] keys. [Return] and
% [Space] activate the currently focussed button, [ESC] the initial default
% button. The key [c] copies the current message to the clipboard (not
% [Ctrl-C]!).
%
% NOTE: The keyboard functions are not working, if the dialog was called from a
% callback of an UICONTROL with the property "Interruptible" set to 'off'.
% The button works even in this case, because they are toggle buttons.
%
% NOTE: Unfortunately the wrapping is performed by TEXTWRAP, which works for
% UICONTROLs only. In consequence the effects of the TeX interpreter cannot be
% considered currently. Perhaps I publish a TEXTWRAP, which works on TEXT
% objects also.
%
% EXAMPLES:
% A warning, which disappears after 15 seconds:
%   AutoWarnDlg('This is a \bfwarning\rm!', 'Ups', struct('Delay', 15));
% Warn and allow the user to cancel or accept:
%   Opt.Delay  = 15;
%   Opt.Button = {'Cancel', 'Reject', 'Accept'};  % First is default
%   [Reply, TimeOut] = AutoWarnDlg( ...
%        {'This is a \bfwarning\rm!', 'Accept, reject or cancel?'}, ...
%        'Question', Opt);
%   fprintf('Reply:   %s\nTimeout: %d\n', Reply, TimeOut);
%
% NOTE: In a STRUCT command double braces are needed to create a cell string!
%
% Tested: Matlab 6.5, 7.7, 7.8
% Author: Jan Simon, Heidelberg, (C) 2009 jATnMINUSsimonDOTde
% License: BSD: Feel free to copy and modify mentioning the original author.
%
% See also WARNDLG, MSGBOX.

% $JRev: R0d V:004 Sum:0533E3C9 Date:11-Aug-2009 18:29:58 $
% $File: User\JSim\Published\AutoWarnDlg\AutoWarnDlg.m $
% History:
% 001: 29-Jul-2009 09:54, No external subfunction from the GL-toolbox.
%      Adjusted XWarnDlg V:069 to be published on Mathwork's FEX.
% 002: 31-Jul-2008 02:51, SQRT inserted to calculate nice size.
% 003: 03-Aug-2009 23:17, [Opt.Sec] -> [Opt.Delay].
%      Typo in the help section found by Jiro Doke - thanks!
% 004: 11-Aug-2009 01:34, 2nd output [TimeOut], expanded input [Opt.Wrap].
%      If the update of the dialog fails, but the dialog is still open, the
%      program stops with an error message now.

% Initialize: ==================================================================
% Global Interface: ------------------------------------------------------------
% Initial values: --------------------------------------------------------------
% Program Interface: -----------------------------------------------------------
nArg = nargin;
if nArg == 0
   Msg      = {'This is an \bfunknown warning\rm!', 'Keep care!'};
   Name     = 'Important';
   Opt.Wrap = false;
elseif nArg == 1
   Name = 'Warning';
   Opt  = [];
elseif nArg == 2
   Opt  = [];
end

% Parse Opt struct:
[Delay, Interpreter, Wrap, Button] = GetOpt(Opt, ...
   {'Delay', 'Interpreter', 'Wrap', 'Button'}, ...
   {60,      'tex',         true,   {}      });

if isempty(Button)
   Button = {'OK'};
elseif ischar(Button)
   Button = {Button};
elseif iscellstr(Button) == 0
   error(['*** ', mfilename, ': [Opt.Button] must be a string or cell string.']);
end
if numel(Button) > 3
   error(['*** ', mfilename, ': [Opt.Button] has more than 3 strings.']);
end

if isa(Msg, 'cell') == 0
   Msg = {Msg};
end

if isempty(Wrap)
   Wrap = true;  % Automatic wrapping
elseif islogical(Wrap)
   Wrap = any(Wrap);
elseif isnumeric(Wrap)
   if Wrap <= 1
      Wrap = (Wrap ~= 0);
   end
elseif not(ischar(Wrap))
   error(['*** ', mfilename, ...
         ': [Opt.Wrap] must be a logical, string or number.']);
end

% User Interface: --------------------------------------------------------------
% Do the work: =================================================================
% Adjust to your demands:
TextFontName   = get(0, 'DefaultTextFontName');
TextFontSize   = 10;
ButtonFontName = TextFontName;
ButtonFontSize = 10;

% Window size:
bakUnits    = get(0, 'Units');
set(0, 'Units', 'pixels');
ScreenVec   = get(0, 'ScreenSize');
set(0, 'Units', bakUnits);
ScreenSize  = ScreenVec(3:4);

WinWidth    = 200;   % Minimal extent, expanded on demand
WinHeight   = 100;
WinWidthMax = 800;
DlgExtent   = [WinWidth, WinHeight];
DlgOrigin   = (ScreenSize - DlgExtent) / 2;

DlgH = figure( ...
   'Name',          Name, ...
   'IntegerHandle', 'off', ...
   'WindowStyle',   'normal', ...
   'MenuBar',       'none', ...
   'NumberTitle',   'off', ...
   'Resize',        'off', ...
   'Units',         'pixels', ...
   'Position',      [DlgOrigin, DlgExtent], ...
   'NextPlot',      'add', ...
   'Visible',       'off', ...
   'Renderer',      'painters', ...
   'DoubleBuffer',  'on', ...
   'BackingStore',  'off', ...
   'DefaultUIControlFontSize', ButtonFontSize, ...
   'DefaultUIControlFontName', ButtonFontName, ...
   'DefaultTextFontName',      TextFontName, ...
   'DefaultTextFontSize',      TextFontSize, ...
   'DefaultTextInterpreter',   Interpreter, ...
   'HandleVisibility',         'on');

% Axis over entire dialog box for text and graphics:
FullAxis = axes( ...
   'Parent',   DlgH, ...
   'Units',    'pixels', ...
   'Position', [1, 1, DlgExtent], ...
   'Visible',  'off', ...
   'XLimMode', 'manual', 'XLim', [1, WinWidth], ...
   'YLimMode', 'manual', 'YLim', [1, WinHeight], ...
   'NextPlot', 'add'), ...
%    'DrawMode', 'normal'); IAND

% Get Warn icon as RGB array:
DlgBG   = get(DlgH, 'Color');
IconRGB = WarnIcon_L(DlgBG);
IconY   = size(IconRGB, 1);
IconX   = size(IconRGB, 2);

% Create buttons: --------------------------------------------------------------
nButton   = length(Button);
ButtonH   = zeros(nButton, 1);
FrameH    = ButtonH;            % Faster than: zeros(nButton, 1);
ButtonExt = zeros(nButton, 4);
FrameAdd  = [-1, -1, 1, 1];
for iButton = 1:length(Button)
   pos              = [WinWidth - 70 * iButton, 8, 60, 24];
   ButtonH(iButton) = uicontrol(DlgH, ...
      'Style',    'ToggleButton', ...
      'String',   Button{iButton}, ...
      'Position', pos);
   FrameH(iButton) = rectangle( ...
      'Position',  pos + FrameAdd, ...
      'EdgeColor', 'none', ...
      'FaceColor', 'none');
   ButtonExt(iButton, :) = get(ButtonH(iButton), 'Extent');
end  % for iButton
UD.FrameH  = FrameH;
UD.ButtonH = ButtonH;

% Match window width to buttons:
maxButtonWidth = max(ButtonExt(:, 3));
if maxButtonWidth > 52
   if (maxButtonWidth + 10) * nButton + 40 < 440
      ButtonWidth(1:nButton) = maxButtonWidth + 10;
   else
      ButtonWidth = max(24, ButtonExt(:, 3)) + 10;
   end
   AllButtonWidth = sum(ButtonWidth) + 10 * nButton + 60;
else  % Small enough for default size:
   ButtonWidth(1:nButton) = 60;
   AllButtonWidth         = 70 * nButton + 60;
end

% Current default button:
UD.ButtonFocus = 1;
if nButton > 1
   set(FrameH(1), 'EdgeColor', zeros(1, 3));
end

% Create message box: ----------------------------------------------------------
% (Unfortunately the UICONTROL cannot handle TeX interpreter!)
minTextWidth = WinWidth - 10 - IconX;
TextWidth    = max(AllButtonWidth, minTextWidth);  % Adjusted on demand
blindH       = uicontrol(DlgH, 'Style', 'text', ...
   'String',   '', ...
   'Position', [0, 0, TextWidth, 500], ...
   'FontSize', TextFontSize, ...     % Skip default ButtonFontSize
   'FontName', TextFontName, ...     % Skip default ButtonFontName
   'Visible',  'off');

if ischar(Wrap)  % Dummy string to get width:
   set(blindH, 'String', Wrap);
   TextExt = ceil(get(blindH, 'Extent'));
   set(blindH, 'Position', [0, 0, max(minTextWidth, TextExt(3) + 20), 500]);
   WrapMsg = textwrap(blindH, Msg);
   
elseif isa(Wrap, 'double')  % Width in pixels:
   set(blindH, 'Position', [0, 0, max(minTextWidth, Wrap), 500]);
   WrapMsg = textwrap(blindH, Msg);
   
elseif Wrap  % Automatic wrapping:
   % Find a nice size for the text with approximate 2/3 size:
   WrapMsg = textwrap(blindH, Msg);
   set(blindH, 'String', WrapMsg);
   TextExt = ceil(get(blindH, 'Extent'));
   
   % Try a width/height approximately 3/2:
   if TextExt(4) / 2 > TextExt(3) / 3
      TextExt(3) = 3 * sqrt(TextExt(3) * TextExt(4) * 1.5) / 2;
   end
   TextWidth = min(WinWidthMax - 40 - IconX, max(TextWidth, TextExt(3) + 20));
   set(blindH, 'Position', [0, 0, TextWidth, 500]);  % Interpreter = none
   WrapMsg = textwrap(blindH, Msg);
   
else   % No wrapping:
   WrapMsg = Msg;
end
delete(blindH);

% Final text object (Interpreter defined in inputs):
TextH = text(20 + IconX, WinHeight - 10, WrapMsg, ...
   'Parent',            FullAxis, ...
   'VerticalAlignment', 'top');
UD.TextH = TextH;
TextExt  = ceil(get(TextH, 'Extent'));

% Match size for button and text:
ContWidth = max(IconX + 40 + TextExt(3), AllButtonWidth);
WinWidth  = max(WinWidth, min(ContWidth, WinWidthMax));
WinHeight = min(40 + max(TextExt(4), IconY) + 14, ScreenSize(2) - 86);
DlgExtent = [WinWidth, WinHeight];
DlgOrigin = ceil((ScreenSize - DlgExtent) / 2);
set(DlgH, 'Position', [DlgOrigin, DlgExtent]);

% Move text and buttons:
set(FullAxis, ...
   'Position', [1, 1, DlgExtent], ...
   'XLim', [1, WinWidth], 'YLim', [1, WinHeight]);
set(TextH, 'Position', [20 + IconX, WinHeight - 10], 'Visible', 'on');

pos = [WinWidth, 8, 60, 24];
for iButton = 1:length(Button)
   pos(1) = pos(1) - ButtonWidth(iButton) - 10;
   pos(3) = ButtonWidth(iButton);
   set(ButtonH(iButton), 'Position', pos);
   set(FrameH(iButton),  'Position', pos + FrameAdd);
end  % for iButton

% Draw the Icon:
tmpAxisH = axes( ...
   'Parent',   DlgH, ...
   'Units',    'pixels', ...
   'NextPlot', 'add', ...
   'Position', [10, WinHeight - 10 - IconY, IconX, IconY], ...
   'HitTest',  'off', ...
   'Visible',  'off', ...
   'YDir',     'reverse', ...
   'XLimMode', 'manual',    'YLimMode', 'manual', ...
   'XLim',     [0.5, 46.5], 'YLim', [0.5, 48.5]);
% IconH = image(IconRGB, 'Parent', tmpAxisH, 'EraseMode', 'none'); IAND
IconH = image(IconRGB, 'Parent', tmpAxisH);

% Wait for deleting of the window:
set(DlgH, 'Visible', 'on', 'HandleVisibility', 'callback', ...
   'KeyPressFcn', @localKeyPress, ...
   'UserData',    UD);

% Write remaining seconds:
TimeFmt = '%02d';
TimeH   = text(4, 1, sprintf(TimeFmt, Delay), ...
   'Parent',   FullAxis, ...
   'FontSize', 7, ...
   'FontName', 'fixedwidth', ...
   'VerticalAlignment',   'bottom', ...
   'HorizontalAlignment', 'left', ...
   'Interpreter',         'none');

% Ugly problems of Matlab's Callback methods:
% The callback of the button is not processed when this routine was called from
% a callback with Interruptible==off... Therefore the value of the toggle button
% is tested too.
IconNo          = zeros(size(IconRGB));
IconNo(:, :, 1) = DlgBG(1);
IconNo(:, :, 2) = DlgBG(2);
IconNo(:, :, 3) = DlgBG(3);
%IconDiff        = IconRGB - IconNo;

% The wait loop: ---------------------------------------------------------------
Ti      = datenum(clock) * 86400;
TEnd    = Ti + Delay;
q       = sin(0:0.12:pi) .^ 2;
nq      = length(q);
iq      = 1;
pressed = 0;
cValue  = {'Value'};  % GET(H, {Prop}) replies a cell even for scalar H!
while and(Ti < TEnd, any(pressed) == 0)
   % Note: PAUSE does not advance CPUTIME on Matlab 7.
   % Therefore the slower DATENUM(CLOCK) is used here.
   pause(max(0.01, 0.035 - datenum(clock) * 86400 + Ti));
   Ti = datenum(clock) * 86400;
   try
      set(TimeH, 'String', sprintf(TimeFmt, round(TEnd - Ti)));
   catch  % Handle TimeH is invalid, if the dialog was closed externally:
      if ishandle(DlgH)
         error(['*** ', mfilename, ': Unexpected problem: ', ...
               char(10), lasterr]);
      end
      break;
   end
   
   % Check for a pressed key:
   try
      pressedC = get(ButtonH, cValue);
      pressed  = cat(2, pressedC{:});
      %set(IconH, 'CData', IconRGB - IconDiff * q(iq));
      set(IconH, 'CData', IconRGB);
   
   catch  % Handle IconH is invalid, if the dialog was closed externally:
      if ishandle(DlgH)
         error(['*** ', mfilename, ': Unexpected problem: ', ...
               char(10), lasterr]);
      end
      break;
   end
   iq = rem(iq, nq) + 1;
end

% Delete the window if not done before: ----------------------------------------
if ishandle(DlgH)
   delete(DlgH);
end
drawnow;

% Copy information about hit button to output, if requested:
if nargout
   TimeOut  = (Ti > TEnd);
   fPressed = find(pressed);        % [pressed] is not LOGICAL!
   if TimeOut || isempty(fPressed)  % After closing the window manually
      Reply = Button{1};            % The default button
   else
      Reply = Button{fPressed};
   end
end

return;


% ******************************************************************************
function RGBIcon = WarnIcon_L(BG)
% Storing the icon as CHAR array takes less memory.
ind = [ ...
      'aaaaaaaaaaaaaaaaaaaakjbkaaaaaaaaaaaaaaaaaaaaaa'; ...
      'aaaaaaaaaaaaaaaaaajlcccccfaaaaaaaaaaaaaaaaaaaa'; ...
      'aaaaaaaaaaaaaaaaafccclccccljaaaaaaaaaaaaaaaaaa'; ...
      'aaaaaaaaaaaaaaaafcclbmddlcclkaaaaaaaaaaaaaaaaa'; ...
      'aaaaaaaaaaaaaaajlcfoooeggdcclaaaaaaaaaaaaaaaaa'; ...
      'aaaaaaaaaaaaaaafpfoooiheggdccjaaaaaaaaaaaaaaaa'; ...
      'aaaaaaaaaaaaaabcpnoihhhhhgglplaaaaaaaaaaaaaaaa'; ...
      'aaaaaaaaaaaaaafpfoihhhhhhhgdpcbaaaaaaaaaaaaaaa'; ...
      'aaaaaaaaaaaaablpnohhhhhhhhhgfplaaaaaaaaaaaaaaa'; ...
      'aaaaaaaaaaaaafpboihhhhhhhhhgdpcbaaaaaaaaaaaaaa'; ...
      'aaaaaaaaaaaabccnohhhhggghhhhgfplaaaaaaaaaaaaaa'; ...
      'aaaaaaaaaaaafpboihhhdfffdhhhgdccbaaaaaaaaaaaaa'; ...
      'aaaaaaaaaaajccnohhhhfpppfhhhhgfplaaaaaaaaaaaaa'; ...
      'aaaaaaaaaaafpboihhhhfcccfhhhhgdccbaaaaaaaaaaaa'; ...
      'aaaaaaaaaajclnohhhhhfcccfhhhhhgfplaaaaaaaaaaaa'; ...
      'aaaaaaaaaafpboihhhhhfcccfhhhhhgdccbaaaaaaaaaaa'; ...
      'aaaaaaaaajclnohhhhhhfcccfhhhhhhgfplaaaaaaaaaaa'; ...
      'aaaaaaaaafpboihhhhhhfcccfhhhhhhgdccbaaaaaaaaaa'; ...
      'aaaaaaaajclnohhhhhhhfcccfhhhhhhhgfplaaaaaaaaaa'; ...
      'aaaaaaaafpboihhhhhhhfcccfhhhhhhhgdccbaaaaaaaaa'; ...
      'aaaaaaajclnohhhhhhhhfcccdhhhhhhhhgfplaaaaaaaaa'; ...
      'aaaaaaafpboihhhhhhhhdcccdhhhhhhhhedlcbaaaaaaaa'; ...
      'aaaaaajclnohhhhhhhhhdcccdhhhhhhhhhgfplkaaaaaaa'; ...
      'aaaaaafpfoihhhhhhhhhgcccghhhhhhhhhedlcbaaaaaaa'; ...
      'aaaaajclnohhhhhhhhhhgcccghhhhhhhhhhgfclkaaaaaa'; ...
      'aaaaalpfoihhhhhhhhhhhccchhhhhhhhhhhedlcbaaaaaa'; ...
      'aaaabclnohhhhhhhhhhhhccchhhhhhhhhhhhgfclkaaaaa'; ...
      'aaaalcboihhhhhhhhhhhhlcfhhhhhhhhhhhhedlcbaaaaa'; ...
      'aaabclkohhhhhhhhhhhhhfcfhhhhhhhhhhhhhgfclkaaaa'; ...
      'aaalcboihhhhhhhhhhhhhdcdhhhhhhhhhhhhhedlcbaaaa'; ...
      'aajclkohhhhhhhhhhhhhhdlghhhhhhhhhhhhhhgfclkaaa'; ...
      'aalcboihhhhhhhhhhhhhhhghhhhhhhhhhhhhhhedlcbaaa'; ...
      'abcloohhhhhhhhhhhhhhhggghhhhhhhhhhhhhhhgfclaaa'; ...
      'alcboihhhhhhhhhhhhhhgllldhhhhhhhhhhhhhhgdlcbaa'; ...
      'bcloohhhhhhhhhhhhhhhlpcpcghhhhhhhhhhhhhhgfclaa'; ...
      'lcfoihhhhhhhhhhhhhhgcccccdhhhhhhhhhhhhhhgdlcba'; ...
      'clmoihhhhhhhhhhhhhhhcccccghhhhhhhhhhhhhhgglcla'; ...
      'clmoihhhhhhhhhhhhhhhdpppfhhhhhhhhhhhhhhhgglcla'; ...
      'clmoihhhhhhhhhhhhhhhhgdghhhhhhhhhhhhhhhhgglclj'; ...
      'ccbooihhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhegglclj'; ...
      'ccloooihhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhgggfccfj'; ...
      'bccfoooeggggggggggggggggggggggggggggggggdcccbj'; ...
      'accclmngdddddddddddddddddddddddddddddddfcccfbk'; ...
      'abccccllllllllllllllllllllllllllllllllcccclbba'; ...
      'aablcccccccccccccccccccccccccccccccccccccfbbka'; ...
      'aaabbllllllllllllllllllllllllllllllllllfbbbkaa'; ...
      'aaaajbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbkaaa'; ...
      'aaaaaakjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjkaaaaa'];

map = cat(1, BG, ...
   [  123, 123, 123; ...
      16,    8,   8; ...
      156, 107,  16; ...
      247, 181,  33; ...
      90,   66,   8; ...
      214, 156,  16; ...
      255, 206,   0; ...
      255, 231,  66; ...
      140, 140, 132; ...
      173, 173, 148; ...
      33,   33,  24; ...
      156, 156, 107; ...
      181, 181, 123; ...
      255, 255, 165; ...
      0,     0,   0] / 255);

s       = size(ind);
RGBIcon = reshape(map(double(ind) + (1 - double('a')), 1:3), s(1), s(2), 3);

return;

% ******************************************************************************
function localKeyPress(DlgH, EventData)  %#ok<INUSD>

UD      = get(DlgH, 'UserData');
nButton = length(UD.ButtonH);
switch get(DlgH, 'CurrentCharacter')
   case {13, 32}  % Return, Space: Currently focussed button
      set(UD.ButtonH(UD.ButtonFocus), 'Value', 1);
   case 27  % Escape: Initial default button
      set(UD.ButtonH(1), 'Value', 1);
   case 29  % Left: Move focus
      if nButton > 1  % Nothing to do for a single button!
         UD.ButtonFocus = mod(UD.ButtonFocus - 2, nButton) + 1;
         set(UD.FrameH,                 'EdgeColor', 'none');
         set(UD.FrameH(UD.ButtonFocus), 'EdgeColor', zeros(1, 3));
         set(DlgH, 'UserData', UD);
      end
   case 28  % Right: Move focus
      if nButton > 1
         UD.ButtonFocus = 1 + rem(UD.ButtonFocus, nButton);
         set(UD.FrameH,                 'EdgeColor', 'none');
         set(UD.FrameH(UD.ButtonFocus), 'EdgeColor', zeros(1, 3));
         set(DlgH, 'UserData', UD);
      end
   case {67, 99}  % c, C: Copy warning to clipboard
      Msg = get(UD.TextH, 'String');
      clipboard('copy', sprintf('%s\n', Msg{:}));
end

return;

% ******************************************************************************
function varargout = GetOpt(Opt, Field, Default)

if isa(Opt, 'struct') && ~isempty(Opt)
   OptField = fieldnames(Opt);
   OptData  = struct2cell(Opt);
else
   varargout = Default;
   return;
end

for iField = 1:length(Field)
   Ind = find(strcmpi(OptField, Field{iField}));
   if length(Ind) == 1
      Default{iField} = OptData{Ind};
   end
end
varargout = Default;

return;
