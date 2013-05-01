unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Styles, Styles.Forms;

type
  TForm1 = class(TForm)
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

initialization
  StyleSystem.Metrics.FrameSize := 7;
  StyleSystem.Metrics.HeaderHeight := 28;
  StyleSystem.Metrics.FormButtonWidth := 18;
  StyleSystem.Metrics.FormButtonHeight := 18;
  StyleSystem.LoadElements('E:\Git\DStyles\StyleElements\OrangeGraphit');

{$R *.dfm}

end.
