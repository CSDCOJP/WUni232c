program Sample232c;

uses
  System.StartUpCopy,
  FMX.Forms,
  MMain in 'MMain.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.FormFactor.Orientations := [TFormOrientation.Portrait];
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
