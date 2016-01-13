unit unt_autoBackup;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, DBCtrls,
  StdCtrls, Buttons, udm_main, dbcurredit, LCLType;

type

  { Tfrm_autoBackup }

  Tfrm_autoBackup = class(TForm)
    btnCancel: TBitBtn;
    btnSave: TBitBtn;
    lblLastBackUp: TDBText;
    Label1: TLabel;
    Label2: TLabel;
    rdgKind: TDBRadioGroup;
    edtBackupTimes: TRxDBCurrEdit;
    procedure btnCancelClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frm_autoBackup: Tfrm_autoBackup;

implementation

{$R *.lfm}

{ Tfrm_autoBackup }

procedure Tfrm_autoBackup.FormShow(Sender: TObject);
begin
  dm_main.sqlDoBackup.Open;
  if (dm_main.sqlDoBackup.IsEmpty) then
    dm_main.sqlDoBackup.Insert
  else
    dm_main.sqlDoBackup.Edit;
  dm_main.sqlDoBackup.Open;
end;

procedure Tfrm_autoBackup.btnSaveClick(Sender: TObject);
begin
  try
    dm_main.sqlDoBackup.Post;
    dm_main.sqlDoBackup.ApplyUpdates(0);
    dm_main.SQLT_Client.Commit;
  except
    on E: Exception do
      Application.MessageBox(PChar('Erro ao gravar dados!' + e.Message),
        'Aviso!', MB_OK + MB_ICONERROR);
  end;
  ModalResult := mrOk;
end;

procedure Tfrm_autoBackup.btnCancelClick(Sender: TObject);
begin
  dm_main.sqlDoBackup.Cancel;
  ModalResult := mrCancel;

end;

end.
