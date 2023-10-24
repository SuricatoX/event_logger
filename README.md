# Event Logger: Ferramenta de Depuração de Eventos para Servidores FiveM

O Event Logger é uma ferramenta poderosa destinada a ajudar administradores e desenvolvedores de servidores FiveM a diagnosticar e resolver problemas relacionados a eventos que podem estar causando instabilidade ou quedas no servidor. Especialmente projetado para rastrear eventos do servidor para o cliente (S > C), este script é essencial quando você suspeita que eventos excessivos estão afetando o desempenho do seu servidor.

## Recursos e Funcionalidades

- **Depuração de Eventos S > C**: Foca na monitoração de eventos que vão do servidor para o cliente, que são conhecidos por terem um alto custo de rede e CPU, e são os mais propensos a causar problemas de desempenho.
- **Detecção de Eventos Excessivos**: Ajuda a identificar eventos específicos que podem estar sendo disparados em excesso, permitindo uma ação rápida para resolver o problema.
- **Logs Detalhados**: Gera logs detalhados que podem ser revisados para identificar os eventos problemáticos.

## Alertas e Indicações de Problemas

Quando o servidor começa a apresentar os seguintes sinais, é um indicativo de que o Event Logger pode ser necessário:

- `Network thread hitch warning`
- `Sync thread hitch warning`

## Como Usar

### 1. Instalação da Dependência

Antes de começar a depurar, você precisa instalar as dependências necessárias em todos os recursos do seu servidor.

```sh
/loginstall
```

- Execute este comando no terminal do servidor.
- Isso garantirá que o script do logger funcione adequadamente.

### 2. Remoção da Dependência

Após concluir a análise e antes de remover o script, as dependências devem ser removidas:

```sh
/loguninstall
```

- Execute este comando no terminal do servidor.

### 3. Captura de Logs de Eventos

Quando você perceber que o servidor está começando a apresentar warnings de `Network` e `Sync thread hitch`, siga estes passos:

1. Execute o comando `/logevent` no terminal. Isso irá gerar um arquivo .log com os disparos de eventos dos últimos 10 minutos.
2. Vá até o diretório `server-data` (onde o seu arquivo `server.cfg` está localizado), abra a pasta `logEvent` e abra o documento .log gerado.
3. Analise o documento para identificar quais eventos podem estar sobrecarregando o servidor.

## Suporte e Contato

Se você precisar de ajuda ou quiser discutir sobre o script, fique à vontade para entrar em contato.

---

Se essa ferramenta ajudou a salvar o seu servidor, fico feliz em poder ajudar. Tamo junto! 🤝