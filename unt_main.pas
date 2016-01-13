unit unt_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, RTTICtrls, Forms, Controls, Graphics, Dialogs,
  Menus, DBGrids, ComCtrls, Buttons, StdCtrls, EditBtn, maskedit, unt_config,
  unt_utils, unt_inputPassword, unt_autoBackup, udm_main, DB, sqldb, LCLType,
  ExtCtrls, LMessages, PopupNotifier, ftpsend, ACBrCalculadora;

type

  { Tfrm_main }

  Tfrm_main = class(TForm)
    btnAddFile: TBitBtn;
    btnExit: TBitBtn;
    btnUpdateRepositorie: TBitBtn;
    btnRemoteRestore: TBitBtn;
    btn_Cancel: TBitBtn;
    dsFiles: TDataSource;
    grd_repositories: TDBGrid;
    gb_Actions: TGroupBox;
    mnuDelete: TMenuItem;
    mnuMain: TMainMenu;
    mnuConfigAutoBackup: TMenuItem;
    mnuAccessConfig: TMenuItem;
    mnuConfig: TMenuItem;
    pb_progress: TProgressBar;
    ppmGrid: TPopupMenu;
    sqlFiles: TSQLQuery;
    sqlFilesfilename: TStringField;
    sqlFilesfilepath: TStringField;
    sqlFilesid: TLongintField;
    sqlFilesinclusiondate: TDateTimeField;
    sqlFileslastbackup: TDateTimeField;
    tmrTray: TTimer;
    triMain: TTrayIcon;
    procedure btnAddFileClick(Sender: TObject);
    procedure btnExitClick(Sender: TObject);
    procedure btnRemoteRestoreClick(Sender: TObject);
    procedure btnUpdateRepositorieClick(Sender: TObject);
    procedure btn_CancelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormWindowStateChange(Sender: TObject);
    procedure grd_repositoriesCellClick(Column: TColumn);
    procedure grd_repositoriesDblClick(Sender: TObject);
    procedure mnuAccessConfigClick(Sender: TObject);
    procedure mnuConfigAutoBackupClick(Sender: TObject);
    procedure mnuConfigClick(Sender: TObject);
    procedure mnuDeleteClick(Sender: TObject);
    procedure tmrTrayTimer(Sender: TObject);
    procedure triMainDblClick(Sender: TObject);
    procedure WMCloseQuery(var message: TLMessage); message LM_CLOSEQUERY;
    function doBackup(aDate: TDateTime): boolean;

  private
    { private declarations }
  public
    { public declarations }
  end;

  { TSendFile }

  TSendFile = class(TThread)
  private
    procedure SyncEvent;
  protected
    procedure Execute; override;
  end;

  { TReceiveFile }

  TReceiveFile = class(TThread)
  private
    procedure SyncEvent;
  protected
    procedure Execute; override;
  end;

var
  frm_main: Tfrm_main;

implementation

{$R *.lfm}

{ TReceiveFile }

procedure TReceiveFile.SyncEvent;
var
  path: string;
begin
  CreateDir(ExtractFilePath(ApplicationName) + 'RESTORES');
  CreateDir(ExtractFilePath(ApplicationName) + 'RESTORES\' +
    StringReplace(DateToStr(now), '/', '-', [rfReplaceAll]));

  path := ExtractFilePath(ApplicationName) + 'RESTORES\' +
    StringReplace(DateToStr(now), '/', '-', [rfReplaceAll]) + '\';

  frm_main.pb_progress.Position := 0;
  FtpGetFile('ftp.server.com.br', '21', '/Web/repo/' +
    frm_main.sqlFilesfilename.AsString, path + frm_main.sqlFilesfilename.AsString,
    'user', 'password');
  frm_main.pb_progress.Position := frm_main.pb_progress.Max;

end;

procedure TReceiveFile.Execute;
begin
  Priority := tpNormal;
  SyncEvent;
  DoTerminate;
end;

{ TSendFile }

procedure TSendFile.SyncEvent;
var
  sql: TSQLQuery;
begin
  sql := TSQLQuery.Create(nil);
  sql.DataBase := dm_main.conn_client;
  sql.Transaction := dm_main.SQLT_Client;
  sql.SQL.Text := 'select * from file';

  sql.Open;
  sql.Last;
  sql.First;
  frm_main.pb_progress.Max := sql.RecordCount;
  frm_main.pb_progress.Position := 0;

  while not (sql.EOF) do
  begin
    FtpPutFile('ftp.server.com.br', '21', '/Web/repo/' +
      sql.FieldByName('filename').AsString,
      sql.FieldByName('filepath').AsString, 'user', 'password');

      sql.Edit;
      sql.FieldByName('lastbackup').AsDateTime := now;
      sql.Post;
      sql.ApplyUpdates;

    sql.Next;

    frm_main.pb_progress.Position := frm_main.pb_progress.Position + 1;
  end;
  dm_main.SQLT_Client.Commit;
  frm_main.sqlFiles.Open;
end;

procedure TSendFile.Execute;
begin
  Priority := tpNormal;
  SyncEvent;
  DoTerminate;
end;

{ Tfrm_main }

procedure Tfrm_main.WMCloseQuery(var message: TLMessage);
begin
  triMain.Visible := True;
  frm_main.Hide;
end;

function Tfrm_main.doBackup(aDate: TDateTime): boolean;
var
  Send: TSendFile;
begin
  Send := TSendFile.Create(True);
  Send.FreeOnTerminate := True;
  Send.Resume;
  pb_progress.Position := 0;
end;

procedure Tfrm_main.FormWindowStateChange(Sender: TObject);
begin
  if frm_main.WindowState = wsMinimized then
  begin
    triMain.Visible := True;
    frm_main.Show;
  end;
end;

procedure Tfrm_main.grd_repositoriesCellClick(Column: TColumn);
begin

end;

procedure Tfrm_main.grd_repositoriesDblClick(Sender: TObject);
begin
  ppmGrid.PopUp;
end;


procedure Tfrm_main.btnUpdateRepositorieClick(Sender: TObject);
begin
  doBackup(now);
end;

procedure Tfrm_main.btnRemoteRestoreClick(Sender: TObject);
var
  Receive: TReceiveFile;
begin
  Receive := TReceiveFile.Create(True);
  Receive.FreeOnTerminate := True;
  Receive.Resume;
  pb_progress.Position := 0;
end;

procedure Tfrm_main.btnExitClick(Sender: TObject);
begin

  if Application.MessageBox('Deseja realmente FECHAR o sistema?',
    'Aviso', MB_YESNO + MB_ICONQUESTION) = mrYes then
  begin
    Application.Terminate;
  end;
end;

procedure Tfrm_main.btnAddFileClick(Sender: TObject);
var
  Dlg: TOpenDialog;
begin
  Dlg := TOpenDialog.Create(nil);
  if Dlg.Execute then
  begin
    try
      sqlFiles.Insert;
      sqlFilesfilename.AsString := ExtractFileName(dlg.FileName);
      sqlFilesfilepath.AsString := dlg.FileName;
      sqlFilesinclusiondate.AsDateTime := now;
      sqlFiles.Post;
      sqlFiles.ApplyUpdates(0);
      dm_main.SQLT_Client.Commit;

    except
      on E: Exception do
        Application.MessageBox(PChar('Erro ao gravar dados' + #13 + e.Message),
          'Aviso', MB_ICONERROR + MB_OK);
    end;
    sqlFiles.Open;
  end;
end;

procedure Tfrm_main.btn_CancelClick(Sender: TObject);
begin

  if pb_progress.Position = 0 then
    Exit;

  if Application.MessageBox(PChar('O backup está em execução!' + #13 +
    'Deseja parar a operação?'), 'Aviso!', MB_YESNO) = mrYes then
  begin

  end;
end;

procedure Tfrm_main.FormCreate(Sender: TObject);
begin

end;

procedure Tfrm_main.FormShow(Sender: TObject);
begin
  sqlFiles.Open;
end;


procedure Tfrm_main.mnuAccessConfigClick(Sender: TObject);
begin
  Application.CreateForm(Tfrm_inputPassword, frm_inputPassword);

  try
    frm_inputPassword.ShowModal;

    if (frm_inputPassword.ModalResult = mrOk) then
    begin
      Application.CreateForm(Tfrm_config, frm_config);
      try
        frm_config.ShowModal;
      finally
        FreeAndNil(frm_config);
      end;
      sqlFiles.Open;
    end
    else
      Application.MessageBox('Senha Inválida!', 'Aviso!', MB_OK + MB_ICONWARNING);


  finally
    FreeAndNil(frm_inputPassword);
  end;

end;

procedure Tfrm_main.mnuConfigAutoBackupClick(Sender: TObject);
begin
  Application.CreateForm(Tfrm_inputPassword, frm_inputPassword);

  try
    frm_inputPassword.ShowModal;

    if (frm_inputPassword.ModalResult = mrOk) then
    begin
      Application.CreateForm(Tfrm_autoBackup, frm_autoBackup);

      try
        frm_autoBackup.ShowModal;
      finally
        FreeAndNil(frm_autoBackup);
      end;
      sqlFiles.Open;
    end
    else
      Application.MessageBox('Senha Inválida!', 'Aviso!', MB_OK + MB_ICONWARNING);
  finally
    FreeAndNil(frm_inputPassword);
  end;

end;

procedure Tfrm_main.mnuConfigClick(Sender: TObject);
begin

end;

procedure Tfrm_main.mnuDeleteClick(Sender: TObject);
begin
  if sqlFiles.IsEmpty then
    Abort;
  if (Application.MessageBox(PChar('Este item será removido da lista de backup' +
    #13 + 'Deseja remove-lo mesmo assim?'), 'Aviso!', MB_YESNO + MB_ICONWARNING)) =
    mrYes then
  begin
    try
      sqlFiles.Delete;
      sqlFiles.ApplyUpdates;
      dm_main.SQLT_Client.Commit;
    except
      on E: Exception do
        Application.MessageBox(PChar('Erro ao remover dados' + #13 + e.Message),
          'Aviso!', MB_OK + MB_ICONERROR);
    end;
    sqlFiles.Open;
  end;
end;

procedure Tfrm_main.tmrTrayTimer(Sender: TObject);
begin
  triMain.Visible := True;
  frm_main.Hide;
  tmrTray.Enabled := False;
end;

procedure Tfrm_main.triMainDblClick(Sender: TObject);
begin
  triMain.Visible := False;
  frm_main.Show;
end;




end.
