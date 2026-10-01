# Modelagem Lógica (3FN) — Controle de Acesso Veicular Granorte (Sprint 3)

Transformação do modelo conceitual (MER) do projeto *Sistema Inteligente de Monitoramento e Controle de Acesso Veicular da Granorte* em modelo relacional, normalizado até a **3ª Forma Normal**, implementado em **PostgreSQL**.

## Conteúdo do repositório

| Arquivo | Descrição |
|---|---|
| `docs/diagrama_logico.md` | Diagrama do modelo lógico em Mermaid (renderiza direto no GitHub) |
| `sql/01_ddl.sql` | `CREATE TABLE` com PK, FK, `NOT NULL`, `UNIQUE`, `CHECK`, `DEFAULT` |
| `sql/02_dml.sql` | ≥ 3 `INSERT` por tabela + 3 consultas `SELECT` com `JOIN` |

Como executar (em banco vazio):

```bash
createdb granorte_db
psql -d granorte_db -f sql/01_ddl.sql
psql -d granorte_db -f sql/02_dml.sql
```

## Cenário

Na portaria da Granorte, câmeras leem a placa e o estado da caçamba dos caminhões basculantes. Cada passagem gera um **acesso** (entrada/saída) e várias **leituras da IA**. Leituras com confiança < 85% vão para conferência manual de um usuário. Tudo fica registrado para auditoria.

## Mapeamento MER → Relacional

| Regra | Aplicação |
|---|---|
| Entidade → tabela | `transportadora`, `motorista`, `veiculo`, `usuario`, `camera`, `acesso`, `leitura_ia`, `auditoria` |
| Relacionamento 1:N → FK no lado N | `veiculo.id_transportadora`, `motorista.id_transportadora`, `acesso.id_veiculo`, `acesso.id_motorista`, `leitura_ia.id_acesso`, `leitura_ia.id_camera`, `auditoria.id_usuario` |
| Relacionamento opcional → FK anulável | `acesso.id_motorista` e `acesso.id_usuario_conf` (só preenchido se houve conferência manual) |
| Relacionamento N:N → tabela associativa | Acesso × Câmera é N:N; resolvido por `leitura_ia`, que ainda guarda atributos próprios (placa lida, confiança, estado da caçamba, horário) |
| Atributo → coluna | Chaves substitutas (`SERIAL`) e naturais protegidas por `UNIQUE` (placa, CPF, CNPJ, e-mail) |

## Normalização até a 3FN

**Ponto de partida (tabela única, como seria numa planilha da portaria):**

`REGISTRO(placa, tipo_veiculo, capacidade_ton, cnpj, razao_social, cpf_motorista, nome_motorista, cnh_validade, nome_conferente, email_conferente, perfil_conferente, entrada_em, saida_em, status, carga_entrada, carga_saida, camera1, confianca1, camera2, confianca2, ...)`

### 1FN — atributos atômicos e sem grupos repetitivos
- **Problema:** `camera1/confianca1`, `camera2/confianca2`... são um **grupo repetitivo** (número de leituras varia por passagem e as colunas ficam vazias).
- **Correção:** cada leitura vira uma linha. A tabela passa a ter chave composta **(placa, entrada_em, cod_camera)**, e todos os atributos ficam atômicos (um valor por célula).

### 2FN — sem dependência parcial da chave composta
Com a chave **(placa, entrada_em, cod_camera)**, havia dependências parciais:

| Atributos | Dependem apenas de | Nova tabela |
|---|---|---|
| tipo_veiculo, capacidade_ton, cnpj... | `placa` | `veiculo` |
| entrada_em/saída, status, carga, motorista... | `(placa, entrada_em)` | `acesso` |
| nome_camera, tipo_camera, url_rtsp | `cod_camera` | `camera` |
| placa_lida, confiança, estado_cacamba | chave completa | `leitura_ia` |

Assim, cada atributo não-chave depende da **chave inteira** de sua tabela. Na implementação, usamos chaves substitutas (`id_veiculo`, `id_acesso`, `id_camera`), deixando `placa` como `UNIQUE`.

### 3FN — sem dependência transitiva
Dependências onde um atributo não-chave determina outro não-chave:

| Dependência transitiva | Correção |
|---|---|
| `placa → cnpj → razao_social` (razão social depende da transportadora, não do veículo) | tabela `transportadora`; `veiculo` guarda apenas `id_transportadora` (FK) |
| `acesso → cpf_motorista → nome_motorista, cnh_validade` | tabela `motorista`; `acesso` guarda apenas `id_motorista` |
| `motorista → cnpj → razao_social` (mesmo caso) | `motorista.id_transportadora` (FK) |
| `acesso → email_conferente → nome_conferente, perfil_conferente` | tabela `usuario`; `acesso` guarda apenas `id_usuario_conf` |

**Resultado:** cada fato é armazenado uma única vez (a razão social de uma transportadora existe em 1 linha, não em milhares de acessos), eliminando anomalias de inserção, atualização e exclusão.

## Restrições de integridade

- **PK/FK** em todas as tabelas; FKs sem exclusão em cascata, exceto `leitura_ia.id_acesso` (`ON DELETE CASCADE`, pois a leitura não existe sem o acesso).
- **UNIQUE:** `placa`, `cpf`, `cnpj`, `email`, `camera.nome`.
- **CHECK:** formato de placa (Mercosul e antigo), CPF (11 dígitos), CNPJ (14 dígitos), `saida_em >= entrada_em`, `peso_liquido_kg >= 0`, `confianca` entre 0 e 100, `capacidade_ton > 0`.
- **DEFAULT:** `now()` nos timestamps, `ativo = TRUE`, `status = 'CONFERENCIA_MANUAL'`, `carga_entrada = 'NAO_IDENTIFICADO'`.
- **ENUM:** `perfil_usuario`, `status_acesso`, `tipo_camera`, `estado_cacamba`.

## Consultas de exemplo (`sql/02_dml.sql`)

1. **Histórico de acessos** — `acesso ⨝ veiculo ⨝ motorista ⨝ transportadora`.
2. **Leituras com confiança < 85%** — `leitura_ia ⨝ camera ⨝ acesso ⨝ veiculo` + `LEFT JOIN usuario` (quem conferiu).
3. **Acessos e carga por transportadora** — `LEFT JOIN` + `GROUP BY`.
