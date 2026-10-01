-- =====================================================================
-- 02_dml.sql — Carga de dados (>= 3 INSERT por tabela) e consultas com JOIN
-- Executar após 01_ddl.sql, em banco vazio (IDs SERIAL começam em 1).
-- =====================================================================
SET search_path TO granorte;

-- ---------- usuario ----------
INSERT INTO usuario (nome, email, senha_hash, perfil) VALUES ('Ana Souza',   'ana.souza@granorte.com.br',   'hash_ana',   'ADMIN');
INSERT INTO usuario (nome, email, senha_hash, perfil) VALUES ('Bruno Lima',  'bruno.lima@granorte.com.br',  'hash_bruno', 'OPERADOR');
INSERT INTO usuario (nome, email, senha_hash, perfil) VALUES ('Carla Mendes','carla.mendes@granorte.com.br','hash_carla', 'AUDITOR');

-- ---------- transportadora ----------
INSERT INTO transportadora (razao_social, cnpj) VALUES ('Translog Maranhão Ltda',   '11222333000181');
INSERT INTO transportadora (razao_social, cnpj) VALUES ('Rota Norte Transportes',   '22333444000172');
INSERT INTO transportadora (razao_social, cnpj) VALUES ('Cargas do Nordeste S/A',   '33444555000163');

-- ---------- motorista ----------
INSERT INTO motorista (id_transportadora, nome, cpf, cnh_validade) VALUES (1, 'José Almeida',   '11122233344', '2028-05-10');
INSERT INTO motorista (id_transportadora, nome, cpf, cnh_validade) VALUES (2, 'Marcos Pereira', '22233344455', '2027-11-30');
INSERT INTO motorista (id_transportadora, nome, cpf, cnh_validade) VALUES (3, 'Paulo Ribeiro',  '33344455566', '2029-02-15');

-- ---------- veiculo ----------
INSERT INTO veiculo (id_transportadora, placa, tipo, capacidade_ton) VALUES (1, 'ABC1D23', 'BASCULANTE', 32.00);
INSERT INTO veiculo (id_transportadora, placa, tipo, capacidade_ton) VALUES (2, 'QRS4T56', 'BASCULANTE', 28.50);
INSERT INTO veiculo (id_transportadora, placa, tipo, capacidade_ton) VALUES (3, 'MNO7P89', 'BASCULANTE', 35.00);

-- ---------- camera ----------
INSERT INTO camera (nome, tipo, url_rtsp) VALUES ('Cam Placa Frente',   'PLACA_FRENTE',       'rtsp://192.168.0.11/stream');
INSERT INTO camera (nome, tipo, url_rtsp) VALUES ('Cam Placa Traseira', 'PLACA_TRAS',         'rtsp://192.168.0.12/stream');
INSERT INTO camera (nome, tipo, url_rtsp) VALUES ('Cam Basculante Entrada', 'BASCULANTE_ENTRADA', 'rtsp://192.168.0.13/stream');
INSERT INTO camera (nome, tipo, url_rtsp) VALUES ('Cam Basculante Saída',   'BASCULANTE_SAIDA',   'rtsp://192.168.0.14/stream');

-- ---------- acesso ----------
INSERT INTO acesso (id_veiculo, id_motorista, id_usuario_conf, entrada_em, saida_em, status, carga_entrada, carga_saida, peso_liquido_kg)
VALUES (1, 1, NULL, '2026-09-28 07:45-03', '2026-09-28 09:10-03', 'FINALIZADO', 'VAZIA', 'CHEIA', 31200.00);
INSERT INTO acesso (id_veiculo, id_motorista, id_usuario_conf, entrada_em, saida_em, status, carga_entrada, carga_saida, peso_liquido_kg)
VALUES (2, 2, 2,    '2026-09-28 08:20-03', '2026-09-28 10:05-03', 'FINALIZADO', 'VAZIA', 'CHEIA', 27800.00);
INSERT INTO acesso (id_veiculo, id_motorista, id_usuario_conf, entrada_em, saida_em, status, carga_entrada)
VALUES (3, 3, 2,    '2026-09-29 06:50-03', NULL, 'CONFERENCIA_MANUAL', 'VAZIA');
INSERT INTO acesso (id_veiculo, id_motorista, id_usuario_conf, entrada_em, saida_em, status, carga_entrada)
VALUES (1, 1, NULL, '2026-09-29 07:30-03', NULL, 'AUTORIZADO', 'VAZIA');

-- ---------- leitura_ia ----------
INSERT INTO leitura_ia (id_acesso, id_camera, placa_lida, confianca, estado_cacamba, capturado_em) VALUES (1, 1, 'ABC1D23', 96.40, NULL,    '2026-09-28 07:45-03');
INSERT INTO leitura_ia (id_acesso, id_camera, placa_lida, confianca, estado_cacamba, capturado_em) VALUES (1, 3, NULL,      91.20, 'VAZIA', '2026-09-28 07:46-03');
INSERT INTO leitura_ia (id_acesso, id_camera, placa_lida, confianca, estado_cacamba, capturado_em) VALUES (2, 1, 'QRS4T56', 88.75, NULL,    '2026-09-28 08:20-03');
INSERT INTO leitura_ia (id_acesso, id_camera, placa_lida, confianca, estado_cacamba, capturado_em) VALUES (3, 1, 'MNO7P89', 72.10, NULL,    '2026-09-29 06:50-03');
INSERT INTO leitura_ia (id_acesso, id_camera, placa_lida, confianca, estado_cacamba, capturado_em) VALUES (4, 2, 'ABC1D23', 94.00, NULL,    '2026-09-29 07:30-03');

-- ---------- auditoria ----------
INSERT INTO auditoria (id_usuario, acao, tabela, id_registro, detalhes) VALUES (1, 'LOGIN',     'usuario', 1, 'Login do administrador');
INSERT INTO auditoria (id_usuario, acao, tabela, id_registro, detalhes) VALUES (2, 'APROVACAO', 'acesso',  2, 'Conferência manual aprovada (confiança 88,75%)');
INSERT INTO auditoria (id_usuario, acao, tabela, id_registro, detalhes) VALUES (2, 'UPDATE',    'acesso',  3, 'Acesso enviado para conferência manual (confiança 72,10%)');

-- =====================================================================
-- CONSULTAS COM JOIN
-- =====================================================================

-- Consulta 1: histórico de acessos com veículo, motorista e transportadora (4 tabelas)
SELECT a.id_acesso,
       v.placa,
       m.nome            AS motorista,
       t.razao_social    AS transportadora,
       a.entrada_em,
       a.saida_em,
       a.status
FROM acesso a
JOIN veiculo       v ON v.id_veiculo        = a.id_veiculo
JOIN motorista     m ON m.id_motorista      = a.id_motorista
JOIN transportadora t ON t.id_transportadora = v.id_transportadora
ORDER BY a.entrada_em DESC;

-- Consulta 2: leituras da IA abaixo do limiar de 85% (vão para conferência manual)
SELECT l.id_leitura,
       v.placa,
       c.nome       AS camera,
       l.confianca,
       a.status     AS status_acesso,
       u.nome       AS conferido_por
FROM leitura_ia l
JOIN camera  c ON c.id_camera  = l.id_camera
JOIN acesso  a ON a.id_acesso  = l.id_acesso
JOIN veiculo v ON v.id_veiculo = a.id_veiculo
LEFT JOIN usuario u ON u.id_usuario = a.id_usuario_conf
WHERE l.confianca < 85
ORDER BY l.confianca;

-- Consulta 3 (extra): total de acessos e carga líquida por transportadora
SELECT t.razao_social,
       COUNT(a.id_acesso)                  AS total_acessos,
       COALESCE(SUM(a.peso_liquido_kg), 0) AS peso_total_kg
FROM transportadora t
LEFT JOIN veiculo v ON v.id_transportadora = t.id_transportadora
LEFT JOIN acesso  a ON a.id_veiculo        = v.id_veiculo
GROUP BY t.razao_social
ORDER BY total_acessos DESC;
