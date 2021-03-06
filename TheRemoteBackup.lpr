program TheRemoteBackup;

{$mode objfpc}{$H+}

uses {$IFDEF UNIX} {$IFDEF UseCThreads}
  cthreads, {$ENDIF} {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  unt_main,
  runtimetypeinfocontrols,
  unt_config,
  udm_main,
  unt_utils,
  rxnew,
  unt_inputPassword,
  unt_ftpConfig;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(Tfrm_main, frm_main);
  Application.CreateForm(Tfrm_config, frm_config);
  Application.CreateForm(Tdm_main, dm_main);
  Application.CreateForm(Tfrm_inputPassword, frm_inputPassword);
  Application.CreateForm(Tfrm_ftpConfig, frm_ftpConfig);
  Application.Run;
end.
