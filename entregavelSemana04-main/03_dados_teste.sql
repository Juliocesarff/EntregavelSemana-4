-- 03_dados_teste.sql — massa de dados para o EXPLAIN ANALYZE ter volume realista
SET search_path TO granorte;

INSERT INTO usuario (nome, email, senha_hash, perfil) VALUES
 ('Admin Granorte',  'admin@granorte.com.br',  'hash_demo', 'ADMIN'),
 ('Operador Portaria','operador@granorte.com.br','hash_demo','OPERADOR'),
 ('Auditor Interno', 'auditor@granorte.com.br', 'hash_demo', 'AUDITOR');

INSERT INTO transportadora (razao_social, cnpj)
SELECT 'Transportadora ' || g, lpad(g::text, 14, '0') FROM generate_series(1, 20) g;

INSERT INTO motorista (id_transportadora, nome, cpf, cnh_validade)
SELECT 1 + (g % 20), 'Motorista ' || g, lpad(g::text, 11, '0'), current_date + 365
FROM generate_series(1, 200) g;

INSERT INTO veiculo (id_transportadora, placa, capacidade_ton)
SELECT 1 + (g % 20),
       chr(65 + g % 26) || chr(65 + (g / 26) % 26) || chr(65 + (g / 676) % 26)
         || (g % 10) || 'A' || lpad((g % 100)::text, 2, '0'),
       20 + (g % 15)
FROM generate_series(1, 500) g
ON CONFLICT DO NOTHING;

INSERT INTO camera (nome, tipo, url_rtsp) VALUES
 ('Cam Placa Frente',   'PLACA_FRENTE',       'rtsp://cam1'),
 ('Cam Placa Traseira', 'PLACA_TRAS',         'rtsp://cam2'),
 ('Cam Basculante Ent', 'BASCULANTE_ENTRADA', 'rtsp://cam3'),
 ('Cam Basculante Sai', 'BASCULANTE_SAIDA',   'rtsp://cam4');

-- 100 mil acessos distribuídos em ~1 ano
INSERT INTO acesso (id_veiculo, id_motorista, entrada_em, saida_em, status, carga_entrada, carga_saida)
SELECT v.id_veiculo,
       1 + (g % 200),
       ts,
       CASE WHEN g % 50 = 0 THEN NULL ELSE ts + interval '90 minutes' END,
       CASE WHEN g % 50 = 0 THEN 'CONFERENCIA_MANUAL'::status_acesso ELSE 'FINALIZADO'::status_acesso END,
       'VAZIA', CASE WHEN g % 50 = 0 THEN NULL ELSE 'CHEIA'::estado_cacamba END
FROM (SELECT g, now() - (g * interval '5 minutes') AS ts FROM generate_series(1, 100000) g) s(g, ts)
JOIN LATERAL (SELECT id_veiculo FROM veiculo ORDER BY id_veiculo OFFSET (s.g % 500) LIMIT 1) v ON true;

INSERT INTO leitura_ia (id_acesso, id_camera, placa_lida, confianca, estado_cacamba)
SELECT id_acesso, 1, 'ABC1D23', 70 + (id_acesso % 30), NULL FROM acesso;

ANALYZE;
