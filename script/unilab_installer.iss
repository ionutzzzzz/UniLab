; UniLab Standalone Windows Installer Script
; Requires Inno Setup 6+

[Setup]
AppId={{C1A2B3D4-E5F6-4A7B-8C9D-0E1F2A3B4C5D}
AppName=UniLab
AppVersion=1.0.0
AppPublisher=UniLab Team
AppPublisherURL=https://github.com/UniLab-Platform/UniLab
AppSupportURL=https://github.com/UniLab-Platform/UniLab/issues
AppUpdatesURL=https://github.com/UniLab-Platform/UniLab
DefaultDirName={autopf}\UniLab
DisableProgramGroupPage=yes
; Uncomment the following line to run in non administrative install mode (install for current user only.)
;PrivilegesRequired=lowest
OutputDir=..\dist
OutputBaseFilename=UniLab_Windows_Setup
SetupIconFile=..\frontend\windows\runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; The source directory is relative to the location of this .iss script
Source: "..\release-windows\Unilab\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\UniLab"; Filename: "{app}\UniLab.exe"
Name: "{autodesktop}\UniLab"; Filename: "{app}\UniLab.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\UniLab.exe"; Description: "{cm:LaunchProgram,UniLab}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}\backend"
Type: filesandordirs; Name: "{app}\Lib"
Type: filesandordirs; Name: "{app}\Scripts"
Type: filesandordirs; Name: "{app}\sample"
