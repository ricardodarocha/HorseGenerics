object DMDados: TDMDados
  OldCreateOrder = False
  Height = 150
  Width = 215
  object Conexao: TFDConnection
    Params.Strings = (
      'Database=D:\dados\dados.db'
      'DriverID=sQLite')
    Connected = True
    LoginPrompt = False
    Left = 40
    Top = 24
  end
  object Query: TFDQuery
    Connection = Conexao
    SQL.Strings = (
      'SELECT * FROM CONSULTAS where codigo = :codigo')
    Left = 40
    Top = 72
    ParamData = <
      item
        Name = 'CODIGO'
        DataType = ftInteger
        ParamType = ptInput
        Value = 1
      end>
  end
end
