-- Versão: 20251017000000
-- Descrição: Rollback completo para uma versão estável do sistema.
-- Remove módulos complexos e problemáticos (CRM, Pedidos de Venda, etc.)
-- e recria as estruturas essenciais do zero para garantir consistência.

-- Etapa 1: Remover com segurança todas as dependências e objetos personalizados
DROP FUNCTION IF EXISTS public.is_member_of_empresa(uuid) CASCADE;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

DROP TABLE IF EXISTS public.pedidos_vendas_itens;
DROP TABLE IF EXISTS public.pedidos_vendas;
DROP TABLE IF EXISTS public.crm_oportunidade_itens;
DROP TABLE IF EXISTS public.crm_oportunidades;
DROP TABLE IF EXISTS public.vendedores_contatos;
DROP TABLE IF EXISTS public.vendedores;
DROP TABLE IF EXISTS public.produto_fornecedores;
DROP TABLE IF EXISTS public.produto_atributos;
DROP TABLE IF EXISTS public.produto_imagens;
DROP TABLE IF EXISTS public.clientes_anexos;
DROP TABLE IF EXISTS public.clientes_contatos;
DROP TABLE IF EXISTS public.servicos;
DROP TABLE IF EXISTS public.produtos;
DROP TABLE IF EXISTS public.embalagens;
DROP TABLE IF EXISTS public.papel_permissoes;
DROP TABLE IF EXISTS public.papeis;
DROP TABLE IF EXISTS public.categorias_financeiras;
DROP TABLE IF EXISTS public.formas_pagamento;
DROP TABLE IF EXISTS public.empresa_usuarios;
DROP TABLE IF EXISTS public.empresas;

DROP TYPE IF EXISTS public.status_pedido_venda;
DROP TYPE IF EXISTS public.frete_por_conta;
DROP TYPE IF EXISTS public.crm_etapa_funil;
DROP TYPE IF EXISTS public.crm_status_oportunidade;
DROP TYPE IF EXISTS public.situacao_vendedor;
DROP TYPE IF EXISTS public.tipo_pessoa_vendedor;
DROP TYPE IF EXISTS public.tipo_contribuinte_icms;
DROP TYPE IF EXISTS public.regra_liberacao_comissao;
DROP TYPE IF EXISTS public.tipo_comissao;
DROP TYPE IF EXISTS public.tipo_produto;
DROP TYPE IF EXISTS public.situacao_produto;
DROP TYPE IF EXISTS public.origem_produto;
DROP TYPE IF EXISTS public.tipo_embalagem_produto;
DROP TYPE IF EXISTS public.situacao_servico;
DROP TYPE IF EXISTS public.tipo_pessoa;
DROP TYPE IF EXISTS public.tipo_contato;
DROP TYPE IF EXISTS public.tipo_categoria_financeira;

-- Etapa 2: Recriar a estrutura fundamental

-- Tabela de Empresas
CREATE TABLE public.empresas (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    razao_social text NOT NULL,
    fantasia text,
    cnpj text UNIQUE,
    email text,
    logo_url text
);
ALTER TABLE public.empresas ENABLE ROW LEVEL SECURITY;

-- Tabela de ligação Usuário <-> Empresa
CREATE TABLE public.empresa_usuarios (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(empresa_id, user_id)
);
ALTER TABLE public.empresa_usuarios ENABLE ROW LEVEL SECURITY;

-- Função para criar perfil e primeira empresa para um novo usuário
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Insere o perfil do usuário na tabela de usuários da empresa
  INSERT INTO public.empresa_usuarios (user_id, empresa_id)
  SELECT NEW.id, e.id FROM public.empresas e
  WHERE e.id = (SELECT empresa_id FROM public.empresa_usuarios eu WHERE eu.user_id = auth.uid() LIMIT 1);
  RETURN NEW;
END;
$$;

-- Gatilho para chamar a função quando um novo usuário é criado
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Função para verificar se um usuário pertence a uma empresa
CREATE OR REPLACE FUNCTION public.is_member_of_empresa(p_empresa_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.empresa_usuarios
    WHERE empresa_id = p_empresa_id
      AND user_id = auth.uid()
  );
END;
$$;


-- Etapa 3: Recriar o módulo de Clientes e Fornecedores

-- Tipos ENUM para Clientes
CREATE TYPE public.tipo_pessoa AS ENUM ('PF', 'PJ');
CREATE TYPE public.tipo_contato AS ENUM ('cliente', 'fornecedor', 'ambos');

-- Tabela de Clientes e Fornecedores
CREATE TABLE public.clientes_fornecedores (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid REFERENCES auth.users(id),
    
    nome_razao_social text NOT NULL,
    fantasia text,
    tipo_pessoa tipo_pessoa NOT NULL,
    tipo_contato tipo_contato NOT NULL,
    cnpj_cpf text,
    inscricao_estadual text,
    inscricao_municipal text,
    rg text,
    rnm text,

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

    UNIQUE(empresa_id, cnpj_cpf)
);
ALTER TABLE public.clientes_fornecedores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow members to manage their own company clients" ON public.clientes_fornecedores
  FOR ALL USING (is_member_of_empresa(empresa_id));

-- Tabela de Contatos Adicionais
CREATE TABLE public.clientes_contatos (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid NOT NULL,
    cliente_fornecedor_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    nome text NOT NULL,
    setor text,
    email text,
    telefone text,
    ramal text
);
ALTER TABLE public.clientes_contatos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow members to manage contacts" ON public.clientes_contatos
  FOR ALL USING (is_member_of_empresa(empresa_id));

-- Função para criar cliente completo
CREATE OR REPLACE FUNCTION public.create_cliente_fornecedor_completo(
    p_empresa_id uuid,
    p_cliente_data jsonb,
    p_contatos jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_cliente_id uuid;
    v_contato jsonb;
BEGIN
    INSERT INTO public.clientes_fornecedores (empresa_id, created_by, nome_razao_social, fantasia, tipo_pessoa, tipo_contato, cnpj_cpf, inscricao_estadual, inscricao_municipal, rg, rnm, cep, endereco, numero, complemento, bairro, municipio, uf, cobranca_diferente, cobr_cep, cobr_endereco, cobr_numero, cobr_complemento, cobr_bairro, cobr_municipio, cobr_uf, telefone, telefone_adicional, celular, email, email_nfe, website, observacoes)
    VALUES (
        p_empresa_id,
        auth.uid(),
        p_cliente_data->>'nomeRazaoSocial',
        p_cliente_data->>'fantasia',
        (p_cliente_data->>'tipoPessoa')::tipo_pessoa,
        (p_cliente_data->>'tipoContato')::tipo_contato,
        p_cliente_data->>'cnpjCpf',
        p_cliente_data->>'inscricaoEstadual',
        p_cliente_data->>'inscricaoMunicipal',
        p_cliente_data->>'rg',
        p_cliente_data->>'rnm',
        p_cliente_data->>'cep',
        p_cliente_data->>'endereco',
        p_cliente_data->>'numero',
        p_cliente_data->>'complemento',
        p_cliente_data->>'bairro',
        p_cliente_data->>'municipio',
        p_cliente_data->>'uf',
        (p_cliente_data->>'cobrancaDiferente')::boolean,
        p_cliente_data->>'cobrCep',
        p_cliente_data->>'cobrEndereco',
        p_cliente_data->>'cobrNumero',
        p_cliente_data->>'cobrComplemento',
        p_cliente_data->>'cobrBairro',
        p_cliente_data->>'cobrMunicipio',
        p_cliente_data->>'cobrUf',
        p_cliente_data->>'telefone',
        p_cliente_data->>'telefoneAdicional',
        p_cliente_data->>'celular',
        p_cliente_data->>'email',
        p_cliente_data->>'emailNfe',
        p_cliente_data->>'website',
        p_cliente_data->>'observacoes'
    ) RETURNING id INTO v_cliente_id;

    IF p_contatos IS NOT NULL THEN
        FOR v_contato IN SELECT * FROM jsonb_array_elements(p_contatos)
        LOOP
            INSERT INTO public.clientes_contatos (empresa_id, cliente_fornecedor_id, nome, setor, email, telefone, ramal)
            VALUES (p_empresa_id, v_cliente_id, v_contato->>'nome', v_contato->>'setor', v_contato->>'email', v_contato->>'telefone', v_contato->>'ramal');
        END LOOP;
    END IF;

    RETURN v_cliente_id;
END;
$$;

-- Função para atualizar cliente completo
CREATE OR REPLACE FUNCTION public.update_cliente_fornecedor_completo(
    p_cliente_id uuid,
    p_cliente_data jsonb,
    p_contatos jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_empresa_id uuid;
    v_contato jsonb;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.clientes_fornecedores WHERE id = p_cliente_id;

    IF NOT is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Permission denied';
    END IF;

    UPDATE public.clientes_fornecedores
    SET
        nome_razao_social = p_cliente_data->>'nomeRazaoSocial',
        fantasia = p_cliente_data->>'fantasia',
        tipo_pessoa = (p_cliente_data->>'tipoPessoa')::tipo_pessoa,
        tipo_contato = (p_cliente_data->>'tipoContato')::tipo_contato,
        cnpj_cpf = p_cliente_data->>'cnpjCpf',
        inscricao_estadual = p_cliente_data->>'inscricaoEstadual',
        inscricao_municipal = p_cliente_data->>'inscricaoMunicipal',
        rg = p_cliente_data->>'rg',
        rnm = p_cliente_data->>'rnm',
        cep = p_cliente_data->>'cep',
        endereco = p_cliente_data->>'endereco',
        numero = p_cliente_data->>'numero',
        complemento = p_cliente_data->>'complemento',
        bairro = p_cliente_data->>'bairro',
        municipio = p_cliente_data->>'municipio',
        uf = p_cliente_data->>'uf',
        cobranca_diferente = (p_cliente_data->>'cobrancaDiferente')::boolean,
        cobr_cep = p_cliente_data->>'cobrCep',
        cobr_endereco = p_cliente_data->>'cobrEndereco',
        cobr_numero = p_cliente_data->>'cobrNumero',
        cobr_complemento = p_cliente_data->>'cobrComplemento',
        cobr_bairro = p_cliente_data->>'cobrBairro',
        cobr_municipio = p_cliente_data->>'cobrMunicipio',
        cobr_uf = p_cliente_data->>'cobrUf',
        telefone = p_cliente_data->>'telefone',
        telefone_adicional = p_cliente_data->>'telefoneAdicional',
        celular = p_cliente_data->>'celular',
        email = p_cliente_data->>'email',
        email_nfe = p_cliente_data->>'emailNfe',
        website = p_cliente_data->>'website',
        observacoes = p_cliente_data->>'observacoes',
        updated_at = now()
    WHERE id = p_cliente_id;

    DELETE FROM public.clientes_contatos WHERE cliente_fornecedor_id = p_cliente_id;

    IF p_contatos IS NOT NULL THEN
        FOR v_contato IN SELECT * FROM jsonb_array_elements(p_contatos)
        LOOP
            INSERT INTO public.clientes_contatos (empresa_id, cliente_fornecedor_id, nome, setor, email, telefone, ramal)
            VALUES (v_empresa_id, p_cliente_id, v_contato->>'nome', v_contato->>'setor', v_contato->>'email', v_contato->>'telefone', v_contato->>'ramal');
        END LOOP;
    END IF;
END;
$$;

-- Função para deletar cliente
CREATE OR REPLACE FUNCTION public.delete_cliente_fornecedor_if_member(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_empresa_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.clientes_fornecedores WHERE id = p_id;
    IF is_member_of_empresa(v_empresa_id) THEN
        DELETE FROM public.clientes_fornecedores WHERE id = p_id;
    ELSE
        RAISE EXCEPTION 'Permission denied';
    END IF;
END;
$$;
