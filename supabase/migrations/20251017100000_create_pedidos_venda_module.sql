-- Habilita a extensão pgcrypto se ainda não estiver habilitada
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";

-- =============================================
-- 1. TIPOS ENUMERADOS
-- =============================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'status_pedido_venda') THEN
        CREATE TYPE public.status_pedido_venda AS ENUM (
            'Aberto',
            'Atendido',
            'Cancelado',
            'Faturado'
        );
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'frete_por_conta') THEN
        CREATE TYPE public.frete_por_conta AS ENUM (
            'CIF', -- Custo, Seguro e Frete (Remetente paga)
            'FOB'  -- Livre a Bordo (Destinatário paga)
        );
    END IF;
END$$;

-- =============================================
-- 2. TABELAS
-- =============================================
/*
          # CRIAÇÃO: Tabela de Pedidos de Venda
          Cria a tabela principal para armazenar os pedidos de venda.

          ## Query Description: Esta operação cria uma nova tabela `pedidos_vendas` e não afeta dados existentes. É uma adição estrutural segura.
          
          ## Metadata:
          - Schema-Category: ["Structural"]
          - Impact-Level: ["Low"]
          - Requires-Backup: [false]
          - Reversible: [true]
*/
CREATE TABLE IF NOT EXISTS public.pedidos_vendas (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    created_by uuid REFERENCES auth.users(id),
    numero SERIAL,
    cliente_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id),
    vendedor_id uuid REFERENCES public.vendedores(id),
    natureza_operacao TEXT NOT NULL,
    status public.status_pedido_venda NOT NULL DEFAULT 'Aberto',
    data_venda TIMESTAMPTZ NOT NULL DEFAULT now(),
    data_prevista_entrega DATE,
    valor_total NUMERIC(15, 2) NOT NULL DEFAULT 0,
    desconto NUMERIC(15, 2) DEFAULT 0,
    frete_por_conta public.frete_por_conta,
    valor_frete NUMERIC(15, 2) DEFAULT 0,
    transportadora_id uuid REFERENCES public.clientes_fornecedores(id),
    observacoes TEXT,
    observacoes_internas TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

/*
          # CRIAÇÃO: Tabela de Itens do Pedido de Venda
          Cria a tabela para armazenar os itens de cada pedido de venda.

          ## Query Description: Esta operação cria uma nova tabela `pedidos_vendas_itens` e não afeta dados existentes. É uma adição estrutural segura.
          
          ## Metadata:
          - Schema-Category: ["Structural"]
          - Impact-Level: ["Low"]
          - Requires-Backup: [false]
          - Reversible: [true]
*/
CREATE TABLE IF NOT EXISTS public.pedidos_vendas_itens (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    pedido_venda_id uuid NOT NULL REFERENCES public.pedidos_vendas(id) ON DELETE CASCADE,
    produto_id uuid REFERENCES public.produtos(id),
    servico_id uuid REFERENCES public.servicos(id),
    descricao TEXT NOT NULL,
    quantidade NUMERIC(15, 4) NOT NULL,
    valor_unitario NUMERIC(15, 4) NOT NULL,
    valor_total NUMERIC(15, 2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_produto_ou_servico CHECK (produto_id IS NOT NULL OR servico_id IS NOT NULL)
);

-- =============================================
-- 3. POLÍTICAS DE SEGURANÇA (RLS)
-- =============================================
ALTER TABLE public.pedidos_vendas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos_vendas_itens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow full access to own company data" ON public.pedidos_vendas;
CREATE POLICY "Allow full access to own company data"
ON public.pedidos_vendas
FOR ALL
USING (empresa_id = (SELECT private.get_empresa_id_for_user(auth.uid())));

DROP POLICY IF EXISTS "Allow full access to own company data" ON public.pedidos_vendas_itens;
CREATE POLICY "Allow full access to own company data"
ON public.pedidos_vendas_itens
FOR ALL
USING (
    (SELECT empresa_id FROM public.pedidos_vendas WHERE id = pedido_venda_id) = (SELECT private.get_empresa_id_for_user(auth.uid()))
);

-- =============================================
-- 4. FUNÇÕES RPC
-- =============================================

/*
          # CRIAÇÃO: Função para buscar produtos e serviços
          Cria uma função para buscar produtos e serviços em uma única consulta para o autocompletar.

          ## Query Description: Esta operação cria uma nova função `search_produtos_e_servicos`. É uma adição segura.
          
          ## Metadata:
          - Schema-Category: ["Structural"]
          - Impact-Level: ["Low"]
          - Requires-Backup: [false]
          - Reversible: [true]
*/
CREATE OR REPLACE FUNCTION public.search_produtos_e_servicos(p_empresa_id uuid, p_query text)
RETURNS TABLE(id uuid, nome text, preco_venda numeric, codigo text, unidade text, tipo text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.nome,
        p.preco_venda,
        p.codigo,
        p.unidade,
        'produto'::text AS tipo
    FROM public.produtos p
    WHERE p.empresa_id = p_empresa_id
      AND p.situacao = 'Ativo'
      AND (p.nome ILIKE '%' || p_query || '%' OR p.codigo ILIKE '%' || p_query || '%')
    LIMIT 10;

    RETURN QUERY
    SELECT
        s.id,
        s.descricao AS nome,
        s.preco AS preco_venda,
        s.codigo,
        s.unidade,
        'servico'::text AS tipo
    FROM public.servicos s
    WHERE s.empresa_id = p_empresa_id
      AND s.situacao = 'Ativo'
      AND (s.descricao ILIKE '%' || p_query || '%' OR s.codigo ILIKE '%' || p_query || '%')
    LIMIT 10;
END;
$$;

/*
          # CRIAÇÃO: Função para criar pedido de venda completo
          Cria um pedido de venda e seus itens de forma transacional.

          ## Query Description: Esta operação cria uma nova função `create_pedido_venda_completo`. É uma adição segura.
          
          ## Metadata:
          - Schema-Category: ["Structural"]
          - Impact-Level: ["Low"]
          - Requires-Backup: [false]
          - Reversible: [true]
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
    v_item jsonb;
BEGIN
    -- Inserir o pedido principal
    INSERT INTO public.pedidos_vendas (
        empresa_id, cliente_id, vendedor_id, natureza_operacao, status, data_venda, data_prevista_entrega, valor_total, desconto, frete_por_conta, valor_frete, transportadora_id, observacoes, observacoes_internas, created_by
    )
    VALUES (
        p_empresa_id,
        (p_pedido_data->>'clienteId')::uuid,
        (p_pedido_data->>'vendedorId')::uuid,
        p_pedido_data->>'naturezaOperacao',
        (p_pedido_data->>'status')::status_pedido_venda,
        (p_pedido_data->>'dataVenda')::timestamptz,
        (p_pedido_data->>'dataPrevistaEntrega')::date,
        (p_pedido_data->>'valorTotal')::numeric,
        (p_pedido_data->>'desconto')::numeric,
        (p_pedido_data->>'fretePorConta')::frete_por_conta,
        (p_pedido_data->>'valorFrete')::numeric,
        (p_pedido_data->>'transportadoraId')::uuid,
        p_pedido_data->>'observacoes',
        p_pedido_data->>'observacoesInternas',
        auth.uid()
    ) RETURNING id INTO v_pedido_id;

    -- Inserir os itens
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_itens)
    LOOP
        INSERT INTO public.pedidos_vendas_itens (
            pedido_venda_id, produto_id, servico_id, descricao, quantidade, valor_unitario, valor_total
        )
        VALUES (
            v_pedido_id,
            (v_item->>'produtoId')::uuid,
            (v_item->>'servicoId')::uuid,
            v_item->>'descricao',
            (v_item->>'quantidade')::numeric,
            (v_item->>'valorUnitario')::numeric,
            (v_item->>'valorTotal')::numeric
        );
    END LOOP;

    RETURN v_pedido_id;
END;
$$;

/*
          # CRIAÇÃO: Função para atualizar pedido de venda completo
          Atualiza um pedido de venda e seus itens de forma transacional.

          ## Query Description: Esta operação cria uma nova função `update_pedido_venda_completo`. É uma adição segura.
          
          ## Metadata:
          - Schema-Category: ["Structural"]
          - Impact-Level: ["Low"]
          - Requires-Backup: [false]
          - Reversible: [true]
*/
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
    v_item jsonb;
    v_item_ids_in_payload uuid[];
BEGIN
    -- Atualizar o pedido principal
    UPDATE public.pedidos_vendas
    SET
        cliente_id = (p_pedido_data->>'clienteId')::uuid,
        vendedor_id = (p_pedido_data->>'vendedorId')::uuid,
        natureza_operacao = p_pedido_data->>'naturezaOperacao',
        status = (p_pedido_data->>'status')::status_pedido_venda,
        data_venda = (p_pedido_data->>'dataVenda')::timestamptz,
        data_prevista_entrega = (p_pedido_data->>'dataPrevistaEntrega')::date,
        valor_total = (p_pedido_data->>'valorTotal')::numeric,
        desconto = (p_pedido_data->>'desconto')::numeric,
        frete_por_conta = (p_pedido_data->>'fretePorConta')::frete_por_conta,
        valor_frete = (p_pedido_data->>'valorFrete')::numeric,
        transportadora_id = (p_pedido_data->>'transportadoraId')::uuid,
        observacoes = p_pedido_data->>'observacoes',
        observacoes_internas = p_pedido_data->>'observacoesInternas',
        updated_at = now()
    WHERE id = p_pedido_id;

    -- Coletar IDs dos itens no payload
    SELECT array_agg((item->>'id')::uuid)
    INTO v_item_ids_in_payload
    FROM jsonb_array_elements(p_itens) AS item
    WHERE item->>'id' IS NOT NULL;

    -- Deletar itens que não estão mais no payload
    DELETE FROM public.pedidos_vendas_itens
    WHERE pedido_venda_id = p_pedido_id
      AND id NOT IN (SELECT unnest(v_item_ids_in_payload));

    -- Atualizar ou inserir itens
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_itens)
    LOOP
        IF v_item->>'id' IS NOT NULL THEN
            -- Atualizar item existente
            UPDATE public.pedidos_vendas_itens
            SET
                produto_id = (v_item->>'produtoId')::uuid,
                servico_id = (v_item->>'servicoId')::uuid,
                descricao = v_item->>'descricao',
                quantidade = (v_item->>'quantidade')::numeric,
                valor_unitario = (v_item->>'valorUnitario')::numeric,
                valor_total = (v_item->>'valorTotal')::numeric,
                updated_at = now()
            WHERE id = (v_item->>'id')::uuid;
        ELSE
            -- Inserir novo item
            INSERT INTO public.pedidos_vendas_itens (
                pedido_venda_id, produto_id, servico_id, descricao, quantidade, valor_unitario, valor_total
            )
            VALUES (
                p_pedido_id,
                (v_item->>'produtoId')::uuid,
                (v_item->>'servicoId')::uuid,
                v_item->>'descricao',
                (v_item->>'quantidade')::numeric,
                (v_item->>'valorUnitario')::numeric,
                (v_item->>'valorTotal')::numeric
            );
        END IF;
    END LOOP;
END;
$$;

/*
          # CRIAÇÃO: Função para deletar pedido de venda
          Deleta um pedido de venda. A deleção dos itens é feita em cascata.

          ## Query Description: Esta operação cria uma nova função `delete_pedido_venda`. É uma adição segura.
          
          ## Metadata:
          - Schema-Category: ["Structural"]
          - Impact-Level: ["Low"]
          - Requires-Backup: [false]
          - Reversible: [true]
*/
CREATE OR REPLACE FUNCTION public.delete_pedido_venda(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    DELETE FROM public.pedidos_vendas WHERE id = p_id;
END;
$$;
