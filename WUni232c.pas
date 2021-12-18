unit WUni232c;

interface

{
WUni232c  Component: www.csd.co.jp
Copyright (c) 2015-2017 - CSD Co.,LTD.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

}

uses
  System.SysUtils, System.Classes ,system. 	DateUtils,
  System.Types, System.UITypes,  System.Variants,
  Winapi.Windows,
  System.IOUtils;

const
CopyRight                = 'WUni232c Component (C) 2015..2017 CSD Co.,LTD.';
VERSIONTBL               = 'WUni232c Version 1.10 For Windows';
XOFFXON                  = $1311;

type
  TParityBit   = (ParityNone, ParityOdd, ParityEven, ParityMark, ParitySpace);
  TByteSize    = (Bit7, Bit8);
  TStopBit     = (Stopbit1,  Stopbit2);
  TFlowControl = (CtrlNone , CtrlDtrDsr  , CtrlRtsCts   , CtrlXonXoff);

type
   TUsbNotify = procedure (Sender: TObject) of object;

 TWUni232c = class(TComponent)

 private var
    { Private 宣言 }
    FPort           : Byte;
    FCopyRight      : String;

    FBaudRate       : Cardinal;
    FByteSize       : TByteSize;
    FParityBit      : TParityBit;
    FStopBit        : TStopBit;
    FFlowControl    : TFlowControl;

    FConnect        : Boolean;
    FHANDLE 		: Integer;
    FDCB    		: TDCB;  



    procedure SetBaudRate(Value   : Cardinal        );
    procedure SetParityBit(Value  : TParityBit    );
    procedure SetByteSize(Value    : TByteSize      );
    procedure SetStopBit (Value   : TStopBit      );
    procedure SetFlowControl(Value: TFlowControl);

  protected
  public
      constructor Create(AOwner: TComponent); override;
      destructor Destroy; override;

      function  Open  ():Integer;
      function  Close ():Integer;
      function  Write ( Size : Cardinal; Buffer : PByte ):Integer;
      function  Read  ( Size : Cardinal; Buffer : PByte ):Integer;
      function  GetModemStatus():Integer;
      function  SetModemStatus(State:Word):integer;
      function  SetModemBreak(waitms: Cardinal):Integer;
      function  GetVersion():String;
      function  Error2Str(OpenErrorCode: Integer):String;

  published
    property Port       : Byte       read FPort       write FPort default 1;
    property BaudRate  : Cardinal    read FBaudRate   write SetBaudRate;
    property ParityBits: TParityBit  read FParityBit  write SetParityBit;
    property ByteSize  : TByteSize   read FByteSize   write SetByteSize;
    property StopBits  : TStopBit    read FStopBit    write SetStopBit;
    property Connect     : Boolean   read FConnect;
    property FlowControls: TFlowControl read FFlowControl write SetFlowControl;
  end;

procedure Register;

implementation

constructor TWUni232c.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCopyRight   :=  CopyRight;
  FBaudRate    := 115200;
  FParityBit   := ParityNone;
  FByteSize    := Bit8;
  FStopBit     := Stopbit1;
  FFlowControl := CtrlNone;
  FPort        := 1;
  FHandle      := (-1);
end;


destructor TWUni232c.Destroy;
begin
  Close();
  inherited Destroy;
end;

procedure TWUni232c.SetBaudRate(Value: Cardinal);
begin
  FBaudRate := Value;
end;

procedure TWUni232c.SetByteSize(Value: TByteSize);
begin
  FByteSize := Value;
end;

procedure TWUni232c.SetParityBit(Value: TParityBit);
begin
  FParityBit := Value;
end;

procedure TWUni232c.SetStopBit(Value: TStopBit);
begin
  FStopBit := Value;
end;

procedure TWUni232c.SetFlowControl(Value: TFlowControl);
begin
  FFlowControl := Value;
end;


//***********************************/
//*   OOOO                          */
//*  OO  OO                         */
//*  OO  OO  ppppp    eeee   nnnnn  */
//*  OO  OO  pp  pp  ee  ee  nn  nn */
//*  OO  OO  pp  pp  eeeeee  nn  nn */
//*  OO  OO  ppppp   ee      nn  nn */
//*   OOOO   pp       eeee   nn  nn */
//*          pp                     */
//***********************************/
function  TWUni232c.Open  ():Integer;
var
    PortName: array [0 .. 32] of Char;
    CommTimeouts : TCommTimeouts;
begin
   Result := -2;
   if FHandle >= 0 then exit;
   begin
       FillChar(PortName,sizeof(PortName),0);

	   StrPCopy(PortName, '\\.\COM' + IntToStr(FPort));

       FHandle := CreateFile(
                   PortName,
                   GENERIC_READ or GENERIC_WRITE,
                   0,                     //
                   nil,                   //
                   OPEN_EXISTING,         //
                   FILE_ATTRIBUTE_NORMAL, //
                   0);                    //

       if FHandle < 0 then // On Error?
            raise Exception.Create('Com Port Open Error'); //


       SetupComm(FHandle, 1024*32, 1024*32);			// Buffers 32k borth
       PurgeComm(FHandle, PURGE_TXABORT or PURGE_RXABORT or PURGE_TXCLEAR or   PURGE_RXCLEAR);

       CommTimeouts.ReadIntervalTimeout         := MAXDWORD;
       CommTimeouts.ReadTotalTimeoutMultiplier  := 0;
       CommTimeouts.ReadTotalTimeoutConstant    := 100;
       CommTimeouts.WriteTotalTimeoutMultiplier := 0;
       CommTimeouts.WriteTotalTimeoutConstant   := 100;
       SetCommTimeouts(FHandle, CommTimeouts);

       GetCommState(FHandle, FDCB);
        // 通信環境の設定
       FDCB.BaudRate := FBaudRate;      
       FDCB.ByteSize := ord(FByteSize)+7;

       if(FStopBit = Stopbit1 )  then  FDCB.StopBits := 0    // Stop Bit 1
       else                            FDCB.StopBits := 2;   // Stop Bit 2

       FDCB.Flags := FDCB.Flags and $FEC0C000;
       FDCB.Flags := FDCB.Flags or  $00000001; // binaly enable

       if FParityBit = ParityNone then
                   FDCB.Flags := FDCB.Flags and  $fffffffd
       else
                   FDCB.Flags := FDCB.Flags or   $00000002;     // Parity Eanble!!

        FDCB.Parity := Ord(FParityBit);

        SetCommState(FHandle, FDCB);

        case FFlowControl of
        CtrlNone   : FDCB.Flags := FDCB.Flags or $00001010;  // RTS DTR
        CtrlRtsCts : FDCB.Flags := FDCB.Flags or $00002014;  // RTS CTS
        CtrlDtrDsr : FDCB.Flags := FDCB.Flags or $00001028;  // DTR DSR
        CtrlXonXoff: FDCB.Flags := FDCB.Flags or $00001310;  // XONXOFF
        end;
        FDCB.XonLim  := 128;
        FDCB.XoffLim := 128;
        FDCB.XonChar  := Ansichar(XOFFXON mod $100);
        FDCB.XoffChar := Ansichar(XOFFXON div $100);
        FDCB.EvtChar  := Ansichar(0);

        SetCommState(FHandle, FDCB);

        SetCommMask(FHandle, 0);
        EscapeCommFunction(FHandle, SETDTR); // DTRをオンにする
        FConnect      := True;
        Result := 0;             //OK
   end;
end;

(*
//***********************************/
//*  FFFFFF                         */
//*  FF       lll                   */
//*  FF        ll     oooo   ww   ww*/
//*  FFFF      ll    oo  oo  ww w ww*/
//*  FF        ll    oo  oo  wwwwwww*/
//*  FF        ll    oo  oo   wwwww */
//*  FF       llll    oooo    ww ww */
//***********************************/
(*
function  TWUni232c.SetFlow():Integer;
begin
 Result :=  0;
end;
*)
//*******************************************/
//*   CCCC                                  */
//*  CC  CC   lll                           */
//*  CC        ll     oooo    sssss   eeee  */
//*  CC        ll    oo  oo  ss      ee  ee */
//*  CC        ll    oo  oo   ssss   eeeeee */
//*  CC  CC    ll    oo  oo      ss  ee     */
//*   CCCC    llll    oooo   sssss    eeee  */
//*******************************************/
function TWUni232c.Close():Integer;
begin
     result := 0;
     if FHandle >= 0  then
     begin
       EscapeCommFunction(FHandle, CLRDTR);
       PurgeComm(FHandle, PURGE_TXABORT or PURGE_RXABORT or PURGE_TXCLEAR or   PURGE_RXCLEAR);
       CloseHandle(FHandle);               
       FHandle := -1;
     end;
     FConnect  := False;
end;
//*******************************************/
//*  WW   WW                                */
//*  WW   WW           ii      tt           */
//*  WW   WW rrrrr           tttttt   eeee  */
//*  WW W WW rr  rr   iii      tt    ee  ee */
//*  WWWWWWW rr        ii      tt    eeeeee */
//*  WWW WWW rr        ii      tt    ee     */
//*  WW   WW rr       iiii      ttt   eeee  */
//* Write Data Max 64 byte;                 */
//*******************************************/
function TWUni232c.Write( Size : cardinal ; Buffer : PBYTE ):Integer;
var
 dwError: DWord;
 GetSize : Cardinal;
 Stat: TComStat;
 dwBytesWritten: DWord;
begin
   result := -1;     //
  if FHandle < 0 then
  begin
      exit;
  end;

   GetCommState(FHandle, FDCB);
   
   GetSize := Size;
   if(GetSize >= 64) then GetSize := 64;		// Max Size Change! CounterMesure For Andoriod!!

   repeat // 送信キューが空くのを待つ
        ClearCommError(FHandle, dwError, @Stat);
   until (64 - Stat.cbOutQue) >= int64(GetSize);

  if not WriteFile(FHandle, Buffer^, Size, dwBytesWritten, Nil ) then
  begin
      ClearCommError(FHandle, dwError, @Stat);
      result := -8;
      exit
  end;
  result := dwBytesWritten;
end;
//***********************************/
//*  RRRRR                          */
//*  RR  RR                      dd */
//*  RR  RR   eeee    aaaa       dd */
//*  RRRRR   ee  ee      aa   ddddd */
//*  RRRR    eeeeee   aaaaa  dd  dd */
//*  RR RR   ee      aa  aa  dd  dd */
//*  RR  RR   eeee    aaaaa   ddddd */
//***********************************/
function TWUni232c.Read( Size : cardinal ; Buffer : PByte ):Integer;
var
    dwError: DWord;
    Stat: TComStat;
    dwLength: DWord;
begin
   result := -1;
    if FHandle < 0 then
    begin
      exit;
    end;

    ClearCommError(FHandle, dwError, @Stat);
    dwLength := Size;
    if not ReadFile(FHandle, Buffer^, Size, dwLength, NIL) then
    begin
        ClearCommError(FHandle, dwError, @Stat); 
        result := -9;
//      raise Exception.Create('Com Read Buffer Error')
        exit;
    end;
    Result := dwLength;
end;
//*******************************************************************/
//*   GGGG                   MM   MM                                */
//*  GG  GG            tt    MMM MMM             dd                 */
//*  GG       eeee   tttttt  MMMMMMM  oooo       dd   eeee   mm  mm */
//*  GG GGG  ee  ee    tt    MM M MM oo  oo   ddddd  ee  ee  mmmmmmm*/
//*  GG  GG  eeeeee    tt    MM   MM oo  oo  dd  dd  eeeeee  mmmmmmm*/
//*  GG  GG  ee        tt    MM   MM oo  oo  dd  dd  ee      mm m mm*/
//*   GGGG    eeee      ttt  MM   MM  oooo    ddddd   eeee   mm   mm*/
//*******************************************************************/
function TWUni232c.GetModemStatus():Integer;
var
   State : DWord;
begin
  Result := -1;
  if GetCommModemStatus( FHandle, State) then
   begin
    Result := 0;
    if State and MS_CTS_ON <> 0  then result := result or $10;
    if State and MS_DSR_ON <> 0  then result := result or $20;
    if State and MS_RING_ON <> 0 then result := result or $40;
    if State and MS_RLSD_ON <> 0 then result := result or $80;
  end
end;
// *******************************************************************/
// *   SSSS                   MM   MM                                */
// *  SS  SS            tt    MMM MMM             dd                 */
// *  SS       eeee   tttttt  MMMMMMM  oooo       dd   eeee   mm  mm */
// *   SSSS   ee  ee    tt    MM M MM oo  oo   ddddd  ee  ee  mmmmmmm*/
// *      SS  eeeeee    tt    MM   MM oo  oo  dd  dd  eeeeee  mmmmmmm*/
// *  SS  SS  ee        tt    MM   MM oo  oo  dd  dd  ee      mm m mm*/
// *   SSSS    eeee      ttt  MM   MM  oooo    ddddd   eeee   mm   mm*/
// *******************************************************************/
function TWUni232c.SetModemStatus(State: Word): integer;
begin
//  DTR 1
//  RTS 2
   if  State and $01 <> 0 then  EscapeCommFunction(FHandle,SETDTR )
   else                         EscapeCommFunction(FHandle,CLRDTR );
   if  State and $02 <> 0 then  EscapeCommFunction(FHandle,SETRTS )
   else                         EscapeCommFunction(FHandle,CLRRTS );
   result := 0;
end;
//*******************************************************************/
//*   SSSS                   BBBBB                                  */
//*  SS  SS            tt    BB  BB                  kk             */
//*  SS       eeee   tttttt  BB  BB  rrrrr    aaaa   kk       eeee  */
//*   SSSS   ee  ee    tt    BBBBB   rr  rr      aa  kk kk   ee  ee */
//*      SS  eeeeee    tt    BB  BB  rr       aaaaa  kkkk    eeeeee */
//*  SS  SS  ee        tt    BB  BB  rr      aa  aa  kk kk   ee     */
//*   SSSS    eeee      ttt  BBBBB   rr       aaaaa  kk  kk   eeee  */
//*******************************************************************/
function TWUni232c.SetModemBreak(waitms: Cardinal):Integer;
begin
    EscapeCommFunction(FHandle, SETBREAK); 
    sleep(waitms);
    EscapeCommFunction(FHandle, CLRBREAK); 
    result := 0;
end;

//***********************************************************/
//*   OOOO           EEEEEE                                 */
//*  OO  OO          EE                                     */
//*  OO  OO  nnnnn   EE      rrrrr   rrrrr    oooo   rrrrr  */
//*  OO  OO  nn  nn  EEEE    rr  rr  rr  rr  oo  oo  rr  rr */
//*  OO  OO  nn  nn  EE      rr      rr      oo  oo  rr     */
//*  OO  OO  nn  nn  EE      rr      rr      oo  oo  rr     */
//*   OOOO   nn  nn  EEEEEE  rr      rr       oooo   rr     */
//***********************************************************/
function TWUni232c.Error2Str(OpenErrorCode: Integer):String;
var
  msg: string;
begin
  msg := Format('Error Code = %d', [OpenErrorCode])+slineBreak;
  case OpenErrorCode of
        0   : msg := msg + 'NO Error';
        -2  : msg := msg + 'Already ComPort Open';
        -3  : msg := msg + 'Please Device Connect';
        -4  : msg := msg + 'Can not Open Device';
        -5  : msg := msg + 'Can not Open Device';
        -6  : msg := msg + 'Can not Open Device';
        -7  : msg := msg + 'The end of the expiration date';
        -8  : msg := msg + 'Write Buffer Error'; // For Win
        -9  : msg := msg + 'Read Buffer Error' ; // For Win
     else
              msg := msg + 'Unknown Error';
  end;
  result := msg;
end;
//***********************************************************/
//*  VV  VV                                                 */
//*  VV  VV                            ii                   */
//*  VV  VV   eeee   rrrrr    sssss           oooo   nnnnn  */
//*  VV  VV  ee  ee  rr  rr  ss       iii    oo  oo  nn  nn */
//*  VV  VV  eeeeee  rr       ssss     ii    oo  oo  nn  nn */
//*   VVVV   ee      rr          ss    ii    oo  oo  nn  nn */
//*    VV     eeee   rr      sssss    iiii    oooo   nn  nn */
//***********************************************************/
function  TWUni232c.GetVersion():String;
begin
    Result := VERSIONTBL;
end;


procedure Register;
begin
  RegisterComponents('UsbTool', [TWUni232c]);
end;

end.

