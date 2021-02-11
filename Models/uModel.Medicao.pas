unit uModel.Medicao;

interface

uses Assis.SqlExtractor;

type

  TMedicao = class
    Codigo: Integer;
    Indicador: Integer;
    Simbolo: String;
    Data: TDatetime;
    Data_base: TDatetime;
    Usuario: VARCHAR;
    Variacao: Currency;
    Valor: Currency;
    Total: Currency;
    Percentual: Currency;
    Cor: Integer;
    Conexao: Integer;
    Lote: TDatetime;
  end;

implementation

end.
