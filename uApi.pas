unit uApi;

interface

uses

  {$REGION 'Controller'}
  uController.Api,
  {$ENDREGION}

  {$REGION 'Models'}
  uModel.Consulta,
  uModel.Medicao

  {$ENDREGION};

  Type
  Dominios = class
    class function Publicar: String;
  end;


implementation

{ Dominios }

class function Dominios.Publicar: String;

begin

  TApiController<TConsulta>.Publicar('/consulta');
  TApiController<TMedicao>.Publicar('/medicao');


end;

end.
