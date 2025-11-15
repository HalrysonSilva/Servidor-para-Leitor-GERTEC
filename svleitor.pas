unit svleitor;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IdContext, IdTCPServer, Vcl.StdCtrls,
  System.Generics.Collections, IdBaseComponent, System.DateUtils, Vcl.ExtCtrls,
  IdComponent, IdCustomTCPServer, Vcl.ComCtrls, dxGDIPlusClasses,Registry;

type
  TForm1 = class(TForm)
    IdTCPServer1: TIdTCPServer;
    Panel2: TPanel;
    MemoLog: TMemo;
    ListBuscaPreco: TListBox;
    Panel3: TPanel;
    Image1: TImage;
    Panel1: TPanel;
    Label1: TLabel;
    EDITPORT: TEdit;
    BTNREINICIAR: TButton;
    btnlimpalog: TButton;
    BtnBuscarEquip: TButton;
    Label2: TLabel;
    TrayIcon1: TTrayIcon;
    procedure IdTCPServer1Execute(AContext: TIdContext);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure IdTCPServer1Connect(AContext: TIdContext);
    procedure FormCreate(Sender: TObject);
    procedure BTNREINICIARClick(Sender: TObject);
    procedure btnlimpalogClick(Sender: TObject);
    procedure BtnBuscarEquipClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure TrayIcon1DblClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    { Private declarations }
    procedure Log(const aText: string);
    procedure ListarEquipamentos;
    procedure ListarDispositivosConectados;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses CONEXAOBD;

procedure TForm1.Log(const aText: string);
begin
  TThread.Queue(nil,
    procedure
    begin
      MemoLog.Lines.Add(FormatDateTime('dd/mm/yyyy hh:nn:ss', Now) + ' - ' + aText);
    end
  );
end;

procedure TForm1.TrayIcon1DblClick(Sender: TObject);
begin
  // Mostra o formulário novamente
  Self.Show;
  // Traz a janela para a frente e a restaura se estiver minimizada
  Application.BringToFront;
end;

procedure TForm1.IdTCPServer1Connect(AContext: TIdContext);
begin
  Log('Nova conexão de: ' + AContext.Connection.Socket.Binding.PeerIP);
  try
    AContext.Connection.IOHandler.WriteLn('#ok');
    Log('Comando de handshake "#ok" enviado.');
  except
    on E: Exception do
      Log('Erro ao enviar #ok: ' + E.Message);
  end;
end;


procedure TForm1.ListarDispositivosConectados;
var
  Context: TIdContext;
  Lista: TList;
begin
  ListBuscaPreco.Items.BeginUpdate;
  try
    ListBuscaPreco.Items.Clear;

    // Pega a lista de contextos conectados
    Lista := IdTCPServer1.Contexts.LockList;
    try
      for Context in Lista do
      begin
        ListBuscaPreco.Items.Add(
          Context.Binding.PeerIP + ':' + Context.Binding.PeerPort.ToString
        );
      end;
    finally
      // Aqui sim você libera o lock
      IdTCPServer1.Contexts.UnlockList;
    end;

  finally
    ListBuscaPreco.Items.EndUpdate;
  end;
end;




procedure TForm1.ListarEquipamentos;
begin
  try
   ListBuscaPreco.Items.Clear;

  finally

  end;


end;

procedure TForm1.IdTCPServer1Execute(AContext: TIdContext);
var
  CodigoBarras: string;
  Resposta: string;
  PrecoFormatado: string;
  BufferSize: Integer;
  ListaCodigosDispositivos: TStringList;
begin
  // Cria uma lista com os códigos de identificação conhecidos dos leitores
  ListaCodigosDispositivos := TStringList.Create;
  try
    ListaCodigosDispositivos.Add('bpg2e');
    ListaCodigosDispositivos.Add('tc506s');
    // Adicione outros códigos de dispositivos conhecidos aqui, se necessário

    while AContext.Connection.Connected do
    begin
      try
        BufferSize := AContext.Connection.IOHandler.InputBuffer.Size;
        if BufferSize > 0 then
        begin
          CodigoBarras := Trim(AContext.Connection.IOHandler.ReadString(BufferSize));

          // Se o código começar com '#', remove o caractere.
          if CodigoBarras.StartsWith('#') then
            CodigoBarras := Copy(CodigoBarras, 2, Length(CodigoBarras));

          Log('Recebido código: ' + CodigoBarras);

          // Verifica se o código recebido é um dos códigos de identificação de dispositivo
          if ListaCodigosDispositivos.IndexOf(CodigoBarras) <> -1 then
          begin
            Log('A string recebida é um identificador de dispositivo, não um código de barras. Ignorando.');
            // Envia um "ok" para o dispositivo para confirmar que a mensagem foi recebida.
            AContext.Connection.IOHandler.WriteLn('OK;Dispositivo Reconhecido');
            Log('Resposta enviada: OK;Dispositivo Reconhecido');
          end
          else
          begin
            // Se não for um código de dispositivo, assume que é um código de barras e processa
            TThread.Queue(nil,
              procedure
              begin
                try
                  with DataModule1.QryProdutos do
                  begin
                    Close;
                    SQL.Clear;
                    SQL.Add('SELECT PrecoVenda, Produto FROM tabest1 WHERE codinterno = :Codigo');
                    ParamByName('Codigo').AsString := CodigoBarras;
                    Open;

                    if not IsEmpty then
                    begin
                      PrecoFormatado := Format('%.2f', [FieldByName('PrecoVenda').AsFloat]);
                      Resposta := Format('OK;%s;%s', [
                        FieldByName('Produto').AsString,
                        PrecoFormatado
                      ]);
                      Log('Produto encontrado: ' + FieldByName('Produto').AsString + ' - ' + PrecoFormatado);
                    end
                    else
                    begin
                      Resposta := 'ERRO;Produto Nao Encontrado';
                      Log('Modelo do Leitor: ' + CodigoBarras);
                    end;

                    Close;
                  end;
                except
                  on E: Exception do
                  begin
                    Resposta := 'ERRO;Erro Interno';
                    Log('ERRO na busca do banco de dados: ' + E.Message);
                  end;
                end;

                AContext.Connection.IOHandler.WriteLn(Resposta);
                Log('Resposta enviada: ' + Resposta);
              end
            );
          end;
        end;
        Sleep(50);
      except
        on E: Exception do
        begin
          if (Pos('Connection Closed', E.Message) > 0) or (Pos('socket', E.Message) > 0) then
          begin
            Log('Conexão fechada pelo leitor. OK.');
            AContext.Connection.Disconnect;
            Break;
          end
          else
          begin
            Log('Erro inesperado na comunicação: ' + E.Message);
            AContext.Connection.Disconnect;
            Break;
          end;
        end;
      end;
    end;
  finally
    // Libera a lista de códigos de dispositivo da memória
    ListaCodigosDispositivos.Free;
  end;
  Log('Conexão finalizada com: ' + AContext.Connection.Socket.Binding.PeerIP);
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caHide;

  // Encerra o servidor TCP se estiver ativo
  if Assigned(IdTCPServer1) and IdTCPServer1.Active then
    IdTCPServer1.Active := False;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  Reg: TRegistry;
  AppPath: string;
begin
  EDITPORT.Text := '6500';

  // --- Código para inicialização automática (já discutido) ---
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', True) then
    begin
      AppPath := '"' + ParamStr(0) + '"';
      Reg.WriteString('svLeitor', AppPath);
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
  // --- Fim do código ---

  // --- Esconde o formulário ao iniciar ---
  Application.ShowMainForm := False;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  if WindowState = wsMinimized then
  begin
    Hide; // Esconde o formulário
    TrayIcon1.Visible := True; // Garante que o ícone da bandeja esteja visível
    Application.ShowMainForm := False; // Remove da barra de tarefas
  end;
end;

procedure TForm1.FormShow(Sender: TObject);
begin

ListarDispositivosConectados;
end;

procedure TForm1.BtnBuscarEquipClick(Sender: TObject);
begin
 try
  BtnBuscarEquip.Enabled := false;
  ListarDispositivosConectados;
 finally
  BtnBuscarEquip.Enabled := true;
 end;
end;

procedure TForm1.btnlimpalogClick(Sender: TObject);
begin
  MemoLog.Clear;
end;

procedure TForm1.BTNREINICIARClick(Sender: TObject);
var
  NovaPorta: Integer;
begin
  if TryStrToInt(EDITPORT.Text, NovaPorta) then
  begin
    if IdTCPServer1.Active then
    begin
      Log('Reiniciando servidor na porta ' + EDITPORT.Text);
      IdTCPServer1.Active := False;
    end;

    IdTCPServer1.DefaultPort := NovaPorta;
    IdTCPServer1.Active := True;
    Log('Servidor iniciado na porta ' + EDITPORT.Text);
  end
  else
  begin
    Log('Erro: A porta deve ser um número válido.');
  end;
end;

end.
