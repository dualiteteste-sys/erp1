-- =================================================================
-- MIGRATION: CRIAÇÃO COMPLETA DO MÓDULO DE PEDIDOS DE VENDA
--
-- Descrição:
-- Este script cria todas as tabelas, tipos, funções e políticas
-- de segurança necessárias para o funcionamento do módulo de
-- Pedidos de Venda.
--
-- Passos:
-- 1. Cria os tipos ENUM para status e frete.
-- 2. Cria as tabelas `pedidos_vendas` e `pedidos_vendas_itens`.
-- 3. Habilita e aplica as políticas de segurança (RLS).
-- 4. Cria as funções RPC para CRUD seguro e busca de itens.
-- =================================================================

-- 1. CRIAÇÃO DOS TIPOS (ENUMS)
/*
          # [Operation Name]
          Criação dos tipos ENUM `pedidos_vendas_status` e `frete_por_conta`.

          ## Query Description: [Cria novos tipos de dados (ENUMs) que serão usados nas tabelas de pedidos de venda para garantir a consistência dos valores de status e tipo de frete. Operação segura e estrutural.]
          
          ## Metadata:
          - Schema-Category: ["Structural"]
          - Impact-Level: ["Low"]
          - Requires-Backup: [false]
          - Reversible: [true]
          
          ## Structure Details:
          - Tipos criados: `public.pedidos_vendas_status`, `public.frete_por_conta`
          
          ## Security Implications:
          - RLS Status: [N/A]
          - Policy Changes: [No]
          - Auth Requirements: [N/A]
          
          ## Performance Impact:
          - Indexes: [N/A]
          - Triggers: [N/A]
          - Estimated Impact: [Nenhum impacto de performance.]
          */
CREATE TYPE public.pedidos_vendas_status AS ENUM ('Aberto', 'Atendido', 'Cancelado', 'Faturado');
CREATE TYPE public.frete_por_conta AS ENUM ('CIF', 'FOB');

-- 2. CRIAÇÃO DAS TABELAS
/*
          # [Operation Name]
          Criação das tabelas `pedidos_vendas` e `pedidos_vendas_itens`.

          ## Query Description: [Cria as tabelas principais para armazenar os pedidos de venda e seus respectivos itens. Define colunas, chaves primárias, chaves estrangeiras e constraints. Operação estrutural segura se as tabelas não existirem.]
          
          ## Metadata:
          - Schema-Category: ["Structural"]
          - Impact-Level: ["Medium"]
          - Requires-Backup: [false]
          - Reversible: [true]
          
          ## Structure Details:
          - Tabelas criadas: `public.pedidos_vendas`, `public.pedidos_vendas_itens`
          
          ## Security Implications:
          - RLS Status: [Enabled]
          - Policy Changes: [Yes]
          - Auth Requirements: [JWT]
          
          ## Performance Impact:
          - Indexes: [Added]
          - Triggers: [N/A]
          - Estimated Impact: [Criação de índices pode consumir recursos momentaneamente. Consultas futuras serão mais rápidas.]
          */
CREATE TABLE public.pedidos_vendas (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    created_by uuid REFERENCES auth.users(id),
    numero serial NOT NULL,
    cliente_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id),
    vendedor_id uuid REFERENCES public.vendedores(id),
    natureza_operacao text NOT NULL,
    status public.pedidos_vendas_status DEFAULT 'Aberto'::public.pedidos_vendas_status NOT NULL,
    data_venda timestamp with time zone DEFAULT now() NOT NULL,
    data_prevista_entrega timestamp with time zone,
    valor_total numeric(15,2) DEFAULT 0 NOT NULL,
    desconto numeric(15,2) DEFAULT 0,
    frete_por_conta public.frete_por_conta,
    valor_frete numeric(15,2) DEFAULT 0,
    transportadora_id uuid REFERENCES public.clientes_fornecedores(id),
    observacoes text,
    observacoes_internas text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    UNIQUE (empresa_id, numero)
);

CREATE TABLE public.pedidos_vendas_itens (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    pedido_venda_id uuid NOT NULL REFERENCES public.pedidos_vendas(id) ON DELETE CASCADE,
    produto_id uuid REFERENCES public.produtos(id),
    servico_id uuid REFERENCES public.servicos(id),
    descricao text NOT NULL,
    quantidade numeric(15,4) NOT NULL,
    valor_unitario numeric(15,4) NOT NULL,
    valor_total numeric(15,2) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_produto_ou_servico CHECK (((produto_id IS NOT NULL) AND (servico_id IS NULL)) OR ((produto_id IS NULL) AND (servico_id IS NOT NULL)) OR ((produto_id IS NULL) AND (servico_id IS NULL)))
);

-- 3. POLÍTICAS DE SEGURANÇA (RLS)
ALTER TABLE public.pedidos_vendas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos_vendas_itens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Permite acesso total para membros da empresa"
ON public.pedidos_vendas
FOR ALL
USING (public.is_member_of_empresa(empresa_id));

CREATE POLICY "Permite acesso total para membros da empresa"
ON public.pedidos_vendas_itens
FOR ALL
USING (
  (
    SELECT public.is_member_of_empresa(pv.empresa_id)
    FROM public.pedidos_vendas pv
    WHERE pv.id = pedido_venda_id
  )
);

-- 4. FUNÇÕES RPC
/*
          # [Operation Name]
          Criação das funções RPC para Pedidos de Venda.

          ## Query Description: [Cria ou substitui as funções `create_pedido_venda_completo`, `update_pedido_venda_completo`, `delete_pedido_venda` e `search_produtos_e_servicos`. Essas funções encapsulam a lógica de negócio para manipulação de pedidos de venda, garantindo a integridade dos dados e a aplicação de regras de segurança. Operação segura que não afeta dados existentes.]
          
          ## Metadata:
          - Schema-Category: ["Structural"]
          - Impact-Level: ["Low"]
          - Requires-Backup: [false]
          - Reversible: [true]
          
          ## Structure Details:
          - Funções criadas/substituídas: `create_pedido_venda_completo`, `update_pedido_venda_completo`, `delete_pedido_venda`, `search_produtos_e_servicos`
          
          ## Security Implications:
          - RLS Status: [Enabled]
          - Policy Changes: [No]
          - Auth Requirements: [JWT]
          
          ## Performance Impact:
          - Indexes: [N/A]
          - Triggers: [N/A]
          - Estimated Impact: [Nenhum impacto de performance.]
          */
CREATE OR REPLACE FUNCTION public.create_pedido_venda_completo(
    p_empresa_id uuid,
    p_pedido_data jsonb,
    p_itens jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_pedido_id uuid;
BEGIN
    INSERT INTO public.pedidos_vendas (
        empresa_id, created_by, cliente_id, vendedor_id, natureza_operacao, status,
        data_venda, data_prevista_entrega, valor_total, desconto, frete_por_conta,
        valor_frete, transportadora_id, observacoes, observacoes_internas
    )
    VALUES (
        p_empresa_id,
        auth.uid(),
        (p_pedido_data->>'cliente_id')::uuid,
        (p_pedido_data->>'vendedor_id')::uuid,
        p_pedido_data->>'natureza_operacao',
        (p_pedido_data->>'status')::pedidos_vendas_status,
        (p_pedido_data->>'data_venda')::timestamptz,
        (p_pedido_data->>'data_prevista_entrega')::timestamptz,
        (p_pedido_data->>'valor_total')::numeric,
        (p_pedido_data->>'desconto')::numeric,
        (p_pedido_data->>'frete_por_conta')::frete_por_conta,
        (p_pedido_data->>'valor_frete')::numeric,
        (p_pedido_data->>'transportadora_id')::uuid,
        p_pedido_data->>'observacoes',
        p_pedido_data->>'observacoes_internas'
    )
    RETURNING id INTO v_pedido_id;

    IF p_itens IS NOT NULL AND jsonb_array_length(p_itens) > 0 THEN
        INSERT INTO public.pedidos_vendas_itens (
            pedido_venda_id, produto_id, servico_id, descricao, quantidade, valor_unitario, valor_total
        )
        SELECT
            v_pedido_id,
            (item->>'produto_id')::uuid,
            (item->>'servico_id')::uuid,
            item->>'descricao',
            (item->>'quantidade')::numeric,
            (item->>'valor_unitario')::numeric,
            (item->>'valor_total')::numeric
        FROM jsonb_array_elements(p_itens) AS item;
    END IF;

    RETURN v_pedido_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_pedido_venda_completo(
    p_pedido_id uuid,
    p_pedido_data jsonb,
    p_itens jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_empresa_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.pedidos_vendas WHERE id = p_pedido_id;
    IF NOT public.is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada para atualizar este pedido.';
    END IF;

    UPDATE public.pedidos_vendas
    SET
        cliente_id = (p_pedido_data->>'cliente_id')::uuid,
        vendedor_id = (p_pedido_data->>'vendedor_id')::uuid,
        natureza_operacao = p_pedido_data->>'natureza_operacao',
        status = (p_pedido_data->>'status')::pedidos_vendas_status,
        data_venda = (p_pedido_data->>'data_venda')::timestamptz,
        data_prevista_entrega = (p_pedido_data->>'data_prevista_entrega')::timestamptz,
        valor_total = (p_pedido_data->>'valor_total')::numeric,
        desconto = (p_pedido_data->>'desconto')::numeric,
        frete_por_conta = (p_pedido_data->>'frete_por_conta')::frete_por_conta,
        valor_frete = (p_pedido_data->>'valor_frete')::numeric,
        transportadora_id = (p_pedido_data->>'transportadora_id')::uuid,
        observacoes = p_pedido_data->>'observacoes',
        observacoes_internas = p_pedido_data->>'observacoes_internas',
        updated_at = now()
    WHERE id = p_pedido_id;

    DELETE FROM public.pedidos_vendas_itens WHERE pedido_venda_id = p_pedido_id;

    IF p_itens IS NOT NULL AND jsonb_array_length(p_itens) > 0 THEN
        INSERT INTO public.pedidos_vendas_itens (
            pedido_venda_id, produto_id, servico_id, descricao, quantidade, valor_unitario, valor_total
        )
        SELECT
            p_pedido_id,
            (item->>'produto_id')::uuid,
            (item->>'servico_id')::uuid,
            item->>'descricao',
            (item->>'quantidade')::numeric,
            (item->>'valor_unitario')::numeric,
            (item->>'valor_total')::numeric
        FROM jsonb_array_elements(p_itens) AS item;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_pedido_venda(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_empresa_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.pedidos_vendas WHERE id = p_id;
    IF NOT public.is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada para deletar este pedido.';
    END IF;
    DELETE FROM public.pedidos_vendas WHERE id = p_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.search_produtos_e_servicos(p_empresa_id uuid, p_query text)
RETURNS TABLE(id uuid, nome text, preco_venda numeric, tipo text)
LANGUAGE sql STABLE
AS $$
  SELECT id, nome, preco_venda, 'produto' as tipo
  FROM public.produtos
  WHERE empresa_id = p_empresa_id AND situacao = 'Ativo' AND nome ILIKE '%' || p_query || '%'
  UNION ALL
  SELECT id, descricao as nome, preco as preco_venda, 'servico' as tipo
  FROM public.servicos
  WHERE empresa_id = p_empresa_id AND situacao = 'Ativo' AND descricao ILIKE '%' || p_query || '%'
  LIMIT 10;
$$;
