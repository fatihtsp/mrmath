inherited mrMathMtxViewerFrame: TmrMathMtxViewerFrame
  inherited MessageLabel: TLabel
    Visible = True
  end
  object pnlProperties: TPanel
    Left = 0
    Top = 312
    Width = 439
    Height = 57
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
    object lblCapWidth: TLabel
      Left = 24
      Top = 3
      Width = 28
      Height = 13
      Caption = 'Width'
    end
    object lblCapHeight: TLabel
      Left = 24
      Top = 27
      Width = 31
      Height = 13
      Caption = 'Height'
    end
    object lblWidth: TLabel
      Left = 71
      Top = 3
      Width = 15
      Height = 13
      Caption = '---'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblHeight: TLabel
      Left = 71
      Top = 27
      Width = 15
      Height = 13
      Caption = '---'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblCapSubWidth: TLabel
      Left = 128
      Top = 3
      Width = 44
      Height = 13
      Caption = 'Subwidth'
    end
    object lblSubHeight: TLabel
      Left = 182
      Top = 27
      Width = 15
      Height = 13
      Caption = '---'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblSubWidth: TLabel
      Left = 182
      Top = 3
      Width = 15
      Height = 13
      Caption = '---'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblCapSubHeight: TLabel
      Left = 128
      Top = 27
      Width = 48
      Height = 13
      Caption = 'Subheight'
    end
    object lblCapLineWidth: TLabel
      Left = 248
      Top = 3
      Width = 88
      Height = 13
      Caption = 'Row width (bytes)'
    end
    object lblLineWidth: TLabel
      Left = 360
      Top = 3
      Width = 15
      Height = 13
      Caption = '---'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object btnConfigure: TSpeedButton
      Left = 408
      Top = 32
      Width = 23
      Height = 22
      Flat = True
      Glyph.Data = {
        36030000424D3603000000000000360000002800000010000000100000000100
        18000000000000030000130B0000130B00000000000000000001FF00FFFF00FF
        FF00FFFF00FFFF00FFFF00FF00669A00669A00669AFF00FFFF00FFFF00FFFF00
        FFFF00FFFF00FFFF00FFFF00FFFF00FF00669A00669A00669A00669A036B9D07
        73A2046E9F00669A00669A00669A00669AFF00FFFF00FFFF00FFFF00FFFF00FF
        00669A067FAF0478AA0472A40D84AF29BDE4269EC4046E9F01689B046E9F0066
        9AFF00FFFF00FFFF00FFFF00FF00669A1583AD50BADA2A9FC4138BB620C5EE23
        D5FE52D9F92392B945A4C577C2DA258FB500669AFF00FFFF00FF00669A0B9FCE
        329BBF8CE9FF6EE3FF4FDDFE31D7FE1AD3FE42DBFE79E6FFA5EEFF9BECFF26A3
        CA026B9E00669AFF00FF00669A60B3CF81CEE498ECFF7AE6FF5BE0FE4CCCE918
        D2FE1CD3FE1AD3FE10D1FE10D1FE10CCF910BDE900669AFF00FF00669AA6DFEF
        C1F4FFA4EEFF86E8FF86A5ACA5A5A59A99999CA0A355B3CA10D1FE10D1FE10D1
        FE10D1FE00669AFF00FF00669A60B3CFC7F5FFB0F0FF94CFDC8B8B8BCDCCCCA5
        A2A2C0ACAC8B8B8B3DC3E348DCFE77E5FF49B4D400669AFF00FF00669A00669A
        BDEEFABCF2FF9DD6E38B8B8BCDCCCCA5A2A2C0ACAC8B8B8B7CB9C791EAFFAAE5
        F400669A00669AFF00FFFF00FFFF00FF00669AC5F4FFA6D8E38B8B8BCDCCCCA5
        A2A2C0ACAC8B8B8B71B7C77BE6FF00669AFF00FFFF00FFFF00FFFF00FFFF00FF
        00669A00669A00669A8B8B8BCDCCCCA5A2A2C0ACAC8B8B8B00669A00669A0066
        9AFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF8B8B8BD4D2D2A0
        9E9EC3ADAD8B8B8BFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF
        FF00FFFF00FFFF00FF8B8B8B9594948D8D8D9593938B8B8BFF00FFFF00FFFF00
        FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF8B8B8BDFDEDEAF
        AFAFA7A0A08B8B8BFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF
        FF00FFFF00FFFF00FF8B8B8BFFFFFFD2D1D1A6A6A68B8B8BFF00FFFF00FFFF00
        FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF8B8B8B8B
        8B8B8B8B8BFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF}
      OnClick = btnConfigureClick
    end
    object chkOnlySubMatrix: TCheckBox
      Left = 248
      Top = 26
      Width = 137
      Height = 17
      Caption = 'Show only submatrix'
      TabOrder = 0
      OnClick = chkOnlySubMatrixClick
    end
  end
  object grdData: TDrawGrid
    Left = 0
    Top = 0
    Width = 439
    Height = 312
    Align = alClient
    DefaultColWidth = 48
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goEditing]
    TabOrder = 1
    OnDblClick = grdDataDblClick
    OnDrawCell = grdDataDrawCell
    OnSetEditText = grdDataSetEditText
  end
end
