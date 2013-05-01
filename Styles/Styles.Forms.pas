unit Styles.Forms;

interface

uses
  Classes, Types, Windows, Messages, Forms;

type
  TForm = class(Forms.TForm)
  private
    FMinimizeRect: TRect;
    FMaximizeRect: TRect;
    FCloseRect: TRect;
    FTopBorderRect: TRect;
    FLeftBorderRect: TRect;
    FRightBorderRect: TRect;
    FBottomBorderRect: TRect;
    FLastHit: Integer;
    procedure NCHitTest(var MSG: TWMNCHitTest); message WM_NCHITTEST;
    procedure NCCalcSize(var MSG: TWMNCCalcSize); message WM_NCCALCSIZE;
    procedure NCLButtonDown(var MSG: TWMNCLButtonDown); message WM_NCLBUTTONDOWN;
    procedure NCLButtonUp(var MSG: TWMNCLButtonUp); message WM_NCLBUTTONUP;
    procedure NCActivate(var MSG: TWMNCActivate); message WM_NCACTIVATE;
    procedure PaintNC(var MSG: TWMNCPaint); message WM_NCPAINT;
    procedure RepaintBorder(ADC: HDC);
    procedure RepaintButtons(ADC: HDC);
    procedure UpdateRects(ANew: TRect);
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

uses
  UxTheme, Styles, Math;

{ TForm }

constructor TForm.Create(AOwner: TComponent);
begin
  inherited;
  Application.ProcessMessages();
  SetWindowTheme(Handle, '', '');
end;

procedure TForm.NCActivate(var MSG: TWMNCActivate);
var
  LDC: HDC;
begin
  if MSG.Unused <> -1 then
  begin
    Canvas.FillRect(Canvas.ClipRect);
    LDC := GetWindowDC(Handle); //GetDCEx(Handle, 0, DCX_WINDOW or DCX_INTERSECTRGN or DCX_USERSTYLE);
    if LDC <> 0 then
    begin
      RepaintBorder(LDC);
      RepaintButtons(LDC);
      ReleaseDC(Handle, LDC);
    end;
  end;
end;

procedure TForm.NCCalcSize(var MSG: TWMNCCalcSize);
var
  LPosRect, LNewClientRect: TRect;
begin
  LPosRect := MSG.CalcSize_Params.rgrc0;
  inherited;
  if MSG.CalcValidRects then
  begin
    LNewClientRect := MSG.CalcSize_Params.rgrc0;
    UpdateRects(LPosRect);
  end;
end;

procedure TForm.NCHitTest(var MSG: TWMNCHitTest);
var
  LDC: HDC;
  LPoint: TPoint;
begin
  inherited;
  case MSG.Result of
    HTMINBUTTON, HTMAXBUTTON, HTCLOSE:
    begin
      MSG.Result := HTCAPTION;
      Exit;
    end;
  end;
  LPoint := Point(MSG.XPos, MSG.YPos);
  LPoint.X := LPoint.X - Left;
  LPoint.Y := LPoint.Y - Top;
  if PtInRect(FTopBorderRect, LPoint) then
  begin
    if PtInRect(FMinimizeRect, LPoint) then
    begin
      MSG.Result := HTMINBUTTON;
      Exit;
    end
    else if PtInRect(FMaximizeRect, LPoint) then
    begin
      MSG.Result := HTMAXBUTTON;
      Exit;
    end
    else if PtInRect(FCloseRect, LPoint) then
    begin
      MSG.Result := HTCLOSE;
      Exit;
    end;
  end;
end;

procedure TForm.NCLButtonDown(var MSG: TWMNCLButtonDown);
begin
  case MSG.HitTest of
    HTMINBUTTON, HTMAXBUTTON, HTCLOSE:
    begin
      FLastHit := MSG.HitTest;
    end;
    else
    begin
      inherited;
    end;
  end;
end;

procedure TForm.NCLButtonUp(var MSG: TWMNCLButtonUp);
begin
  case MSG.HitTest of
    HTCLOSE:
    begin
      if FLastHit = MSG.HitTest then
      PostMessage(Handle, WM_SYSCOMMAND, SC_CLOSE, 0);
    end;

    HTMINBUTTON:
    begin
      if FLastHit = MSG.HitTest then
      PostMessage(Handle, WM_SYSCOMMAND, SC_MINIMIZE, 0);
    end;

    HTMAXBUTTON:
    begin
      if FLastHit = MSG.HitTest then
      begin
        if WindowState = wsMaximized then
        begin
          PostMessage(Handle, WM_SYSCOMMAND, SC_RESTORE, 0);
        end
        else
        begin
          PostMessage(Handle, WM_SYSCOMMAND, SC_MAXIMIZE, 0);
        end;
      end;
    end;
    else
    begin
      inherited;
    end;
  end;
end;

procedure TForm.PaintNC(var MSG: TWMNCPaint);
var
  LDC: HDC;
begin
  Canvas.FillRect(Canvas.ClipRect);
  LDC := GetWindowDC(Handle);
  if LDC <> 0 then
  begin
    RepaintBorder(LDC);
    RepaintButtons(LDC);
    ReleaseDC(Handle, LDC);
  end;
end;

procedure TForm.RepaintBorder(ADC: HDC);
begin
  StyleSystem.PaintElement(ADC, FTopBorderRect, 'Form_Border_Top');
  StyleSystem.PaintElement(ADC, FLeftBorderRect, 'Form_Border_Left');
  StyleSystem.PaintElement(ADC, FRightBorderRect, 'Form_Border_Right');
  StyleSystem.PaintElement(ADC, FBottomBorderRect, 'Form_Border_Bottom');
end;

procedure TForm.RepaintButtons(ADC: HDC);
begin
  StyleSystem.PaintElement(ADC, FMinimizeRect, 'Button_Minimize');
  if WindowState = wsMaximized then
  begin
    StyleSystem.PaintElement(ADC, FMaximizeRect, 'Button_Restore');
  end
  else
  begin
    StyleSystem.PaintElement(ADC, FMaximizeRect, 'Button_Maximize');
  end;
  StyleSystem.PaintElement(ADC, FCloseRect, 'Button_Close');
end;

procedure TForm.UpdateRects;
var
  LWIdth, LHeight: Integer;
begin
  LWidth := ANew.Right - ANew.Left;
  LHeight := ANew.Bottom - ANew.Top;
  FTopBorderRect.Left := 0;
  FTopBorderRect.Top := 0;
  FTopBorderRect.Right := LWidth; //Width+1;
  FTopBorderRect.Bottom := GetSystemMetrics(SM_CYSIZEFRAME) + 22; //Height - ClientHeight - GetSystemMetrics(SM_CYSIZEFRAME);

  FLeftBorderRect.Left := 0;
  FLeftBorderRect.Top := FTopBorderRect.Bottom;
  FLeftBorderRect.Right := GetSystemMetrics(SM_CYSIZEFRAME);
  FLeftBorderRect.Bottom := LHeight - GetSystemMetrics(SM_CYSIZEFRAME);

  FRightBorderRect.Top := FLeftBorderRect.Top;
  FRightBorderRect.Left := LWidth - GetSystemMetrics(SM_CYSIZEFRAME);
  FRightBorderRect.Right := LWidth;// + 1;
  FRightBorderRect.Bottom := LHeight - GetSystemMetrics(SM_CYSIZEFRAME);

  FBottomBorderRect.Left := 0;
  FBottomBorderRect.Right := LWidth;// + 1;
  FBottomBorderRect.Top := LHeight - GetSystemMetrics(SM_CYSIZEFRAME);
  FBottomBorderRect.Bottom := LHeight;

  FMinimizeRect.Left := 20;
  FMinimizeRect.Right := FMinimizeRect.Left + 24;
  FMinimizeRect.Top := 2;
  FMinimizeRect.Bottom := FMinimizeRect.Top + 24;

  FMaximizeRect.Left := FMinimizeRect.Right + 5;
  FMaximizeRect.Right := FMaximizeRect.Left + 24;
  FMaximizeRect.Top := 2;
  FMaximizeRect.Bottom := FMaximizeRect.Top + 24;

  FCloseRect.Left := FMaximizeRect.Right + 5;
  FCloseRect.Right := FCloseRect.Left + 24;
  FCloseRect.Top := 2;
  FCloseRect.Bottom := FCloseRect.Top + 24;
end;

end.
