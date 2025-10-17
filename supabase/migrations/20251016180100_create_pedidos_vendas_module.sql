-- Estrutura completa para o módulo de Pedidos de Venda

/*
          # [Operation Name]
          Criação do Módulo de Pedidos de Venda

          ## Query Description: [Este script estabelece toda a infraestrutura de banco de dados para o módulo de Pedidos de Venda. Ele cria as tabelas `pedidos_vendas` e `pedidos_vendas_itens`, define tipos de dados personalizados (ENUMs) para status e frete, e implementa políticas de segurança de linha (RLS) para garantir que os usuários só possam acessar os pedidos de suas respectivas empresas. Além disso, cria funções RPC (`create_pedido_venda_completo`, `update_pedido_venda_completo`, `delete_pedido_venda`, `search_produtos_e_servicos`) para encapsular a lógica de negócio de forma segura e transacional, facilitando a interação do frontend com o banco de dados.]
          
          ## Metadata:
          - Schema-Category: ["Structural"]
          - Impact-Level: ["Medium"]
          - Requires-Backup: [true]
          - Reversible: [false]
          
          ## Structure Details:
          - Cria a tabela `public.pedidos_vendas`.
          - Cria a tabela `public.pedidos_vendas_itens`.
          - Cria os tipos ENUM `public.status_pedido_venda` e `public.frete_por_conta`.
          - Adiciona chaves primárias, estrangeiras e índices.
          - Habilita RLS e cria políticas de segurança.
          - Cria as funções RPC para CRUD e busca.
          
          ## Security Implications:
          - RLS Status: [Enabled]
          - Policy Changes: [Sim, políticas de `SELECT`, `INSERT`, `UPDATE`, `DELETE` são criadas para as novas tabelas.]
          - Auth Requirements: [Todas as operações são validadas contra o `auth.uid()` e a associação do usuário à empresa.]
          
          ## Performance Impact:
          - Indexes: [Adicionados em chaves estrangeiras para otimizar joins.]
          - Triggers: [Nenhum]
          - Estimated Impact: [Baixo. A criação das tabelas e funções não deve impactar a performance existente. As novas consultas serão eficientes devido aos índices.]
          */

-- 1. Tipos ENUM
CREATE TYPE public.status_pedido_venda AS ENUM ('Aberto', 'Atendido', 'Cancelado', 'Faturado');
CREATE TYPE public.frete_por_conta AS ENUM ('CIF', 'FOB');

-- 2. Tabela Principal: pedidos_vendas
CREATE TABLE public.pedidos_vendas (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    created_by uuid REFERENCES auth.users(id),
    numero serial NOT NULL,
    cliente_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id),
    vendedor_id uuid REFERENCES public.vendedores(id),
    natureza_operacao text NOT NULL,
    status public.status_pedido_venda NOT NULL DEFAULT 'Aberto',
    data_venda timestamp with time zone NOT NULL DEFAULT now(),
    data_prevista_entrega timestamp with time zone,
    valor_total numeric(15, 2) NOT NULL DEFAULT 0,
    desconto numeric(15, 2) DEFAULT 0,
    frete_por_conta public.frete_por_conta,
    valor_frete numeric(15, 2) DEFAULT 0,
    transportadora_id uuid REFERENCES public.clientes_fornecedores(id),
    observacoes text,
    observacoes_internas text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.pedidos_vendas ENABLE ROW LEVEL SECURITY;
CREATE UNIQUE INDEX idx_pedidos_vendas_empresa_numero ON public.pedidos_vendas(empresa_id, numero);

-- 3. Tabela de Itens: pedidos_vendas_itens
CREATE TABLE public.pedidos_vendas_itens (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    pedido_venda_id uuid NOT NULL REFERENCES public.pedidos_vendas(id) ON DELETE CASCADE,
    produto_id uuid REFERENCES public.produtos(id),
    servico_id uuid REFERENCES public.servicos(id),
    descricao text NOT NULL,
    quantidade numeric(15, 4) NOT NULL,
    valor_unitario numeric(15, 4) NOT NULL,
    valor_total numeric(15, 2) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_produto_ou_servico CHECK (produto_id IS NOT NULL OR servico_id IS NOT NULL)
);
ALTER TABLE public.pedidos_vendas_itens ENABLE ROW LEVEL SECURITY;

-- 4. Políticas de Segurança (RLS)
CREATE POLICY "Allow members to manage their own company's sales orders"
ON public.pedidos_vendas
FOR ALL
USING (private.is_member_of_empresa(empresa_id))
WITH CHECK (private.is_member_of_empresa(empresa_id));

CREATE POLICY "Allow members to manage items of their own company's sales orders"
ON public.pedidos_vendas_itens
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM public.pedidos_vendas pv
    WHERE pv.id = pedidos_vendas_itens.pedido_venda_id
      AND private.is_member_of_empresa(pv.empresa_id)
  )
);

-- 5. Funções RPC

-- Função de Busca (Produtos e Serviços)
CREATE OR REPLACE FUNCTION public.search_produtos_e_servicos(p_empresa_id uuid, p_query text)
RETURNS TABLE(id uuid, nome text, preco_venda numeric, tipo text) AS $$
BEGIN
  RETURN QUERY
    SELECT p.id, p.nome, p.preco_venda, 'produto' as tipo
    FROM public.produtos p
    WHERE p.empresa_id = p_empresa_id AND p.situacao = 'Ativo' AND p.nome ILIKE '%' || p_query || '%'
    UNION ALL
    SELECT s.id, s.descricao as nome, s.preco as preco_venda, 'servico' as tipo
    FROM public.servicos s
    WHERE s.empresa_id = p_empresa_id AND s.situacao = 'Ativo' AND s.descricao ILIKE '%' || p_query || '%';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.search_produtos_e_servicos(uuid, text) SET search_path = public, private;


-- Função para Criar Pedido Completo
CREATE OR REPLACE FUNCTION public.create_pedido_venda_completo(p_empresa_id uuid, p_pedido_data jsonb, p_itens jsonb)
RETURNS uuid AS $$
DECLARE
  v_pedido_id uuid;
  v_item jsonb;
BEGIN
  IF NOT private.is_member_of_empresa(p_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não autorizado para esta empresa';
  END IF;

  INSERT INTO public.pedidos_vendas (empresa_id, created_by, cliente_id, vendedor_id, natureza_operacao, status, data_venda, data_prevista_entrega, valor_total, desconto, valor_frete, transportadora_id, observacoes, observacoes_internas)
  VALUES (
    p_empresa_id,
    auth.uid(),
    (p_pedido_data->>'cliente_id')::uuid,
    (p_pedido_data->>'vendedor_id')::uuid,
    p_pedido_data->>'natureza_operacao',
    (p_pedido_data->>'status')::public.status_pedido_venda,
    (p_pedido_data->>'data_venda')::timestamptz,
    (p_pedido_data->>'data_prevista_entrega')::timestamptz,
    (p_pedido_data->>'valor_total')::numeric,
    (p_pedido_data->>'desconto')::numeric,
    (p_pedido_data->>'valor_frete')::numeric,
    (p_pedido_data->>'transportadora_id')::uuid,
    p_pedido_data->>'observacoes',
    p_pedido_data->>'observacoes_internas'
  ) RETURNING id INTO v_pedido_id;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_itens)
  LOOP
    INSERT INTO public.pedidos_vendas_itens (pedido_venda_id, produto_id, servico_id, descricao, quantidade, valor_unitario, valor_total)
    VALUES (
      v_pedido_id,
      (v_item->>'produto_id')::uuid,
      (v_item->>'servico_id')::uuid,
      v_item->>'descricao',
      (v_item->>'quantidade')::numeric,
      (v_item->>'valor_unitario')::numeric,
      (v_item->>'valor_total')::numeric
    );
  END LOOP;

  RETURN v_pedido_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.create_pedido_venda_completo(uuid, jsonb, jsonb) SET search_path = public, private;


-- Função para Atualizar Pedido Completo
CREATE OR REPLACE FUNCTION public.update_pedido_venda_completo(p_pedido_id uuid, p_pedido_data jsonb, p_itens jsonb)
RETURNS void AS $$
DECLARE
  v_item jsonb;
  v_empresa_id uuid;
BEGIN
  SELECT empresa_id INTO v_empresa_id FROM public.pedidos_vendas WHERE id = p_pedido_id;
  IF NOT private.is_member_of_empresa(v_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não autorizado para esta empresa';
  END IF;

  UPDATE public.pedidos_vendas
  SET
    cliente_id = (p_pedido_data->>'cliente_id')::uuid,
    vendedor_id = (p_pedido_data->>'vendedor_id')::uuid,
    natureza_operacao = p_pedido_data->>'natureza_operacao',
    status = (p_pedido_data->>'status')::public.status_pedido_venda,
    data_venda = (p_pedido_data->>'data_venda')::timestamptz,
    data_prevista_entrega = (p_pedido_data->>'data_prevista_entrega')::timestamptz,
    valor_total = (p_pedido_data->>'valor_total')::numeric,
    desconto = (p_pedido_data->>'desconto')::numeric,
    valor_frete = (p_pedido_data->>'valor_frete')::numeric,
    transportadora_id = (p_pedido_data->>'transportadora_id')::uuid,
    observacoes = p_pedido_data->>'observacoes',
    observacoes_internas = p_pedido_data->>'observacoes_internas',
    updated_at = now()
  WHERE id = p_pedido_id;

  DELETE FROM public.pedidos_vendas_itens WHERE pedido_venda_id = p_pedido_id;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_itens)
  LOOP
    INSERT INTO public.pedidos_vendas_itens (pedido_venda_id, produto_id, servico_id, descricao, quantidade, valor_unitario, valor_total)
    VALUES (
      p_pedido_id,
      (v_item->>'produto_id')::uuid,
      (v_item->>'servico_id')::uuid,
      v_item->>'descricao',
      (v_item->>'quantidade')::numeric,
      (v_item->>'valor_unitario')::numeric,
      (v_item->>'valor_total')::numeric
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.update_pedido_venda_completo(uuid, jsonb, jsonb) SET search_path = public, private;


-- Função para Deletar Pedido
CREATE OR REPLACE FUNCTION public.delete_pedido_venda(p_id uuid)
RETURNS void AS $$
DECLARE
  v_empresa_id uuid;
BEGIN
  SELECT empresa_id INTO v_empresa_id FROM public.pedidos_vendas WHERE id = p_id;
  IF NOT private.is_member_of_empresa(v_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não autorizado para esta empresa';
  END IF;
  
  DELETE FROM public.pedidos_vendas WHERE id = p_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.delete_pedido_venda(uuid) SET search_path = public, private;
