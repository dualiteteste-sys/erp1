-- Versão 3: Corrige erro de sintaxe </sql>

-- Início do Bloco de "Terra Arrasada"
DO $$
DECLARE
    r RECORD;
BEGIN
    -- Remove todas as políticas de RLS do esquema public
    FOR r IN (SELECT tablename, policyname FROM pg_policies WHERE schemaname = 'public') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON public."' || r.tablename || '"';
    END LOOP;

    -- Remove todos os triggers do esquema public
    FOR r IN (SELECT trigger_name, event_object_table FROM information_schema.triggers WHERE trigger_schema = 'public') LOOP
        EXECUTE 'DROP TRIGGER IF EXISTS "' || r.trigger_name || '" ON public."' || r.event_object_table || '" CASCADE';
    END LOOP;

    -- Remove todas as funções do esquema public
    FOR r IN (SELECT routine_name, specific_name FROM information_schema.routines WHERE routine_schema = 'public') LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS public."' || r.routine_name || '" CASCADE';
    END LOOP;
    
    -- Remove todas as funções do esquema private
    FOR r IN (SELECT routine_name, specific_name FROM information_schema.routines WHERE routine_schema = 'private') LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS private."' || r.routine_name || '" CASCADE';
    END LOOP;

    -- Remove todas as tabelas do esquema public
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
        EXECUTE 'DROP TABLE IF EXISTS public."' || r.tablename || '" CASCADE';
    END LOOP;

    -- Remove todos os tipos (ENUMs) do esquema public
    FOR r IN (SELECT t.typname FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace WHERE n.nspname = 'public' AND t.typtype = 'e') LOOP
        EXECUTE 'DROP TYPE IF EXISTS public."' || r.typname || '" CASCADE';
    END LOOP;
END $$;
-- Fim do Bloco de "Terra Arrasada"

-- 1. Criação de Tipos (ENUMs)
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

-- 2. Criação das Tabelas
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
    cnpj text,
    cpf text,
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
ALTER TABLE public.empresas ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.empresa_usuarios (
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    PRIMARY KEY (empresa_id, user_id)
);
ALTER TABLE public.empresa_usuarios ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.clientes_fornecedores (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nome_razao_social text NOT NULL,
    tipo_pessoa tipo_pessoa NOT NULL,
    tipo_contato tipo_contato NOT NULL,
    fantasia text,
    cnpj_cpf text,
    inscricao_estadual text,
    inscricao_municipal text,
    rg text,
    rnm text,
    cep text,
    municipio text,
    uf text,
    endereco text,
    bairro text,
    numero text,
    complemento text,
    cobranca_diferente boolean NOT NULL DEFAULT false,
    cobr_cep text,
    cobr_municipio text,
    cobr_uf text,
    cobr_endereco text,
    cobr_bairro text,
    cobr_numero text,
    cobr_complemento text,
    telefone text,
    telefone_adicional text,
    celular text,
    website text,
    email text,
    email_nfe text,
    observacoes text,
    created_by uuid REFERENCES auth.users(id),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    UNIQUE (empresa_id, cnpj_cpf)
);
ALTER TABLE public.clientes_fornecedores ENABLE ROW LEVEL SECURITY;

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
ALTER TABLE public.clientes_contatos ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.clientes_anexos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    cliente_fornecedor_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE,
    bucket text NOT NULL DEFAULT 'clientes_anexos',
    storage_path text NOT NULL,
    filename text NOT NULL,
    content_type text,
    tamanho_bytes bigint,
    created_at timestamptz DEFAULT now()
);
ALTER TABLE public.clientes_anexos ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.embalagens (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    descricao text NOT NULL,
    tipo tipo_embalagem_produto NOT NULL,
    peso numeric,
    largura numeric,
    altura numeric,
    comprimento numeric,
    diametro numeric,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);
ALTER TABLE public.embalagens ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.produtos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nome text NOT NULL,
    tipo tipo_produto,
    situacao situacao_produto,
    codigo text,
    codigo_barras text,
    unidade text,
    preco_venda numeric NOT NULL,
    custo_medio numeric,
    origem origem_produto,
    ncm text,
    cest text,
    controlar_estoque boolean DEFAULT true,
    estoque_inicial numeric,
    estoque_minimo numeric,
    estoque_maximo numeric,
    localizacao text,
    dias_preparacao integer,
    controlar_lotes boolean DEFAULT false,
    peso_liquido numeric,
    peso_bruto numeric,
    numero_volumes integer,
    embalagem_id uuid REFERENCES public.embalagens(id),
    largura numeric,
    altura numeric,
    comprimento numeric,
    diametro numeric,
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
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.produto_imagens (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    storage_path text NOT NULL,
    nome_arquivo text NOT NULL,
    tamanho_bytes bigint,
    content_type text,
    created_at timestamptz DEFAULT now()
);
ALTER TABLE public.produto_imagens ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.produto_atributos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    atributo text NOT NULL,
    valor text,
    UNIQUE(produto_id, atributo)
);
ALTER TABLE public.produto_atributos ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.produto_fornecedores (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    fornecedor_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE,
    codigo_no_fornecedor text,
    UNIQUE(produto_id, fornecedor_id)
);
ALTER TABLE public.produto_fornecedores ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.servicos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    descricao text NOT NULL,
    preco numeric NOT NULL,
    situacao situacao_servico NOT NULL,
    codigo text,
    unidade text,
    codigo_servico text,
    nbs text,
    descricao_complementar text,
    observacoes text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);
ALTER TABLE public.servicos ENABLE ROW LEVEL SECURITY;

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
    aliquota_comissao numeric,
    desconsiderar_comissionamento_linhas_produto boolean,
    observacoes_comissao text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    UNIQUE (empresa_id, email)
);
ALTER TABLE public.vendedores ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.vendedores_contatos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    vendedor_id uuid NOT NULL REFERENCES public.vendedores(id) ON DELETE CASCADE,
    nome text NOT NULL,
    setor text,
    email text,
    telefone text,
    ramal text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);
ALTER TABLE public.vendedores_contatos ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.papeis (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nome text NOT NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    UNIQUE(empresa_id, nome)
);
ALTER TABLE public.papeis ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.papel_permissoes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    papel_id uuid NOT NULL REFERENCES public.papeis(id) ON DELETE CASCADE,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    permissao_id text NOT NULL,
    UNIQUE(papel_id, permissao_id)
);
ALTER TABLE public.papel_permissoes ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.categorias_financeiras (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    descricao text NOT NULL,
    tipo tipo_categoria_financeira NOT NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);
ALTER TABLE public.categorias_financeiras ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.formas_pagamento (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    descricao text NOT NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);
ALTER TABLE public.formas_pagamento ENABLE ROW LEVEL SECURITY;

-- 3. Criação de Funções e Triggers
-- Função para associar novo usuário a uma empresa
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Cria uma empresa para o novo usuário
  INSERT INTO public.empresas (id, razao_social, created_by)
  VALUES (gen_random_uuid(), new.email, new.id);
  
  -- Vincula o usuário à empresa recém-criada
  INSERT INTO public.empresa_usuarios (empresa_id, user_id)
  SELECT id, new.id FROM public.empresas WHERE created_by = new.id;
  
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.handle_new_user() SET search_path = public;

-- Trigger para chamar a função acima
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Funções de segurança
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

CREATE OR REPLACE FUNCTION private.is_member_of_empresa(p_user_id uuid, p_empresa_id uuid)
RETURNS boolean AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM public.empresa_usuarios
        WHERE user_id = p_user_id AND empresa_id = p_empresa_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION private.is_member_of_empresa(uuid, uuid) SET search_path = '';

-- Funções CRUD (exemplo para clientes)
CREATE OR REPLACE FUNCTION public.create_cliente_fornecedor_completo(p_empresa_id uuid, p_cliente_data jsonb, p_contatos jsonb)
RETURNS uuid AS $$
DECLARE
    v_cliente_id uuid;
BEGIN
    INSERT INTO public.clientes_fornecedores (empresa_id, nome_razao_social, tipo_pessoa, tipo_contato, fantasia, cnpj_cpf, inscricao_estadual, inscricao_municipal, rg, rnm, cep, municipio, uf, endereco, bairro, numero, complemento, cobranca_diferente, cobr_cep, cobr_municipio, cobr_uf, cobr_endereco, cobr_bairro, cobr_numero, cobr_complemento, telefone, telefone_adicional, celular, website, email, email_nfe, observacoes, created_by)
    VALUES (
        p_empresa_id,
        p_cliente_data->>'nome_razao_social',
        (p_cliente_data->>'tipo_pessoa')::tipo_pessoa,
        (p_cliente_data->>'tipo_contato')::tipo_contato,
        p_cliente_data->>'fantasia',
        p_cliente_data->>'cnpj_cpf',
        p_cliente_data->>'inscricao_estadual',
        p_cliente_data->>'inscricao_municipal',
        p_cliente_data->>'rg',
        p_cliente_data->>'rnm',
        p_cliente_data->>'cep',
        p_cliente_data->>'municipio',
        p_cliente_data->>'uf',
        p_cliente_data->>'endereco',
        p_cliente_data->>'bairro',
        p_cliente_data->>'numero',
        p_cliente_data->>'complemento',
        (p_cliente_data->>'cobranca_diferente')::boolean,
        p_cliente_data->>'cobr_cep',
        p_cliente_data->>'cobr_municipio',
        p_cliente_data->>'cobr_uf',
        p_cliente_data->>'cobr_endereco',
        p_cliente_data->>'cobr_bairro',
        p_cliente_data->>'cobr_numero',
        p_cliente_data->>'cobr_complemento',
        p_cliente_data->>'telefone',
        p_cliente_data->>'telefone_adicional',
        p_cliente_data->>'celular',
        p_cliente_data->>'website',
        p_cliente_data->>'email',
        p_cliente_data->>'email_nfe',
        p_cliente_data->>'observacoes',
        auth.uid()
    ) RETURNING id INTO v_cliente_id;

    IF p_contatos IS NOT NULL AND jsonb_array_length(p_contatos) > 0 THEN
        INSERT INTO public.clientes_contatos (empresa_id, cliente_fornecedor_id, nome, setor, email, telefone, ramal)
        SELECT p_empresa_id, v_cliente_id, c->>'nome', c->>'setor', c->>'email', c->>'telefone', c->>'ramal'
        FROM jsonb_array_elements(p_contatos) c;
    END IF;

    RETURN v_cliente_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.create_cliente_fornecedor_completo(uuid, jsonb, jsonb) SET search_path = public;

-- 4. Criação de Policies RLS
-- Habilita RLS em todas as tabelas e cria políticas padrão
DO $$
DECLARE
    tbl RECORD;
BEGIN
    FOR tbl IN 
        SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        EXECUTE 'ALTER TABLE public.' || quote_ident(tbl.tablename) || ' ENABLE ROW LEVEL SECURITY;';
        EXECUTE 'CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.' || quote_ident(tbl.tablename) || 
                ' FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));';
    END LOOP;
END $$;

-- 5. Criação de Storage Buckets
INSERT INTO storage.buckets (id, name, public)
VALUES ('logos', 'logos', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('clientes_anexos', 'clientes_anexos', false)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('produto-imagens', 'produto-imagens', true)
ON CONFLICT (id) DO NOTHING;

-- Políticas de acesso para os buckets
DROP POLICY IF EXISTS "Permite acesso público a logos" ON storage.objects;
CREATE POLICY "Permite acesso público a logos" ON storage.objects FOR SELECT USING (bucket_id = 'logos');

DROP POLICY IF EXISTS "Permite acesso autenticado a anexos" ON storage.objects;
CREATE POLICY "Permite acesso autenticado a anexos" ON storage.objects FOR ALL USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Permite acesso público a imagens de produto" ON storage.objects;
CREATE POLICY "Permite acesso público a imagens de produto" ON storage.objects FOR SELECT USING (bucket_id = 'produto-imagens');
