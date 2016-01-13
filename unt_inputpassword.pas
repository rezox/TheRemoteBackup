unit unt_inputPassword;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, udm_main;

type

  { Tfrm_inputPassword }

  Tfrm_inputPassword = class(TForm)
    btnOk: TBitBtn;
    edtPassword: TEdit;
    Label1: TLabel;
    procedure btnOkClick(Sender: TObject);
    procedure edtPasswordKeyPress(Sender: TObject; var Key: char);
    procedure FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frm_inputPassword: Tfrm_inputPassword;

implementation

{$R *.lfm}

{ Tfrm_inputPassword }

procedure Tfrm_inputPassword.FormKeyDown(Sender: TObject; var Key: word;
  Shift: TShiftState);
begin
  if ((ssAlt in Shift) and (Key = 13)) then
    Key := 0;
end;

procedure Tfrm_inputPassword.btnOkClick(Sender: TObject);
begin
  dm_main.sqlAccount.Open;
  if ((edtPassword.Text = dm_main.sqlAccountpassword.AsString) or
    (dm_main.sqlAccountpassword.AsString = '')) then
    ModalResult := mrOk
  else
    ModalResult := mrCancel;
end;

procedure Tfrm_inputPassword.edtPasswordKeyPress(Sender: TObject; var Key: char);

begin
  if (Key = #13) then
    btnOk.SetFocus;
end;

end.
