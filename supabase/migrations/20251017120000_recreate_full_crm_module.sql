-- Desativa o aviso para o bloco de transação, pois é seguro aqui.
SET client_min_messages TO WARNING;

DO $$
BEGIN
    -- Remove em cascata para evitar erros de dependência com políticas e funções.
    DROP TABLE IF EXISTS public.crm_oportunidades CASCADE;
    DROP TABLE IF EXISTS public.crm_oportunidade_itens CASCADE;
    DROP TYPE IF EXISTS public.crm_etapa_funil CASCADE;
    DROP TYPE IF EXISTS public.crm_status_oportunidade CASCADE;
EXCEPTION
    WHEN undefined_table THEN
        -- Ignora o erro se as tabelas/tipos não existirem
        RAISE NOTICE 'Tabelas ou tipos do CRM não encontrados, continuando com a criação.';
END $$;

-- Reativa todas as mensagens do cliente.
SET client_min_messages TO NOTICE;

-- 1. Tipos de Enumeração
CREATE TYPE public.crm_etapa_funil AS ENUM (
    'Prospecção',
    'Qualificação',
    'Proposta',
    'Negociação',
    'Fechamento'
);

CREATE TYPE public.crm_status_oportunidade AS ENUM (
    'Em Aberto',
    'Ganha',
    'Perdida',
    'Cancelada'
);

-- 2. Tabela Principal de Oportunidades
CREATE TABLE public.crm_oportunidades (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    created_by uuid REFERENCES auth.users(id),
    titulo text NOT NULL,
    valor numeric(15, 2) NOT NULL DEFAULT 0,
    etapa_funil crm_etapa_funil NOT NULL,
    status crm_status_oportunidade NOT NULL,
    data_fechamento_prevista date,
    data_fechamento_real date,
    cliente_id uuid REFERENCES public.clientes_fornecedores(id) ON DELETE SET NULL,
    vendedor_id uuid REFERENCES public.vendedores(id) ON DELETE SET NULL,
    observacoes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.crm_oportunidades ENABLE ROW LEVEL SECURITY;

-- 3. Tabela de Itens da Oportunidade
CREATE TABLE public.crm_oportunidade_itens (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    oportunidade_id uuid NOT NULL REFERENCES public.crm_oportunidades(id) ON DELETE CASCADE,
    produto_id uuid REFERENCES public.produtos(id) ON DELETE SET NULL,
    servico_id uuid REFERENCES public.servicos(id) ON DELETE SET NULL,
    descricao text NOT NULL,
    quantidade numeric(15, 4) NOT NULL,
    valor_unitario numeric(15, 4) NOT NULL,
    valor_total numeric(15, 2) GENERATED ALWAYS AS (quantidade * valor_unitario) STORED,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.crm_oportunidade_itens ENABLE ROW LEVEL SECURITY;

-- 4. Políticas de Segurança (RLS)
CREATE POLICY "CRM Oportunidades members can do all actions"
ON public.crm_oportunidades
FOR ALL
USING (private.is_member_of_empresa(empresa_id))
WITH CHECK (private.is_member_of_empresa(empresa_id));

CREATE POLICY "CRM Oportunidade Itens members can do all actions"
ON public.crm_oportunidade_itens
FOR ALL
USING (
  (
    SELECT private.is_member_of_empresa(op.empresa_id)
    FROM public.crm_oportunidades op
    WHERE op.id = oportunidade_id
  )
);

-- 5. Funções RPC para CRUD seguro
CREATE OR REPLACE FUNCTION public.create_crm_oportunidade(
    p_empresa_id uuid,
    p_oportunidade_data jsonb,
    p_itens jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, private
AS $$
DECLARE
    v_oportunidade_id uuid;
    v_item jsonb;
BEGIN
    -- Insere a oportunidade
    INSERT INTO public.crm_oportunidades (empresa_id, created_by, titulo, valor, etapa_funil, status, data_fechamento_prevista, cliente_id, vendedor_id, observacoes)
    VALUES (
        p_empresa_id,
        auth.uid(),
        p_oportunidade_data->>'titulo',
        (p_oportunidade_data->>'valor')::numeric,
        (p_oportunidade_data->>'etapaFunil')::crm_etapa_funil,
        (p_oportunidade_data->>'status')::crm_status_oportunidade,
        (p_oportunidade_data->>'dataFechamentoPrevista')::date,
        (p_oportunidade_data->>'clienteId')::uuid,
        (p_oportunidade_data->>'vendedorId')::uuid,
        p_oportunidade_data->>'observacoes'
    ) RETURNING id INTO v_oportunidade_id;

    -- Insere os itens
    IF p_itens IS NOT NULL AND jsonb_array_length(p_itens) > 0 THEN
        FOR v_item IN SELECT * FROM jsonb_array_elements(p_itens)
        LOOP
            INSERT INTO public.crm_oportunidade_itens (oportunidade_id, produto_id, servico_id, descricao, quantidade, valor_unitario)
            VALUES (
                v_oportunidade_id,
                (v_item->>'produtoId')::uuid,
                (v_item->>'servicoId')::uuid,
                v_item->>'descricao',
                (v_item->>'quantidade')::numeric,
                (v_item->>'valorUnitario')::numeric
            );
        END LOOP;
    END IF;

    RETURN v_oportunidade_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_crm_oportunidade(
    p_oportunidade_id uuid,
    p_oportunidade_data jsonb,
    p_itens jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, private
AS $$
DECLARE
    v_empresa_id uuid;
    v_item jsonb;
    v_item_id uuid;
    v_existing_item_ids uuid[];
BEGIN
    -- Verifica permissão
    SELECT empresa_id INTO v_empresa_id FROM public.crm_oportunidades WHERE id = p_oportunidade_id;
    IF NOT private.is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Permission denied';
    END IF;

    -- Atualiza a oportunidade
    UPDATE public.crm_oportunidades
    SET
        titulo = p_oportunidade_data->>'titulo',
        valor = (p_oportunidade_data->>'valor')::numeric,
        etapa_funil = (p_oportunidade_data->>'etapaFunil')::crm_etapa_funil,
        status = (p_oportunidade_data->>'status')::crm_status_oportunidade,
        data_fechamento_prevista = (p_oportunidade_data->>'dataFechamentoPrevista')::date,
        cliente_id = (p_oportunidade_data->>'clienteId')::uuid,
        vendedor_id = (p_oportunidade_data->>'vendedorId')::uuid,
        observacoes = p_oportunidade_data->>'observacoes',
        updated_at = now()
    WHERE id = p_oportunidade_id;

    -- Sincroniza os itens
    v_existing_item_ids := ARRAY(SELECT (jsonb_array_elements(p_itens)->>'id')::uuid);

    DELETE FROM public.crm_oportunidade_itens
    WHERE oportunidade_id = p_oportunidade_id AND id NOT IN (SELECT unnest(v_existing_item_ids));

    IF p_itens IS NOT NULL AND jsonb_array_length(p_itens) > 0 THEN
        FOR v_item IN SELECT * FROM jsonb_array_elements(p_itens)
        LOOP
            v_item_id := (v_item->>'id')::uuid;
            IF v_item_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.crm_oportunidade_itens WHERE id = v_item_id) THEN
                UPDATE public.crm_oportunidade_itens
                SET
                    produto_id = (v_item->>'produtoId')::uuid,
                    servico_id = (v_item->>'servicoId')::uuid,
                    descricao = v_item->>'descricao',
                    quantidade = (v_item->>'quantidade')::numeric,
                    valor_unitario = (v_item->>'valorUnitario')::numeric,
                    updated_at = now()
                WHERE id = v_item_id;
            ELSE
                INSERT INTO public.crm_oportunidade_itens (oportunidade_id, produto_id, servico_id, descricao, quantidade, valor_unitario)
                VALUES (
                    p_oportunidade_id,
                    (v_item->>'produtoId')::uuid,
                    (v_item->>'servicoId')::uuid,
                    v_item->>'descricao',
                    (v_item->>'quantidade')::numeric,
                    (v_item->>'valorUnitario')::numeric
                );
            END IF;
        END LOOP;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_crm_oportunidade(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, private
AS $$
DECLARE
    v_empresa_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.crm_oportunidades WHERE id = p_id;
    IF NOT private.is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Permission denied';
    END IF;
    
    DELETE FROM public.crm_oportunidades WHERE id = p_id;
END;
$$;
