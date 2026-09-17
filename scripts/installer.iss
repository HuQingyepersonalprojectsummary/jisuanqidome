; Inno Setup 6 Script for PCalc Advanced Calculator
; Preprocessor definitions expected:
;   #define MyAppName "PCalc Advanced Calculator"
;   #define MyAppVersion "1.0.0"
;   #define MyAppPublisher "PCalc Engineering Team"
;   #define MyAppURL "https://github.com/HuQingyepersonalprojectsummary/jisuanqidome"
;   #define MyAppExeName "PCalc.exe"
;   #define MySourceDir "..\artifacts\staging"
;   #define MyOutputDir "..\artifacts"
;   #define MyOutputBaseFilename "PCalc-1.0.0-win-x64-Setup"
;   #define MyAppIcon "..\project1.ico"

#ifndef MyAppName
  #define MyAppName "PCalc Advanced Calculator"
#endif

#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif

#ifndef MyAppPublisher
  #define MyAppPublisher "PCalc Engineering Team"
#endif

#ifndef MyAppURL
  #define MyAppURL "https://github.com/HuQingyepersonalprojectsummary/jisuanqidome"
#endif

#ifndef MyAppExeName
  #define MyAppExeName "PCalc.exe"
#endif

#ifndef MySourceDir
  #define MySourceDir "..\artifacts\staging"
#endif

#ifndef MyOutputDir
  #define MyOutputDir "..\artifacts"
#endif

#ifndef MyOutputBaseFilename
  #define MyOutputBaseFilename "PCalc-Calculator-Setup"
#endif

#ifndef MyAppIcon
  #define MyAppIcon "..\project1.ico"
#endif

[Setup]
AppId={{E8B24C57-8971-460B-A53A-6D872FB64BC3}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} v{#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\PCalc Calculator
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
OutputDir={#MyOutputDir}
OutputBaseFilename={#MyOutputBaseFilename}
SetupIconFile={#MyAppIcon}
SolidCompression=yes
Compression=lzma2/ultra64
LZMAUseSeparateProcess=yes
ArchitecturesInstallIn64BitMode=x64compatible
ArchitecturesAllowed=x64compatible
DisableProgramGroupPage=auto
WizardStyle=modern
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName} v{#MyAppVersion}
VersionInfoVersion={#MyAppVersion}
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppName} Windows Installer
VersionInfoProductName={#MyAppName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#MySourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\project1.ico"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\project1.ico"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
