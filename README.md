# 🛠 Event Logger: Sua Solução para Depuração de Eventos no FiveM 🛠

---

**Event Logger** é uma ferramenta robusta, desenvolvida com o intuito de auxiliar administradores e desenvolvedores de servidores FiveM a identificar e solucionar problemas associados a eventos que podem estar comprometendo a estabilidade e desempenho do servidor. Este script é focado em eventos que vão do servidor para o cliente (S > C), conhecidos por seu alto custo de processamento e impacto significativo na rede.

## ✨ Destaques e Funcionalidades

- **Análise Específica de Eventos S > C**: Monitoramento direcionado para eventos que transitam do servidor para o cliente, identificando potenciais gargalos e excessos.
- **Identificação Precisa**: Localiza eventos disparados em excesso, proporcionando dados concretos para uma rápida resolução.
- **Logs Detalhados**: Produz registros minuciosos, essenciais para uma análise aprofundada e identificação de eventos problemáticos.

## ⚠ Alertas: Quando Utilizar o Event Logger?

Fique atento aos seguintes sinais no seu servidor, que indicam que o Event Logger pode ser uma ferramenta crucial:

- `Network thread hitch warning`
- `Sync thread hitch warning`

Estas mensagens são sintomas claros de que algo não está certo e uma investigação é necessária.

## 🚀 Como Implementar

### 1️⃣ Instalação e Preparação

Primeiramente, é necessário preparar o terreno instalando as dependências necessárias em todos os recursos do servidor.

```sh
/loginstall
```

- **Execute no terminal do servidor**: Este comando configura tudo para você, garantindo que o Logger opere em plena capacidade.

### 2️⃣ Limpeza Pós-Análise

Após finalizar sua investigação e identificar os culpados, não se esqueça de fazer uma limpeza:

```sh
/loguninstall
```

- **Terminal do Servidor**: Um comando rápido aqui e você remove todas as dependências, deixando seu servidor limpo e ágil novamente.

### 3️⃣ Capturando e Analisando Logs

Quando os primeiros sinais de problemas aparecerem, aqui está o que você precisa fazer:

1. **Dispare o Comando**: `/logevent` diretamente no terminal.
   - Isso gerará um arquivo .log com todos os eventos dos últimos 10 minutos.
2. **Vá até `server-data`**: Dentro, localize a pasta `logEvent` e abra o documento .log que foi gerado.
3. **Hora da Análise**: Mergulhe nos dados, identifique os eventos que estão pesando mais e tome as medidas necessárias.

## 💬 Suporte e Comunidade

Precisa de ajuda? Tem perguntas? Junte-se à nossa comunidade e vamos resolver isso juntos!

---

🎉 **Salvamos o Dia?** Se o Event Logger foi a solução que você precisava, estamos aqui para comemorar a vitória com você! 🎉

📣 **Espalhe a Palavra**: Se você achou essa ferramenta útil, compartilhe com outros administradores e desenvolvedores!

🤝 **Estamos Juntos Nessa**: A comunidade FiveM é forte, e com ferramentas como o Event Logger, fica ainda mais forte!

---