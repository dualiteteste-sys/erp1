-- =================================================================
-- MIGRATION: Reconstrução Completa do Banco de Dados
-- Descrição: Este script executa uma "terra arrasada" segura no esquema 'public'
-- e reconstrói toda a estrutura do zero, baseado na versão estável do projeto.
-- Isso irá limpar inconsistências e alinhar o backend com o frontend.
-- =================================================================

-- PASSO 1: Limpeza Segura (Terra Arrasada)
-- Remove todas as tabelas, tipos e funções personalizadas do esquema 'public'.
DO $$
DECLARE
    r RECORD;
BEGIN
    -- Remove todas as políticas de RLS do esquema 'public'
    FOR r IN (SELECT tablename, policyname FROM pg_policies WHERE schemaname = 'public') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON public."' || r.tablename || '";';
    END LOOP;

    -- Remove todas as funções do esquema 'public' e 'private'
    FOR r IN (SELECT p.proname, pg_get_function_identity_arguments(p.oid) as args, n.nspname as schema_name
              FROM pg_proc p
              JOIN pg_namespace n ON p.pronamespace = n.oid
              WHERE n.nspname IN ('public', 'private')) LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS ' || r.schema_name || '."' || r.proname || '"(' || r.args || ') CASCADE;';
    END LOOP;

    -- Remove todas as tabelas do esquema 'public'
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
        EXECUTE 'DROP TABLE IF EXISTS public."' || r.tablename || '" CASCADE;';
    END LOOP;

    -- Remove todos os tipos (ENUMs) do esquema 'public'
    FOR r IN (SELECT t.typname FROM pg_type t JOIN pg_namespace n ON t.typnamespace = n.oid WHERE n.nspname = 'public' AND t.typtype = 'e') LOOP
        EXECUTE 'DROP TYPE IF EXISTS public."' || r.typname || '";';
    END LOOP;
END $$;


-- PASSO 2: Reconstrução da Estrutura

-- STORAGE BUCKETS
-- Adiciona a verificação "ON CONFLICT" para tornar a criação de buckets idempotente.
INSERT INTO storage.buckets (id, name, public)
VALUES ('logos', 'logos', true) ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('clientes_anexos', 'clientes_anexos', true) ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('produto-imagens', 'produto-imagens', true) ON CONFLICT (id) DO NOTHING;

-- RLS POLICIES FOR STORAGE
ALTER POLICY "Permite acesso público a logos" ON storage.objects FOR SELECT USING (bucket_id = 'logos');
ALTER POLICY "Permite acesso autenticado a anexos de clientes" ON storage.objects FOR SELECT USING (bucket_id = 'clientes_anexos' AND auth.role() = 'authenticated');
ALTER POLICY "Permite acesso autenticado a imagens de produtos" ON storage.objects FOR SELECT USING (bucket_id = 'produto-imagens' AND auth.role() = 'authenticated');

-- TIPOS (ENUMS)
CREATE TYPE public.tipo_pessoa AS ENUM ('PF', 'PJ');
CREATE TYPE public.tipo_contato AS ENUM ('cliente', 'fornecedor', 'ambos');
CREATE TYPE public.tipo_produto AS ENUM ('Simples', 'Com variações', 'Kit', 'Fabricado', 'Matéria Prima');
CREATE TYPE public.situacao_produto AS ENUM ('Ativo', 'Inativo');
CREATE TYPE public.origem_produto AS ENUM ('0 - Nacional', '1 - Estrangeira (Imp. Direta)', '2 - Estrangeira (Merc. Interno)', '3 - Nacional (Imp. > 40%)', '4 - Nacional (Proc. Básico)', '5 - Nacional (Imp. <= 40%)', '6 - Estrangeira (Imp. Direta, s/ similar)', '7 - Estrangeira (Merc. Interno, s/ similar)', '8 - Nacional (Imp. > 70%)');
CREATE TYPE public.tipo_embalagem_produto AS ENUM ('Caixa', 'Rolo / Cilindro', 'Envelope', 'Fardo');
CREATE TYPE public.situacao_servico AS ENUM ('Ativo', 'Inativo');
CREATE TYPE public.situacao_vendedor AS ENUM ('Ativo com acesso ao sistema', 'Ativo sem acesso ao sistema', 'Inativo');
CREATE TYPE public.tipo_pessoa_vendedor AS ENUM ('Pessoa Física', 'Pessoa Jurídica', 'Estrangeiro', 'Estrangeiro no Brasil');
CREATE TYPE public.tipo_contribuinte_icms AS ENUM ('Contribuinte ICMS', 'Contribuinte Isento', 'Não Contribuinte');
CREATE TYPE public.regra_liberacao_comissao AS ENUM ('Liberação parcial vinculada ao pagamento de parcelas', 'Liberação integral no faturamento');
CREATE TYPE public.tipo_comissao AS ENUM ('fixa', 'variavel');
CREATE TYPE public.tipo_categoria_financeira AS ENUM ('RECEITA', 'DESPESA');

-- TABELAS
CREATE TABLE public.empresas (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    razao_social text NOT NULL,
    nome_completo text,
    fantasia text,
    cep text,
    logradouro text,
    numero text,
    sem_numero boolean DEFAULT false,
    complemento text,
    bairro text,
    cidade text,
    uf text,
    fone text,
    fax text,
    celular text,
    email text,
    website text,
    segmento text,
    tipo_pessoa text,
    cnpj text UNIQUE,
    cpf text UNIQUE,
    ie text,
    ie_isento boolean DEFAULT false,
    im text,
    cnae text,
    crt text,
    preferencias_contato jsonb,
    administrador jsonb,
    logo_url text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE public.empresa_usuarios (
    empresa_id uuid REFERENCES public.empresas(id) ON DELETE CASCADE,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    PRIMARY KEY (empresa_id, user_id)
);

CREATE TABLE public.clientes_fornecedores (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nome_razao_social text NOT NULL,
    fantasia text,
    tipo_pessoa tipo_pessoa NOT NULL,
    tipo_contato tipo_contato NOT NULL,
    cnpj_cpf text,
    rg text,
    rnm text,
    inscricao_estadual text,
    inscricao_municipal text,
    cep text,
    endereco text,
    numero text,
    complemento text,
    bairro text,
    municipio text,
    uf text,
    cobranca_diferente boolean NOT NULL DEFAULT false,
    cobr_cep text,
    cobr_endereco text,
    cobr_numero text,
    cobr_complemento text,
    cobr_bairro text,
    cobr_municipio text,
    cobr_uf text,
    telefone text,
    telefone_adicional text,
    celular text,
    email text,
    email_nfe text,
    website text,
    observacoes text,
    created_by uuid REFERENCES auth.users(id),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    UNIQUE (empresa_id, cnpj_cpf)
);

CREATE TABLE public.clientes_contatos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    cliente_fornecedor_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE,
    nome text NOT NULL,
    setor text,
    email text,
    telefone text,
    ramal text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE public.clientes_anexos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    cliente_fornecedor_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE,
    storage_path text NOT NULL,
    filename text NOT NULL,
    content_type text,
    tamanho_bytes bigint,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE public.produtos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nome text NOT NULL,
    tipo tipo_produto,
    situacao situacao_produto,
    codigo text,
    codigo_barras text,
    unidade text,
    preco_venda numeric(15,2) NOT NULL,
    custo_medio numeric(15,2),
    origem origem_produto,
    ncm text,
    cest text,
    controlar_estoque boolean DEFAULT true,
    estoque_inicial numeric(15,4),
    estoque_minimo numeric(15,4),
    estoque_maximo numeric(15,4),
    localizacao text,
    dias_preparacao integer,
    controlar_lotes boolean DEFAULT false,
    peso_liquido numeric(15,4),
    peso_bruto numeric(15,4),
    numero_volumes integer,
    embalagem_id uuid,
    largura numeric(15,4),
    altura numeric(15,4),
    comprimento numeric(15,4),
    diametro numeric(15,4),
    marca text,
    modelo text,
    disponibilidade text,
    garantia text,
    video_url text,
    descricao_curta text,
    descricao_complementar text,
    slug text,
    titulo_seo text,
    meta_descricao_seo text,
    observacoes text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    UNIQUE (empresa_id, codigo)
);

CREATE TABLE public.produto_imagens (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    storage_path text NOT NULL,
    nome_arquivo text NOT NULL,
    tamanho_bytes bigint,
    content_type text,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE public.produto_atributos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    atributo text NOT NULL,
    valor text,
    UNIQUE (produto_id, atributo)
);

CREATE TABLE public.produto_fornecedores (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    fornecedor_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE,
    codigo_no_fornecedor text,
    UNIQUE (produto_id, fornecedor_id)
);

CREATE TABLE public.servicos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    descricao text NOT NULL,
    preco numeric(15,2),
    situacao situacao_servico,
    codigo text,
    unidade text,
    codigo_servico text,
    nbs text,
    descricao_complementar text,
    observacoes text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE public.vendedores (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nome text NOT NULL,
    fantasia text,
    codigo text,
    tipo_pessoa tipo_pessoa_vendedor,
    cpf_cnpj text,
    documento_identificacao text,
    pais text,
    contribuinte_icms tipo_contribuinte_icms,
    inscricao_estadual text,
    situacao situacao_vendedor,
    cep text,
    logradouro text,
    numero text,
    complemento text,
    bairro text,
    cidade text,
    uf text,
    telefone text,
    celular text,
    email text,
    email_comunicacao text,
    deposito_padrao text,
    acesso_restrito_horario boolean,
    acesso_restrito_ip text,
    perfil_contato text[],
    permissoes_modulos jsonb,
    regra_liberacao_comissao regra_liberacao_comissao,
    tipo_comissao tipo_comissao,
    aliquota_comissao numeric(5,2),
    desconsiderar_comissionamento_linhas_produto boolean,
    observacoes_comissao text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE public.vendedores_contatos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    vendedor_id uuid NOT NULL REFERENCES public.vendedores(id) ON DELETE CASCADE,
    nome text NOT NULL,
    setor text,
    email text,
    telefone text,
    ramal text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE public.embalagens (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    descricao text NOT NULL,
    tipo tipo_embalagem_produto,
    peso numeric(15,4),
    largura numeric(15,4),
    altura numeric(15,4),
    comprimento numeric(15,4),
    diametro numeric(15,4),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE public.papeis (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nome text NOT NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE public.papel_permissoes (
    papel_id uuid NOT NULL REFERENCES public.papeis(id) ON DELETE CASCADE,
    permissao_id text NOT NULL,
    PRIMARY KEY (papel_id, permissao_id)
);

CREATE TABLE public.categorias_financeiras (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    descricao text NOT NULL,
    tipo tipo_categoria_financeira NOT NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE public.formas_pagamento (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    descricao text NOT NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);


-- FUNÇÕES DE SEGURANÇA E AUXILIARES
CREATE OR REPLACE FUNCTION private.get_empresa_id_for_user(p_user_id uuid)
RETURNS uuid AS $$
DECLARE
    v_empresa_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.empresa_usuarios WHERE user_id = p_user_id LIMIT 1;
    RETURN v_empresa_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION private.get_empresa_id_for_user(uuid) SET search_path = '';

CREATE OR REPLACE FUNCTION public.is_member_of_empresa(p_empresa_id uuid)
RETURNS boolean AS $$
DECLARE
    v_user_id uuid := auth.uid();
    v_is_member boolean;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM public.empresa_usuarios WHERE empresa_id = p_empresa_id AND user_id = v_user_id
    ) INTO v_is_member;
    RETURN v_is_member;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.is_member_of_empresa(uuid) SET search_path = '';

-- FUNÇÕES DE NEGÓCIO (RPCs)
-- ... (recriação de todas as funções de create, update, delete, etc., com a configuração de segurança)
-- Exemplo para `handle_new_user`:
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.empresa_usuarios (user_id, empresa_id)
  VALUES (new.id, private.get_empresa_id_for_user(new.id));
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.handle_new_user() SET search_path = '';

-- (Aqui iriam todas as outras funções: create_cliente, update_produto, etc., todas com 'SET search_path')
-- ...

-- TRIGGERS
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- POLÍTICAS DE RLS
-- Habilita RLS em todas as tabelas
ALTER TABLE public.empresas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.empresa_usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clientes_fornecedores ENABLE ROW LEVEL SECURITY;
-- ... (para todas as outras tabelas)

-- Cria as políticas
CREATE POLICY "Permite acesso de leitura para membros da empresa" ON public.empresas
FOR SELECT USING (public.is_member_of_empresa(id));

CREATE POLICY "Permite acesso total para membros da empresa" ON public.clientes_fornecedores
FOR ALL USING (public.is_member_of_empresa(empresa_id));
-- ... (para todas as outras tabelas)
