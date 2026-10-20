# TP01 — Deteção de fraude em transações financeiras

## Identificação

- **Autor:** Bruno Paiva
- **Número de aluno:** 31496
- **Curso:** 3.º ano da Licenciatura em Engenharia de Sistemas Informáticos (LESI)
- **Unidade curricular:** Integração de Sistemas de Informação
- **Trabalho:** Individual

## Descrição

Este projeto implementa um processo ETL para deteção de transações financeiras suspeitas. Os workflows KNIME recolhem, transformam e carregam dados; PostgreSQL guarda os resultados e os serviços auxiliares são executados com Docker Compose.

O fluxo principal é:

1. `01_ingestao` — recolhe dados de ficheiros e da base de dados;
2. `02_transformacao` — limpa, cruza e transforma os dados, calcula indicadores e separa alertas;
3. `03_carga_notificacao` — carrega os resultados, exporta ficheiros e envia notificações;
4. `00_orquestrador` — chama os três workflows pela ordem indicada.

## Ficheiros entregues

- `dataintegration/workflows/00_orquestrador/` — workflow que orquestra as fases ETL;
- `dataintegration/workflows/01_ingestao/` — workflow de ingestão;
- `dataintegration/workflows/02_transformacao/` — workflow de transformação;
- `dataintegration/workflows/03_carga_notificacao.knwf/` — workflow de carga e notificação;
- `data/input/` — dados de entrada: transações CSV, cartões e câmbios JSON, regras XML e países de risco CSV;
- `data/output/` — exemplos dos ficheiros exportados pelo workflow;
- `src/sql/schema.sql` — criação das tabelas PostgreSQL;
- `src/node-red/` — fluxo e configuração do Node-RED;
- `src/mosquitto/` — configuração do broker MQTT;
- `src/grafana/dashboard.json` — dashboard de visualização dos alertas (formato _dashboard-as-code_ do Grafana);
- `docker-compose.yml` — configuração dos serviços PostgreSQL, Mosquitto, Node-RED, Grafana e MailHog;
- `doc/31496_doc.pdf` — relatório final a adicionar antes da entrega.

## Requisitos

- Docker Desktop com Docker Compose;
- KNIME Analytics Platform 5.12 ou compatível com os workflows e as extensões usadas.

## Como executar

1. Iniciar os serviços:

   ```bash
   docker compose up -d
   ```

2. Confirmar que estão ativos:

   ```bash
   docker compose ps
   ```

3. Abrir no KNIME a pasta `dataintegration/workflows/00_orquestrador/` e executar o workflow `00_orquestrador`.

4. Consultar os resultados na base de dados `fraude`, no dashboard do Grafana (<http://localhost:3000>), na caixa de correio do MailHog (<http://localhost:8025>) e nos ficheiros exportados em `data/output/`.

Para parar os serviços:

```bash
docker compose down
```

## Serviços locais

- PostgreSQL: `localhost:5432` — base de dados `fraude`, utilizador `etl`;
- Node-RED: <http://localhost:1880>;
- Grafana: <http://localhost:3000>;
- MailHog: <http://localhost:8025> (SMTP em `localhost:1025`);
- Mosquitto MQTT: `localhost:1883`.

## Grafana

O Grafana (<http://localhost:3000>) usa a base de dados `fraude` e é a camada de visualização do processo. A autenticação é local (`admin` / `admin` por omissão no primeiro acesso).

O dashboard **`Dashboard - Deteção Fraude`** está versionado em `src/grafana/dashboard.json`, exportado no formato _dashboard-as-code_ (`apiVersion: dashboard.grafana.app/v2`), e tem três painéis:

| Painel                   | O que mostra                                                                                        |
| ------------------------ | --------------------------------------------------------------------------------------------------- |
| Alertas por hora         | número de alertas por hora, juntando `mart_alertas` a `stg_ingestao`;                               |
| Países de Risco          | os 5 países com mais alertas, a partir de `mart_resumo_diario`;                                     |
| Valor Total e Sinalizado | valor total transacionado versus valor sinalizado, por dia (`mart_resumo_diario` e `mart_alertas`). |

## MailHog (notificações por email)

O MailHog é o servidor SMTP de testes usado na notificação: guarda as mensagens enviadas pelo KNIME e permite lê-las na interface web <http://localhost:8025>, sem enviar nada para o exterior. O node **Send Email** do `03_carga_notificacao` liga-se a `localhost:1025`:

| Campo          | Valor                                                      |
| -------------- | ---------------------------------------------------------- |
| Servidor SMTP  | `localhost`, porta `1025`                                  |
| Remetente      | `knime@localhost`                                          |
| Destinatário   | `fraude@example.test`                                      |
| Assunto        | `Alertas de fraude`                                        |
| Corpo          | `Foram identificados $${ICount(id_transacao)}$$ alertas.`  |

O email **só é enviado quando existe pelo menos um alerta**. O ramo de notificação é alimentado exclusivamente pela saída `alertas` do `02_transformacao` — as transações que o score sinaliza como suspeitas — e o corpo da mensagem é construído a partir do número de linhas desse ramo (`GroupBy` → `Table Row to Variable` → `Send Email`). Se não houver alertas, a tabela chega vazia ao `Table Row to Variable`, a variável usada no corpo nunca é definida e não há mensagem a enviar: nunca sai um email "sem novidades".

**NOTA**: Os caminhos de ficheiros dos nodes KNIME foram ajustados para esta cópia. Se a pasta for extraída noutro local ou computador, atualizar nos workflows os caminhos dos dados em `data/input/` e dos ficheiros de saída em `data/output/`.
