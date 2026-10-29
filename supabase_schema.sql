-- ==============================================================================
-- AMBIENTE MÉDICO PCD — SCHEMA OFICIAL SUPABASE / POSTGRESQL
-- Projeto: kiyjfjrrbqetolbcctpf
-- URL: https://kiyjfjrrbqetolbcctpf.supabase.co
-- Data de Criação: 28/10/2026
-- Instruções: Cole este script no SQL Editor do seu Dashboard Supabase e execute ("Run").
-- ==============================================================================

-- 1. EXTENSÕES NECESSÁRIAS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 2. TABELA: perfil_medico (Identificação do Médico Responsável)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.perfil_medico (
    id TEXT PRIMARY KEY DEFAULT 'padrao',
    nome TEXT NOT NULL DEFAULT '',
    crm TEXT NOT NULL DEFAULT '',
    uf VARCHAR(2) NOT NULL DEFAULT 'SP',
    especialidade TEXT NOT NULL DEFAULT 'Médico(a) do Trabalho',
    ativo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

COMMENT ON TABLE public.perfil_medico IS 'Perfil e credenciais do médico responsável pelos laudos PCD.';

-- ==============================================================================
-- 3. TABELA: agendamentos (Agenda Médica, Fila do Dia e Status)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.agendamentos (
    id TEXT PRIMARY KEY,
    protocolo TEXT NOT NULL,
    nome TEXT NOT NULL,
    cpf VARCHAR(14) DEFAULT '',
    cargo TEXT DEFAULT '',
    setor TEXT DEFAULT '',
    rg VARCHAR(20) DEFAULT '',
    nascimento DATE,
    data_hora TIMESTAMPTZ,
    data DATE,
    tipo_atendimento TEXT NOT NULL DEFAULT 'Avaliação PCD',
    status TEXT NOT NULL DEFAULT 'aguardando', -- 'aguardando', 'em_andamento', 'pendente', 'concluido'
    observacoes TEXT DEFAULT '',
    origens JSONB DEFAULT '{}'::jsonb,
    atestados JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

COMMENT ON TABLE public.agendamentos IS 'Agenda de atendimentos periciais e fila do dia.';

-- Índices para buscas ultrarrápidas
CREATE INDEX IF NOT EXISTS idx_agendamentos_status ON public.agendamentos(status);
CREATE INDEX IF NOT EXISTS idx_agendamentos_data ON public.agendamentos(data);
CREATE INDEX IF NOT EXISTS idx_agendamentos_cpf ON public.agendamentos(cpf);
CREATE INDEX IF NOT EXISTS idx_agendamentos_nome ON public.agendamentos(nome);

-- ==============================================================================
-- 4. TABELA: laudos_pcd (Histórico Clínico Completo e Emissão de Laudos)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.laudos_pcd (
    id TEXT PRIMARY KEY,
    protocolo TEXT NOT NULL,
    nome TEXT NOT NULL,
    cpf VARCHAR(14) DEFAULT '',
    cargo TEXT DEFAULT '',
    setor TEXT DEFAULT '',
    rg VARCHAR(20) DEFAULT '',
    nascimento DATE,
    local_exame TEXT NOT NULL DEFAULT 'Bauru - SP',
    data_avaliacao DATE NOT NULL DEFAULT CURRENT_DATE,
    medico_responsavel TEXT DEFAULT '',
    
    -- Critérios e Classificações Clínicas (JSONB com estrutura íntegra)
    origens JSONB NOT NULL DEFAULT '{}'::jsonb,
    cid10 VARCHAR(20) DEFAULT '',
    descricao_impedimentos TEXT DEFAULT '',
    tipos JSONB NOT NULL DEFAULT '{}'::jsonb,
    subtipos_fisica JSONB NOT NULL DEFAULT '{}'::jsonb,
    altura_nanismo VARCHAR(20) DEFAULT '',
    impedimentos_fisica JSONB NOT NULL DEFAULT '{}'::jsonb,
    impedimentos_auditiva JSONB NOT NULL DEFAULT '{}'::jsonb,
    subtipos_visual JSONB NOT NULL DEFAULT '{}'::jsonb,
    impedimentos_visual JSONB NOT NULL DEFAULT '{}'::jsonb,
    subtipos_intelectual JSONB NOT NULL DEFAULT '{}'::jsonb,
    data_inicio_intelectual VARCHAR(20) DEFAULT '',
    impedimentos_intelectual JSONB NOT NULL DEFAULT '{}'::jsonb,
    subtipos_mental JSONB NOT NULL DEFAULT '{}'::jsonb,
    detalhes_psicossocial TEXT DEFAULT '',
    impedimentos_mental JSONB NOT NULL DEFAULT '{}'::jsonb,
    subtipos_reabilitado JSONB NOT NULL DEFAULT '{}'::jsonb,
    outros_reabilitado_texto TEXT DEFAULT '',
    cif_itens JSONB NOT NULL DEFAULT '{}'::jsonb,
    documentos JSONB NOT NULL DEFAULT '{"audiometria": false, "relatorio_especialista": false, "relatorio_obs": "", "certificado_inss": false, "certificado_obs": "", "outros": false, "outros_obs": ""}'::jsonb,
    atestados JSONB DEFAULT '[]'::jsonb,
    
    -- Status e Auditoria
    status TEXT NOT NULL DEFAULT 'concluido', -- 'em_andamento', 'pendente', 'concluido'
    concluido_em TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

COMMENT ON TABLE public.laudos_pcd IS 'Laudos periciais caracterizadores de deficiência emitidos e arquivados.';

CREATE INDEX IF NOT EXISTS idx_laudos_protocolo ON public.laudos_pcd(protocolo);
CREATE INDEX IF NOT EXISTS idx_laudos_cpf ON public.laudos_pcd(cpf);
CREATE INDEX IF NOT EXISTS idx_laudos_nome ON public.laudos_pcd(nome);
CREATE INDEX IF NOT EXISTS idx_laudos_cid10 ON public.laudos_pcd(cid10);
CREATE INDEX IF NOT EXISTS idx_laudos_status ON public.laudos_pcd(status);

-- ==============================================================================
-- 5. TABELA: configuracoes (Identidade Visual, Logo e Dados Institucionais)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.configuracoes (
    id TEXT PRIMARY KEY DEFAULT 'geral',
    logo_base64 TEXT DEFAULT '',
    dados_empresa JSONB NOT NULL DEFAULT '{
        "razao": "Ambiental Qualidade de Vida no Trabalho LTDA",
        "cnpj": "05.478.504/0006-40",
        "unidades": [
            {"nome": "Matriz", "end": "Rua Fortunato Zillo, 101 – Vila Antonieta I", "cidade": "Lençóis Paulista – SP · CEP 18682-005", "tel": "(14) 3269-7900"},
            {"nome": "Filial Bauru", "end": "R. Adolpho José Pereira, 4-65 – Jd. Dom Henrique", "cidade": "Bauru – SP · CEP 01332-903", "tel": "(14) 2106-5555"},
            {"nome": "Filial Bela Vista", "end": "R. Itapeva, 500 (Térreo) – Bela Vista", "cidade": "São Paulo – SP · CEP 01332-903", "tel": "(11) 3586-8366"},
            {"nome": "Filial Tatuapé", "end": "R. Coronel Joaquim Antônia Dias, 117 – Tatuapé", "cidade": "São Paulo – SP · CEP 03308-040", "tel": "(11) 3586-8357"}
        ]
    }'::jsonb,
    preferencias JSONB NOT NULL DEFAULT '{}'::jsonb,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

COMMENT ON TABLE public.configuracoes IS 'Configurações de identidade visual, dados da empresa e filiais.';

-- ==============================================================================
-- 6. TABELA: rascunho_sessao (Sincronização da Ficha Ativa em Preenchimento)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.rascunho_sessao (
    id TEXT PRIMARY KEY DEFAULT 'sessao_ativa',
    dados JSONB NOT NULL DEFAULT '{}'::jsonb,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

COMMENT ON TABLE public.rascunho_sessao IS 'Rascunho persistente em tempo real da ficha médica em andamento.';

-- ==============================================================================
-- 7. FUNÇÃO E GATILHOS DE ATUALIZAÇÃO AUTOMÁTICA (updated_at)
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_perfil_medico_updated_at ON public.perfil_medico;
CREATE TRIGGER trigger_perfil_medico_updated_at
BEFORE UPDATE ON public.perfil_medico
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trigger_agendamentos_updated_at ON public.agendamentos;
CREATE TRIGGER trigger_agendamentos_updated_at
BEFORE UPDATE ON public.agendamentos
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trigger_laudos_pcd_updated_at ON public.laudos_pcd;
CREATE TRIGGER trigger_laudos_pcd_updated_at
BEFORE UPDATE ON public.laudos_pcd
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trigger_configuracoes_updated_at ON public.configuracoes;
CREATE TRIGGER trigger_configuracoes_updated_at
BEFORE UPDATE ON public.configuracoes
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trigger_rascunho_sessao_updated_at ON public.rascunho_sessao;
CREATE TRIGGER trigger_rascunho_sessao_updated_at
BEFORE UPDATE ON public.rascunho_sessao
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ==============================================================================
-- 8. POLÍTICAS DE SEGURANÇA (ROW LEVEL SECURITY - RLS)
-- Permite acesso transparente para consultas e escritas da clínica médica
-- ==============================================================================
ALTER TABLE public.perfil_medico ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agendamentos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.laudos_pcd ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.configuracoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rascunho_sessao ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Permitir acesso completo perfil_medico" ON public.perfil_medico;
CREATE POLICY "Permitir acesso completo perfil_medico" ON public.perfil_medico FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir acesso completo agendamentos" ON public.agendamentos;
CREATE POLICY "Permitir acesso completo agendamentos" ON public.agendamentos FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir acesso completo laudos_pcd" ON public.laudos_pcd;
CREATE POLICY "Permitir acesso completo laudos_pcd" ON public.laudos_pcd FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir acesso completo configuracoes" ON public.configuracoes;
CREATE POLICY "Permitir acesso completo configuracoes" ON public.configuracoes FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir acesso completo rascunho_sessao" ON public.rascunho_sessao;
CREATE POLICY "Permitir acesso completo rascunho_sessao" ON public.rascunho_sessao FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

-- Permissões de esquema para as roles da API Supabase
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;

-- ==============================================================================
-- 9. HABILITAÇÃO DO SUPABASE REALTIME (SINCRONIZAÇÃO EM TEMPO REAL)
-- ==============================================================================
DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.agendamentos;
    ALTER PUBLICATION supabase_realtime ADD TABLE public.laudos_pcd;
    ALTER PUBLICATION supabase_realtime ADD TABLE public.perfil_medico;
    ALTER PUBLICATION supabase_realtime ADD TABLE public.configuracoes;
    ALTER PUBLICATION supabase_realtime ADD TABLE public.rascunho_sessao;
EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN undefined_object THEN NULL;
END $$;

-- ==============================================================================
-- 10. CARGA INICIAL DE REGISTROS PADRÃO
-- ==============================================================================
INSERT INTO public.perfil_medico (id, nome, crm, uf, especialidade)
VALUES ('padrao', 'Dr. Roberto Carlos Almeida', '142.890', 'SP', 'Médico(a) do Trabalho')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.configuracoes (id)
VALUES ('geral')
ON CONFLICT (id) DO NOTHING;

-- ==============================================================================
-- 11. MIGRAÇÃO RETROATIVA (CASO AS TABELAS JÁ TENHAM SIDO CRIADAS ANTES)
-- ==============================================================================
ALTER TABLE public.agendamentos ADD COLUMN IF NOT EXISTS atestados JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.laudos_pcd ADD COLUMN IF NOT EXISTS atestados JSONB DEFAULT '[]'::jsonb;

-- ==============================================================================
-- 12. TABELA: atestados_arquivos (Arquivos Físicos em Base64 - Sincronização entre PCs)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.atestados_arquivos (
    id TEXT PRIMARY KEY,
    nome TEXT NOT NULL,
    tipo TEXT,
    tamanho BIGINT,
    categoria TEXT,
    dados TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.atestados_arquivos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permitir acesso completo atestados_arquivos" ON public.atestados_arquivos;
CREATE POLICY "Permitir acesso completo atestados_arquivos" ON public.atestados_arquivos FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
GRANT ALL ON public.atestados_arquivos TO anon, authenticated;
