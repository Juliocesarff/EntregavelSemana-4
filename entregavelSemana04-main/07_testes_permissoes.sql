-- 07_testes_permissoes.sql — prova do menor privilégio (executar como postgres)
SET search_path TO granorte;

SET ROLE usr_portaria;
SELECT count(*) AS operador_le_veiculos FROM veiculo;
DO $$ BEGIN DELETE FROM acesso WHERE id_acesso = -1; EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'OPERADOR: DELETE em acesso NEGADO (esperado)'; END $$;
DO $$ BEGIN PERFORM senha_hash FROM usuario; EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'OPERADOR: leitura de usuario NEGADA (esperado)'; END $$;
RESET ROLE;

SET ROLE usr_auditoria;
SELECT count(*) AS auditor_le_acessos FROM acesso;
DO $$ BEGIN INSERT INTO auditoria (acao, tabela) VALUES ('INSERT','x'); EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'AUDITOR: INSERT NEGADO (esperado)'; END $$;
DO $$ BEGIN PERFORM senha_hash FROM usuario; EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'AUDITOR: coluna senha_hash NEGADA (esperado)'; END $$;
RESET ROLE;
