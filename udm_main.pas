unit udm_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, mysql56conn, sqlite3conn, sqldb, DB, FileUtil, Forms,
  LCLType;

type

  { Tdm_main }

  Tdm_main = class(TDataModule)
    conn_server: TMySQL56Connection;
    conn_client: TSQLite3Connection;
    dsDoBackup: TDataSource;
    dsAccount: TDataSource;
    sqlAccount: TSQLQuery;
    sqlAccountACCESSKEY: TStringField;
    sqlAccountDOC: TStringField;
    sqlAccountpassword: TStringField;
    sqlDoBackup: TSQLQuery;
    sqlDoBackupid: TLongintField;
    sqlDoBackupkindoftime: TStringField;
    sqlDoBackuplastbackup: TDateTimeField;
    sqlDoBackuptimes: TLongintField;
    SQLT_Client: TSQLTransaction;
    SQLT_Server: TSQLTransaction;
    procedure DataModuleCreate(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  dm_main: Tdm_main;

implementation

{$R *.lfm}

{ Tdm_main }

procedure Tdm_main.DataModuleCreate(Sender: TObject);
begin
  with conn_client do
  begin
    DatabaseName := ExtractFilePath(ApplicationName) + 'TRB_DB.sqlite';
    HostName := 'localhost';
  end;

  try
    conn_client.Connected := True;
  except
    on E: Exception do
      Application.MessageBox(PChar('Falha ao Conectar a Base Local!!' + #13 + e.Message),
        'Aviso!', MB_OK);
  end;

end;

end.
