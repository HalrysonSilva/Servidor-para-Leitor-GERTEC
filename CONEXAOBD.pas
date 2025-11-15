unit CONEXAOBD;

interface

uses
  System.SysUtils, System.Classes,MidasLib, Uni, UniProvider, SQLServerUniProvider, UniDacVcl, System.IniFiles,
  DBAccess, Data.DB, MemDS,   windows , forms,
    Vcl.Dialogs,  System.IOUtils, DASQLMonitor, UniSQLMonitor, Datasnap.DBClient;

    const
  ARQUIVO_CONEXAO = 'Servcom.dll';

type
  TDataModule1 = class(TDataModule)
    ConDados: TUniConnection; // Componente de conexão

    SQLServerUniProvider1: TSQLServerUniProvider;
    UniSQLMonitor1: TUniSQLMonitor;
    UniConnectDialog1: TUniConnectDialog;
    QRYPRODUTOS: TUniQuery;



    procedure DataModuleCreate(Sender: TObject); // DataSource para grid
  private
    procedure CarregarConexao(const NomeConnection: string;
      UniConnectDialog: TUniConnectDialog);

    function LerArqCfg(Topico, variavel, sNomeArquivo: string): string;
    function Alltrim(const Search: string): string;
    function LerArquivoConteudo(sNomeArquivo: String): WideString;
    { Private declarations }
  public
      procedure ConectaBanco(bAbre: Boolean=true);
    { Public declarations }

  end;

var
  DataModule1: TDataModule1; // Instância global do DataModule

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}




{$R *.dfm}


procedure TDataModule1.CarregarConexao(const NomeConnection: string; UniConnectDialog: TUniConnectDialog);
var
  CaminhoArquivo: string;
  ConnStr: string;
  Connection: TUniConnection;
begin
  CaminhoArquivo := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + ARQUIVO_CONEXAO;

  // Obtem o componente dinamicamente
  Connection := TUniConnection(FindComponent(NomeConnection));
  if not Assigned(Connection) then
  begin
    ShowMessage('Componente ' + NomeConnection + ' não encontrado!');
    Exit;
  end;

  // Verifica se o arquivo de conexão existe
  if FileExists(CaminhoArquivo) then
  begin
    ConnStr := Trim(TFile.ReadAllText(CaminhoArquivo, TEncoding.UTF8));
    Connection.Connected := False;
    Connection.ConnectString := ConnStr;
    try
      Connection.Connected := True;
    except
      on E: Exception do
      begin
        ShowMessage('Erro ao conectar: ' + E.Message);
        if Assigned(UniConnectDialog) then
        begin
          if UniConnectDialog.Execute then
          begin
            Connection.Connected := True;
            TFile.WriteAllText(CaminhoArquivo, Connection.ConnectString, TEncoding.UTF8);
          end;
        end;
      end;
    end;
  end
  else
  begin
    // Se não existe, abre o diálogo de conexão
    if Assigned(UniConnectDialog) and UniConnectDialog.Execute then
    begin
      Connection.Connected := True;
      TFile.WriteAllText(CaminhoArquivo, Connection.ConnectString, TEncoding.UTF8);
    end
    else
      ShowMessage('Arquivo de conexão não encontrado e usuário cancelou a configuração.');
  end;
end;

procedure TDataModule1.DataModuleCreate(Sender: TObject);
begin

  try
      //CarregarConexao('UniConnection1',UniConnectDialog1);
//      ConectaBanco(false);
      ConectaBanco(true);
  finally

  end;

end;



procedure TDataModule1.ConectaBanco(bAbre: Boolean=true);
var
  sParamServer, sParamDataBase, sParamUser, sParamPassWord: string;
  sParamProvider: string;
  bDeletaArqConexao: Boolean;

   sArqConexao : string;
  cfg_PathSistema: string;
  sConfiguracao: TStringlist;
begin

  If bAbre = FALSE then
  begin
    conDados.Close;
    Exit;
  end;

  try
    sConfiguracao := TStringlist.Create;
    cfg_PathSistema := ExtractFilePath(Application.ExeName);
    // BuscaPrimeiro Arquivo Raiz do ServSic, caso não exista, então usa do Raiz NFetop
    // sArqConexao := cfg_PathSistema + 'Servcom.dll';

    sArqConexao := '..\Servsicx\ServCom.dll';

    if not FileExists(sArqConexao) then
      sArqConexao := '..\Servsic\ServCom.dll';

    if not FileExists(sArqConexao) then
      sArqConexao := cfg_PathSistema + 'Servcom.dll';


    // uniSQLMonitor1.Active := (LerSys('DATABASE', 'DBMONITOR') = 'S');

    IF bAbre then
    begin

      bDeletaArqConexao := FALSE;

      If (not FileExists(sArqConexao)) then
      begin
        if not conDados.ConnectDialog.Execute then
        begin
          ShowMessage
            ('Configuração da conexão com Banco de Dados SQL "CANCELADA PELO USUARIO"!');
          Application.Terminate;
          Exit;
        end;

        if conDados.Connected then
        BEGIN
          Exit;
        end
        ELSE
        begin
          ShowMessage
            ('FALHA na Configuração da conexão com Banco de Dados SQL!');
          Application.Terminate;
        end;

      end;

      // Carrega Parametros
      sParamServer := LerArqCfg('', 'SERVER NAME', sArqConexao);
      if sParamServer <= ' ' then
        sParamServer := LerArqCfg('', 'Data Source', sArqConexao);

      sParamDataBase := LerArqCfg('', 'DATABASE NAME', sArqConexao);
      if sParamDataBase <= ' ' then
        sParamDataBase := LerArqCfg('', 'Initial Catalog', sArqConexao);

      sParamUser := LerArqCfg('', 'USER NAME', sArqConexao);
      if sParamUser <= ' ' then
        sParamUser := LerArqCfg('', 'User ID', sArqConexao);

      sParamPassWord := LerArqCfg('', 'PASSWORD', sArqConexao);

      IF Length(sParamProvider) <= 1 then
      begin
        sParamProvider := 'prSQL';

      end;

      // Conexão SDac
      if sParamServer > ' ' then
      begin
        conDados.Server := sParamServer;
        conDados.Database := sParamDataBase;
        conDados.Username := sParamUser;
        conDados.Password := sParamPassWord;
        bDeletaArqConexao := True;
      end
      else
      begin
        conDados.ConnectString := LerArquivoConteudo(sArqConexao);
      end;

      conDados.Connected := True;

    end
    else
    begin
      conDados.Connected := FALSE;
      conDados.Close;
    end;

  finally
    if conDados.Connected then
    begin
      sConfiguracao.Text := conDados.ConnectString;
      sConfiguracao.SaveToFile(sArqConexao);
    end;

    FreeAndNil(sConfiguracao);
  end;
end;


function TDataModule1.LerArquivoConteudo(sNomeArquivo : String): WideString ;
var
  sConfig : TStringList;
  sConteudo : WideString;

begin
  try

    sConfig := TStringList.Create;
    if FileExists(sNomeArquivo) then
    begin
      sConfig.LoadFromFile(sNomeArquivo);
      sConteudo := sConfig.Text;
    end;
    Result := sConteudo;

   except
    Result := '';
   end;
end;


function TDataModule1.LerArqCfg(Topico, variavel, sNomeArquivo: string): string;
var
  ArquivoINI: TIniFile;
  ArquivoTXT: TextFile;
  sArquivo: WideString;
  sLinha: string;
  iPos, iTam, iTamLinha: Integer;
begin
  if Pos(':', sNomeArquivo) > 0 then
    sArquivo := PChar(sNomeArquivo)
  else
    sArquivo := PChar(ExtractFilePath(Application.ExeName) + sNomeArquivo);

  // Caso seja um Arquivo sem SESSÃO [] OU SEJA UM TXT
  if Topico <= ' ' then
  begin
    iPos := 0;
    iTam := Length(variavel + '=');
    iTamLinha := 0;
    AssignFile(ArquivoTXT, sArquivo);

    Reset(ArquivoTXT);
    While not Eoln(ArquivoTXT) do
    begin
      Readln(ArquivoTXT, sLinha);
      iPos := Pos(UpperCase(variavel) + '=', UpperCase(sLinha));
      if iPos > 0 then
      begin
        // iTamLinha := Length(sLinha);
        sLinha := Alltrim(Copy(sLinha, (iPos + iTam), 100));
        // Ler Até a Posição Ponto e Virgula (;)
        iPos := Pos(';', UpperCase(sLinha));
        if iPos > 0 then
        begin
          sLinha := Alltrim(Copy(sLinha, 1, iPos - 1));
        end;

        Result := sLinha;
        Break;
      end;
    end;
    CloseFile(ArquivoTXT); // Fecha o Arquivo
  end;
  IF iPos > 0 then
    Exit;

  ArquivoINI := TIniFile.Create(sArquivo);
  ArquivoINI.ReadString(Topico, variavel, '');
  Result := ArquivoINI.ReadString(Topico, variavel, '');
  ArquivoINI.Free;
end;

function TDataModule1.Alltrim(const Search: string): string;
const
  BlackSpace = [#33 .. #126];
var

  Index: byte;

begin
  Index := 1;
  while (Index <= Length(Search)) and not(Search[Index] in BlackSpace) do
  begin
    Index := Index + 1;
  end;
  Result := Copy(Search, Index, 255);
  Index := Length(Result);
  while (Index > 0) and not(Result[Index] in BlackSpace) do
  begin
    Index := Index - 1;
  end;
  Result := Copy(Result, 1, Index);
end;








end.

