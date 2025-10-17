-- Remove a função principal e todas as políticas de segurança dependentes em cascata.
DROP FUNCTION IF EXISTS public.is_member_of_empresa(uuid) CASCADE;

-- Remove as outras funções que podem ter sido criadas sem o search_path correto.
DROP FUNCTION IF EXISTS public.get_empresa_id_for_user(uuid);
DROP FUNCTION IF EXISTS public.create_cliente_fornecedor_completo(uuid,jsonb,jsonb[]);
DROP FUNCTION IF EXISTS public.update_cliente_fornecedor_completo(uuid,jsonb,jsonb[]);
DROP FUNCTION IF EXISTS public.create_cliente_anexo(uuid,uuid,text,text,text,bigint);
DROP FUNCTION IF EXISTS public.create_produto_completo(uuid,jsonb,jsonb[],jsonb[]);
DROP FUNCTION IF EXISTS public.update_produto_completo(uuid,jsonb,jsonb[],jsonb[]);
DROP FUNCTION IF EXISTS public.delete_produto(uuid);
DROP FUNCTION IF EXISTS public.create_produto_imagem(uuid,text,text,text,bigint);
DROP FUNCTION IF EXISTS public.create_servico(uuid,text,numeric,text,text,text,text,text,text);
DROP FUNCTION IF EXISTS public.update_servico(uuid,text,numeric,text,text,text,text,text,text);
DROP FUNCTION IF EXISTS public.delete_servico(uuid);
DROP FUNCTION IF EXISTS public.create_embalagem(uuid,text,text,numeric,numeric,numeric,numeric,numeric);
DROP FUNCTION IF EXISTS public.update_embalagem(uuid,text,text,numeric,numeric,numeric,numeric,numeric);
DROP FUNCTION IF EXISTS public.delete_embalagem(uuid);
DROP FUNCTION IF EXISTS public.create_vendedor(uuid,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,boolean,text,text[],jsonb,text,text,numeric,boolean,text,jsonb[]);
DROP FUNCTION IF EXISTS public.update_vendedor(uuid,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,text,boolean,text,text[],jsonb,text,text,numeric,boolean,text,jsonb[]);
DROP FUNCTION IF EXISTS public.delete_vendedor(uuid);
DROP FUNCTION IF EXISTS public.check_vendedor_email_exists(uuid,text,uuid);
DROP FUNCTION IF EXISTS public.create_crm_oportunidade(uuid,jsonb,jsonb[]);
DROP FUNCTION IF EXISTS public.update_crm_oportunidade(uuid,jsonb,jsonb[]);
DROP FUNCTION IF EXISTS public.delete_crm_oportunidade(uuid);
DROP FUNCTION IF EXISTS public.create_pedido_venda_completo(uuid,jsonb,jsonb[]);
DROP FUNCTION IF EXISTS public.update_pedido_venda_completo(uuid,jsonb,jsonb[]);
DROP FUNCTION IF EXISTS public.delete_pedido_venda(uuid);
DROP FUNCTION IF EXISTS public.search_produtos_e_servicos(uuid,text);


-- Recria a função `is_member_of_empresa` com o search_path seguro.
CREATE OR REPLACE FUNCTION public.is_member_of_empresa(p_empresa_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
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

-- Recria as outras funções, todas com o search_path seguro.
CREATE OR REPLACE FUNCTION public.get_empresa_id_for_user(p_user_id uuid)
RETURNS uuid
LANGUAGE sql
SECURITY DEFINER
SET search_path = 'public'
AS $$
  SELECT empresa_id FROM public.empresa_usuarios WHERE user_id = p_user_id LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.create_cliente_anexo(p_empresa_id uuid, p_cliente_id uuid, p_storage_path text, p_filename text, p_content_type text, p_tamanho_bytes bigint)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  new_anexo_id uuid;
  result jsonb;
BEGIN
  IF NOT is_member_of_empresa(p_empresa_id) THEN
    RAISE EXCEPTION 'Acesso negado';
  END IF;

  INSERT INTO public.clientes_anexos (empresa_id, cliente_fornecedor_id, storage_path, filename, content_type, tamanho_bytes)
  VALUES (p_empresa_id, p_cliente_id, p_storage_path, p_filename, p_content_type, p_tamanho_bytes)
  RETURNING id INTO new_anexo_id;

  SELECT jsonb_build_object(
    'id', a.id,
    'createdAt', a.created_at,
    'updatedAt', a.updated_at,
    'empresaId', a.empresa_id,
    'clienteFornecedorId', a.cliente_fornecedor_id,
    'storagePath', a.storage_path,
    'filename', a.filename,
    'contentType', a.content_type,
    'tamanhoBytes', a.tamanho_bytes
  ) INTO result
  FROM public.clientes_anexos a
  WHERE a.id = new_anexo_id;

  RETURN result;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_produto_imagem(p_produto_id uuid, p_storage_path text, p_filename text, p_content_type text, p_tamanho_bytes bigint)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  v_empresa_id uuid;
  new_imagem_id uuid;
  result jsonb;
BEGIN
  SELECT empresa_id INTO v_empresa_id FROM public.produtos WHERE id = p_produto_id;
  
  IF v_empresa_id IS NULL OR NOT is_member_of_empresa(v_empresa_id) THEN
    RAISE EXCEPTION 'Acesso negado';
  END IF;

  INSERT INTO public.produto_imagens (produto_id, storage_path, nome_arquivo, content_type, tamanho_bytes)
  VALUES (p_produto_id, p_storage_path, p_filename, p_content_type, p_tamanho_bytes)
  RETURNING id INTO new_imagem_id;

  SELECT jsonb_build_object(
    'id', i.id,
    'createdAt', i.created_at,
    'updatedAt', i.updated_at,
    'produtoId', i.produto_id,
    'storagePath', i.storage_path,
    'nomeArquivo', i.nome_arquivo,
    'contentType', i.content_type,
    'tamanhoBytes', i.tamanho_bytes
  ) INTO result
  FROM public.produto_imagens i
  WHERE i.id = new_imagem_id;

  RETURN result;
END;
$$;

-- Recria todas as políticas de segurança que foram removidas.
ALTER TABLE public.clientes_fornecedores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow access to own company data" ON public.clientes_fornecedores FOR ALL USING (public.is_member_of_empresa(empresa_id));

ALTER TABLE public.clientes_contatos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow access to own company data" ON public.clientes_contatos FOR ALL USING (public.is_member_of_empresa(empresa_id));

ALTER TABLE public.clientes_anexos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow access to own company data" ON public.clientes_anexos FOR ALL USING (public.is_member_of_empresa(empresa_id));

ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow access to own company data" ON public.produtos FOR ALL USING (public.is_member_of_empresa(empresa_id));

ALTER TABLE public.produto_imagens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow access via product" ON public.produto_imagens FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.produtos p
    WHERE p.id = produto_id AND public.is_member_of_empresa(p.empresa_id)
  )
);

ALTER TABLE public.produto_atributos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow access via product" ON public.produto_atributos FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.produtos p
    WHERE p.id = produto_id AND public.is_member_of_empresa(p.empresa_id)
  )
);

ALTER TABLE public.produto_fornecedores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow access via product" ON public.produto_fornecedores FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.produtos p
    WHERE p.id = produto_id AND public.is_member_of_empresa(p.empresa_id)
  )
);

ALTER TABLE public.servicos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow access to own company data" ON public.servicos FOR ALL USING (public.is_member_of_empresa(empresa_id));

ALTER TABLE public.embalagens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow access to own company data" ON public.embalagens FOR ALL USING (public.is_member_of_empresa(empresa_id));

ALTER TABLE public.vendedores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow access to own company data" ON public.vendedores FOR ALL USING (public.is_member_of_empresa(empresa_id));

ALTER TABLE public.vendedores_contatos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow access via vendor" ON public.vendedores_contatos FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.vendedores v
    WHERE v.id = vendedor_id AND public.is_member_of_empresa(v.empresa_id)
  )
);

ALTER TABLE public.crm_oportunidades ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow access to own company data" ON public.crm_oportunidades FOR ALL USING (public.is_member_of_empresa(empresa_id));

ALTER TABLE public.crm_oportunidade_itens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow access via opportunity" ON public.crm_oportunidade_itens FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.crm_oportunidades o
    WHERE o.id = oportunidade_id AND public.is_member_of_empresa(o.empresa_id)
  )
);

ALTER TABLE public.pedidos_vendas ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow access to own company data" ON public.pedidos_vendas FOR ALL USING (public.is_member_of_empresa(empresa_id));

ALTER TABLE public.pedidos_vendas_itens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow access via order" ON public.pedidos_vendas_itens FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.pedidos_vendas pv
    WHERE pv.id = pedido_venda_id AND public.is_member_of_empresa(pv.empresa_id)
  )
);

ALTER TABLE public.papeis ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow access to own company data" ON public.papeis FOR ALL USING (public.is_member_of_empresa(empresa_id));

ALTER TABLE public.papel_permissoes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow access via role" ON public.papel_permissoes FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.papeis p
    WHERE p.id = papel_id AND public.is_member_of_empresa(p.empresa_id)
  )
);

ALTER TABLE public.categorias_financeiras ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow access to own company data" ON public.categorias_financeiras FOR ALL USING (public.is_member_of_empresa(empresa_id));

ALTER TABLE public.formas_pagamento ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow access to own company data" ON public.formas_pagamento FOR ALL USING (public.is_member_of_empresa(empresa_id));
