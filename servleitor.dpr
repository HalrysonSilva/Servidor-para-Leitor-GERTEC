program servleitor;

uses
  Vcl.Forms,
  svleitor in 'svleitor.pas' {Form1},
  CONEXAOBD in 'CONEXAOBD.pas' {DataModule1: TDataModule},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := False; // Mude para False

  // Mova a linha Application.ShowMainForm para antes da criação do formulário
  Application.ShowMainForm := False;

  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TDataModule1, DataModule1);

  TStyleManager.TrySetStyle('Glow');

  Application.Run;
end.
