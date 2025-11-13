# Servidor para Leitor GERTEC

Projeto desenvolvido para estabelecer a comunicação direta com os leitores de código de barras da Gertec, eliminando a necessidade de utilizar o software proprietário da fabricante.

## 📋 Sobre o Projeto

O **Servidor para Leitor GERTEC** atua como um *middleware* leve, customizável e independente. Seu principal objetivo é fornecer uma interface de comunicação direta para a captura de dados dos leitores Gertec (Modelos: *[Inserir Modelos Suportados, ex: EasyScan, MultiScan]*), permitindo a integração descomplicada com sistemas legados, ERPs ou qualquer aplicação que necessite de leituras de código de barras em tempo real.

O servidor recebe as leituras e as armazena de forma organizada no banco de dados, prontas para serem consumidas pela sua aplicação principal.

## 🚀 Tecnologias Utilizadas

Este projeto foi construído no ambiente de desenvolvimento padrão do sistema:

* **Linguagem/IDE:** Delphi 10.3 (ou superior)
* **Banco de Dados:** Microsoft SQL Server 

## 🔧 Pré-requisitos

Para executar e desenvolver neste projeto, você precisará ter instalado:

* **IDE:** Delphi 10.3 (Rio) ou superior.
* **Banco de Dados:** Acesso a uma instância do Microsoft SQL Server.
* **Conectividade:** Componentes de comunicação serial (COM) ou de rede (TCP/IP) compatíveis com Delphi (ex: **Indy** ou **Synapse**).
