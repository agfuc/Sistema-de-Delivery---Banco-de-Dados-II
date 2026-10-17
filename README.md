# Sistema de Delivery - Banco de Dados II

Trabalho da disciplina de Banco de Dados II (IFSC Canoinhas). A ideia é um sistema de delivery tipo ifood, usando **PostgreSQL** pra parte relacional (clientes, pedidos, pagamentos, etc) e **MongoDB** pra parte NoSQL (cardápio personalizável e avaliações com fotos).

## Estrutura das pastas

```
Db-trabalho/
├── README.md
├── sql/
│   ├── criacao_banco.sql   -> cria o banco inteiro (tabelas, procedures, triggers, views, roles...)
│   └── testes_banco.sql    -> popula com dados de teste e roda os exemplos pedidos no trabalho
├── nosql-app/               -> app Java que mexe nos dois bancos juntos
│   └── src/main/java/com/delivery/nosql/
│       ├── Main.java                -> menu no terminal
│       ├── ConexaoBanco.java        -> conecta no Postgres e no Mongo
│       └── GerenciadorDelivery.java -> as operações em si (pedido, avaliação, etc)
└── etc/
    ├── configura_banco.bat -> script pra recriar o banco no Windows sem digitar tudo na mão
    ├── backup-e-restore.md -> comandos de backup/restore que usamos
    ├── der-delivery.pdf    -> DER do banco
    └── Requisitos.txt      -> enunciado do trabalho
```

## Requisitos

No Windows, instale:

- **JDK 25 LTS** (Temurin recomendado), necessário para compilar o projeto.
- **Apache Maven 3.9+**, usado para baixar os drivers, compilar e executar.
- **PostgreSQL 14 ou superior**; os comandos abaixo usam PostgreSQL 18.
- **MongoDB Community Server 7.0**, compatível com a versão do driver Java deste projeto.
- Opcional: **Visual Studio Code** e a extensão **Extension Pack for Java** para depurar pela IDE. `psql`/pgAdmin e `mongosh` também são opcionais.

## Instalação no Windows

Abra o PowerShell. Instale o JDK, PostgreSQL e MongoDB pelo WinGet:

```powershell
winget install --id EclipseAdoptium.Temurin.25.JDK --exact --source winget
winget install --id PostgreSQL.PostgreSQL.18 --exact --source winget
winget install --id MongoDB.Server --version 7.0.28 --exact --source winget
```

Durante a instalação do PostgreSQL, defina e anote a senha do usuário administrador `postgres`. Ela será solicitada ao criar o banco.

O MongoDB deve ser instalado como serviço do Windows e escutar na porta padrão `27017`. A versão 7.0.28 foi escolhida por compatibilidade com o driver MongoDB Java usado pelo projeto.

Instale o Maven 3.9.11 a partir do arquivo binário oficial:

```powershell
$version = '3.9.11'
$tools = Join-Path $HOME 'tools'
New-Item -ItemType Directory -Force -Path $tools | Out-Null
$zip = Join-Path $env:TEMP "apache-maven-$version-bin.zip"
Invoke-WebRequest "https://dlcdn.apache.org/maven/maven-3/$version/binaries/apache-maven-$version-bin.zip" -OutFile $zip
Expand-Archive -LiteralPath $zip -DestinationPath $tools -Force
$env:MAVEN_HOME = Join-Path $tools "apache-maven-$version"
$env:Path = "$env:MAVEN_HOME\bin;$env:Path"
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$mavenBin = Join-Path $env:MAVEN_HOME 'bin'
if ($userPath -notlike "*$mavenBin*") {
    [Environment]::SetEnvironmentVariable('Path', "$mavenBin;$userPath", 'User')
}
```

Configure o JDK e confira as versões na mesma janela do PowerShell:

```powershell
$jdkPaths = @(
    (Join-Path $env:USERPROFILE '.jdk'),
    (Join-Path $env:ProgramFiles 'Eclipse Adoptium')
)
$jdk = Get-ChildItem -Path $jdkPaths -Directory -Filter 'jdk-25*' -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending | Select-Object -First 1
if (-not $jdk) { throw 'JDK 25 não encontrado. Instale o Temurin 25.' }
$env:JAVA_HOME = $jdk.FullName
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
java -version
mvn -version
```

As variáveis definidas com `$env:` valem para a janela atual. O comando acima também adiciona o Maven ao `Path` do usuário; feche e reabra o terminal/VS Code para que novos processos recebam o `Path` atualizado. Se o JDK não for encontrado automaticamente, configure `JAVA_HOME` nas Variáveis de Ambiente do Windows.

## Configurar e iniciar os bancos

Inicie os serviços do Windows em um PowerShell **como administrador**:

```powershell
Start-Service postgresql-x64-18
Start-Service MongoDB
Get-Service postgresql-x64-18, MongoDB
```

Se o nome do serviço PostgreSQL for diferente, encontre-o com `Get-Service *postgres*`. Confirme que os dois serviços estão `Running` antes de iniciar o aplicativo.

No PowerShell, a partir da pasta raiz do repositório, configure senhas próprias para os usuários da aplicação. O helper abaixo solicita cada senha sem exibi-la e mantém os valores somente no ambiente do processo atual:

```powershell
function Set-ProcessSecret {
    param([string]$Name, [string]$Prompt)
    $secure = Read-Host -Prompt $Prompt -AsSecureString
    if ($secure.Length -eq 0) { throw 'A senha não pode estar vazia.' }
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        [Environment]::SetEnvironmentVariable(
            $Name,
            [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer),
            'Process'
        )
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
        $secure.Dispose()
    }
}

Set-ProcessSecret 'DELIVERY_PG_DBA_PASSWORD' 'Senha nova para usuario_dba'
Set-ProcessSecret 'DELIVERY_PG_CLIENTE_PASSWORD' 'Senha nova para usuario_cliente'
Set-ProcessSecret 'DELIVERY_PG_RESTAURANTE_PASSWORD' 'Senha nova para usuario_restaurante'
Set-ProcessSecret 'DELIVERY_PG_ENTREGADOR_PASSWORD' 'Senha nova para usuario_entregador'
Set-ProcessSecret 'PGPASSWORD' 'Senha do administrador postgres'
```

Crie o banco e execute os scripts nesta ordem. A senha de `postgres`, informada pelo helper seguro acima, é usada por `psql` apenas nesta janela:

```powershell
psql -h localhost -p 5432 -U postgres -d postgres -c "CREATE DATABASE delivery;"
psql -v ON_ERROR_STOP=1 -h localhost -p 5432 -U postgres -d delivery -f .\sql\criacao_banco.sql
psql -h localhost -p 5432 -U postgres -d delivery -f .\sql\testes_banco.sql
```

Se `psql` não for reconhecido, adicione `C:\Program Files\PostgreSQL\18\bin` ao `Path` ou use o executável completo: `& 'C:\Program Files\PostgreSQL\18\bin\psql.exe'`.

O primeiro script cria as tabelas e os usuários da aplicação, usando as senhas definidas no ambiente para esta instalação. O segundo insere os dados de teste usados pelos exemplos. O arquivo SQL interrompe a execução se as variáveis de senha necessárias não estiverem definidas.

> **Atenção:** `etc\configura_banco.bat` recria o banco `delivery` e remove usuários/roles antigos. Isso apaga os dados que já existirem nesse banco; use-o somente quando quiser uma instalação limpa.

O MongoDB precisa estar ativo em `localhost:27017`. A aplicação cria o banco `delivery_nosql` e as collections quando necessário; não é preciso executar comandos de criação no MongoDB. A conexão atual não usa autenticação. Se habilitar autenticação no servidor, ajuste a URI em `ConexaoBanco.java`.

## Compilar e executar

Com os serviços ativos, na raiz do repositório execute:

```powershell
$env:JAVA_HOME = $jdk.FullName
$env:Path = "$env:JAVA_HOME\bin;$env:MAVEN_HOME\bin;$env:Path"
$env:DELIVERY_PG_USER = 'usuario_dba'
$env:DELIVERY_PG_PASSWORD = $env:DELIVERY_PG_DBA_PASSWORD
mvn -f .\nosql-app\pom.xml compile exec:java
```

O menu é interativo: mantenha a janela aberta e digite a opção desejada. No VS Code, abra **Terminal > Run Task** e escolha **Run delivery app (JDK 25)**; essa tarefa também solicita a senha de conexão sem exibi-la. Para executar os comandos Maven de dentro de `nosql-app`, use `mvn compile exec:java` com `DELIVERY_PG_PASSWORD` configurada.

Ao terminar, remova as variáveis de senha do processo:

```powershell
Remove-Item Env:DELIVERY_PG_DBA_PASSWORD, Env:DELIVERY_PG_CLIENTE_PASSWORD, Env:DELIVERY_PG_RESTAURANTE_PASSWORD, Env:DELIVERY_PG_ENTREGADOR_PASSWORD, Env:DELIVERY_PG_PASSWORD, Env:PGPASSWORD -ErrorAction SilentlyContinue
```

O script `etc\configura_banco.bat` também configura o banco e solicita a senha administrativa sem exibi-la. **Atenção:** ele recria o banco e apaga os dados existentes.

Senhas que já tenham sido publicadas devem ser trocadas também em qualquer banco existente; alterar os arquivos do repositório não invalida senhas antigas. Para trocá-las sem exibir os valores, conecte-se como administrador (`psql -h localhost -U postgres -d delivery`) e use o comando interativo `\password usuario_dba` (repita para cada usuário que precisar rotacionar).

## Menu do programa

```
1. Semear Cardapio com Itens Customizaveis (MongoDB)
2. Realizar Novo Pedido Hibrido (PostgreSQL + MongoDB)
3. Avaliar Restaurante com Fotos (MongoDB)
4. Ver Nota Media de Restaurante (MongoDB Aggregation)
5. Listar Historico de Pedidos com Detalhes (Hibrido)
0. Sair
```

Pra testar tudo, a ordem que faz mais sentido é: roda a opção 1 primeiro (semeia o cardápio no Mongo), depois 2 (faz um pedido), 3 (avalia), 4 (vê a média) e 5 (lista tudo junto).

## Como Postgres e Mongo se conversam

A tabela `pedido_itens` (Postgres) tem uma coluna `mongodb_item_id` que guarda o `_id` do documento de customização lá no Mongo. É basicamente isso que liga os dois bancos: o pedido em si (valor, pagamento, status) fica garantido no Postgres com transação ACID, e a personalização do item (borda, ingrediente extra, observação) fica solta no Mongo sem precisar mexer no schema relacional toda vez que inventar uma opção nova.

## Por que usar os dois bancos (CAP)

O trabalho pede pra justificar com o Teorema CAP. Resumindo bem simples:

- **PostgreSQL = CA** (Consistência + Disponibilidade). Como é tudo ACID com COMMIT/ROLLBACK, dado financeiro (pedido, pagamento) não pode ficar inconsistente, então faz sentido usar ele pra isso.
- **MongoDB = AP** (Disponibilidade + Tolerância a Partição). Não tem schema fixo nem constraint entre as collections, então é mais flexível - serve bem pra coisa que muda de formato de restaurante pra restaurante, tipo as opções do cardápio e as fotos da avaliação.