unit uModel.Consulta;

interface

uses
  Assis.SqlExtractor;

type

TConsulta = class
  Codigo: Integer;
  Nome: VARCHAR;
  Descricao: VARCHAR;
  Query: TEXT;
  Conexao: Integer;
  Publicar: Boolean;
  Ocultar: Boolean;
  GrupoArvore: Integer;
end;

implementation

end.
