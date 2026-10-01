-- =====================================================================
-- 01_ddl.sql — Modelo lógico (3FN) implementado em PostgreSQL
-- Projeto: Controle de Acesso Veicular Granorte
-- =====================================================================
DROP SCHEMA IF EXISTS granorte CASCADE;
CREATE SCHEMA granorte;
SET search_path TO granorte;

-- ---------- Tipos enumerados (integridade de domínio) ----------------
CREATE TYPE perfil_usuario   AS ENUM ('ADMIN', 'OPERADOR', 'AUDITOR');
CREATE TYPE status_acesso    AS ENUM ('AUTORIZADO', 'CONFERENCIA_MANUAL', 'NEGADO', 'FINALIZADO');
CREATE TYPE tipo_camera      AS ENUM ('PLACA_FRENTE', 'PLACA_TRAS', 'BASCULANTE_ENTRADA', 'BASCULANTE_SAIDA');
CREATE TYPE estado_cacamba   AS ENUM ('CHEIA', 'VAZIA', 'NAO_IDENTIFICADO');

-- ---------- Usuários do sistema (login da plataforma) -----------------
CREATE TABLE usuario (
    id_usuario     SERIAL       PRIMARY KEY,
    nome           VARCHAR(120) NOT NULL,
    email          VARCHAR(160) NOT NULL UNIQUE,
    senha_hash     TEXT         NOT NULL,
    perfil         perfil_usuario NOT NULL DEFAULT 'OPERADOR',
    ativo          BOOLEAN      NOT NULL DEFAULT TRUE,
    criado_em      TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- ---------- Transportadora / Motorista / Veículo ----------------------
CREATE TABLE transportadora (
    id_transportadora SERIAL       PRIMARY KEY,
    razao_social      VARCHAR(160) NOT NULL,
    cnpj              CHAR(14)     NOT NULL UNIQUE,
    ativa             BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT ck_cnpj_numerico CHECK (cnpj ~ '^[0-9]{14}$')
);

CREATE TABLE motorista (
    id_motorista      SERIAL       PRIMARY KEY,
    id_transportadora INT          NOT NULL REFERENCES transportadora(id_transportadora),
    nome              VARCHAR(120) NOT NULL,
    cpf               CHAR(11)     NOT NULL UNIQUE,
    cnh_validade      DATE         NOT NULL,
    ativo             BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT ck_cpf_numerico CHECK (cpf ~ '^[0-9]{11}$')
);

CREATE TABLE veiculo (
    id_veiculo        SERIAL       PRIMARY KEY,
    id_transportadora INT          NOT NULL REFERENCES transportadora(id_transportadora),
    placa             CHAR(7)      NOT NULL UNIQUE,
    tipo              VARCHAR(30)  NOT NULL DEFAULT 'BASCULANTE',
    capacidade_ton    NUMERIC(6,2) NOT NULL,
    autorizado        BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT ck_placa_formato CHECK (placa ~ '^[A-Z]{3}[0-9][A-Z0-9][0-9]{2}$'),
    CONSTRAINT ck_capacidade    CHECK (capacidade_ton > 0)
);

-- ---------- Câmeras ----------------------------------------------------
CREATE TABLE camera (
    id_camera   SERIAL      PRIMARY KEY,
    nome        VARCHAR(60) NOT NULL UNIQUE,
    tipo        tipo_camera NOT NULL,
    url_rtsp    TEXT        NOT NULL,
    ativa       BOOLEAN     NOT NULL DEFAULT TRUE
);

-- ---------- Acesso veicular (entrada/saída) ---------------------------
CREATE TABLE acesso (
    id_acesso       BIGSERIAL     PRIMARY KEY,
    id_veiculo      INT           NOT NULL REFERENCES veiculo(id_veiculo),
    id_motorista    INT           REFERENCES motorista(id_motorista),
    id_usuario_conf INT           REFERENCES usuario(id_usuario),  -- quem conferiu manualmente
    entrada_em      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    saida_em        TIMESTAMPTZ,
    status          status_acesso NOT NULL DEFAULT 'CONFERENCIA_MANUAL',
    carga_entrada   estado_cacamba NOT NULL DEFAULT 'NAO_IDENTIFICADO',
    carga_saida     estado_cacamba,
    peso_liquido_kg NUMERIC(10,2),
    observacao      TEXT,
    CONSTRAINT ck_saida_apos_entrada CHECK (saida_em IS NULL OR saida_em >= entrada_em),
    CONSTRAINT ck_peso_positivo      CHECK (peso_liquido_kg IS NULL OR peso_liquido_kg >= 0)
);

-- ---------- Leituras da IA (placa/OCR/classificação de caçamba) -------
CREATE TABLE leitura_ia (
    id_leitura     BIGSERIAL     PRIMARY KEY,
    id_acesso      BIGINT        NOT NULL REFERENCES acesso(id_acesso) ON DELETE CASCADE,
    id_camera      INT           NOT NULL REFERENCES camera(id_camera),
    placa_lida     VARCHAR(10),
    confianca      NUMERIC(5,2)  NOT NULL,
    estado_cacamba estado_cacamba,
    capturado_em   TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT ck_confianca CHECK (confianca BETWEEN 0 AND 100)
);

-- ---------- Auditoria ---------------------------------------------------
CREATE TABLE auditoria (
    id_auditoria BIGSERIAL   PRIMARY KEY,
    id_usuario   INT         REFERENCES usuario(id_usuario),
    acao         VARCHAR(20) NOT NULL,
    tabela       VARCHAR(40) NOT NULL,
    id_registro  BIGINT,
    detalhes     TEXT,
    criado_em    TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_acao CHECK (acao IN ('INSERT','UPDATE','DELETE','LOGIN','APROVACAO'))
);
