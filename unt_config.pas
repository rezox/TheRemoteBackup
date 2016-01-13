unit unt_config;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, DbCtrls, udm_main, LCLType;

type

  { Tfrm_config }

  Tfrm_config = class(TForm)
    btnSave: TBitBtn;
    btnCancel: TBitBtn;
    edtDoc: TDBEdit;
    edtKey: TDBEdit;
    edtPassword: TDBEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    procedure btnCancelClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frm_config: Tfrm_config;

implementation

{$R *.lfm}

{ Tfrm_config }

procedure Tfrm_config.btnCancelClick(Sender: TObject);
begin
  dm_main.sqlAccount.Cancel;
  ModalResult:= mrCancel;
end;

procedure Tfrm_config.btnSaveClick(Sender: TObject);
begin
  try
    dm_main.sqlAccount.Post;
    dm_main.sqlAccount.ApplyUpdates(0);
    dm_main.SQLT_Client.Commit;
  except on E : Exception do
    Application.MessageBox(pChar('Erro ao Gravar Informações!'+#13+e.Message),'Aviso!', MB_OK );
  end;
  ModalResult:= mrOk;
end;

procedure Tfrm_config.FormShow(Sender: TObject);
begin
  dm_main.sqlAccount.Edit;
end;

end.

