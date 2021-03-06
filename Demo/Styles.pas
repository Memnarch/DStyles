unit Styles;

interface

uses
  Classes, Types, Windows, SysUtils, Generics.Collections, Graphics, PNGImage;

type
  TMetrics = class
  private
    FHeaderHeight: Integer;
    FFrameSize: Integer;
    FFormButtonHeight: Integer;
    FFormButtonWidth: Integer;
  public
    property FrameSize: Integer read FFrameSize write FFrameSize;
    property HeaderHeight: Integer read FHeaderHeight write FHeaderHeight;
    property FormButtonWidth: Integer read FFormButtonWidth write FFormButtonWidth;
    property FormButtonHeight: Integer read FFormButtonHeight write FFormButtonHeight;
  end;

  TStyleSystem = class
  private
    FElements: TDictionary<string, TBitmap>;
    FDummy: TBitmap;
    FMetrics: TMetrics;
    procedure SetupDummy();
    procedure InitMetrics();
  public
    constructor Create();
    destructor Destroy(); override;
    procedure LoadElements(AFolder: string);
    function GetElement(AName: string): TBitmap;
    procedure PaintElement(ADC: HDC; ARect: TRect; AElementName: string; AAlpha: Byte = 255);
    procedure PaintTileElement(ADC: HDC; ARect, ATile: TRect; AElement: TBitmap; AAlpha: Byte = 255);
    property Metrics: TMetrics read FMetrics write FMetrics;
  end;

var
  StyleSystem: TStyleSystem;

const
  DCX_USERSTYLE = $10000;

implementation

uses
  IOUtils, Math;

{ TStyleSystem }

constructor TStyleSystem.Create;
begin
  FElements := TDictionary<string, TBitmap>.Create();
  FDummy := TBitmap.Create();// TPngImage.CreateBlank(COLOR_RGBALPHA, 8, 128, 128);
  FMetrics := TMetrics.Create();
  SetupDummy();
  InitMetrics();
end;

destructor TStyleSystem.Destroy;
begin
  FElements.Free;
  FMetrics.Free;
  inherited;
end;

function TStyleSystem.GetElement(AName: string): TBitmap;
var
  LResult: TBitmap;
begin
  Result := FDummy;
  if FElements.TryGetValue(AName, LResult) then
  begin
    Result := LResult;
  end;
end;

procedure TStyleSystem.InitMetrics;
begin
  FMetrics.FrameSize := 16;// GetSystemMetrics(SM_CYSIZEFRAME);
  FMetrics.FHeaderHeight := 22 + FMetrics.FrameSize;
  FMetrics.FormButtonWidth := 24;
  FMetrics.FormButtonHeight := 24;
end;

procedure TStyleSystem.LoadElements(AFolder: string);
var
  LFiles: TStringDynArray;
  LFile, LName: string;
  LGraphic: TBitmap;
begin
  FElements.Clear();
  LFiles := TDirectory.GetFiles(AFolder);
  for LFile in LFiles do
  begin
    if SameText('.bmp', ExtractFileExt(LFile)) then
    begin
      LGraphic := TBitmap.Create();
      try
        LName := ChangeFileExt(ExtractFileName(LFile), '');
        LGraphic.LoadFromFile(LFile);
      finally
        FElements.Add(LName, LGraphic);
      end;
    end;
  end;
end;

procedure TStyleSystem.PaintElement(ADC: HDC; ARect: TRect;
  AElementName: string; AAlpha: Byte = 255);
var
  LElement: TBitmap;
begin
  LElement := GetElement(AElementName);
  PaintTileElement(ADC, ARect, Rect(0, 0, Lelement.Width, LElement.Height), LElement);
end;

procedure TStyleSystem.PaintTileElement(ADC: HDC; ARect, ATile: TRect;
  AElement: TBitmap; AAlpha: Byte);
var
  LFunc: _BLENDFUNCTION;
begin
  LFunc.BlendOp := AC_SRC_OVER;
  LFunc.BlendFlags := 0;
  LFunc.AlphaFormat := AC_SRC_ALPHA;
  LFunc.SourceConstantAlpha := AAlpha;
  StretchBlt(ADC, ARect.Left, ARect.Top, ARect.Right-ARect.Left, ARect.Bottom-ARect.Top,
    AELement.Canvas.Handle, ATile.Left, ATile.Top, Min(ATile.Right, AElement.Width), Min(ATile.Bottom, AElement.Height), SRCCOPY);
//  AlphaBlend(ADC, ARect.Left, ARect.Top, ARect.Right-ARect.Left, ARect.Bottom-ARect.Top,
//    LELement.Canvas.Handle, 0, 0, LELement.Width, LELement.Height, LFunc);
end;

procedure TStyleSystem.SetupDummy;
begin
  FDummy.SetSize(128, 128);
  FDummy.Canvas.Brush.Color := clFuchsia;
  FDummy.Canvas.FillRect(FDummy.Canvas.ClipRect);
end;

initialization
  StyleSystem := TStyleSystem.Create();

finalization
  StyleSystem.Free;

end.
