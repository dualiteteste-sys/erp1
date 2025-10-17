-- Versão 5 (Final) - Reconstrução Completa e Corrigida

-- =================================================================
-- PASSO 1: TERRA ARRASADA (LIMPEZA SEGURA)
-- Remove todas as tabelas, tipos e funções personalizadas no esquema 'public'.
-- =================================================================
DO $$
DECLARE
    r RECORD;
BEGIN
    -- Drop all tables in public schema owned by the current user
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
        EXECUTE 'DROP TABLE IF EXISTS public.' || quote_ident(r.tablename) || ' CASCADE';
    END LOOP;

    -- Drop all functions in public schema (exceto as do Supabase)
    FOR r IN (
        SELECT p.proname, pg_get_function_identity_arguments(p.oid) as args
        FROM pg_proc p
        JOIN pg_namespace ns ON p.pronamespace = ns.oid
        WHERE ns.nspname = 'public' AND pg_catalog.pg_get_userbyid(p.proowner) NOT IN ('supabase_admin', 'postgres')
    ) LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS public.' || quote_ident(r.proname) || '(' || r.args || ') CASCADE';
    END LOOP;

    -- Drop all procedures in public schema
    FOR r IN (
        SELECT p.proname, pg_get_function_identity_arguments(p.oid) as args
        FROM pg_proc p
        JOIN pg_namespace ns ON p.pronamespace = ns.oid
        WHERE ns.nspname = 'public' AND p.prokind = 'p'
    ) LOOP
        EXECUTE 'DROP PROCEDURE IF EXISTS public.' || quote_ident(r.proname) || '(' || r.args || ') CASCADE';
    END LOOP;

    -- Drop all custom types in public schema
    FOR r IN (SELECT typname FROM pg_type WHERE typnamespace = 'public'::regnamespace AND typtype = 'e') LOOP
        EXECUTE 'DROP TYPE IF EXISTS public.' || quote_ident(r.typname) || ' CASCADE';
    END LOOP;
END $$;


-- =================================================================
-- PASSO 2: RECONSTRUÇÃO DA ESTRUTURA
-- Cria todas as tabelas, tipos e funções do zero.
-- =================================================================

-- ---- TIPOS (ENUMS) ----
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

-- ---- TABELAS ----

-- Tabela de Empresas
CREATE TABLE public.empresas (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    razao_social text NOT NULL,
    fantasia text,
    cnpj text UNIQUE,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    logo_url text,
    email text,
    -- Adicionando colunas que estavam faltando nos schemas
    nome_completo text,
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
    website text,
    segmento text,
    tipo_pessoa text,
    cpf text,
    ie text,
    ie_isento boolean DEFAULT false,
    im text,
    cnae text,
    crt text,
    preferencias_contato jsonb,
    administrador jsonb
);
COMMENT ON TABLE public.empresas IS 'Armazena as informações de cada empresa (tenant).';

-- Tabela de Junção: Empresa <-> Usuários
CREATE TABLE public.empresa_usuarios (
    empresa_id uuid REFERENCES public.empresas(id) ON DELETE CASCADE,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    PRIMARY KEY (empresa_id, user_id)
);
COMMENT ON TABLE public.empresa_usuarios IS 'Tabela de junção para relacionamento N-N entre empresas e usuários.';

-- Tabela de Clientes e Fornecedores
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

-- Tabela de Contatos Adicionais de Clientes
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

-- Tabela de Anexos de Clientes
CREATE TABLE public.clientes_anexos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    cliente_fornecedor_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE,
    storage_path text NOT NULL,
    filename text NOT NULL,
    content_type text,
    tamanho_bytes bigint,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Tabela de Embalagens
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

-- Tabela de Produtos
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
    controlar_lotes boolean,
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

-- Tabelas relacionadas a Produtos
CREATE TABLE public.produto_imagens (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    storage_path text NOT NULL,
    nome_arquivo text NOT NULL,
    tamanho_bytes bigint,
    content_type text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE public.produto_atributos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    atributo text NOT NULL,
    valor text,
    UNIQUE(produto_id, atributo)
);

CREATE TABLE public.produto_fornecedores (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    fornecedor_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE,
    codigo_no_fornecedor text
);

-- Tabela de Serviços
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

-- Tabela de Vendedores
CREATE TABLE public.vendedores (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nome text NOT NULL,
    fantasia text,
    codigo text,
    tipo_pessoa tipo_pessoa_vendedor NOT NULL,
    cpf_cnpj text,
    documento_identificacao text,
    pais text,
    contribuinte_icms tipo_contribuinte_icms,
    inscricao_estadual text,
    situacao situacao_vendedor NOT NULL,
    cep text,
    logradouro text,
    numero text,
    complemento text,
    bairro text,
    cidade text,
    uf text,
    telefone text,
    celular text,
    email text UNIQUE,
    email_comunicacao text,
    deposito_padrao text,
    acesso_restrito_horario boolean DEFAULT false,
    acesso_restrito_ip text,
    perfil_contato text[],
    permissoes_modulos jsonb,
    regra_liberacao_comissao regra_liberacao_comissao,
    tipo_comissao tipo_comissao,
    aliquota_comissao numeric,
    desconsiderar_comissionamento_linhas_produto boolean DEFAULT false,
    observacoes_comissao text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Tabela de Contatos Adicionais de Vendedores
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

-- Tabela de Papéis
CREATE TABLE public.papeis (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nome text NOT NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Tabela de Junção: Papel <-> Permissões
CREATE TABLE public.papel_permissoes (
    papel_id uuid NOT NULL REFERENCES public.papeis(id) ON DELETE CASCADE,
    permissao_id text NOT NULL,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    PRIMARY KEY (papel_id, permissao_id)
);

-- Tabela de Categorias Financeiras
CREATE TABLE public.categorias_financeiras (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    descricao text NOT NULL,
    tipo tipo_categoria_financeira NOT NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Tabela de Formas de Pagamento
CREATE TABLE public.formas_pagamento (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    descricao text NOT NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- ---- FUNÇÕES E TRIGGERS ----

-- Função para associar novo usuário a uma empresa
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Tenta encontrar uma empresa com o mesmo CNPJ/CPF do usuário
  INSERT INTO public.empresa_usuarios (empresa_id, user_id)
  SELECT id, NEW.id FROM public.empresas WHERE cnpj = NEW.raw_user_meta_data->>'cpf_cnpj'
  ON CONFLICT (empresa_id, user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.handle_new_user() SET search_path = 'public';

-- Trigger para chamar a função acima quando um novo usuário é criado
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Função para obter o empresa_id do usuário logado
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

-- Função para verificar se o usuário é membro da empresa
CREATE OR REPLACE FUNCTION private.is_member_of_empresa(p_empresa_id uuid)
RETURNS boolean AS $$
DECLARE
    is_member boolean;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM public.empresa_usuarios
        WHERE user_id = auth.uid() AND empresa_id = p_empresa_id
    ) INTO is_member;
    RETURN is_member;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION private.is_member_of_empresa(uuid) SET search_path = '';

-- Funções para CRUD de Clientes
-- (Demais funções de CRUD serão adicionadas conforme necessário)

-- ---- POLÍTICAS DE RLS ----
ALTER TABLE public.empresas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.empresa_usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clientes_fornecedores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clientes_contatos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clientes_anexos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.embalagens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produto_imagens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produto_atributos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produto_fornecedores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.servicos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendedores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendedores_contatos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.papeis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.papel_permissoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categorias_financeiras ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.formas_pagamento ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Membros podem ver suas próprias empresas" ON public.empresas FOR SELECT USING (private.is_member_of_empresa(id));
CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.empresas FOR ALL USING (private.is_member_of_empresa(id));

CREATE POLICY "Usuários podem ver suas próprias associações" ON public.empresa_usuarios FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.clientes_fornecedores FOR ALL USING (private.is_member_of_empresa(empresa_id));
CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.clientes_contatos FOR ALL USING (private.is_member_of_empresa(empresa_id));
CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.clientes_anexos FOR ALL USING (private.is_member_of_empresa(empresa_id));
CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.embalagens FOR ALL USING (private.is_member_of_empresa(empresa_id));
CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.produtos FOR ALL USING (private.is_member_of_empresa(empresa_id));
CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.produto_imagens FOR ALL USING (EXISTS (SELECT 1 FROM produtos WHERE produtos.id = produto_imagens.produto_id AND private.is_member_of_empresa(produtos.empresa_id)));
CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.produto_atributos FOR ALL USING (EXISTS (SELECT 1 FROM produtos WHERE produtos.id = produto_atributos.produto_id AND private.is_member_of_empresa(produtos.empresa_id)));
CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.produto_fornecedores FOR ALL USING (EXISTS (SELECT 1 FROM produtos WHERE produtos.id = produto_fornecedores.produto_id AND private.is_member_of_empresa(produtos.empresa_id)));
CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.servicos FOR ALL USING (private.is_member_of_empresa(empresa_id));
CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.vendedores FOR ALL USING (private.is_member_of_empresa(empresa_id));
CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.vendedores_contatos FOR ALL USING (private.is_member_of_empresa(empresa_id));
CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.papeis FOR ALL USING (private.is_member_of_empresa(empresa_id));
CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.papel_permissoes FOR ALL USING (private.is_member_of_empresa(empresa_id));
CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.categorias_financeiras FOR ALL USING (private.is_member_of_empresa(empresa_id));
CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.formas_pagamento FOR ALL USING (private.is_member_of_empresa(empresa_id));

-- ---- STORAGE BUCKETS ----
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
    ('logos', 'logos', true, 2097152, '{"image/png", "image/jpeg", "image/svg+xml"}'),
    ('clientes_anexos', 'clientes_anexos', false, 2097152, NULL),
    ('produto-imagens', 'produto-imagens', true, 2097152, '{"image/png", "image/jpeg", "image/webp", "image/gif"}')
ON CONFLICT (id) DO NOTHING;

-- ---- STORAGE RLS POLICIES ----
DROP POLICY IF EXISTS "Permite acesso público a logos" ON storage.objects;
CREATE POLICY "Permite acesso público a logos" ON storage.objects FOR SELECT USING (bucket_id = 'logos');

DROP POLICY IF EXISTS "Permite acesso a imagens de produtos" ON storage.objects;
CREATE POLICY "Permite acesso a imagens de produtos" ON storage.objects FOR SELECT USING (bucket_id = 'produto-imagens');

DROP POLICY IF EXISTS "Membros da empresa podem gerenciar anexos de clientes" ON storage.objects;
CREATE POLICY "Membros da empresa podem gerenciar anexos de clientes" ON storage.objects FOR ALL
USING (
    bucket_id = 'clientes_anexos' AND
    private.is_member_of_empresa((storage.foldername(name))[1]::uuid)
)
WITH CHECK (
    bucket_id = 'clientes_anexos' AND
    private.is_member_of_empresa((storage.foldername(name))[1]::uuid)
);
