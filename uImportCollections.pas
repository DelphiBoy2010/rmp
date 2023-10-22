unit uImportCollections;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB, Vcl.Grids, Vcl.StdCtrls,
  Vcl.DBGrids, RMP.Ctrls.FontButton, Vcl.ExtCtrls, rmpro.restAPI,
  Datasnap.DBClient, Vcl.ComCtrls;
const
  C_sectorId = '64746bd16c02fc65d2d50add';  //dev
  C_API_url = 'https://apidev.pimflare.com/v1';//dev
  C_token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6Ij'
    +'Y1MjNhM2JkYTRjMThkNjYxNWQ3NDQzYSIsInRlYW1JZCI6IjY1MjNhM2JkYTRjMThkNjYxNWQ3ND'
    +'QzYiIsImVtYWlsIjoicGF0cmljay5hQHBpbWZsYXJlLmNvbSIsInJvbGUiOiJjdXN0b21lciIsI'
    +'mlzVGVhbU93bmVyIjp0cnVlLCJpYXQiOjE2OTc4ODI3NjEsImV4cCI6MTY5ODc0Njc2MX0.Hbu29_jP5J-bDEnRm6GFNazlv79Hx-umDKFj0U66MS8';

//  C_API_url = 'https://apidemo.pimflare.com/v1';//demo
//  C_sectorId = '648456cfcffef72e58d29831'; //demo
//  C_token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY1MjRlODJhYmRjOTBmNT'
//    +'YzOTE0NTgzMyIsInRlYW1JZCI6IjY1MjRlODJhYmRjOTBmNTYzOTE0NTgzNCIsImVt'
//    +'YWlsIjoicGF0cmljay5hQHBpbWZsYXJlLmNvbSIsInJvbGUiOiJjdXN0b21lciIsImlzVG'
//    +'VhbU93bmVyIjp0cnVlLCJpYXQiOjE2OTcyOTIyMTQsImV4cCI6MTY5ODE1NjIxNH0.P2vYeAgG085EPxrzsXfCgsM91yA8dQxeF_pVaqcVGzw';

type
  ImportModeType = (imPim, imExcel);
  TfrmImportCollections = class(TForm)
    DS1: TDataSource;
    ClientDataSet1: TClientDataSet;
    PageControl1: TPageControl;
    pgGateway: TTabSheet;
    pgSelectVendor: TTabSheet;
    pgData: TTabSheet;
    btnExcelFile: TButton;
    btnPimAPI: TButton;
    Panel1: TPanel;
    Label1: TLabel;
    Panel2: TPanel;
    Panel3: TPanel;
    btnNext2: TButton;
    btnBack2: TButton;
    Panel4: TPanel;
    btnBack3: TButton;
    cbVendors: TComboBox;
    btnLoadVendors: TFontButton;
    Panel5: TPanel;
    Label2: TLabel;
    Panel6: TPanel;
    Label3: TLabel;
    DBGrid1: TDBGrid;
    panBottom: TPanel;
    btnImport: TFontButton;
    Memo1: TMemo;
    lblPages: TLabel;
    btnLoadNextPage: TButton;
    btnLoadPreviousPage: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnLoadVendorsClick(Sender: TObject);
    procedure btnImportClick(Sender: TObject);
    procedure btnPimAPIClick(Sender: TObject);
    procedure btnExcelFileClick(Sender: TObject);
    procedure btnBack2Click(Sender: TObject);
    procedure btnNext2Click(Sender: TObject);
    procedure btnBack3Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnLoadNextPageClick(Sender: TObject);
    procedure btnLoadPreviousPageClick(Sender: TObject);
  private
    { Private declarations }
    FRestAPI: TRestAPI;
    FImportMode: ImportModeType;
    FDataPage: Integer;
    procedure GridStyle();
    procedure LoadAllData();
    procedure LoadVendorData(aVendoreId: string; aPageIndex: Integer);
    function CreateVendor(aName: string): Integer;
    function CreateCollection(aVendorId: Integer; aCollectionName: string): Integer;
    function CreateDesign(aVendorId: Integer; aDesignName: string): Integer;
    function CreateColor(aColorName: string): Integer;
    function CreateItemType(aTypeName: string): Integer;
    function CreateOrigin(aOrigin: string): Integer;
    function CreateShape(aShape: string): Integer;
    function CreateStyle(aStyle: string): Integer;
    function CreateBrand(aBrand: string): Integer;
    function CreateContent(aContent: string): Integer;
    function CreateSKU(aSkuID, aVendorId, aCollectionID,
      aDesignID, aColorID, aCategoryID, aUnitID, aTypeID,
      aOriginID, aShapeID, aStyleID, aBrandID, aContentID: Integer;
      aSKUName, aSkuWidth, aSkuLength, aMarketCost, aSkuPrice1: string): Integer;
    function GetObjectPK(aTableName, aPKname, aWhere: string): Integer;
    function GetMaterial(aMaterial: string): string;
  public
    { Public declarations }
  end;

var
  frmImportCollections: TfrmImportCollections;

implementation
 uses
 REST.Response.Adapter, System.JSON, REST.Client, uDB, uQuery,
 Globals;
{$R *.dfm}

procedure TfrmImportCollections.btnBack2Click(Sender: TObject);
begin
  PageControl1.ActivePage := pgGateway;
end;

procedure TfrmImportCollections.btnBack3Click(Sender: TObject);
begin
  if FImportMode = imPim then
  begin
    PageControl1.ActivePage := pgSelectVendor;
  end
  else
  begin
    PageControl1.ActivePage := pgGateway;
  end;

end;

procedure TfrmImportCollections.btnExcelFileClick(Sender: TObject);
begin
  FImportMode := imExcel;
  PageControl1.ActivePage := pgData;
end;

procedure TfrmImportCollections.btnImportClick(Sender: TObject);
var
  dataSet: TDataSet;
  vendorName, design, collection, color, itemType, origin, style, sku: string;
  material, shape, brand, skuWidth, skuLength, marketCost, skuPrice1, content: string;
  qry: AQuery;
  vendorID, designID, collectionID, colorID, skuID, categoryID: Integer;
  unitID, typeID, originID, shapeID, styleID, brandID, contentID: Integer;
begin
  dataSet := DBGrid1.DataSource.DataSet;
  dataSet.First;
  while not dataSet.Eof do
  begin
    vendorName := DataSet.FieldByName('teamTitle').AsString;
    collection := DataSet.FieldByName('collection').AsString;
    design := DataSet.FieldByName('design').AsString;
    color := DataSet.FieldByName('color').AsString;
    sku := DataSet.FieldByName('sku').AsString;
    itemType := DataSet.FieldByName('construction').AsString;
    origin := DataSet.FieldByName('origin').AsString;
    material := DataSet.FieldByName('material').AsString;
    shape := DataSet.FieldByName('shape').AsString;
    style := DataSet.FieldByName('style').AsString;
    brand := DataSet.FieldByName('brand').AsString;
    skuWidth := DataSet.FieldByName('width').AsString;
    skuLength := DataSet.FieldByName('length').AsString;
    marketCost := DataSet.FieldByName('baseCost').AsString;
    skuPrice1 := DataSet.FieldByName('marketPrice').AsString;
    categoryID := 107;
    unitID := 138;

    content := GetMaterial(material);
    qry := AQuery.Create(qManual);
    try
      //Add vendor
      qry.SQL.Text := 'SELECT * FROM Vendor WHERE CompanyName=' + QuotedStr(vendorName);
      qry.Open;
      if qry.IsEmpty then
      begin
        vendorID := CreateVendor(vendorName);
      end
      else
      begin
        vendorID := qry.FieldByName('id').AsInteger;
      end;
      //add collection
      qry.Close;
      qry.SQL.Text := 'SELECT * FROM Collection WHERE VendorId=' + vendorId.ToString
        + ' and Collection='+ QuotedStr(collection);
      qry.Open;
      if qry.IsEmpty then
      begin
        collectionID := CreateCollection(vendorID, collection);
      end
      else
      begin
        collectionID := qry.FieldByName('id').AsInteger;
      end;
      //add design
      qry.Close;
      qry.SQL.Text := 'SELECT * FROM DesignCode WHERE Val=' + QuotedStr(design);
      qry.Open;
      if qry.IsEmpty then
      begin
        designID := CreateDesign(vendorID, design);
      end
      else
      begin
        designID := qry.FieldByName('id').AsInteger;
      end;
      //add color
      qry.Close;
      qry.SQL.Text := 'SELECT * FROM SysTables WHERE Flt = 8 and Val=' + QuotedStr(color);
      qry.Open;
      if qry.IsEmpty then
      begin
        colorID := CreateColor(color);
      end
      else
      begin
        colorID := qry.FieldByName('id').AsInteger;
      end;
      //add type
      qry.Close;
      qry.SQL.Text := 'SELECT * FROM SysTables WHERE Flt = 14 and Val=' + QuotedStr(itemType);
      qry.Open;
      if qry.IsEmpty then
      begin
        typeID := CreateItemType(itemType);
      end
      else
      begin
        typeID := qry.FieldByName('id').AsInteger;
      end;
      //add origin
      qry.Close;
      qry.SQL.Text := 'SELECT * FROM SysTables WHERE Flt = 11 and Val=' + QuotedStr(origin);
      qry.Open;
      if qry.IsEmpty then
      begin
        originID := CreateOrigin(origin);
      end
      else
      begin
        originID := qry.FieldByName('id').AsInteger;
      end;
      //add shape
      qry.Close;
      qry.SQL.Text := 'SELECT * FROM SysTables WHERE Flt = 30 and Val=' + QuotedStr(shape);
      qry.Open;
      if qry.IsEmpty then
      begin
        shapeID := CreateShape(shape);
      end
      else
      begin
        shapeID := qry.FieldByName('id').AsInteger;
      end;
      //add style
      qry.Close;
      qry.SQL.Text := 'SELECT * FROM SysTables WHERE Flt = 31 and Val=' + QuotedStr(style);
      qry.Open;
      if qry.IsEmpty then
      begin
        styleID := CreateStyle(style);
      end
      else
      begin
        styleID := qry.FieldByName('id').AsInteger;
      end;
      //add brand
      qry.Close;
      qry.SQL.Text := 'SELECT * FROM SysTables WHERE Flt = 34 and Val=' + QuotedStr(brand);
      qry.Open;
      if qry.IsEmpty then
      begin
        brandID := CreateBrand(brand);
      end
      else
      begin
        brandID := qry.FieldByName('id').AsInteger;
      end;
      //add content
      qry.Close;
      qry.SQL.Text := 'SELECT * FROM SysTables WHERE Flt = 12 and Val=' + QuotedStr(content);
      qry.Open;
      if qry.IsEmpty then
      begin
        contentID := CreateContent(content);
      end
      else
      begin
        contentID := qry.FieldByName('id').AsInteger;
      end;
      //add sku
      qry.Close;
      qry.SQL.Text := 'SELECT * FROM sku WHERE Vendor=' + vendorId.ToString
        + ' and sku='+ QuotedStr(sku);
      qry.Open;
      if qry.IsEmpty then
      begin
        skuID := -1;
      end
      else
      begin
        skuID := qry.FieldByName('id').AsInteger;
      end;

      skuID := CreateSKU(skuID, vendorId, collectionID, designID, colorID,
        categoryID, unitID, typeID, originID, shapeID, styleID,
        brandID, contentID, sku, skuWidth, skuLength, marketCost, skuPrice1);
    finally
      qry.Free;
    end;

    dataSet.Next;
  end;

  ShowMessage(dataSet.RecordCount.ToString + ' items have been imported');
end;

procedure TfrmImportCollections.btnLoadNextPageClick(Sender: TObject);
var
  vendorId: string;
begin
  vendorId := string(cbVendors.Items.Objects[cbVendors.ItemIndex]);
  Inc(FDataPage);
  LoadVendorData(vendorId, FDataPage);
end;

procedure TfrmImportCollections.btnLoadPreviousPageClick(Sender: TObject);
var
  vendorId: string;
begin
  vendorId := string(cbVendors.Items.Objects[cbVendors.ItemIndex]);
  Dec(FDataPage);
  if FDataPage < 1 then
    FDataPage := 1;
  LoadVendorData(vendorId, FDataPage);
end;

procedure TfrmImportCollections.btnLoadVendorsClick(Sender: TObject);
var
  payload: string;
  res: string;
  ds: TDataset;
  DataSetAdapter: TRESTResponseDataSetAdapter;
  response: TJSONValue;
  DataArray: TJSONArray;
  I: Integer;
  title: string;
  id: string;
begin
  ds := nil;
  payload := '';
  res := FRestAPI.Select('/teams', payload, ds);
  response := TJSONObject.ParseJSONValue(res);
  DataArray := response.GetValue<TJSONArray>('data');
  for I := 0 to DataArray.Count - 1 do
  begin
    if DataArray.Items[I].TryGetValue<string>('title', title) then
    begin
      cbVendors.AddItem(DataArray.Items[I].GetValue<string>('title'),
        TObject(DataArray.Items[I].GetValue<string>('id')));
    end;
  end;
  Memo1.Text := res;
  //GridStyle();
end;

procedure TfrmImportCollections.btnNext2Click(Sender: TObject);
var
  vendorId: string;
begin
  if cbVendors.ItemIndex > 0 then
  begin
    PageControl1.ActivePage := pgData;
    vendorId := string(cbVendors.Items.Objects[cbVendors.ItemIndex]);
    LoadVendorData(vendorId, 1);
  end
  else
  begin
    ShowMessage('Please select a vendor');
  end;
end;

procedure TfrmImportCollections.btnPimAPIClick(Sender: TObject);
begin
  FImportMode := imPim;
  PageControl1.ActivePage := pgSelectVendor;
end;

function TfrmImportCollections.CreateBrand(aBrand: string): Integer;
var
  qry: AQuery;
begin
  qry := AQuery.Create(qMANUAL);
  try
    qry.Kind:= qINSERT;
    qry.Addtable('SysTables', '');
    qry.AddField('Id',UniqId('SysTables'), False);
    qry.AddField('Flt',34, False);
    qry.AddField('Val',aBrand, True);
    qry.AddField('User_id',UserId, False);
    qry.ExecSQL;

    Result := GetObjectPK('SysTables', 'id', 'Flt=34'
      + ' and Val=' + QuotedStr(aBrand));
  finally
    qry.Free;
  end;

end;

function TfrmImportCollections.CreateCollection(aVendorId: Integer;
  aCollectionName: string): Integer;
var
  qry: AQuery;
begin
  qry := AQuery.Create(qMANUAL);
  try
    qry.Kind:= qINSERT;
    qry.Addtable('Collection', '');
    qry.AddField('Id',UniqId('Collection'), False);
    qry.AddField('VendorId',aVendorId, False);
    qry.AddField('Collection',aCollectionName, True);
    qry.AddField('User_id',UserId, False);
    qry.ExecSQL;

    Result := GetObjectPK('Collection', 'id', 'VendorId='+aVendorId.ToString
      + ' and Collection=' + QuotedStr(aCollectionName));
  finally
    qry.Free;
  end;

end;

function TfrmImportCollections.CreateColor(aColorName: string): Integer;
var
  qry: AQuery;
begin
  qry := AQuery.Create(qMANUAL);
  try
    qry.Kind:= qINSERT;
    qry.Addtable('SysTables', '');
    qry.AddField('Id',UniqId('SysTables'), False);
    qry.AddField('Flt',8, False);
    qry.AddField('Val',aColorName, True);
    qry.AddField('User_id',UserId, False);
    qry.ExecSQL;

    Result := GetObjectPK('SysTables', 'id', 'Flt=8'
      + ' and Val=' + QuotedStr(aColorName));
  finally
    qry.Free;
  end;

end;

function TfrmImportCollections.CreateContent(aContent: string): Integer;
var
  qry: AQuery;
begin
  qry := AQuery.Create(qMANUAL);
  try
    qry.Kind:= qINSERT;
    qry.Addtable('SysTables', '');
    qry.AddField('Id',UniqId('SysTables'), False);
    qry.AddField('Flt',12, False);
    qry.AddField('Val',aContent, True);
    qry.AddField('User_id',UserId, False);
    qry.ExecSQL;

    Result := GetObjectPK('SysTables', 'id', 'Flt=12'
      + ' and Val=' + QuotedStr(aContent));
  finally
    qry.Free;
  end;
end;

function TfrmImportCollections.CreateDesign(aVendorId: Integer;
  aDesignName: string): Integer;
var
  qry: AQuery;
begin
  qry := AQuery.Create(qMANUAL);
  try
    qry.Kind:= qINSERT;
    qry.Addtable('DesignCode', '');
    qry.AddField('Id',UniqId('DesignCode'), False);
    qry.AddField('VendorId',aVendorId, False);
    qry.AddField('Val',aDesignName, True);
    qry.AddField('User_id',UserId, False);
    qry.ExecSQL;

    Result := GetObjectPK('DesignCode', 'id', 'VendorId='+aVendorId.ToString
      + ' and Val=' + QuotedStr(aDesignName));
  finally
    qry.Free;
  end;

end;

function TfrmImportCollections.CreateItemType(aTypeName: string): Integer;
var
  qry: AQuery;
begin
  qry := AQuery.Create(qMANUAL);
  try
    qry.Kind:= qINSERT;
    qry.Addtable('SysTables', '');
    qry.AddField('Id',UniqId('SysTables'), False);
    qry.AddField('Flt',14, False);
    qry.AddField('Val',aTypeName, True);
    qry.AddField('User_id',UserId, False);
    qry.ExecSQL;

    Result := GetObjectPK('SysTables', 'id', 'Flt=14'
      + ' and Val=' + QuotedStr(aTypeName));
  finally
    qry.Free;
  end;
end;

function TfrmImportCollections.CreateOrigin(aOrigin: string): Integer;
var
  qry: AQuery;
begin
  qry := AQuery.Create(qMANUAL);
  try
    qry.Kind:= qINSERT;
    qry.Addtable('SysTables', '');
    qry.AddField('Id',UniqId('SysTables'), False);
    qry.AddField('Flt',11, False);
    qry.AddField('Val',aOrigin, True);
    qry.AddField('User_id',UserId, False);
    qry.ExecSQL;

    Result := GetObjectPK('SysTables', 'id', 'Flt=11'
      + ' and Val=' + QuotedStr(aOrigin));
  finally
    qry.Free;
  end;

end;

function TfrmImportCollections.CreateShape(aShape: string): Integer;
var
  qry: AQuery;
begin
  qry := AQuery.Create(qMANUAL);
  try
    qry.Kind:= qINSERT;
    qry.Addtable('SysTables', '');
    qry.AddField('Id',UniqId('SysTables'), False);
    qry.AddField('Flt',30, False);
    qry.AddField('Val',aShape, True);
    qry.AddField('User_id',UserId, False);
    qry.ExecSQL;

    Result := GetObjectPK('SysTables', 'id', 'Flt=30'
      + ' and Val=' + QuotedStr(aShape));
  finally
    qry.Free;
  end;
end;

function TfrmImportCollections.CreateSKU(aSkuID, aVendorId, aCollectionID,
  aDesignID, aColorID, aCategoryID, aUnitID, aTypeID, aOriginID, aShapeID,
  aStyleID, aBrandID, aContentID: Integer;
  aSKUName, aSkuWidth, aSkuLength, aMarketCost, aSkuPrice1: string): Integer;
var
  qry: AQuery;
  sql: string;
begin
  qry := AQuery.Create(qMANUAL);
  try
    sql:=
      'ModifySku_Import '+
      ' @id ='+ IntToStr(aSkuID) +#13+
      ',@SKU = '+QuotedStr(aSKUName)+#13+
      ',@Discontinued = '+IntToStr(BoolToInt(False))+#13+
      ',@Vendor =      '+IntToStr(aVendorId)+#13+
      ',@DesignId =    '+IntToStr(aDesignID)+#13+
      ',@DesignCodeId ='+IntToStr(aDesignID)+#13+
      ',@CollectionID = '+IntToStr(aCollectionID)+#13+
      ',@SkuBkgrndID = '+IntToStr(aColorID)+#13+
      ',@Category =    '+IntToStr(aCategoryID)+#13+
      ',@UnitId =      '+IntToStr(aUnitID)+#13+
      ',@TypeId =      '+IntToStr(aTypeID)+#13+
      ',@OriginId =    '+IntToStr(aOriginID)+#13+
      ',@ShapeID =     '+IntToStr(aShapeID)+#13+
      ',@StyleID =     '+IntToStr(aStyleID)+#13+
      ',@BrandID =     '+IntToStr(aBrandID)+#13+
      ',@SkuWidth =    '+ aSkuWidth +#13+
      ',@SkuLength =   '+ aSkuLength+#13+
      ',@MarketCost =  '+DeformatMoney(aMarketCost)+#13+
      ',@SkuPrice1 =   '+DeformatMoney(aSkuPrice1)+#13+
      ',@Contentid =   '+IntToStr(aContentID)+#13+
      ',@User_Id =     '+IntToStr(UserId)+#13;
//      ',@IsImage =     ''N'''+#13+
//      ',@ConditionId = '+IntToStr(cmbCondition.ID)+#13+
//      ',@SubStyleID =  '+IntToStr(cmbSubStyle.ID)+#13+
//      ',@QualityID =   '+IntToStr(cmbQuality.ID)+#13+
//      ',@Uniqum = '''+BoolToStr(chkUniqum.Checked)+''''+#13+
//      ',@ImageFile =   '+QuotedStr(SKUImage)+#13+
//      sql:= sql +
//         ',@CollectionID = '+IntToStr(aCollectionID)+#13+
//         ',@UPC = '+         UPC_To_Val(edUPC.Text)+#13+
//         ',@SkuBorderID = '+IntToStr(cmbSkuBorder.Id)+#13+
//         ',@Reorder_Lvl = '+IntToStr(edtReordLvl.Value)+#13+
//         ',@Desired_Lvl = '+IntToStr(edtDesirLvl.Value)+#13;
//      sql:= sql + ',@SkuWeight = '+IntToStr(edSKUWeight.Value)+#13;
//      sql:= sql +
//         ',@UnitPrice = '+DeformatMoney(edUnitPrice.Text)+#13+
//      sql:= sql +

//         ',@SkuPrice2 = '+DeformatMoney(edSkuPrice2.Text)+#13;
    qry.SQL.Text := sql;
    qry.Open;
    Result := qry.FieldByName('Id').AsInteger;
  finally
    qry.Free;
  end;

end;

function TfrmImportCollections.CreateStyle(aStyle: string): Integer;
var
  qry: AQuery;
begin
  qry := AQuery.Create(qMANUAL);
  try
    qry.Kind:= qINSERT;
    qry.Addtable('SysTables', '');
    qry.AddField('Id',UniqId('SysTables'), False);
    qry.AddField('Flt',31, False);
    qry.AddField('Val',aStyle, True);
    qry.AddField('User_id',UserId, False);
    qry.ExecSQL;

    Result := GetObjectPK('SysTables', 'id', 'Flt=31'
      + ' and Val=' + QuotedStr(aStyle));
  finally
    qry.Free;
  end;

end;

function TfrmImportCollections.CreateVendor(aName: string): Integer;
var
  qry: AQuery;
begin
  qry := AQuery.Create(qMANUAL);
  try
    qry.Kind:= qSelect;
    qry.OpenProc('ModifyVendor %d, ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ' +
             '''%s'', ''%s'', ''%s'', ''%s'', ''%s'', %d, ''%s'', ''%s'', ''%s'', ' +
             '''%s'', ''%s'', ''%s'', ''%s''',
             [0, aName, '','', '','', '', '', '', '',
             '', 0, '', 'false','false','', '', 'false', 'false']);

    Result := qry.FieldByName('Id').AsInteger;
  finally
    qry.Free;
  end;
end;

procedure TfrmImportCollections.FormCreate(Sender: TObject);
begin
  FImportMode := imPim;
  FRestAPI := TRestAPI.Create(C_API_url, '', '',C_token, false, false, true);
end;

procedure TfrmImportCollections.FormShow(Sender: TObject);
begin
  PageControl1.ActivePage := pgGateway;
  FDataPage := 1;
end;

function TfrmImportCollections.GetMaterial(aMaterial: string): string;
var
  material: string;
  Index: Integer;
begin
  material := aMaterial.Replace('[', '', [rfReplaceAll, rfIgnoreCase]);
  material := material.Replace(']', '', [rfReplaceAll, rfIgnoreCase]);
  material := material.Replace('"', '', [rfReplaceAll, rfIgnoreCase]);
  index := material.IndexOf(',');
  if index < 0 then
  begin
    Index := material.Length;
  end;
  material := Copy(material, 0, index);
  Index := material.IndexOf('%');
  if index > 0 then
  begin
    Inc(index, 2);
  end;
  material := Copy(material, Index, material.Length);
  Result := Trim(material);
end;

function TfrmImportCollections.GetObjectPK(aTableName, aPKname, aWhere: string): Integer;
var
  qry: AQuery;
begin
  qry := AQuery.Create(qMANUAL);
  try
    qry.Kind:= qMANUAL;
    qry.SQL.Text := 'Select ' + aPKname + ' From '+ aTableName + ' Where ' + aWhere;
    qry.Open;

    Result := qry.FieldByName(aPKname).AsInteger;
  finally
    qry.Free;
  end;
end;

procedure TfrmImportCollections.GridStyle;
var
  I: Integer;
begin
  for I := 0 to DBGrid1.Columns.Count - 1 do
  begin
    DBGrid1.Columns[I].Width := 100;
  end;
end;

procedure TfrmImportCollections.LoadAllData;
var
  payload: string;
  res: string;
  ds: TDataset;
  DataSetAdapter: TRESTResponseDataSetAdapter;
  response: TJSONValue;
begin
  ds := nil;
  ds := nil;
  payload := '{"sectorId": "'+C_sectorId+'",'
              +'"sort":{"createdAt":1, "x":1},"pagination": {"page":1,"perPage":10}}';
  res := FRestAPI.Insert('/products/search', payload, ds);
  response := TJSONObject.ParseJSONValue(res);
  response := response.GetValue<TJSONValue>('data');
  DataSetAdapter := TRESTResponseDataSetAdapter.Create(nil);
  DataSetAdapter.StringFieldSize := 8000;
  DataSetAdapter.Dataset := TDataSet(ClientDataSet1);
  DataSetAdapter.UpdateDataSet(response);
  DataSetAdapter.Active := True;
  Memo1.Text := res;
  GridStyle();
end;

procedure TfrmImportCollections.LoadVendorData(aVendoreId: string; aPageIndex: Integer);
var
  payload: string;
  res: string;
  ds: TDataset;
  DataSetAdapter: TRESTResponseDataSetAdapter;
  response: TJSONValue;
  pages: TJSONValue;
begin
  ds := nil;
  payload := '{"sectorId": "'+C_sectorId+'",'
              +'"sort":{"createdAt":1, "x":1},"pagination": {"page":'+ aPageIndex.ToString+',"perPage":100},'
              +' "filters":[ {"filter":{"teamId": "'+aVendoreId+'"}}]}';
  res := FRestAPI.Insert('/products/search', payload, ds);
  response := TJSONObject.ParseJSONValue(res);

  pages := response.GetValue<TJSONValue>('pages');
  lblPages.Caption := '  Page ' + pages.GetValue<string>('page') + ' of '
    +pages.GetValue<string>('totalPages')
    + ' , (Total Items:'+ pages.GetValue<string>('totalItems') +')  ';

  response := response.GetValue<TJSONValue>('data');
  DataSetAdapter := TRESTResponseDataSetAdapter.Create(nil);
  DataSetAdapter.StringFieldSize := 8000;
  DataSetAdapter.Dataset := TDataSet(ClientDataSet1);
  DataSetAdapter.UpdateDataSet(response);
  DataSetAdapter.Active := True;
  Memo1.Text := res;
  GridStyle();

end;

end.
