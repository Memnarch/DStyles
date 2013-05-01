unit Styles.Forms;

interface

uses
  Classes, Types, Windows, Messages, Forms, Graphics;

type
  TButtonState = (bsNormal, bsHover, bsPressed);

  TForm = class(Forms.TForm)
  private
    FMinimizeRect: TRect;
    FMaximizeRect: TRect;
    FCloseRect: TRect;
    FMinState: TButtonState;
    FMaxState: TButtonState;
    FCloseState: TButtonState;
    FTopBorderRect: TRect;
    FLeftBorderRect: TRect;
    FRightBorderRect: TRect;
    FBottomBorderRect: TRect;
    FLastHit: Integer;
    procedure NCMouseMove(var MSG: TWMNCMouseMove); message WM_NCMOUSEMOVE;
    procedure HandleMouseLeave();
    procedure NCHitTest(var MSG: TWMNCHitTest); message WM_NCHITTEST;
    procedure NCCalcSize(var MSG: TWMNCCalcSize); message WM_NCCALCSIZE;
    procedure NCLButtonDown(var MSG: TWMNCLButtonDown); message WM_NCLBUTTONDOWN;
    procedure NCLButtonUp(var MSG: TWMNCLButtonUp); message WM_NCLBUTTONUP;
    procedure NCActivate(var MSG: TWMNCActivate); message WM_NCACTIVATE;
    procedure PaintNC(var MSG: TWMNCPaint); message WM_NCPAINT;
    procedure RepaintBorder(ADC: HDC);
    procedure RepaintButtons(ADC: HDC);
    procedure UpdateRects(ANew: TRect);
    procedure UpdateButtons();
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

uses
  uxTheme, Styles, Math;

{ TForm }

constructor TForm.Create(AOwner: TComponent);
begin
  inherited;
  BorderIcons := BorderIcons - [biSystemMenu];
  FLastHit := -1;
  Application.ProcessMessages();
  SetWindowTheme(Handle, '', '');
end;

procedure TForm.NCActivate(var MSG: TWMNCActivate);
var
  LDC: HDC;
begin
  if MSG.Unused <> -1 then
  begin
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
  LPoint: TPoint;
  LUpdatedButtons: Boolean;
begin
  LUpdatedButtons := (not ((FMinState = FMaxState) and (FMinState = FCloseState))) and (FLastHit = -1);
  if LUpdatedButtons then
  begin
    FMinState := bsNormal;
    FMaxState := bsNormal;
    FCloseState := bsNormal;
  end;

  inherited;
  case MSG.Result of
    HTMINBUTTON, HTMAXBUTTON, HTCLOSE:
    begin
      MSG.Result := HTCAPTION;
      if LUpdatedButtons then
      begin
        UpdateButtons();
      end;
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
      if FLastHit = -1 then
      begin
        FMinState := bsHover;
        UpdateButtons();
      end;
      Exit;
    end
    else if PtInRect(FMaximizeRect, LPoint) then
    begin
      MSG.Result := HTMAXBUTTON;
      if FLastHit = -1 then
      begin
        FMaxState := bsHover;
        UpdateButtons();
      end;
      Exit;
    end
    else if PtInRect(FCloseRect, LPoint) then
    begin
      MSG.Result := HTCLOSE;
      if FLastHit = -1 then
      begin
        FCloseState := bsHover;
        UpdateButtons();
      end;
      Exit;
    end
    else if LUpdatedButtons then
    begin
      UpdateButtons();
    end;
  end;
end;

procedure TForm.NCLButtonDown(var MSG: TWMNCLButtonDown);
begin
  case MSG.HitTest of
    HTMINBUTTON, HTMAXBUTTON, HTCLOSE:
    begin
      FLastHit := MSG.HitTest;
      case MSG.HitTest of
        HTMINBUTTON:
        begin
          FMinState := bsPressed;
        end;

        HTMAXBUTTON:
        begin
          FMaxState := bsPressed;
        end;

        HTCLOSE:
        begin
          FCloseState := bsPressed;
        end;
      end;
      UpdateButtons();
    end;
    else
    begin
      FLastHit := -1;
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
  FLastHit := -1;
end;

procedure TForm.HandleMouseLeave;
begin
  FMinState := bsNormal;
  FMaxState := bsNormal;
  FCloseState := bsNormal;
  FLastHit := -1;
  UpdateButtons();
end;

procedure TForm.NCMouseMove(var MSG: TWMNCMouseMove);
begin
  if (FLastHit <> -1) and (MSG.HitTest <> FLastHit) then
  begin
    HandleMouseLeave();
  end;
end;

procedure TForm.PaintNC(var MSG: TWMNCPaint);
var
  LDC: HDC;
begin
  LDC := GetWindowDC(Handle);
  if LDC <> 0 then
  begin
    RepaintBorder(LDC);
    RepaintButtons(LDC);
    ReleaseDC(Handle, LDC);
  end;
end;

procedure TForm.RepaintBorder(ADC: HDC);
var
  LELement: TBitmap;
begin
  LELement := StyleSystem.GetElement('Form_Border_Top');
  //left corner
  StyleSystem.PaintTileElement(ADC, Rect(FTopBorderRect.Left, FTopBorderRect.Top, FTopBorderRect.Left +8, FTopBorderRect.Bottom),
    Rect(0,0, 8, FTopBorderRect.Bottom), LELement);
  //center piece
  StyleSystem.PaintTileElement(ADC, Rect(FTopBorderRect.Left+8, FTopBorderRect.Top, FTopBorderRect.Right-8, FTopBorderRect.Bottom),
    Rect(8,0, LELement.Width-16, FTopBorderRect.Bottom), LELement);
  //right corner
  StyleSystem.PaintTileElement(ADC, Rect(FTopBorderRect.Right-8, FTopBorderRect.Top, FTopBorderRect.Right, FTopBorderRect.Bottom),
    Rect(LELement.Width-8,0, 8, FTopBorderRect.Bottom), LELement);

  StyleSystem.PaintElement(ADC, FLeftBorderRect, 'Form_Border_Left');
  StyleSystem.PaintElement(ADC, FRightBorderRect, 'Form_Border_Right');
  LELement := StyleSystem.GetElement('Form_Border_Bottom');
  //left corner
  StyleSystem.PaintTileElement(ADC, Rect(FBottomBorderRect.Left, FBottomBorderRect.Top, FBottomBorderRect.Left+8, FBottomBorderRect.Bottom),
  Rect(0, 0, 8, 8), LELement);
  //center part
  StyleSystem.PaintTileElement(ADC, Rect(FBottomBorderRect.Left+8, FBottomBorderRect.Top, FBottomBorderRect.Right-8, FBottomBorderRect.Bottom),
  Rect(8, 0, LELement.Width-16, 8), LELement);
  //Right corner corner
  StyleSystem.PaintTileElement(ADC, Rect(FBottomBorderRect.Right-8, FBottomBorderRect.Top, FBottomBorderRect.Right, FBottomBorderRect.Bottom),
  Rect(LELement.Width-8, 0, 8, 8), LELement);
end;

procedure TForm.RepaintButtons(ADC: HDC);
begin
  case FMinState of
    bsNormal: StyleSystem.PaintElement(ADC, FMinimizeRect, 'Button_Minimize');
    bsHover: StyleSystem.PaintElement(ADC, FMinimizeRect, 'Button_Minimize_Hover');
    bsPressed: StyleSystem.PaintElement(ADC, FMinimizeRect, 'Button_Minimize_Pressed');
  end;

  if WindowState = wsMaximized then
  begin
    case FMaxState of
      bsNormal: StyleSystem.PaintElement(ADC, FMaximizeRect, 'Button_Restore');
      bsHover: StyleSystem.PaintElement(ADC, FMaximizeRect, 'Button_Restore_Hover');
      bsPressed: StyleSystem.PaintElement(ADC, FMaximizeRect, 'Button_Restore_Pressed');
    end;
  end
  else
  begin
    case FMaxState of
      bsNormal: StyleSystem.PaintElement(ADC, FMaximizeRect, 'Button_Maximize');
      bsHover: StyleSystem.PaintElement(ADC, FMaximizeRect, 'Button_Maximize_Hover');
      bsPressed: StyleSystem.PaintElement(ADC, FMaximizeRect, 'Button_Maximize_Pressed');
    end;
  end;

  case FCloseState of
    bsNormal: StyleSystem.PaintElement(ADC, FCloseRect, 'Button_Close');
    bsHover: StyleSystem.PaintElement(ADC, FCloseRect, 'Button_Close_Hover');
    bsPressed: StyleSystem.PaintElement(ADC, FCloseRect, 'Button_Close_Pressed');
  end;
end;

procedure TForm.UpdateButtons;
var
  LDC: HDC;
begin
  LDC := GetWindowDC(Handle);
  if LDC <> 0 then
  begin
    RepaintButtons(LDC);
    ReleaseDC(Handle, LDC);
  end;
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
