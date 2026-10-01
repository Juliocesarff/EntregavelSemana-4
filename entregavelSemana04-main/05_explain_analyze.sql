-- =====================================================================
-- 05_explain_analyze.sql — Verificação do uso real dos índices
-- =====================================================================
SET search_path TO granorte;

-- CONSULTA 1: histórico de um veículo (usa idx_acesso_veiculo_entrada)
EXPLAIN (ANALYZE, BUFFERS)
SELECT id_acesso, entrada_em, saida_em, status
FROM acesso
WHERE id_veiculo = 10
ORDER BY entrada_em DESC
LIMIT 20;

-- CONSULTA 2: veículos ainda na planta (usa índice parcial idx_acesso_abertos)
EXPLAIN (ANALYZE, BUFFERS)
SELECT a.id_acesso, v.placa, a.entrada_em
FROM acesso a
JOIN veiculo v ON v.id_veiculo = a.id_veiculo
WHERE a.saida_em IS NULL
ORDER BY a.entrada_em;

-- CONSULTA 3 (comparativo): mesma consulta 1 SEM os índices de acesso => Seq Scan
BEGIN;
DROP INDEX idx_acesso_veiculo_entrada;
DROP INDEX idx_acesso_entrada_em;
EXPLAIN (ANALYZE, BUFFERS)
SELECT id_acesso, entrada_em, saida_em, status
FROM acesso
WHERE id_veiculo = 10
ORDER BY entrada_em DESC
LIMIT 20;
ROLLBACK;  -- os índices são restaurados
