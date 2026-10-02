#ifndef MyAppVersion
  #define MyAppVersion "0.0.0"
#endif
#define MyAppName "MusicStream"
#define MyAppPublisher "sauvank"
#define MyAppExeName "MusicStream.exe"

[Setup]
AppId={{5B7C1E92-3A4D-4F68-9E21-6D0A8C4B7F13}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
OutputBaseFilename=MusicStream-v{#MyAppVersion}-Setup-x64
OutputDir=..\..\release_windows
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
