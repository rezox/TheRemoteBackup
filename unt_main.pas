unit unt_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, RTTICtrls, Forms, Controls, Graphics, Dialogs,
  Menus, DBGrids, ComCtrls, Buttons, StdCtrls, EditBtn, maskedit, unt_config,
  unt_utils, unt_inputPassword, unt_autoBackup, udm_main, unt_ftpConfig, DB,
  sqldb, LCLType, ExtCtrls, LMessages, PopupNotifier, ftpsend, IniFiles, blcksock;

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
    lblStatus: TLabel;
    mnuFtpConfig: TMenuItem;
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
    procedure mnuFtpConfigClick(Sender: TObject);
    procedure tmrTrayTimer(Sender: TObject);
    procedure triMainClick(Sender: TObject);
    procedure triMainDblClick(Sender: TObject);
    procedure WMCloseQuery(var message: TLMessage); message LM_CLOSEQUERY;
    procedure setFtpAccount(user: string; passwd: string);
    procedure loadFtpConfig;
    procedure SockCallBack(Sender: TObject; Reason: THookSocketReason;
      const Value: string);
    procedure upload();
    procedure download();
  private
    { private declarations }
    aServer: string;
    aPort: string;
    aFtpRepoPath: string;
    aFtpUser: string;
    aFtpPasswd: string;

    segundos: integer;

    currentBytes, beforeBytes, totalBytes: integer;

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
  ftp: TFTPSend;
begin
  CreateDir(ExtractFilePath(ApplicationName) + 'RESTORES');
  CreateDir(ExtractFilePath(ApplicationName) + 'RESTORES\' +
    StringReplace(DateToStr(now), '/', '-', [rfReplaceAll]));

  path := ExtractFilePath(ApplicationName) + 'RESTORES\' +
    StringReplace(DateToStr(now), '/', '-', [rfReplaceAll]) + '\';

  ftp := TFTPSend.Create;

  ftp.Username := frm_main.aFtpUser;
  ftp.Password := frm_main.aFtpPasswd;
  ftp.TargetHost := frm_main.aServer;
  ftp.TargetPort := frm_main.aPort;
  Application.ProcessMessages;

  // Atualiza a barra;
  ftp.DSock.OnStatus := @frm_main.SockCallBack;

  if (not ftp.RetrieveFile(frm_main.aFtpRepoPath + Frm_main.sqlFilesfilename.AsString,False)) then
    frm_main.lblStatus.Caption := 'Status: Erro ao Baixar Arquivo'
  else
    frm_main.lblStatus.Caption := 'Status: Arquivo Restaurado com Sucesso!';


  //frm_main.pb_progress.Position := 0;
  //if ( not ftpGetFile(frm_main.aServer, frm_main.aPort, frm_main.aFtpRepoPath +
  //  frm_main.sqlFilesfilename.AsString, path + frm_main.sqlFilesfilename.AsString,
  //  frm_main.aFtpUser, frm_main.aFtpPasswd)) then
  //begin
  //  Application.MessageBox('Arquivo não Encontrado!', 'Aviso', MB_OK + MB_ICONWARNING);
  //
  //end
  //else
  //  frm_main.pb_progress.Position := frm_main.pb_progress.Max;
end;

procedure TReceiveFile.Execute;
begin
  Priority := tpNormal;
  SyncEvent;
  DoTerminate;
end;

{ TSendFile }

procedure TSendFile.SyncEvent;
begin

end;

procedure Tfrm_main.upload;
var
  sql: TSQLQuery;
  ftp: TFTPSend;
  aFile: string;
begin
  sql := TSQLQuery.Create(nil);
  sql.DataBase := dm_main.conn_client;
  sql.Transaction := dm_main.SQLT_Client;
  sql.SQL.Text := 'select * from file';

  sql.Open;
  sql.Last;
  sql.First;

  frm_main.pb_progress.Position := 0;

  while not (sql.EOF) do
  begin
    try
      //Get file size
      aFile := sql.FieldByName('filepath').AsString;
      totalBytes := FileSize(aFile);

      ftp := TFTPSend.Create;
      ftp.Username := frm_main.aFtpUser;
      ftp.Password := frm_main.aFtpPasswd;
      ftp.TargetHost := frm_main.aServer;
      ftp.TargetPort := frm_main.aPort;
      Application.ProcessMessages;

      // Atualiza a barra;
      ftp.DSock.OnStatus := @frm_main.SockCallBack;

      // Login;
      if not ftp.Login then
      begin
        Application.MessageBox('Login incorreto', 'Atenção !!!', MB_ICONWARNING);
        Exit;
      end;

      // Define o nome do arquivo para o FTP;
      aFile := sql.FieldByName('filepath').AsString;
      ftp.DirectFileName := sql.FieldByName('filepath').AsString;
      ftp.DirectFile := True;

      // Trocar diretório FTP;
      if (frm_main.aFtpRepoPath <> '') then
        ftp.ChangeWorkingDir(frm_main.aFtpRepoPath);
      aFile := sql.FieldByName('filename').AsString;

      // Arquivo de armazenamento para o servidor FTP;
      if (ftp.StoreFile(aFile, False) = True) then
        lblStatus.Caption := 'Status: Backup Realizado com Sucesso!'
      else
        lblStatus.Caption := 'Status: Erro ao Realizar Backup!';

      Application.ProcessMessages;
      ftp.Logout;

      frm_main.pb_progress.Position := 0;
    except
      frm_main.pb_progress.Position := 0;

      ftp.Free;
      Exit;
    end;
    ftp.Free;



    sql.Edit;
    sql.FieldByName('lastbackup').AsDateTime := now;
    sql.Post;
    sql.ApplyUpdates;

    sql.Next;
  end;
  dm_main.SQLT_Client.Commit;
  frm_main.sqlFiles.Open;
  frm_main.pb_progress.Position := 0;

end;

procedure Tfrm_main.download;
var
  path, aFile: string;
  ftp: TFTPSend;
begin
  CreateDir(ExtractFilePath(ApplicationName) + 'RESTORES');
  CreateDir(ExtractFilePath(ApplicationName) + 'RESTORES\' +
    StringReplace(DateToStr(now), '/', '-', [rfReplaceAll]));

  path := ExtractFilePath(ApplicationName) + 'RESTORES\' +
    StringReplace(DateToStr(now), '/', '-', [rfReplaceAll]) + '\';

  ftp := TFTPSend.Create;

  ftp.Username := frm_main.aFtpUser;
  ftp.Password := frm_main.aFtpPasswd;
  ftp.TargetHost := frm_main.aServer;
  ftp.TargetPort := frm_main.aPort;
  Application.ProcessMessages;

  // Define o nome do arquivo para o FTP;
  aFile := Frm_main.sqlFilesfilename.AsString;
  ftp.DirectFileName := aFile;
  ftp.DirectFile:= false;

  ftp.DSock.OnStatus := @frm_main.SockCallBack;

  if (ftp.Login) then
  begin
    totalBytes := ftp.FileSize(frm_main.aFtpRepoPath + aFile);
    if (not ftp.RetrieveFile(frm_main.aFtpRepoPath + aFile,False)) then
      frm_main.lblStatus.Caption := 'Status: Erro ao Baixar Arquivo'
    else
    begin
      ftp.DataStream.SaveToFile(path + aFile);
      frm_main.lblStatus.Caption := 'Status: Arquivo Restaurado com Sucesso!';
    end;
  end
  else
    frm_main.lblStatus.Caption := 'Status: Arquivo Restaurado com Sucesso!';

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

procedure Tfrm_main.setFtpAccount(user: string; passwd: string);
begin
  aFtpUser := user;
  aFtpPasswd := passwd;
end;

procedure Tfrm_main.loadFtpConfig;
var
  iniFile: TInifile;
  Arq: string;
begin
  Arq := ExtractFilePath(Application.ExeName) + 'conf.ini';
  iniFile := TIniFile.Create(Arq);
  try
    aServer := iniFile.ReadString('FTP', 'SERVER', '');
    aPort := iniFile.ReadString('FTP', 'PORT', '21');
    aFtpRepoPath := iniFile.ReadString('FTP', 'REPO_PATH', '/web/repo/');

  finally
    FreeAndNil(iniFile);
  end;
  //if ((aServer = '') or (aFtpUser = '') or (aFtpPasswd = '')) then
  //  Application.MessageBox('Dados do FTP não Configurados', 'Aviso!',
  //    MB_OK + MB_ICONWARNING);

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
  if ( not sqlFiles.IsEmpty) then
    ppmGrid.PopUp;
end;


procedure Tfrm_main.btnUpdateRepositorieClick(Sender: TObject);
begin
  upload();
end;

procedure Tfrm_main.btnRemoteRestoreClick(Sender: TObject);
var
  Receive: TReceiveFile;
begin
  download();
  //Receive := TReceiveFile.Create(True);
  //Receive.FreeOnTerminate := True;
  //Receive.Resume;
  //pb_progress.Position := 0;
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
  loadFtpConfig;
end;

procedure Tfrm_main.FormShow(Sender: TObject);
begin
  sqlFiles.Open;
  setFtpAccount('Admin', '123456');
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

procedure Tfrm_main.mnuFtpConfigClick(Sender: TObject);
begin
  Application.CreateForm(Tfrm_ftpConfig, frm_ftpConfig);
  try
    frm_ftpConfig.ShowModal;
  finally
    FreeAndNil(frm_ftpConfig);
  end;
  loadFtpConfig;
end;

procedure Tfrm_main.tmrTrayTimer(Sender: TObject);
begin
  triMain.Visible := True;
  frm_main.Hide;
  tmrTray.Enabled := False;
end;

procedure Tfrm_main.triMainClick(Sender: TObject);
begin

end;

procedure Tfrm_main.triMainDblClick(Sender: TObject);
begin
  triMain.Visible := False;
  frm_main.Show;
end;


procedure Tfrm_main.SockCallBack(Sender: TObject; Reason: THookSocketReason;
  const Value: string);
begin
  // Download;
  if (Reason = HR_ReadCount) then // HR_ReadCount // Quantidade de dados baixados;
  begin
    beforeBytes := currentBytes;
    Inc(currentBytes, StrToIntDef(Value, 0)); // Incrementa a quantidade de dados;
    pb_progress.Position := Round(1000 * (currentBytes / totalBytes));
    lblStatus.Caption := 'Status: Realizando Download';
  end;

  // Upload;
  if (Reason = HR_WriteCount) then // HR_WriteCount // Quantidade de dados transferidos;
  begin
    beforeBytes := currentBytes;
    Inc(currentBytes, StrToIntDef(Value, 0)); // Incrementa a quantidade transferida;
    pb_progress.Position := Round(1000 * (currentBytes / totalBytes));
    lblStatus.Caption := 'Status: Realizando Backup';
  end;
  Application.ProcessMessages;

  if (Reason = HR_Connect) then
  begin
    beforeBytes := 0;
    currentBytes := 0;
    segundos := 0;
  end;
end;




end.
