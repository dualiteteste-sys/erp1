-- Versão 3: Script de Reconstrução Completa e Final
-- Corrige o erro de sintaxe '</sql>' e garante uma base de dados limpa.

-- Início da "Terra Arrasada" Segura
DO $$
DECLARE
    r RECORD;
BEGIN
    -- Remove todas as políticas de RLS no esquema public
    FOR r IN (SELECT tablename, policyname FROM pg_policies WHERE schemaname = 'public') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON public."' || r.tablename || '";';
    END LOOP;

    -- Remove todos os triggers no esquema public
    FOR r IN (SELECT trigger_name, event_object_table FROM information_schema.triggers WHERE trigger_schema = 'public') LOOP
        EXECUTE 'DROP TRIGGER IF EXISTS "' || r.trigger_name || '" ON public."' || r.event_object_table || '" CASCADE;';
    END LOOP;

    -- Remove todas as funções no esquema public
    FOR r IN (SELECT routine_name, specific_name FROM information_schema.routines WHERE routine_schema = 'public' AND routine_type = 'FUNCTION') LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS public."' || r.routine_name || '" CASCADE;';
    END LOOP;

    -- Remove todas as procedures no esquema public
    FOR r IN (SELECT routine_name, specific_name FROM information_schema.routines WHERE routine_schema = 'public' AND routine_type = 'PROCEDURE') LOOP
        EXECUTE 'DROP PROCEDURE IF EXISTS public."' || r.routine_name || '" CASCADE;';
    END LOOP;

    -- Remove todas as tabelas no esquema public
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
        EXECUTE 'DROP TABLE IF EXISTS public."' || r.tablename || '" CASCADE;';
    END LOOP;

    -- Remove todos os tipos (ENUMs) no esquema public
    FOR r IN (SELECT typname FROM pg_type JOIN pg_namespace ON pg_type.typnamespace = pg_namespace.oid WHERE nspname = 'public' AND typtype = 'e') LOOP
        EXECUTE 'DROP TYPE IF EXISTS public."' || r.typname || '" CASCADE;';
    END LOOP;

    -- Limpa o esquema private também
    FOR r IN (SELECT routine_name FROM information_schema.routines WHERE routine_schema = 'private') LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS private."' || r.routine_name || '"() CASCADE;';
    END LOOP;
END $$;


-- Início da Reconstrução

-- 1. Tipos (ENUMS)
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

-- 2. Tabelas
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
    updated_at timestamptz DEFAULT now(),
    created_by uuid REFERENCES auth.users(id)
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
    UNIQUE(empresa_id, cnpj_cpf)
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

CREATE TABLE public.produtos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nome text NOT NULL,
    tipo tipo_produto NOT NULL,
    situacao situacao_produto NOT NULL,
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
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    UNIQUE(empresa_id, codigo)
);

CREATE TABLE public.produto_imagens (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    storage_path text NOT NULL,
    nome_arquivo text NOT NULL,
    content_type text,
    tamanho_bytes bigint,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE public.produto_atributos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    atributo text NOT NULL,
    valor text,
    UNIQUE(produto_id, atributo)
);

CREATE TABLE public.produto_fornecedores (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    fornecedor_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE,
    codigo_no_fornecedor text,
    UNIQUE(produto_id, fornecedor_id)
);

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
    email text,
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
    updated_at timestamptz DEFAULT now(),
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
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE public.papeis (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nome text NOT NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    UNIQUE(empresa_id, nome)
);

CREATE TABLE public.papel_permissoes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    papel_id uuid NOT NULL REFERENCES public.papeis(id) ON DELETE CASCADE,
    permissao_id text NOT NULL,
    UNIQUE(papel_id, permissao_id)
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

-- 3. Funções e Triggers
-- Função de segurança para verificar se o usuário é membro da empresa
CREATE OR REPLACE FUNCTION private.is_member_of_empresa(p_user_id uuid, p_empresa_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.empresa_usuarios eu
    WHERE eu.user_id = p_user_id AND eu.empresa_id = p_empresa_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION private.is_member_of_empresa(uuid, uuid) SET search_path = public, private;

-- Trigger para criar perfil e associar à empresa no cadastro de novo usuário
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_empresa_id uuid;
BEGIN
  -- Cria a empresa para o novo usuário
  INSERT INTO public.empresas (razao_social, created_by)
  VALUES (new.raw_user_meta_data->>'fullName', new.id)
  RETURNING id INTO v_empresa_id;

  -- Associa o usuário à nova empresa
  INSERT INTO public.empresa_usuarios (user_id, empresa_id)
  VALUES (new.id, v_empresa_id);

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.handle_new_user() SET search_path = public;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Funções RPC para CRUD
CREATE OR REPLACE FUNCTION public.create_cliente_fornecedor_completo(
    p_empresa_id uuid,
    p_cliente_data jsonb,
    p_contatos jsonb
) RETURNS uuid AS $$
DECLARE
    v_cliente_id uuid;
BEGIN
    INSERT INTO public.clientes_fornecedores (empresa_id, nome_razao_social, fantasia, tipo_pessoa, tipo_contato, cnpj_cpf, rg, rnm, inscricao_estadual, inscricao_municipal, cep, endereco, numero, complemento, bairro, municipio, uf, cobranca_diferente, cobr_cep, cobr_endereco, cobr_numero, cobr_complemento, cobr_bairro, cobr_municipio, cobr_uf, telefone, telefone_adicional, celular, email, email_nfe, website, observacoes, created_by)
    VALUES (
        p_empresa_id,
        p_cliente_data->>'nome_razao_social',
        p_cliente_data->>'fantasia',
        (p_cliente_data->>'tipo_pessoa')::tipo_pessoa,
        (p_cliente_data->>'tipo_contato')::tipo_contato,
        p_cliente_data->>'cnpj_cpf',
        p_cliente_data->>'rg',
        p_cliente_data->>'rnm',
        p_cliente_data->>'inscricao_estadual',
        p_cliente_data->>'inscricao_municipal',
        p_cliente_data->>'cep',
        p_cliente_data->>'endereco',
        p_cliente_data->>'numero',
        p_cliente_data->>'complemento',
        p_cliente_data->>'bairro',
        p_cliente_data->>'municipio',
        p_cliente_data->>'uf',
        (p_cliente_data->>'cobranca_diferente')::boolean,
        p_cliente_data->>'cobr_cep',
        p_cliente_data->>'cobr_endereco',
        p_cliente_data->>'cobr_numero',
        p_cliente_data->>'cobr_complemento',
        p_cliente_data->>'cobr_bairro',
        p_cliente_data->>'cobr_municipio',
        p_cliente_data->>'cobr_uf',
        p_cliente_data->>'telefone',
        p_cliente_data->>'telefone_adicional',
        p_cliente_data->>'celular',
        p_cliente_data->>'email',
        p_cliente_data->>'email_nfe',
        p_cliente_data->>'website',
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

CREATE OR REPLACE FUNCTION public.update_cliente_fornecedor_completo(
    p_cliente_id uuid,
    p_cliente_data jsonb,
    p_contatos jsonb
) RETURNS void AS $$
DECLARE
    v_empresa_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.clientes_fornecedores WHERE id = p_cliente_id;
    IF NOT private.is_member_of_empresa(auth.uid(), v_empresa_id) THEN
        RAISE EXCEPTION 'Permission denied';
    END IF;

    UPDATE public.clientes_fornecedores SET
        nome_razao_social = p_cliente_data->>'nome_razao_social',
        fantasia = p_cliente_data->>'fantasia',
        tipo_pessoa = (p_cliente_data->>'tipo_pessoa')::tipo_pessoa,
        tipo_contato = (p_cliente_data->>'tipo_contato')::tipo_contato,
        cnpj_cpf = p_cliente_data->>'cnpj_cpf',
        rg = p_cliente_data->>'rg',
        rnm = p_cliente_data->>'rnm',
        inscricao_estadual = p_cliente_data->>'inscricao_estadual',
        inscricao_municipal = p_cliente_data->>'inscricao_municipal',
        cep = p_cliente_data->>'cep',
        endereco = p_cliente_data->>'endereco',
        numero = p_cliente_data->>'numero',
        complemento = p_cliente_data->>'complemento',
        bairro = p_cliente_data->>'bairro',
        municipio = p_cliente_data->>'municipio',
        uf = p_cliente_data->>'uf',
        cobranca_diferente = (p_cliente_data->>'cobranca_diferente')::boolean,
        cobr_cep = p_cliente_data->>'cobr_cep',
        cobr_endereco = p_cliente_data->>'cobr_endereco',
        cobr_numero = p_cliente_data->>'cobr_numero',
        cobr_complemento = p_cliente_data->>'cobr_complemento',
        cobr_bairro = p_cliente_data->>'cobr_bairro',
        cobr_municipio = p_cliente_data->>'cobr_municipio',
        cobr_uf = p_cliente_data->>'cobr_uf',
        telefone = p_cliente_data->>'telefone',
        telefone_adicional = p_cliente_data->>'telefone_adicional',
        celular = p_cliente_data->>'celular',
        email = p_cliente_data->>'email',
        email_nfe = p_cliente_data->>'email_nfe',
        website = p_cliente_data->>'website',
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
ALTER FUNCTION public.update_cliente_fornecedor_completo(uuid, jsonb, jsonb) SET search_path = public;

-- 4. Storage e Políticas
INSERT INTO storage.buckets (id, name, public) VALUES ('logos', 'logos', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('clientes_anexos', 'clientes_anexos', false) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('produto-imagens', 'produto-imagens', true) ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Permite acesso público a logos" ON storage.objects;
CREATE POLICY "Permite acesso público a logos" ON storage.objects FOR SELECT USING (bucket_id = 'logos');

DROP POLICY IF EXISTS "Permite acesso autenticado a anexos" ON storage.objects;
CREATE POLICY "Permite acesso autenticado a anexos" ON storage.objects FOR ALL USING (bucket_id = 'clientes_anexos' AND private.is_member_of_empresa(auth.uid(), (storage.foldername(name))[1]::uuid)) WITH CHECK (bucket_id = 'clientes_anexos' AND private.is_member_of_empresa(auth.uid(), (storage.foldername(name))[1]::uuid));

DROP POLICY IF EXISTS "Permite acesso público a imagens de produto" ON storage.objects;
CREATE POLICY "Permite acesso público a imagens de produto" ON storage.objects FOR SELECT USING (bucket_id = 'produto-imagens');

-- 5. Ativação de RLS e Criação de Políticas
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

CREATE POLICY "Membros podem gerenciar sua própria empresa" ON public.empresas FOR ALL USING (id IN (SELECT empresa_id FROM public.empresa_usuarios WHERE user_id = auth.uid()));
CREATE POLICY "Usuários podem ver suas associações" ON public.empresa_usuarios FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.clientes_fornecedores FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));
CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.clientes_contatos FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));
CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.clientes_anexos FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));
CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.embalagens FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));
CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.produtos FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));
CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.produto_imagens FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));
CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.produto_atributos FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));
CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.produto_fornecedores FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));
CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.servicos FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));
CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.vendedores FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));
CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.vendedores_contatos FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));
CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.papeis FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));
CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.papel_permissoes FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));
CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.categorias_financeiras FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));
CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.formas_pagamento FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));
