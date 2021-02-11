unit uController.ORM;

interface

uses
  System.Generics.Collections,
  FireDAC.Comp.Client, Data.DB, System.SysUtils;

type

TOrmGarbageCollector = class

  constructor create;
  destructor destory;
  private
    FObjects: TObjectlist<TObject>;
    procedure SetObjects(const Value: TObjectlist<TObject>);

  published

  procedure Inspect(AObject: TObject);
  property Objects: TObjectlist<TObject> read FObjects write SetObjects;
end;

TOrmController = class
  class var FGarbageCollector: TOrmGarbageCollector;
  class function Open<T: class, constructor>(AConexao: TFdConnection; AFiltros: TArray<String>; AValores: Array of variant):T; overload;
  class function Open<T: class, constructor>(AConexao: TFdConnection; AFiltros: TDictionary<String, String>):T; overload;

  class function List<T: class, constructor>(AConexao: TFdConnection; AFiltros: TArray<String>; AValores: Array of variant):TObjectList<T>; overload;
  class function List<T: class, constructor>(AConexao: TFdConnection; AFiltros: TDictionary<String, String>):TObjectList<T>; overload;

  class procedure Post<T: class, constructor>(AConexao: TFdConnection; AObjeto: T; ACodigo: Integer = -1); overload;
  class procedure Post<T: class, constructor>(AConexao: TFdConnection; ALista: TObjectList<T>; ACodigo: Integer = -1); overload;
  class procedure Delete<T>(AConexao: TFdConnection; ATabela: String; ACodigo: Integer);

  class procedure Iterate(ADataset: Tdataset; AProc: TProc<TDataset>);
  private

    class procedure ReadDataset<T: Class>(aDataset: TDataset; var aInstance: T); static;
    class procedure WriteDataset<T: Class>(var aInstance: T; var aDataset: TDataset); static;

end;

implementation

uses

  Assis.SQLExtractor,
  Assis.RttiInterceptor,
  System.Rtti;

{ TOrmController }

class function TOrmController.List<T>(AConexao: TFdConnection; AFiltros: TArray<String>; AValores: array of variant): TObjectList<T>;
var
  VQuery: TFDQuery;
  Objeto: T;
begin
  Result := TObjectList<T>.Create;
  FGarbageCollector.Inspect(Result);

  VQuery := TFDQuery.Create(nil);

  try
    vQuery.Open(TSqlExtractor<T>.ExtractSelectSql(Result, AFiltros),AValores);
    FreeAndNil(Result);

    vQuery.First;
    while not VQuery.Eof do
    begin
      Objeto := T.Create;
      ReadDataset(VQuery, Objeto);
      Result.add(Objeto);
      VQuery.Next;
    end;

    FGarbageCollector.Inspect(Result);
  finally
    FreeAndNil(VQuery);
  end;
end;

class function TOrmController.List<T>(AConexao: TFdConnection; AFiltros: TDictionary<String, String>): TObjectList<T>;
var
  VQuery: TFDQuery;
  Objeto: T;
  AValores: Array of variant;
  I: Integer;
begin
  Result := TObjectList<T>.Create;
  VQuery := TFDQuery.Create(nil);

  try
    setLength(AValores, AFiltros.Count);
    for I := 0 to AFiltros.Count -1 do
        AValores[I] := Variant(AFiltros.Values.ToArray[I]);
    vQuery.Open(TSqlExtractor<T>.ExtractSelectSql(Result, AFiltros), AValores);

    vQuery.First;
    while not VQuery.Eof do
    begin
      Objeto := T.Create;
      ReadDataset(VQuery, Objeto);
      Result.add(Objeto);
      VQuery.Next;
    end;
    FGarbageCollector.Inspect(Result);
  finally
    FreeAndNil(VQuery);
  end;

end;

class function TOrmController.Open<T>(AConexao: TFdConnection; AFiltros: TArray<String>; AValores: array of variant): T;
var
  VQuery: TFdQuery;
  I: Integer;
begin
  if length(AFiltros) <> length(AValores) then
    raise Exception.Create('Parâmetros informados não corresponde ao número de filtros');

  VQuery := TFDQuery.Create(nil);

  try
    Result := T.Create();
    vQuery.Open(TSqlExtractor<T>.ExtractSelectSql(Result, AFiltros),AValores);
    ReadDataset(VQuery, Result);

    FGarbageCollector.Inspect(Result);
  finally
    FreeAndNil(VQuery);
  end;
end;

class function TOrmController.Open<T>(AConexao: TFdConnection; AFiltros: TDictionary<String, String>): T;
var
  VQuery: TFDQuery;
  AValores: Array of variant;
  VValue: variant;
  I: Integer;
begin
 VQuery := TFDQuery.Create(nil);

  try
    Result := T.Create();
    setLength(AValores, AFiltros.Count);
    for I := 0 to AFiltros.Count -1 do
        AValores[I] := Variant(AFiltros.Values.ToArray[I]);
    vQuery.Open(TSqlExtractor<T>.ExtractSelectSql(Result, AFiltros.Keys.ToArray), AValores);
    ReadDataset(VQuery, Result);

    FGarbageCollector.Inspect(Result);
  finally
    FreeAndNil(VQuery);
  end;
end;


class procedure TOrmController.Post<T>(AConexao: TFdConnection; ALista: TObjectList<T>; ACodigo: Integer);
var
  AItem: T;
begin
  for AItem in ALista do
  begin
    Post<T>(AConexao, AItem, ACodigo);
  end;
end;

class procedure TOrmController.Post<T>(AConexao: TFdConnection; AObjeto: T; ACodigo: Integer);
var
  ASql: string;
  AQuery: TFdQuery;
begin
  ASql := TSqlExtractor<T>.ExtractSelectSql(AObjeto, ['codigo']);
  AQuery.Open(ASQL, [ACodigo]);
  if AQuery.RecordCount = 1 then
    AQuery.Edit
  else
    AQuery.Insert;

  ReadDataset(AQuery, AObjeto);
  AQuery.Post;
end;

class procedure TOrmController.ReadDataset<T>(aDataset: TDataset; var aInstance: T);

var   LocalInstance: T;
begin
  //Don't move the dataset cursor, because it is used inside iterator

  LocalInstance := AInstance;
  TRttiInterceptor<T>.mapProperty(aInstance, procedure (prop: TRttiProperty) begin
      if Prop.IsWritable then
      begin
        if aDataset.FindField(prop.Name) <> nil then
        begin
          try
            prop.SetValue(Pointer(LocalInstance), TValue.From(aDataset.FieldByName(prop.Name).Value));
          finally

          end;
        end;
      end;

    end);

  TRttiInterceptor<T>.mapField(aInstance, procedure (field: TRttiField) begin
      if aDataset.FindField(field.Name) <> nil then
      begin
        try
            field.SetValue(Pointer(LocalInstance), TValue.From(aDataset.FieldByName(field.Name).Value));
        finally

        end;
      end;
   end);
end;

class procedure TOrmController.WriteDataset<T>(var aInstance: T; var aDataset: TDataset);
var
  LocalInstance: T;
  LocalDataset: TDataset;
begin
  LocalInstance := aInstance;
  LocalDataset := aDataset;
  TRttiInterceptor<T>.mapProperty(aInstance, procedure (prop: TRttiProperty) begin
      if Prop.IsReadable then
      begin
        if LocalDataset.FindField(prop.Name) <> nil then
        begin
          try
            if (LocalDataset.FieldByName(prop.Name).FieldKind = fkData) and not (LocalDataset.FieldByName(prop.Name).ReadOnly) then
              LocalDataset.FieldByName(prop.Name).Value := prop.GetValue(Pointer(LocalInstance)).AsVariant;
          finally

          end;
        end;
      end;

    end);

  TRttiInterceptor<T>.mapField(aInstance, procedure (field: TRttiField) begin
      if LocalDataset.FindField(field.Name) <> nil then
      begin
        try
          if (LocalDataset.FieldByName(field.Name).FieldKind = fkData) and not (LocalDataset.FieldByName(field.Name).ReadOnly) then
            LocalDataset.FieldByName(field.Name).Value := field.GetValue(Pointer(LocalInstance)).AsVariant;
        finally

        end;
      end;
  end);


end;

class procedure TOrmController.Delete<T>(AConexao: TFdConnection; ATabela: String; ACodigo: Integer);
begin
  AConexao.ExecSQL('Delete from ' + ATabela + ' where codigo = ' + ACodigo.ToString);
end;

class procedure TOrmController.Iterate(ADataset: Tdataset; AProc: TProc<TDataset>);
begin
  ADataset.First;
  while not ADataset.Eof do
  begin
    AProc(ADataset);
    ADataset.Next;
  end;

end;

{ TOrmGarbageCollector }

constructor TOrmGarbageCollector.create;
begin
  FObjects := TObjectList<TObject>.Create();
end;

destructor TOrmGarbageCollector.destory;
begin
  FObjects.Free;
end;

procedure TOrmGarbageCollector.Inspect(AObject: TObject);
begin
  FObjects.Add(AObject)
end;

procedure TOrmGarbageCollector.SetObjects(const Value: TObjectlist<TObject>);
begin
  FObjects := Value;
end;

initialization
  TOrmController.FGarbageCollector:= TOrmGarbageCollector.Create;

finalization
  TOrmController.FGarbageCollector.Destroy;

end.



