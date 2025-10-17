-- Versão 3: Script de Reconstrução Completa e Corrigida
-- Garante a existência da coluna `empresa_id` em todas as tabelas relevantes.

-- PASSO 1: Limpeza completa (Terra Arrasada)
DO $$
DECLARE
    r RECORD;
BEGIN
    -- Drop all policies from public tables
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
        EXECUTE 'ALTER TABLE public.' || quote_ident(r.tablename) || ' DISABLE ROW LEVEL SECURITY';
    END LOOP;

    -- Drop functions
    DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
    DROP FUNCTION IF EXISTS private.is_member_of_empresa(uuid) CASCADE;
    DROP FUNCTION IF EXISTS public.create_empresa_and_link_owner(text,text,text) CASCADE;
    DROP FUNCTION IF EXISTS public.create_empresa_and_link_owner_client(text,text,text) CASCADE;
    DROP FUNCTION IF EXISTS public.delete_empresa_if_member(uuid) CASCADE;
    DROP FUNCTION IF EXISTS public.create_cliente_fornecedor_completo(uuid,jsonb,jsonb) CASCADE;
    DROP FUNCTION IF EXISTS public.update_cliente_fornecedor_completo(uuid,jsonb,jsonb) CASCADE;
    DROP FUNCTION IF EXISTS public.delete_cliente_fornecedor_if_member(uuid) CASCADE;
    DROP FUNCTION IF EXISTS public.create_cliente_anexo(uuid,uuid,text,text,text,bigint) CASCADE;
    DROP FUNCTION IF EXISTS public.create_produto_completo(uuid,jsonb,jsonb[],jsonb[]) CASCADE;
    DROP FUNCTION IF EXISTS public.update_produto_completo(uuid,jsonb,jsonb[],jsonb[]) CASCADE;
    DROP FUNCTION IF EXISTS public.delete_produto(uuid) CASCADE;
    DROP FUNCTION IF EXISTS public.create_produto_imagem(uuid,text,text,text,bigint) CASCADE;
    DROP FUNCTION IF EXISTS public.create_servico(uuid,text,numeric,text,text,text,text,text,text,text) CASCADE;
    DROP FUNCTION IF EXISTS public.update_servico(uuid,text,numeric,text,text,text,text,text,text,text) CASCADE;
    DROP FUNCTION IF EXISTS public.delete_servico(uuid) CASCADE;
    DROP FUNCTION IF EXISTS public.create_embalagem(uuid,text,text,numeric,numeric,numeric,numeric,numeric) CASCADE;
    DROP FUNCTION IF EXISTS public.update_embalagem(uuid,text,text,numeric,numeric,numeric,numeric,numeric) CASCADE;
    DROP FUNCTION IF EXISTS public.delete_embalagem(uuid) CASCADE;
    DROP FUNCTION IF EXISTS public.create_vendedor(uuid,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text[],jsonb,text,text,numeric,boolean,text,jsonb) CASCADE;
    DROP FUNCTION IF EXISTS public.update_vendedor(uuid,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text[],jsonb,text,text,numeric,boolean,text,jsonb) CASCADE;
    DROP FUNCTION IF EXISTS public.delete_vendedor(uuid) CASCADE;
    DROP FUNCTION IF EXISTS public.check_vendedor_email_exists(uuid,text,uuid) CASCADE;
    DROP FUNCTION IF EXISTS public.set_papel_permissions(uuid,text[]) CASCADE;
    DROP FUNCTION IF EXISTS private.get_empresa_id_for_user(uuid) CASCADE;

    -- Drop tables
    DROP TABLE IF EXISTS public.clientes_contatos CASCADE;
    DROP TABLE IF EXISTS public.clientes_anexos CASCADE;
    DROP TABLE IF EXISTS public.clientes_fornecedores CASCADE;
    DROP TABLE IF EXISTS public.produto_imagens CASCADE;
    DROP TABLE IF EXISTS public.produto_atributos CASCADE;
    DROP TABLE IF EXISTS public.produto_fornecedores CASCADE;
    DROP TABLE IF EXISTS public.produtos CASCADE;
    DROP TABLE IF EXISTS public.embalagens CASCADE;
    DROP TABLE IF EXISTS public.servicos CASCADE;
    DROP TABLE IF EXISTS public.vendedores_contatos CASCADE;
    DROP TABLE IF EXISTS public.vendedores CASCADE;
    DROP TABLE IF EXISTS public.papel_permissoes CASCADE;
    DROP TABLE IF EXISTS public.papeis CASCADE;
    DROP TABLE IF EXISTS public.categorias_financeiras CASCADE;
    DROP TABLE IF EXISTS public.formas_pagamento CASCADE;
    DROP TABLE IF EXISTS public.empresa_usuarios CASCADE;
    DROP TABLE IF EXISTS public.empresas CASCADE;

    -- Drop types
    DROP TYPE IF EXISTS public.tipo_pessoa;
    DROP TYPE IF EXISTS public.tipo_contato;
    DROP TYPE IF EXISTS public.tipo_produto;
    DROP TYPE IF EXISTS public.situacao_produto;
    DROP TYPE IF EXISTS public.origem_produto;
    DROP TYPE IF EXISTS public.tipo_embalagem_produto;
    DROP TYPE IF EXISTS public.situacao_servico;
    DROP TYPE IF EXISTS public.situacao_vendedor;
    DROP TYPE IF EXISTS public.tipo_pessoa_vendedor;
    DROP TYPE IF EXISTS public.tipo_contribuinte_icms;
    DROP TYPE IF EXISTS public.regra_liberacao_comissao;
    DROP TYPE IF EXISTS public.tipo_comissao;
    DROP TYPE IF EXISTS public.tipo_categoria_financeira;
END $$;

-- PASSO 2: Recriação da Estrutura
-- Tipos (ENUMs)
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

-- Tabelas
CREATE TABLE public.empresas (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    razao_social text NOT NULL,
    fantasia text,
    cnpj text UNIQUE,
    email text,
    logo_url text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    -- Campos adicionais do formulário
    nome_completo text,
    cep text,
    logradouro text,
    numero text,
    sem_numero boolean,
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
    ie_isento boolean,
    im text,
    cnae text,
    crt text,
    preferencias_contato jsonb,
    administrador jsonb
);

CREATE TABLE public.empresa_usuarios (
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    PRIMARY KEY (empresa_id, user_id)
);

CREATE TABLE public.clientes_fornecedores (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nome_razao_social text NOT NULL,
    tipo_pessoa tipo_pessoa NOT NULL,
    tipo_contato tipo_contato NOT NULL,
    cobranca_diferente boolean NOT NULL DEFAULT false,
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
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
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
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.clientes_anexos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    cliente_fornecedor_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE,
    storage_path text NOT NULL,
    filename text NOT NULL,
    content_type text,
    tamanho_bytes bigint,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

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
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
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
    estoque_inicial numeric,
    estoque_minimo numeric,
    estoque_maximo numeric,
    localizacao text,
    dias_preparacao integer,
    controlar_lotes boolean,
    estoque_atual numeric,
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
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(empresa_id, codigo)
);

CREATE TABLE public.produto_imagens (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    storage_path text NOT NULL,
    nome_arquivo text NOT NULL,
    tamanho_bytes bigint,
    content_type text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.produto_atributos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    atributo text NOT NULL,
    valor text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(produto_id, atributo)
);

CREATE TABLE public.produto_fornecedores (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    fornecedor_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE,
    codigo_no_fornecedor text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(produto_id, fornecedor_id)
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
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
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
    aliquota_comissao numeric,
    desconsiderar_comissionamento_linhas_produto boolean,
    observacoes_comissao text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(empresa_id, email)
);

CREATE TABLE public.vendedores_contatos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    vendedor_id uuid NOT NULL REFERENCES public.vendedores(id) ON DELETE CASCADE,
    nome text NOT NULL,
    setor text,
    email text,
    telefone text,
    ramal text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.papeis (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nome text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(empresa_id, nome)
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
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.formas_pagamento (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    descricao text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- PASSO 3: Funções e Políticas de Segurança
-- Função para verificar se o usuário é membro da empresa
CREATE OR REPLACE FUNCTION private.is_member_of_empresa(p_empresa_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.empresa_usuarios
    WHERE empresa_id = p_empresa_id
      AND user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION private.is_member_of_empresa(uuid) SET search_path = public,private;

-- Função para obter a empresa do usuário
CREATE OR REPLACE FUNCTION private.get_empresa_id_for_user(p_user_id uuid)
RETURNS uuid AS $$
DECLARE
    v_empresa_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.empresa_usuarios WHERE user_id = p_user_id LIMIT 1;
    RETURN v_empresa_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION private.get_empresa_id_for_user(uuid) SET search_path = public,private;

-- Trigger para criar empresa e vincular usuário
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  v_empresa_id uuid;
BEGIN
  -- Cria a empresa
  INSERT INTO public.empresas (razao_social, fantasia, cnpj, email)
  VALUES (
    new.raw_user_meta_data->>'fullName',
    new.raw_user_meta_data->>'fullName',
    new.raw_user_meta_data->>'cpf_cnpj',
    new.email
  ) RETURNING id INTO v_empresa_id;

  -- Vincula o usuário à empresa
  INSERT INTO public.empresa_usuarios (empresa_id, user_id)
  VALUES (v_empresa_id, new.id);

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.handle_new_user() SET search_path = public;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Políticas de Segurança (RLS)
ALTER TABLE public.empresas ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Membros podem ver suas próprias empresas" ON public.empresas FOR SELECT USING (id IN (SELECT empresa_id FROM public.empresa_usuarios WHERE user_id = auth.uid()));

ALTER TABLE public.empresa_usuarios ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Usuários podem ver seus próprios vínculos" ON public.empresa_usuarios FOR SELECT USING (user_id = auth.uid());

-- Função genérica para aplicar políticas
CREATE OR REPLACE PROCEDURE public.apply_rls_policy(table_name text)
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;', table_name);
  EXECUTE format('CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.%I FOR ALL USING (empresa_id IN (SELECT empresa_id FROM public.empresa_usuarios WHERE user_id = auth.uid()));', table_name);
END;
$$;

-- Aplicar RLS a todas as tabelas relevantes
CALL public.apply_rls_policy('clientes_fornecedores');
CALL public.apply_rls_policy('clientes_contatos');
CALL public.apply_rls_policy('clientes_anexos');
CALL public.apply_rls_policy('produtos');
CALL public.apply_rls_policy('produto_imagens');
CALL public.apply_rls_policy('produto_atributos');
CALL public.apply_rls_policy('produto_fornecedores');
CALL public.apply_rls_policy('embalagens');
CALL public.apply_rls_policy('servicos');
CALL public.apply_rls_policy('vendedores');
CALL public.apply_rls_policy('vendedores_contatos');
CALL public.apply_rls_policy('papeis');
CALL public.apply_rls_policy('papel_permissoes');
CALL public.apply_rls_policy('categorias_financeiras');
CALL public.apply_rls_policy('formas_pagamento');


-- PASSO 4: Storage Buckets
INSERT INTO storage.buckets (id, name, public)
VALUES ('logos', 'logos', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('clientes_anexos', 'clientes_anexos', false)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('produto-imagens', 'produto-imagens', true)
ON CONFLICT (id) DO NOTHING;

-- Políticas de acesso ao Storage
DROP POLICY IF EXISTS "Permite acesso público a logos" ON storage.objects;
CREATE POLICY "Permite acesso público a logos" ON storage.objects FOR SELECT USING (bucket_id = 'logos');

DROP POLICY IF EXISTS "Permite acesso a anexos de clientes para membros da empresa" ON storage.objects;
CREATE POLICY "Permite acesso a anexos de clientes para membros da empresa" ON storage.objects FOR ALL
USING (
  bucket_id = 'clientes_anexos' AND
  private.is_member_of_empresa((storage.foldername(name))[1]::uuid)
);

DROP POLICY IF EXISTS "Permite acesso público a imagens de produtos" ON storage.objects;
CREATE POLICY "Permite acesso público a imagens de produtos" ON storage.objects FOR SELECT USING (bucket_id = 'produto-imagens');

DROP POLICY IF EXISTS "Permite upload de imagens de produtos para membros da empresa" ON storage.objects;
CREATE POLICY "Permite upload de imagens de produtos para membros da empresa" ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'produto-imagens' AND
  private.is_member_of_empresa((storage.foldername(name))[1]::uuid)
);

DROP POLICY IF EXISTS "Permite delete de imagens de produtos para membros da empresa" ON storage.objects;
CREATE POLICY "Permite delete de imagens de produtos para membros da empresa" ON storage.objects FOR DELETE
USING (
  bucket_id = 'produto-imagens' AND
  private.is_member_of_empresa((storage.foldername(name))[1]::uuid)
);

-- PASSO 5: Funções RPC para CRUD
-- (As funções serão recriadas aqui para garantir que usem a estrutura correta)

-- CLIENTES
CREATE OR REPLACE FUNCTION public.create_cliente_fornecedor_completo(
    p_empresa_id uuid,
    p_cliente_data jsonb,
    p_contatos jsonb
)
RETURNS uuid AS $$
DECLARE
    v_cliente_id uuid;
BEGIN
    INSERT INTO public.clientes_fornecedores (empresa_id, nome_razao_social, tipo_pessoa, tipo_contato, cobranca_diferente, fantasia, cnpj_cpf, inscricao_estadual, inscricao_municipal, rg, rnm, cep, municipio, uf, endereco, bairro, numero, complemento, cobr_cep, cobr_municipio, cobr_uf, cobr_endereco, cobr_bairro, cobr_numero, cobr_complemento, telefone, telefone_adicional, celular, website, email, email_nfe, observacoes)
    VALUES (
        p_empresa_id,
        p_cliente_data->>'nome_razao_social',
        (p_cliente_data->>'tipo_pessoa')::tipo_pessoa,
        (p_cliente_data->>'tipo_contato')::tipo_contato,
        (p_cliente_data->>'cobranca_diferente')::boolean,
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
        p_cliente_data->>'observacoes'
    ) RETURNING id INTO v_cliente_id;

    IF p_contatos IS NOT NULL AND jsonb_array_length(p_contatos) > 0 THEN
        INSERT INTO public.clientes_contatos (empresa_id, cliente_fornecedor_id, nome, setor, email, telefone, ramal)
        SELECT p_empresa_id, v_cliente_id, c->>'nome', c->>'setor', c->>'email', c->>'telefone', c->>'ramal'
        FROM jsonb_array_elements(p_contatos) c;
    END IF;

    RETURN v_cliente_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.create_cliente_fornecedor_completo(uuid,jsonb,jsonb) SET search_path = public;

CREATE OR REPLACE FUNCTION public.update_cliente_fornecedor_completo(
    p_cliente_id uuid,
    p_cliente_data jsonb,
    p_contatos jsonb
)
RETURNS void AS $$
DECLARE
    v_empresa_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.clientes_fornecedores WHERE id = p_cliente_id;
    IF NOT private.is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Permission denied';
    END IF;

    UPDATE public.clientes_fornecedores
    SET
        nome_razao_social = p_cliente_data->>'nome_razao_social',
        tipo_pessoa = (p_cliente_data->>'tipo_pessoa')::tipo_pessoa,
        tipo_contato = (p_cliente_data->>'tipo_contato')::tipo_contato,
        cobranca_diferente = (p_cliente_data->>'cobranca_diferente')::boolean,
        fantasia = p_cliente_data->>'fantasia',
        cnpj_cpf = p_cliente_data->>'cnpj_cpf',
        inscricao_estadual = p_cliente_data->>'inscricao_estadual',
        inscricao_municipal = p_cliente_data->>'inscricao_municipal',
        rg = p_cliente_data->>'rg',
        rnm = p_cliente_data->>'rnm',
        cep = p_cliente_data->>'cep',
        municipio = p_cliente_data->>'municipio',
        uf = p_cliente_data->>'uf',
        endereco = p_cliente_data->>'endereco',
        bairro = p_cliente_data->>'bairro',
        numero = p_cliente_data->>'numero',
        complemento = p_cliente_data->>'complemento',
        cobr_cep = p_cliente_data->>'cobr_cep',
        cobr_municipio = p_cliente_data->>'cobr_municipio',
        cobr_uf = p_cliente_data->>'cobr_uf',
        cobr_endereco = p_cliente_data->>'cobr_endereco',
        cobr_bairro = p_cliente_data->>'cobr_bairro',
        cobr_numero = p_cliente_data->>'cobr_numero',
        cobr_complemento = p_cliente_data->>'cobr_complemento',
        telefone = p_cliente_data->>'telefone',
        telefone_adicional = p_cliente_data->>'telefone_adicional',
        celular = p_cliente_data->>'celular',
        website = p_cliente_data->>'website',
        email = p_cliente_data->>'email',
        email_nfe = p_cliente_data->>'email_nfe',
        observacoes = p_cliente_data->>'observacoes',
        updated_at = now()
    WHERE id = p_cliente_id;

    DELETE FROM public.clientes_contatos WHERE cliente_fornecedor_id = p_cliente_id;

    IF p_contatos IS NOT NULL AND jsonb_array_length(p_contatos) > 0 THEN
        INSERT INTO public.clientes_contatos (empresa_id, cliente_fornecedor_id, nome, setor, email, telefone, ramal)
        SELECT v_empresa_id, p_cliente_id, c->>'nome', c->>'setor', c->>'email', c->>'telefone', c->>'ramal'
        FROM jsonb_array_elements(p_contatos) c;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.update_cliente_fornecedor_completo(uuid,jsonb,jsonb) SET search_path = public;

CREATE OR REPLACE FUNCTION public.delete_cliente_fornecedor_if_member(p_id uuid)
RETURNS void AS $$
DECLARE
    v_empresa_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.clientes_fornecedores WHERE id = p_id;
    IF private.is_member_of_empresa(v_empresa_id) THEN
        DELETE FROM public.clientes_fornecedores WHERE id = p_id;
    ELSE
        RAISE EXCEPTION 'Permission denied';
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.delete_cliente_fornecedor_if_member(uuid) SET search_path = public,private;

CREATE OR REPLACE FUNCTION public.create_cliente_anexo(p_empresa_id uuid, p_cliente_id uuid, p_storage_path text, p_filename text, p_content_type text, p_tamanho_bytes bigint)
RETURNS json AS $$
DECLARE
    new_anexo public.clientes_anexos;
BEGIN
    IF NOT private.is_member_of_empresa(p_empresa_id) THEN
        RAISE EXCEPTION 'Permission denied';
    END IF;
    INSERT INTO public.clientes_anexos(empresa_id, cliente_fornecedor_id, storage_path, filename, content_type, tamanho_bytes)
    VALUES (p_empresa_id, p_cliente_id, p_storage_path, p_filename, p_content_type, p_tamanho_bytes)
    RETURNING * INTO new_anexo;
    RETURN row_to_json(new_anexo);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.create_cliente_anexo(uuid,uuid,text,text,text,bigint) SET search_path = public,private;

-- PRODUTOS
CREATE OR REPLACE FUNCTION public.create_produto_completo(p_empresa_id uuid, p_produto_data jsonb, p_atributos jsonb, p_fornecedores jsonb)
RETURNS uuid AS $$
DECLARE
    v_produto_id uuid;
BEGIN
    INSERT INTO public.produtos (empresa_id, nome, tipo, situacao, codigo, codigo_barras, unidade, preco_venda, custo_medio, origem, ncm, cest, controlar_estoque, estoque_inicial, estoque_minimo, estoque_maximo, localizacao, dias_preparacao, controlar_lotes, peso_liquido, peso_bruto, numero_volumes, embalagem_id, largura, altura, comprimento, diametro, marca, modelo, disponibilidade, garantia, video_url, descricao_curta, descricao_complementar, slug, titulo_seo, meta_descricao_seo, observacoes)
    VALUES (
        p_empresa_id,
        p_produto_data->>'nome', (p_produto_data->>'tipo')::tipo_produto, (p_produto_data->>'situacao')::situacao_produto, p_produto_data->>'codigo', p_produto_data->>'codigo_barras', p_produto_data->>'unidade', (p_produto_data->>'preco_venda')::numeric, (p_produto_data->>'custo_medio')::numeric, (p_produto_data->>'origem')::origem_produto, p_produto_data->>'ncm', p_produto_data->>'cest', (p_produto_data->>'controlar_estoque')::boolean, (p_produto_data->>'estoque_inicial')::numeric, (p_produto_data->>'estoque_minimo')::numeric, (p_produto_data->>'estoque_maximo')::numeric, p_produto_data->>'localizacao', (p_produto_data->>'dias_preparacao')::integer, (p_produto_data->>'controlar_lotes')::boolean, (p_produto_data->>'peso_liquido')::numeric, (p_produto_data->>'peso_bruto')::numeric, (p_produto_data->>'numero_volumes')::integer, (p_produto_data->>'embalagem_id')::uuid, (p_produto_data->>'largura')::numeric, (p_produto_data->>'altura')::numeric, (p_produto_data->>'comprimento')::numeric, (p_produto_data->>'diametro')::numeric, p_produto_data->>'marca', p_produto_data->>'modelo', p_produto_data->>'disponibilidade', p_produto_data->>'garantia', p_produto_data->>'video_url', p_produto_data->>'descricao_curta', p_produto_data->>'descricao_complementar', p_produto_data->>'slug', p_produto_data->>'titulo_seo', p_produto_data->>'meta_descricao_seo', p_produto_data->>'observacoes'
    ) RETURNING id INTO v_produto_id;

    IF p_atributos IS NOT NULL AND jsonb_array_length(p_atributos) > 0 THEN
        INSERT INTO public.produto_atributos (empresa_id, produto_id, atributo, valor)
        SELECT p_empresa_id, v_produto_id, a->>'atributo', a->>'valor' FROM jsonb_array_elements(p_atributos) a;
    END IF;

    IF p_fornecedores IS NOT NULL AND jsonb_array_length(p_fornecedores) > 0 THEN
        INSERT INTO public.produto_fornecedores (empresa_id, produto_id, fornecedor_id, codigo_no_fornecedor)
        SELECT p_empresa_id, v_produto_id, (f->>'fornecedor_id')::uuid, f->>'codigo_no_fornecedor' FROM jsonb_array_elements(p_fornecedores) f;
    END IF;

    RETURN v_produto_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.create_produto_completo(uuid,jsonb,jsonb,jsonb) SET search_path = public;

CREATE OR REPLACE FUNCTION public.update_produto_completo(p_produto_id uuid, p_produto_data jsonb, p_atributos jsonb, p_fornecedores jsonb)
RETURNS void AS $$
DECLARE
    v_empresa_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.produtos WHERE id = p_produto_id;
    IF NOT private.is_member_of_empresa(v_empresa_id) THEN RAISE EXCEPTION 'Permission denied'; END IF;

    UPDATE public.produtos SET
        nome = p_produto_data->>'nome', tipo = (p_produto_data->>'tipo')::tipo_produto, situacao = (p_produto_data->>'situacao')::situacao_produto, codigo = p_produto_data->>'codigo', codigo_barras = p_produto_data->>'codigo_barras', unidade = p_produto_data->>'unidade', preco_venda = (p_produto_data->>'preco_venda')::numeric, custo_medio = (p_produto_data->>'custo_medio')::numeric, origem = (p_produto_data->>'origem')::origem_produto, ncm = p_produto_data->>'ncm', cest = p_produto_data->>'cest', controlar_estoque = (p_produto_data->>'controlar_estoque')::boolean, estoque_minimo = (p_produto_data->>'estoque_minimo')::numeric, estoque_maximo = (p_produto_data->>'estoque_maximo')::numeric, localizacao = p_produto_data->>'localizacao', dias_preparacao = (p_produto_data->>'dias_preparacao')::integer, controlar_lotes = (p_produto_data->>'controlar_lotes')::boolean, peso_liquido = (p_produto_data->>'peso_liquido')::numeric, peso_bruto = (p_produto_data->>'peso_bruto')::numeric, numero_volumes = (p_produto_data->>'numero_volumes')::integer, embalagem_id = (p_produto_data->>'embalagem_id')::uuid, largura = (p_produto_data->>'largura')::numeric, altura = (p_produto_data->>'altura')::numeric, comprimento = (p_produto_data->>'comprimento')::numeric, diametro = (p_produto_data->>'diametro')::numeric, marca = p_produto_data->>'marca', modelo = p_produto_data->>'modelo', disponibilidade = p_produto_data->>'disponibilidade', garantia = p_produto_data->>'garantia', video_url = p_produto_data->>'video_url', descricao_curta = p_produto_data->>'descricao_curta', descricao_complementar = p_produto_data->>'descricao_complementar', slug = p_produto_data->>'slug', titulo_seo = p_produto_data->>'titulo_seo', meta_descricao_seo = p_produto_data->>'meta_descricao_seo', observacoes = p_produto_data->>'observacoes', updated_at = now()
    WHERE id = p_produto_id;

    DELETE FROM public.produto_atributos WHERE produto_id = p_produto_id;
    IF p_atributos IS NOT NULL AND jsonb_array_length(p_atributos) > 0 THEN
        INSERT INTO public.produto_atributos (empresa_id, produto_id, atributo, valor)
        SELECT v_empresa_id, p_produto_id, a->>'atributo', a->>'valor' FROM jsonb_array_elements(p_atributos) a;
    END IF;

    DELETE FROM public.produto_fornecedores WHERE produto_id = p_produto_id;
    IF p_fornecedores IS NOT NULL AND jsonb_array_length(p_fornecedores) > 0 THEN
        INSERT INTO public.produto_fornecedores (empresa_id, produto_id, fornecedor_id, codigo_no_fornecedor)
        SELECT v_empresa_id, p_produto_id, (f->>'fornecedor_id')::uuid, f->>'codigo_no_fornecedor' FROM jsonb_array_elements(p_fornecedores) f;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.update_produto_completo(uuid,jsonb,jsonb,jsonb) SET search_path = public;

CREATE OR REPLACE FUNCTION public.delete_produto(p_id uuid)
RETURNS text[] AS $$
DECLARE
    v_empresa_id uuid;
    v_image_paths text[];
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.produtos WHERE id = p_id;
    IF NOT private.is_member_of_empresa(v_empresa_id) THEN RAISE EXCEPTION 'Permission denied'; END IF;
    
    SELECT array_agg(storage_path) INTO v_image_paths FROM public.produto_imagens WHERE produto_id = p_id;
    DELETE FROM public.produtos WHERE id = p_id;
    RETURN v_image_paths;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.delete_produto(uuid) SET search_path = public,private;

CREATE OR REPLACE FUNCTION public.create_produto_imagem(p_produto_id uuid, p_storage_path text, p_filename text, p_content_type text, p_tamanho_bytes bigint)
RETURNS json AS $$
DECLARE
    v_empresa_id uuid;
    new_imagem public.produto_imagens;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.produtos WHERE id = p_produto_id;
    IF NOT private.is_member_of_empresa(v_empresa_id) THEN RAISE EXCEPTION 'Permission denied'; END IF;

    INSERT INTO public.produto_imagens(empresa_id, produto_id, storage_path, nome_arquivo, content_type, tamanho_bytes)
    VALUES (v_empresa_id, p_produto_id, p_storage_path, p_filename, p_content_type, p_tamanho_bytes)
    RETURNING * INTO new_imagem;
    RETURN row_to_json(new_imagem);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.create_produto_imagem(uuid,text,text,text,bigint) SET search_path = public,private;

-- DEMAIS FUNÇÕES (serão adicionadas conforme os módulos forem reconstruídos)
