unit uModel.Indicador;

interface

uses
  {Tipos,}
  {uModel.Conexao,}
  uModel.Consulta,
  Assis.SqlExtractor
;

type

  TIndicador = class
    ID: VARCHAR;
    Codigo: INTEGER;
    Nome: VARCHAR;
    Descricao: VARCHAR;
    Simbolo: VARCHAR;
    Grupo: INTEGER;
    Consulta: TConsulta;
    Conexao: {TConexao:} INTEGER;
    Contexto: TEXT;
    Armazenar: INTEGER;


  end;

implementation

end.
