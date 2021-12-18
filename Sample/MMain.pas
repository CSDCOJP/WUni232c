unit MMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.StdCtrls,  FMX.Memo, FMX.ListBox, FMX.Controls.Presentation, FMX.Edit,
  FMX.Layouts,WUni232C, FMX.ScrollBox;
type
  TMainForm = class(TForm)
    Open: TButton;
    WriteUart: TButton;
    ReadUart: TButton;
    Memo1: TMemo;
    Edit1: TEdit;
    Close: TButton;
    Edit2: TEdit;
    Label1: TLabel;
    Parity: TComboBox;
    StopBit: TComboBox;
    BitSet: TComboBox;
    Flow: TComboBox;
    Label2: TLabel;
    Label3: TLabel;
    Rate: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Panel1: TPanel;
    Cts: TRadioButton;
    Rts: TRadioButton;
    Ri: TRadioButton;
    DCD: TRadioButton;
    ReadStaus: TButton;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    Button1: TButton;
    Label7: TLabel;
    Break: TButton;
    B11: TButton;
    B13: TButton;
    Uni232c: TWUni232c;
    procedure OpenClick(Sender: TObject);
    procedure CloseClick(Sender: TObject);
    procedure BitSetChange(Sender: TObject);
    procedure ParityChange(Sender: TObject);
    procedure FlowChange(Sender: TObject);
    procedure StopBitChange(Sender: TObject);
    procedure WriteUartClick(Sender: TObject);
    procedure ReadUartClick(Sender: TObject);
    procedure ReadStausClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure BreakClick(Sender: TObject);
    procedure CheckBox1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure AndroidFpc2321UsbAttach(Sender: TObject);
    procedure AndroidFpc2321UsbDettach(Sender: TObject);
    procedure B11Click(Sender: TObject);
    procedure B13Click(Sender: TObject);
  private
    { private êÈåæ }
  public
    { public êÈåæ }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}



procedure TMainForm.AndroidFpc2321UsbAttach(Sender: TObject);
begin
//    if(not Uni232C.Connect ) then
    OpenClick(Sender);
end;

procedure TMainForm.AndroidFpc2321UsbDettach(Sender: TObject);
begin
    CloseClick(Sender);
end;

procedure TMainForm.B11Click(Sender: TObject);
var
  Buffer : Byte;
begin
    Buffer := $11;
    Uni232C.Write(sizeof(Buffer), @Buffer);
end;

procedure TMainForm.B13Click(Sender: TObject);
var
  Buffer : Byte;
begin
    Buffer := $13;
    Uni232C.Write(sizeof(Buffer), @Buffer);
end;


procedure TMainForm.BitSetChange(Sender: TObject);
begin
  case BitSet.itemIndex of
    0:
      Uni232C.ByteSize := Bit7;
    1:
      Uni232C.ByteSize := Bit8;
  end;
end;

procedure TMainForm.Button1Click(Sender: TObject);
begin
    memo1.Lines.Clear();
end;

procedure TMainForm.BreakClick(Sender: TObject);
begin
  Uni232C.SetModemBreak(1000);
end;

procedure TMainForm.CloseClick(Sender: TObject);
begin
  Uni232C.Close;
  Label7.Text := '';
end;

procedure TMainForm.CheckBox1Change(Sender: TObject);
var
Ret  : Word;
Data : Word;
begin
  Data := $0300;
  if(CheckBox1.IsChecked = True)  then Data := Data or $01;
  if(CheckBox2.IsChecked = True)  then Data := Data or $02;
  ret := Uni232C.SetModemStatus(Data);
  label1.Text := IntToHex(ret,4);
end;


procedure TMainForm.FlowChange(Sender: TObject);
begin
  case Flow.itemIndex of
    0:
      Uni232C.FlowControls := CtrlNone;
    1:
      Uni232C.FlowControls := CtrlRtsCts;
    2:
      Uni232C.FlowControls := CtrlDtrDsr;
    3:
      Uni232C.FlowControls := CtrlXonXoff;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  bitset.itemIndex  := 1;
  stopbit.itemIndex := 0;
  parity.itemIndex  := 0;
  flow  .itemIndex  := 0;

  memo1.Lines.Add('ReadData:');
  Self.Caption := Uni232c.GetVersion();
end;

procedure TMainForm.OpenClick(Sender: TObject);
var
  ret: Integer;
begin
  Uni232C.BaudRate := StrToInt(Edit2.Text);
  ret := Uni232C.open();
  if( Ret < 0) then
          showmessage('Cannot OPEN'+Uni232C.Error2Str(Ret) );
end;



procedure TMainForm.ParityChange(Sender: TObject);
begin
  case Parity.itemIndex of
    0:
      Uni232C.ParityBits := ParityNone;
    1:
      Uni232C.ParityBits := ParityOdd;
    2:
      Uni232C.ParityBits := ParityEven;
    3:
      Uni232C.ParityBits := ParityMark;
    4:
       Uni232C.ParityBits := ParitySpace;
  end;
end;

procedure TMainForm.ReadStausClick(Sender: TObject);
var
//  i : integer;
  ret : integer;
  str: String;
begin
  ret := Uni232C.GetModemStatus();
//  label7.Text := IntTohex(ret,8);
  if( Ret >= 0) then
  begin
  Cts .IsChecked := (( Ret And $10) <> 0 );
  Rts .IsChecked := (( Ret And $20) <> 0 );
  Ri  .IsChecked := (( Ret And $40) <> 0 );
  DCD .IsChecked := (( Ret And $80) <> 0 );
  str := IntToHex(ret,4)+ ' '+#$0d+#$0a;
  end;
end;

procedure TMainForm.ReadUartClick(Sender: TObject);
var
  str : String;
  ret : integer;
  i: byte;
  Buffer: array [0 .. $3F] of byte;
begin
  FillChar(Buffer,Sizeof(Buffer),0);

  for i := 0 to $3F do
    Buffer[i] := i;
////////// Max Read  Ftdi:62(?) PL2303:(64)///////////////
  ret := Uni232C.Read(64, @Buffer);

  str := '';
  if( Ret >= 0) then
        Label7.Text := 'Read Length:'+IntToHex(ret,8)
  else
        Label7.Text := 'Read Failed:ErrorCode'+IntTostr(ret) ;

  if( Ret <= 0 ) then exit;
  for i := 0 to ret-1 do
       str := str + Char(Buffer[i]);

   memo1.Lines.add(str);
end;

procedure TMainForm.StopBitChange(Sender: TObject);
begin
  case stopbit.itemIndex of
    0:
      Uni232C.StopBits := Stopbit1;
    1:
      Uni232C.StopBits := Stopbit2;
  end;
end;


procedure TMainForm.WriteUartClick(Sender: TObject);
var
  i: byte;
  Buffer: array [0 .. $3F] of byte;
  ret: Integer;
  Count : Integer;
begin
  FillChar(Buffer,sizeof(Buffer),0);
  Count := Edit1.Text.length;
  if( Count >= Sizeof(Buffer) )  then Count := Sizeof(Buffer);
  for i := 0 to Count-1 do
{$ifdef MSWINDOWS}
    Buffer[i] := byte(Edit1.Text[i+1]);
{$else}
    Buffer[i] := byte(Edit1.Text[i]);
{$endif}
   /////// Max Write Count = 64 ///////////////////////////////
  ret := Uni232C.Write(Edit1.Text.length, @Buffer);
  if( Ret >= 0) then
        Label7.Text := 'Write Length:'+IntToHex(ret,8)
  else
        Label7.Text := 'Write Failed:ErrorCode'+IntTostr(ret) ;

end;

end.
