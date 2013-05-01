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
  StyleSystem.LoadElements('E:\Git\DStyles\StyleElements\Test');

{$R *.dfm}

end.
