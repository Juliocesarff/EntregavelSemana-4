-- =====================================================================
-- 04_transacoes.sql — Transações ACID com RETURNING, SAVEPOINT e ROLLBACK
-- =====================================================================
SET search_path TO granorte;

-- ---------------------------------------------------------------------
-- TRANSAÇÃO 1: registrar entrada de um caminhão (veículo + acesso + leituras + auditoria)
-- O RETURNING captura o ID gerado e o repassa às tabelas filhas na mesma transação.
-- ---------------------------------------------------------------------
BEGIN;

WITH novo_veiculo AS (
    INSERT INTO veiculo (id_transportadora, placa, capacidade_ton)
    VALUES (1, 'XYZ9K88', 30)
    RETURNING id_veiculo
), novo_acesso AS (
    INSERT INTO acesso (id_veiculo, id_motorista, status, carga_entrada)
    SELECT id_veiculo, 1, 'AUTORIZADO', 'VAZIA' FROM novo_veiculo
    RETURNING id_acesso
), leituras AS (
    INSERT INTO leitura_ia (id_acesso, id_camera, placa_lida, confianca)
    SELECT id_acesso, 1, 'XYZ9K88', 93.40 FROM novo_acesso
    RETURNING id_acesso
)
INSERT INTO auditoria (id_usuario, acao, tabela, id_registro, detalhes)
SELECT 2, 'INSERT', 'acesso', id_acesso, 'Entrada autorizada pela IA (>=85%)' FROM leituras;

COMMIT;

-- ---------------------------------------------------------------------
-- TRANSAÇÃO 2: conferência manual com SAVEPOINT e ROLLBACK parcial.
-- Se a etapa opcional falhar, desfazemos só ela e mantemos a aprovação.
-- ---------------------------------------------------------------------
BEGIN;

UPDATE acesso
   SET status = 'AUTORIZADO', id_usuario_conf = 2
 WHERE id_acesso = (SELECT min(id_acesso) FROM acesso WHERE status = 'CONFERENCIA_MANUAL');

SAVEPOINT antes_saida;

-- Registro de saída inválido (saída antes da entrada) => viola ck_saida_apos_entrada
DO $$
BEGIN
    UPDATE acesso SET saida_em = entrada_em - interval '1 hour'
     WHERE status = 'AUTORIZADO' AND id_usuario_conf = 2;
EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'Saída inválida rejeitada pela constraint (esperado).';
END $$;

-- Em psql interativo, após um erro real usaríamos: ROLLBACK TO SAVEPOINT antes_saida;
ROLLBACK TO SAVEPOINT antes_saida;

INSERT INTO auditoria (id_usuario, acao, tabela, detalhes)
VALUES (2, 'APROVACAO', 'acesso', 'Conferência manual aprovada; saída inválida descartada');

COMMIT;

-- ---------------------------------------------------------------------
-- TRANSAÇÃO 3 (demonstra ROLLBACK total): erro => nada é gravado
-- ---------------------------------------------------------------------
BEGIN;
INSERT INTO transportadora (razao_social, cnpj) VALUES ('Teste Rollback', '99999999999999');
SELECT count(*) AS transportadoras_dentro_da_transacao FROM transportadora;
ROLLBACK;
SELECT count(*) AS transportadoras_apos_rollback FROM transportadora;
