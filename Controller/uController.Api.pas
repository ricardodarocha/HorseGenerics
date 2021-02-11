unit uController.Api;

interface

uses
  Horse,
  Generics.Collections,
  FireDAC.Comp.Client,
  uProvider.Firedac,
  SysUtils;

type

  TApiController<T: Class, Constructor> = class

  class procedure Publicar(aRota: String);
  class procedure GetOne(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  class procedure GetAll(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  class procedure Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  class procedure Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);

  private

    class function ExtrairParametro(Req: THorseRequest; aParamName: String): String; static;
    class function ExtrairQueryParam(Req: THorseRequest; aParamName: String): String; static;
  end;

implementation

uses
  System.Generics.Collections,
  Dataset.Serialize,
  System.JSON,
  System.NetEncoding;

{ TController<T> }

class function TApiController<T>.ExtrairParametro(Req: THorseRequest; aParamName: String): String;
begin
  try
    result := Req.Params[aParamName];
  except
    result := '';
  end;
end;


class function TApiController<T>.ExtrairQueryParam(Req: THorseRequest; aParamName: String): String;
begin
  try
    result := Req.Query[aParamName];
  except
    result := '';
  end;
end;

class procedure TApiController<T>.GetAll(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  AProvider: TProviderFiredac;
  vCodigo: Integer;
  vPagina: Integer;
  vPacote: Integer;
  ARetorno: TJsonObject;
begin
  ARetorno := TJsonObject.Create;

  vCodigo := StrToIntDef(ExtrairParametro (Req, 'codigo'),  0);
  vPagina := StrToIntDef(ExtrairQueryParam(Req, 'pagina'),  1);
  vPacote := StrToIntDef(ExtrairQueryParam(Req, 'pacote'), 50);

  AProvider := TProviderFiredac.Create(nil);
  try

   try
    if vCodigo = 0 then
      ARetorno.AddPair('dados', aProvider.Get<T>([], [], vPagina, vPacote).ToJSONArray())
    else
      ARetorno.AddPair('dados', aProvider.Get<T>(['codigo'],
                                                 [vCodigo],
                                                  vPagina,
                                                  vPacote)
                                         .ToJSONObject() );

    if AProvider.Erro <> '' then
      ARetorno.AddPair('erro', aProvider.Erro)

   except on E: Exception do
      begin
        ARetorno.AddPair(TJSONPair.Create('erro',
          TJSONObject.Create()
            .AddPair(TJSONPair.Create('classe', e.ClassName))
            .AddPair(TJSONPair.Create('mensagem', e.Message))
          ));
      end;

   end;

    Res.Send(ARetorno)
       .Status(AProvider.Status);

  finally
    FreeAndNil(AProvider);
  end;
end;

class procedure TApiController<T>.GetOne(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  VCodigo: Integer;
  AProvider: TProviderFiredac;
  AResultado: TJsonObject;
  VUsuario: string;
  Encoding: TBase64Encoding;
begin
  Encoding := TBase64Encoding.Create();
  VUsuario := Encoding.Decode(Req.Headers['authorization']);
  Encoding.Free;
  VCodigo := StrToIntDef(ExtrairQueryParam(Req, 'codigo'),0);

  AProvider := TProviderFiredac.Create(nil);
  try
    if VCodigo = 0 then
    begin
      AResultado := TJsonObject.Create;
      AResultado.AddPair('dados', aProvider.Get<T>().ToJSONArray())
    end
    else
      AResultado := aProvider.Get<T>(['codigo'], [VCodigo]).ToJSONObject();

    if AProvider.Erro <> '' then
      AResultado.AddPair('erro', AProvider.Erro);

    Res.Send<TJsonObject>(AResultado)
       .Status(AProvider.Status);
  finally

    FreeAndNil(AProvider);
  end;
end;


class procedure TApiController<T>.Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  AJson: TJsonObject;
  AProvider: TProviderFiredac;
begin
  AProvider := TProviderFiredac.Create(nil);
  try
    try
      AJson := Req.Body<TJsonObject>;
      Res.Send(AProvider.Post<T>(AJson, 'codigo = ' + AJson.Values['codigo'].ToString))
        .Status(THTTPStatus.Created);
    except
      on E: Exception do
      begin
        Res.Send(TJSONObject
          .Create(TJsonPair.Create('Erro', E.Message))
          .AddPair(TJsonPair.Create('Classe', E.ClassName)))
          .Status(THTTPStatus.InternalServerError);
      end;

    end;
  finally
    FreeAndNil(AProvider);
  end;
end;

class procedure TApiController<T>.Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  ACodigo: Integer;
  AProvider: TProviderFiredac;
  ARetorno: TJSONObject;
  ACodigoStatus: Integer;
begin
  AProvider := TProviderFiredac.Create(nil);
  try
    ARetorno := TJSONObject.Create;

    try
      ACodigo := Req.Params['codigo'].ToInteger;
    except on E: Exception do
      begin
        ARetorno.AddPair(TJSONPair.Create('erro',
          TJSONObject.Create()
            .AddPair(TJSONPair.Create('classe', e.ClassName))
            .AddPair(TJSONPair.Create('mensagem', e.Message))
          ));
        Res.Send<TJsonObject>(ARetorno)
           .Status(400);
      end;
    end;

    if ACodigo > 0 then
    begin

      try
        ACodigoStatus := 200;
        if aProvider.Delete<T>('codigo', ACodigo) then
          ARetorno.AddPair(TJSONPair.Create('resultado', T.className + ' codigo=' + ACodigo.toString + ' removido'))
        else
          ACodigoStatus := 404;

        Res.Send<TJsonObject>(ARetorno)
           .Status(ACodigoStatus);
      except on E: Exception do
      begin
        ARetorno.AddPair(TJSONPair.Create('erro',
          TJSONObject.Create()
            .AddPair(TJSONPair.Create('classe', e.ClassName))
            .AddPair(TJSONPair.Create('mensagem', e.Message))
          ));
        ACodigoStatus := 500;
        Res.Send<TJsonObject>(ARetorno)
           .Status(ACodigoStatus);
      end;

      end;
    end
    else
      Res.Send<TJsonObject>(ARetorno
         .AddPair(TJSONPair.Create('erro', 'parâmetro código não informado')))
         .Status(400);
  finally
    FreeAndNil(AProvider);
  end;

end;

class procedure TApiController<T>.Publicar(aRota: String);
begin
    THorse.Get(aRota +'/', TApiController<T>.GetAll);
    THorse.Get(aRota +'/:codigo', TApiController<T>.GetOne);
    THorse.Post(aRota +'/', TApiController<T>.Post);
    THorse.Put(aRota +'/:codigo', TApiController<T>.Post);
    THorse.Delete(aRota +'/:codigo', TApiController<T>.Delete);
end;

end.
