program Demo;

uses
  Forms,
  Main in 'Main.pas' {Form1},
  Styles.Forms in '..\Styles\Styles.Forms.pas',
  Styles in 'Styles.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
