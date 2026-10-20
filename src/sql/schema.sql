-- TP01 - deteccao de fraude: esquema base
CREATE TABLE stg_ingestao (
  id_transacao  TEXT PRIMARY KEY,
  data_hora     TIMESTAMP,
  pan           TEXT,
  pan_mascara   TEXT,
  id_cartao     TEXT,
  comerciante   TEXT,
  mcc           TEXT,
  pais          TEXT,
  canal         TEXT,
  valor         NUMERIC(12,2),
  moeda         TEXT,
  origem        TEXT
);

CREATE TABLE stg_stream (
  id_mensagem   SERIAL PRIMARY KEY,
  recebido_em   TIMESTAMP DEFAULT now(),
  payload       JSONB
);

CREATE TABLE dim_cartao (
  id_cartao     TEXT PRIMARY KEY,
  id_cliente    TEXT,
  nome_cliente  TEXT,
  pais_emissor  TEXT,
  tipo          TEXT,
  limite        NUMERIC(12,2),
  emitido_em    DATE
);

CREATE TABLE ref_comerciante (
  mcc           TEXT PRIMARY KEY,
  categoria     TEXT,
  risco         SMALLINT
);

CREATE TABLE ref_pais_risco (
  pais          TEXT PRIMARY KEY,
  risco         SMALLINT
);

CREATE TABLE ref_cambio (
  dia           DATE,
  moeda         TEXT,
  taxa_eur      NUMERIC(12,6),
  PRIMARY KEY (dia, moeda)
);

CREATE TABLE mart_alertas (
  id_transacao  TEXT PRIMARY KEY,
  score         INTEGER,
  valor_eur     NUMERIC(12,2),
  criado_em     TIMESTAMP DEFAULT now()
);

CREATE TABLE mart_resumo_diario (
  dia           DATE,
  pais          TEXT,
  n_transacoes  INTEGER,
  n_alertas     INTEGER,
  valor_eur     NUMERIC(14,2), 
  PRIMARY KEY (dia, pais)
);

CREATE TABLE log_execucao (
  execucao_id   SERIAL PRIMARY KEY,
  workflow      TEXT,
  fase          TEXT,
  iniciado_em   TIMESTAMP,
  terminado_em  TIMESTAMP,
  estado        TEXT,
  n_linhas      INTEGER,
  mensagem      TEXT
);
