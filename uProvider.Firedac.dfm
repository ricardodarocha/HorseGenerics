object ProviderFiredac: TProviderFiredac
  OldCreateOrder = False
  Height = 150
  Width = 215
  object Wait: TFDGUIxWaitCursor
    Provider = 'Forms'
    Left = 16
    Top = 16
  end
  object Query: TFDQuery
    Connection = Conexao
    FetchOptions.AssignedValues = [evRecsSkip, evRecsMax, evRowsetSize]
    FetchOptions.RecsSkip = 0
    FetchOptions.RecsMax = 5
    SQL.Strings = (
      'select * from consultas')
    Left = 24
    Top = 96
  end
  object Conexao: TFDConnection
    Params.Strings = (
      'Database=D:\Clientes\Agro\dados.db'
      'DriverID=sQLite')
    LoginPrompt = False
    AfterConnect = ConexaoAfterConnect
    BeforeConnect = ConexaoBeforeConnect
    Left = 24
    Top = 64
  end
  object Memory: TFDMemTable
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    Left = 96
    Top = 88
  end
end
