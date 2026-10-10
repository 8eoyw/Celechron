; Celechron 桌面版安装包（Inno Setup 6）
; 先编译：flutter build windows --release -t lib/main_desktop.dart
; 再打包：ISCC.exe /DAppVersion=1.3.1-desktop.1 windows\installer\celechron.iss
; 产物：build\installer\Celechron-Setup-x64.exe
; 按用户安装到 %LOCALAPPDATA%\Programs\Celechron，不需要管理员权限。

#ifndef AppVersion
  #define AppVersion "1.3.1-desktop"
#endif
#define SourceDir "..\..\build\windows\x64\runner\Release"

[Setup]
AppId={{6C1E3B52-8F0A-4D7B-9E21-C3A5F0D4B7E9}
AppName=Celechron
AppVersion={#AppVersion}
AppVerName=Celechron 桌面版 {#AppVersion}
AppPublisher=Celechron 桌面版（非官方）
AppPublisherURL=https://github.com/8eoyw/Celechron
AppSupportURL=https://github.com/8eoyw/Celechron/issues
DefaultDirName={localappdata}\Programs\Celechron
DefaultGroupName=Celechron
DisableProgramGroupPage=yes
DisableDirPage=auto
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir=..\..\build\installer
OutputBaseFilename=Celechron-Setup-x64
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\Celechron.exe
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes

[Languages]
Name: "zh"; MessagesFile: "ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加任务："

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Celechron"; Filename: "{app}\Celechron.exe"
Name: "{group}\卸载 Celechron"; Filename: "{uninstallexe}"
Name: "{userdesktop}\Celechron"; Filename: "{app}\Celechron.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\Celechron.exe"; Description: "立即运行 Celechron"; Flags: nowait postinstall skipifsilent
