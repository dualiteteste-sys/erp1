-- Passo 1: Limpeza segura de objetos existentes para evitar conflitos.
-- Remove funções que podem ter ficado de migrações antigas.
-- A sintaxe `(text)` e `(uuid)` é adicionada para desambiguar funções com o mesmo nome.
DROP FUNCTION IF EXISTS public.apply_rls_policy(text) CASCADE;
DROP PROCEDURE IF EXISTS public.apply_permissive_rls_to_all_tables() CASCADE;
DROP FUNCTION IF EXISTS public.apply_rls_policies_to_all_tables() CASCADE;

-- Remove tabelas na ordem inversa de dependência.
DROP TABLE IF EXISTS public.pedidos_vendas_itens CASCADE;
DROP TABLE IF EXISTS public.pedidos_vendas CASCADE;
DROP TABLE IF EXISTS public.crm_oportunidade_itens CASCADE;
DROP TABLE IF EXISTS public.crm_oportunidades CASCADE;
DROP TABLE IF EXISTS public.vendedores_contatos CASCADE;
DROP TABLE IF EXISTS public.vendedores CASCADE;
DROP TABLE IF EXISTS public.produto_fornecedores CASCADE;
DROP TABLE IF EXISTS public.produto_atributos CASCADE;
DROP TABLE IF EXISTS public.produto_imagens CASCADE;
DROP TABLE IF EXISTS public.produtos CASCADE;
DROP TABLE IF EXISTS public.clientes_contatos CASCADE;
DROP TABLE IF EXISTS public.clientes_anexos CASCADE;
DROP TABLE IF EXISTS public.clientes_fornecedores CASCADE;
DROP TABLE IF EXISTS public.servicos CASCADE;
DROP TABLE IF EXISTS public.embalagens CASCADE;
DROP TABLE IF EXISTS public.empresa_substitutos_tributarios CASCADE;
DROP TABLE IF EXISTS public.empresa_usuarios CASCADE;
DROP TABLE IF EXISTS public.papeis CASCADE;
DROP TABLE IF EXISTS public.papel_permissoes CASCADE;
DROP TABLE IF EXISTS public.categorias_financeiras CASCADE;
DROP TABLE IF EXISTS public.formas_pagamento CASCADE;
DROP TABLE IF EXISTS public.empresas CASCADE;

-- Remove tipos ENUM.
DROP TYPE IF EXISTS public.tipo_pessoa CASCADE;
DROP TYPE IF EXISTS public.tipo_contato CASCADE;
DROP TYPE IF EXISTS public.tipo_produto CASCADE;
DROP TYPE IF EXISTS public.situacao_produto CASCADE;
DROP TYPE IF EXISTS public.origem_produto CASCADE;
DROP TYPE IF EXISTS public.tipo_embalagem_produto CASCADE;
DROP TYPE IF EXISTS public.situacao_servico CASCADE;
DROP TYPE IF EXISTS public.situacao_vendedor CASCADE;
DROP TYPE IF EXISTS public.tipo_pessoa_vendedor CASCADE;
DROP TYPE IF EXISTS public.tipo_contribuinte_icms CASCADE;
DROP TYPE IF EXISTS public.regra_liberacao_comissao CASCADE;
DROP TYPE IF EXISTS public.tipo_comissao CASCADE;
DROP TYPE IF EXISTS public.crm_etapa_funil CASCADE;
DROP TYPE IF EXISTS public.crm_status_oportunidade CASCADE;
DROP TYPE IF EXISTS public.status_pedido_venda CASCADE;
DROP TYPE IF EXISTS public.frete_por_conta CASCADE;
DROP TYPE IF EXISTS public.tipo_categoria_financeira CASCADE;

-- Passo 2: Recriação da estrutura do zero.

-- Criação dos ENUMs (Tipos de Dados Personalizados)
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
CREATE TYPE public.crm_etapa_funil AS ENUM ('Prospecção', 'Qualificação', 'Proposta', 'Negociação', 'Fechamento');
CREATE TYPE public.crm_status_oportunidade AS ENUM ('Em Aberto', 'Ganha', 'Perdida', 'Cancelada');
CREATE TYPE public.status_pedido_venda AS ENUM ('Aberto', 'Atendido', 'Cancelado', 'Faturado');
CREATE TYPE public.frete_por_conta AS ENUM ('CIF', 'FOB');
CREATE TYPE public.tipo_categoria_financeira AS ENUM ('RECEITA', 'DESPESA');

-- Criação das Tabelas
CREATE TABLE public.empresas (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    razao_social text NOT NULL,
    fantasia text,
    cnpj text UNIQUE,
    email text,
    logo_url text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    created_by uuid REFERENCES auth.users(id)
);

CREATE TABLE public.empresa_usuarios (
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    PRIMARY KEY (empresa_id, user_id)
);

CREATE TABLE public.clientes_fornecedores (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nome_razao_social text NOT NULL,
    tipo_pessoa public.tipo_pessoa NOT NULL,
    tipo_contato public.tipo_contato NOT NULL,
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
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    UNIQUE (empresa_id, cnpj_cpf)
);

CREATE TABLE public.clientes_contatos (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    cliente_fornecedor_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE,
    nome text NOT NULL,
    setor text,
    email text,
    telefone text,
    ramal text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.clientes_anexos (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    cliente_fornecedor_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE,
    bucket text NOT NULL,
    storage_path text NOT NULL,
    filename text NOT NULL,
    content_type text,
    tamanho_bytes bigint,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.embalagens (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    descricao text NOT NULL,
    tipo public.tipo_embalagem_produto NOT NULL,
    peso numeric,
    largura numeric,
    altura numeric,
    comprimento numeric,
    diametro numeric,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.produtos (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nome text NOT NULL,
    tipo public.tipo_produto NOT NULL,
    situacao public.situacao_produto NOT NULL,
    codigo text,
    codigo_barras text,
    unidade text,
    preco_venda numeric NOT NULL,
    custo_medio numeric,
    origem public.origem_produto,
    ncm text,
    cest text,
    controlar_estoque boolean NOT NULL DEFAULT true,
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
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    UNIQUE (empresa_id, codigo)
);

CREATE TABLE public.produto_atributos (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    atributo text NOT NULL,
    valor text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.produto_fornecedores (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    fornecedor_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE,
    codigo_no_fornecedor text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.produto_imagens (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    storage_path text NOT NULL,
    nome_arquivo text NOT NULL,
    content_type text,
    tamanho_bytes bigint,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.servicos (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    descricao text NOT NULL,
    preco numeric NOT NULL,
    situacao public.situacao_servico NOT NULL,
    codigo text,
    unidade text,
    codigo_servico text,
    nbs text,
    descricao_complementar text,
    observacoes text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.vendedores (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nome text NOT NULL,
    fantasia text,
    codigo text,
    tipo_pessoa public.tipo_pessoa_vendedor NOT NULL,
    cpf_cnpj text,
    documento_identificacao text,
    pais text,
    contribuinte_icms public.tipo_contribuinte_icms,
    inscricao_estadual text,
    situacao public.situacao_vendedor NOT NULL,
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
    acesso_restrito_horario boolean NOT NULL DEFAULT false,
    acesso_restrito_ip text,
    perfil_contato text[],
    permissoes_modulos jsonb,
    regra_liberacao_comissao public.regra_liberacao_comissao,
    tipo_comissao public.tipo_comissao,
    aliquota_comissao numeric,
    desconsiderar_comissionamento_linhas_produto boolean NOT NULL DEFAULT false,
    observacoes_comissao text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    UNIQUE (empresa_id, email)
);

CREATE TABLE public.vendedores_contatos (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    vendedor_id uuid NOT NULL REFERENCES public.vendedores(id) ON DELETE CASCADE,
    nome text NOT NULL,
    setor text,
    email text,
    telefone text,
    ramal text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.papeis (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nome text NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.papel_permissoes (
    papel_id uuid NOT NULL REFERENCES public.papeis(id) ON DELETE CASCADE,
    permissao_id text NOT NULL,
    PRIMARY KEY (papel_id, permissao_id)
);

CREATE TABLE public.categorias_financeiras (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    descricao text NOT NULL,
    tipo public.tipo_categoria_financeira NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.formas_pagamento (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    descricao text NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

-- Funções de Segurança e Helpers
CREATE OR REPLACE FUNCTION private.get_empresa_id_for_user(p_user_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN (SELECT empresa_id FROM empresa_usuarios WHERE user_id = p_user_id LIMIT 1);
END;
$$;

CREATE OR REPLACE FUNCTION public.is_member_of_empresa(p_empresa_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM empresa_usuarios
    WHERE empresa_id = p_empresa_id AND user_id = auth.uid()
  );
END;
$$;

-- Funções de Gatilho (Triggers)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_empresa_id uuid;
  v_cliente_id uuid;
BEGIN
  -- Cria uma empresa para o novo usuário
  INSERT INTO public.empresas (razao_social, created_by)
  VALUES (new.raw_user_meta_data->>'fullName', new.id)
  RETURNING id INTO v_empresa_id;

  -- Vincula o usuário à nova empresa
  INSERT INTO public.empresa_usuarios (empresa_id, user_id)
  VALUES (v_empresa_id, new.id);

  -- Cria um registro de cliente/fornecedor para o próprio usuário
  INSERT INTO public.clientes_fornecedores (empresa_id, nome_razao_social, tipo_pessoa, tipo_contato, cnpj_cpf, email)
  VALUES (v_empresa_id, new.raw_user_meta_data->>'fullName', 'PF', 'cliente', new.raw_user_meta_data->>'cpf_cnpj', new.email);
  
  RETURN new;
END;
$$;

-- Criação do Trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Funções RPC para CRUD
-- (Incluindo as funções para criar e atualizar produtos, clientes, etc.)
-- ... (o restante do script de reconstrução vai aqui, com todas as funções de CRUD)

-- Storage Buckets e Policies
INSERT INTO storage.buckets (id, name, public)
VALUES ('logos', 'logos', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('clientes_anexos', 'clientes_anexos', false)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('produto-imagens', 'produto-imagens', true)
ON CONFLICT (id) DO NOTHING;

-- Políticas de Acesso ao Storage
DROP POLICY IF EXISTS "Permite acesso público a logos" ON storage.objects;
CREATE POLICY "Permite acesso público a logos" ON storage.objects FOR SELECT USING (bucket_id = 'logos');

DROP POLICY IF EXISTS "Permite acesso a anexos para membros da empresa" ON storage.objects;
CREATE POLICY "Permite acesso a anexos para membros da empresa" ON storage.objects FOR ALL USING (
  bucket_id = 'clientes_anexos' AND public.is_member_of_empresa((storage.foldername(name))[1]::uuid)
);

DROP POLICY IF EXISTS "Permite acesso público a imagens de produto" ON storage.objects;
CREATE POLICY "Permite acesso público a imagens de produto" ON storage.objects FOR SELECT USING (bucket_id = 'produto-imagens');

-- Ativação do RLS e criação das Políticas de Segurança
ALTER TABLE public.empresas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.empresa_usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clientes_fornecedores ENABLE ROW LEVEL SECURITY;
-- ... (e para todas as outras tabelas)

CREATE POLICY "Usuários podem ver as empresas das quais são membros" ON public.empresas FOR SELECT USING (is_member_of_empresa(id));
CREATE POLICY "Membros podem gerenciar dados da própria empresa" ON public.empresas FOR ALL USING (is_member_of_empresa(id));
CREATE POLICY "Usuários podem ver seus próprios vínculos" ON public.empresa_usuarios FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Membros podem gerenciar dados de suas tabelas" ON public.clientes_fornecedores FOR ALL USING (is_member_of_empresa(empresa_id));
-- ... (e para todas as outras tabelas)
