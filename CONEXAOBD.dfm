object DataModule1: TDataModule1
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 703
  Width = 1030
  object ConDados: TUniConnection
    ProviderName = 'SQL Server'
    Port = 1433
    Database = 'SERVSIC2'
    Username = 'sa'
    Server = '.\CAPIXABA'
    ConnectDialog = UniConnectDialog1
    LoginPrompt = False
    Left = 24
    Top = 24
    EncryptedPassword = 'CEFFCDFFCCFF'
  end
  object UniSQLMonitor1: TUniSQLMonitor
    Left = 24
    Top = 144
  end
  object SQLServerUniProvider1: TSQLServerUniProvider
    Left = 24
    Top = 208
  end
  object UniConnectDialog1: TUniConnectDialog
    DatabaseLabel = 'Database'
    PortLabel = 'Port'
    ProviderLabel = 'Provider'
    Caption = 'Connect'
    UsernameLabel = 'User Name'
    PasswordLabel = 'Password'
    ServerLabel = 'Server'
    ConnectButton = 'Connect'
    CancelButton = 'Cancel'
    Left = 24
    Top = 80
  end
  object QRYPRODUTOS: TUniQuery
    Connection = ConDados
    Left = 128
    Top = 24
  end
end
