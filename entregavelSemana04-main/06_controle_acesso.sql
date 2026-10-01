-- =====================================================================
-- 06_controle_acesso.sql — Princípio do menor privilégio
-- Executar como superusuário (postgres).
-- =====================================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'role_operador')  THEN CREATE ROLE role_operador  NOLOGIN; END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'role_auditor')   THEN CREATE ROLE role_auditor   NOLOGIN; END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'usr_portaria')   THEN CREATE USER usr_portaria   PASSWORD 'troque_esta_senha_1'; END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'usr_auditoria')  THEN CREATE USER usr_auditoria  PASSWORD 'troque_esta_senha_2'; END IF;
END $$;

SET search_path TO granorte;

-- Ninguém herda acesso por padrão
REVOKE ALL ON SCHEMA granorte FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA granorte FROM PUBLIC;

GRANT USAGE ON SCHEMA granorte TO role_operador, role_auditor;

-- OPERADOR (portaria): lê cadastros, registra e atualiza acessos/leituras
GRANT SELECT ON transportadora, motorista, veiculo, camera TO role_operador;
GRANT SELECT, INSERT, UPDATE ON acesso TO role_operador;
GRANT SELECT, INSERT ON leitura_ia, auditoria TO role_operador;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA granorte TO role_operador;
-- (sem DELETE e sem acesso à tabela usuario/senha_hash)

-- AUDITOR: somente leitura; nunca vê hash de senha
GRANT SELECT ON transportadora, motorista, veiculo, camera, acesso, leitura_ia, auditoria TO role_auditor;
GRANT SELECT (id_usuario, nome, email, perfil, ativo) ON usuario TO role_auditor;

-- Associação usuário -> role
GRANT role_operador TO usr_portaria;
GRANT role_auditor  TO usr_auditoria;

-- REVOKE explícito: operador não pode alterar a trilha de auditoria
REVOKE UPDATE, DELETE ON auditoria FROM role_operador;
REVOKE INSERT ON auditoria FROM role_auditor;

ALTER ROLE usr_portaria  SET search_path = granorte;
ALTER ROLE usr_auditoria SET search_path = granorte;
