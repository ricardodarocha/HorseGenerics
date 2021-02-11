unit uProvider.Firedac;

interface

uses
  System.SysUtils,
  System.Classes,
  FireDAC.UI.Intf,
  FireDAC.VCLUI.Wait,
  FireDAC.Stan.Intf,
  FireDAC.Comp.UI,
  FireDAC.Stan.Option,
  FireDAC.Stan.Param,
  FireDAC.Stan.Error,
  FireDAC.DatS,
  FireDAC.Phys.Intf,
  FireDAC.DApt.Intf,
  FireDAC.Stan.Async,
  FireDAC.DApt,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.Phys,
  FireDAC.Comp.Client,
  FireDAC.Comp.DataSet,
  Data.DB,


  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs,
  System.JSON;

type
  TProviderFiredac = class(TDatamodule)
    Wait: TFDGUIxWaitCursor;
    Query: TFDQuery;
    Conexao: TFDConnection;
    Memory: TFDMemTable;
    procedure ConexaoBeforeConnect(Sender: TObject);
    procedure ConexaoAfterConnect(Sender: TObject);
  private
    FStatus: Integer;
    FErro: String;

  public
    function LoadConnection(aJsonObject: TJsonObject): Boolean; overload;
    function LoadConnection(aFilename: TFilename = ''): Boolean; overload;
    function SaveConnection(aFilename: TFilename = ''): Boolean;
    function Get<T: Class, Constructor>(AFiltro: TArray<String> = []; AParams: TArray<Variant> = []; APagina: Integer = 1; APacote: Integer = 50): TDataset;

    function Delete<T: Class, Constructor>(ACampoChave: String; ACodigo: Variant): boolean;
    function Post<T: Class, Constructor>(ADados: TJsonObject; const AMatchCondition: String): TJsonObject;
  published
    property Status: Integer read FStatus;
    property Erro: String read FErro;
  end;

var
  ProviderFiredac: TProviderFiredac;

implementation

uses
  Assis.SQLExtractor,
  Dataset.Serialize;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

{ TProviderFiredac }

procedure TProviderFiredac.ConexaoAfterConnect(Sender: TObject);
begin
  if not FileExists(ChangeFileExt(ParamStr(0), '.ini')) then
    SaveConnection();
end;

procedure TProviderFiredac.ConexaoBeforeConnect(Sender: TObject);
begin
  Conexao.BeforeConnect := nil;
  if Conexao.Connected then
    Exit;

  LoadConnection;
  Conexao.BeforeConnect := ConexaoBeforeConnect;
end;

function TProviderFiredac.LoadConnection(aJsonObject: TJsonObject): Boolean;
var
  VValue: TJSONPair;
begin
  try
    if Conexao.Connected then
      Conexao.Close;
    Conexao.BeforeConnect := nil;
    Conexao.Params.Clear;
      for VValue in AJsonObject do
        Conexao.Params.Add(
          format('%s=%s', [VValue.JsonString.ToString, VValue.JsonValue.ToString]) );

    Conexao.Open();
    Result := Conexao.Connected;
  except
    Result := False;
  end;

end;

function TProviderFiredac.LoadConnection(aFilename: TFilename): Boolean;

begin
  if aFilename = '' then
    aFilename := ChangeFileExt(ParamStr(0), '.ini');

  if not FileExists(aFilename) then
    Exit(False);

  try
    if Conexao.Connected then
      Conexao.Close;
    Conexao.Params.LoadFromFile(aFilename);
    Conexao.BeforeConnect := nil;
    Conexao.Open();
    Result := Conexao.Connected;
  except
    Result := False;
  end;

end;

function TProviderFiredac.SaveConnection(aFilename: TFilename): Boolean;
begin
  if aFilename = '' then
    aFilename := ChangeFileExt(ParamStr(0), '.ini');

  try
    Conexao.Params.SaveToFile(aFilename);
    Result := (FileExists(aFilename));
  except
    result := False;
  end;
end;

function TProviderFiredac.Get<T>(AFiltro: TArray<String>; AParams: TArray<Variant>; APagina: Integer; APacote: Integer): TDataset;
var
  AClasse: T;
  I: Integer;
  QueryTemp: TFdQuery;
begin
  AClasse := T.Create;
  FErro := '';
  FStatus := 503; //Unavailable
  QueryTemp := TFDQuery.Create(self);
  QueryTemp.Connection := Conexao;
  Try
    Try
      QueryTemp.SQL.Text := TSqlExtractor<T>.ExtractSelectSql(AClasse, AFiltro);
      QueryTemp.Params.Prepare(ftInteger, ptInput);
      for I := 0 to Length(AFiltro)-1 do
          QueryTemp.Params.Items[I].Value := AParams[I];

      QueryTemp.FetchOptions.RecsMax := APacote;
      if APacote > 0 then
        QueryTemp.FetchOptions.RecsSkip := APacote * (APagina - 1)
      else
        QueryTemp.FetchOptions.RecsSkip := -1;

      QueryTemp.Open;
      Result := QueryTemp;
      if QueryTemp.RecordCount > 0 then
        FStatus := 200
      else FStatus := 404; //no found
    Except
      on e: Exception do
      begin
        Result := nil;
        if assigned(QueryTemp) then
          FreeAndNil(QueryTemp);
        FStatus := 500;
        FErro := E.Message;
      end;
    End;

  Finally
    FreeAndNil(AClasse);
  End;

end;

function TProviderFiredac.Post<T>(ADados: TJsonObject; const AMatchCondition: String): TJsonObject;
var
  AClasse: T;
  ASql: String;
  Field: TField;
  AErros: TJSONObject;
begin
  AClasse := T.Create;
  try
    try
      ASql := TSqlExtractor<T>.ExtractSelectSql(AClasse);
      Query.SQL.Text := StringReplace(ASql, '/* where não informado */', ' where ' + AMatchCondition, []);

      Query.CachedUpdates := true;
      Query.Open;

      if Query.RecordCount = 0 then
          Query.Insert;

      if Query.RecordCount = 1 then
        Query.Edit;

      if Query.RecordCount > 1 then
        raise Exception.Create('the MatchSQL has returned ' + Query.RecordCount.ToString + ' records. Just first one has been updated');

      Memory.LoadFromJSON(ADados , false);
      for Field in Query.Fields do
      begin
        if Memory.FindField(Field.FieldName) <> nil then
          try
            Field.Value := Memory.FieldByName(Field.FieldName).Value;
          Except on E: Exception do
            begin
              if not assigned(AErros) then
                AErros := TJSONObject.Create;
              AErros.AddPair(TJSONPair.Create(Field.FieldName, E.Message))
            end;

          end;
      end;

      Query.ApplyUpdates(0);

      Result := Query.ToJSONObject();

      if Assigned(AErros) then
        Result.AddPair('', AErros)

      except
        on e: Exception do
          Raise;

    end;
  finally
    FreeAndNil(AClasse);
  end;
end;

function TProviderFiredac.Delete<T>(ACampoChave: String; ACodigo: Variant): boolean;
var
  AClasse: T;
  I: Integer;
  AQuery: TFDQuery;
begin
  AClasse := T.Create;
  AQuery := TFDQuery.Create(self);
  AQuery.Connection := Conexao;
  Try
    Try
      AQuery.SQL.Text := TSqlExtractor<T>.ExtractDeleteSql(AClasse, [ACampoChave]);

      if AQuery.FindParam(ACampoChave) <> nil then
         AQuery.ParamByName(ACampoChave).Value := ACodigo;

      AQuery.ExecSQL;
      Result := True;
      FreeAndnil(AQuery);
    Except
      if assigned(AQuery) then
        FreeAndNil(AQuery);
      Result := False;
    End;

  Finally
    FreeAndNil(AClasse);
  End;
end;


end.
