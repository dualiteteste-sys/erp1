/*
  # [Security] Harden Produto Functions
  Este script de migração fortalece a segurança das funções RPC do módulo de produtos, resolvendo os avisos de "Function Search Path Mutable".
  ## Descrição da Query:
  - Altera as funções `create_produto_completo`, `update_produto_completo` e `delete_produto`.
  - Adiciona `SET search_path = public, extensions` a cada função para definir explicitamente o caminho de busca, prevenindo potenciais ataques de sequestro de função (function hijacking).
  - Esta é uma boa prática de segurança recomendada pelo Supabase.
  ## Metadados:
  - Schema-Category: "Structural"
  - Impact-Level: "Low"
  - Requires-Backup: false
  - Reversible: true (revertendo para a definição anterior)
*/

-- Harden create_produto_completo
CREATE OR REPLACE FUNCTION public.create_produto_completo(
    p_empresa_id uuid,
    p_produto_data jsonb,
    p_atributos jsonb,
    p_fornecedores jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_produto_id uuid;
  v_user_id uuid := auth.uid();
BEGIN
  INSERT INTO public.produtos (empresa_id, created_by, updated_by, nome, tipo, situacao, codigo, codigo_barras, unidade, preco_venda, custo_medio, origem, ncm, cest, controlar_estoque, estoque_inicial, estoque_minimo, estoque_maximo, localizacao, dias_preparacao, controlar_lotes, peso_liquido, peso_bruto, numero_volumes, largura, altura, comprimento, diametro, embalagem_id, marca, modelo, disponibilidade, garantia, video_url, descricao_curta, descricao_complementar, slug, titulo_seo, meta_descricao_seo, observacoes)
  VALUES (
    p_empresa_id, v_user_id, v_user_id,
    p_produto_data->>'nome', (p_produto_data->>'tipo')::public.tipo_produto, (p_produto_data->>'situacao')::public.situacao_produto, p_produto_data->>'codigo', p_produto_data->>'codigoBarras', p_produto_data->>'unidade', (p_produto_data->>'precoVenda')::numeric, (p_produto_data->>'custoMedio')::numeric, (p_produto_data->>'origem')::public.origem_produto, p_produto_data->>'ncm', p_produto_data->>'cest', (p_produto_data->>'controlarEstoque')::boolean, (p_produto_data->>'estoqueInicial')::numeric, (p_produto_data->>'estoqueMinimo')::numeric, (p_produto_data->>'estoqueMaximo')::numeric, p_produto_data->>'localizacao', (p_produto_data->>'diasPreparacao')::integer, (p_produto_data->>'controlarLotes')::boolean, (p_produto_data->>'pesoLiquido')::numeric, (p_produto_data->>'pesoBruto')::numeric, (p_produto_data->>'numeroVolumes')::integer, (p_produto_data->>'largura')::numeric, (p_produto_data->>'altura')::numeric, (p_produto_data->>'comprimento')::numeric, (p_produto_data->>'diametro')::numeric, (p_produto_data->>'embalagemId')::uuid, p_produto_data->>'marca', p_produto_data->>'modelo', p_produto_data->>'disponibilidade', p_produto_data->>'garantia', p_produto_data->>'videoUrl', p_produto_data->>'descricaoCurta', p_produto_data->>'descricaoComplementar', p_produto_data->>'slug', p_produto_data->>'tituloSeo', p_produto_data->>'metaDescricaoSeo', p_produto_data->>'observacoes'
  ) RETURNING id INTO v_produto_id;

  IF p_atributos IS NOT NULL AND jsonb_array_length(p_atributos) > 0 THEN
    INSERT INTO public.produto_atributos (produto_id, atributo, valor)
    SELECT v_produto_id, item->>'atributo', item->>'valor'
    FROM jsonb_array_elements(p_atributos) AS item;
  END IF;

  IF p_fornecedores IS NOT NULL AND jsonb_array_length(p_fornecedores) > 0 THEN
    INSERT INTO public.produto_fornecedores (produto_id, fornecedor_id, codigo_no_fornecedor)
    SELECT v_produto_id, (item->>'fornecedorId')::uuid, item->>'codigoNoFornecedor'
    FROM jsonb_array_elements(p_fornecedores) AS item;
  END IF;
  
  RETURN v_produto_id;
END;
$$;


-- Harden update_produto_completo
CREATE OR REPLACE FUNCTION public.update_produto_completo(
    p_produto_id uuid,
    p_produto_data jsonb,
    p_atributos jsonb,
    p_fornecedores jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id uuid := auth.uid();
BEGIN
  UPDATE public.produtos
  SET
    updated_by = v_user_id,
    nome = COALESCE(p_produto_data->>'nome', nome),
    tipo = COALESCE((p_produto_data->>'tipo')::public.tipo_produto, tipo),
    situacao = COALESCE((p_produto_data->>'situacao')::public.situacao_produto, situacao),
    codigo = COALESCE(p_produto_data->>'codigo', codigo),
    codigo_barras = COALESCE(p_produto_data->>'codigoBarras', codigo_barras),
    unidade = COALESCE(p_produto_data->>'unidade', unidade),
    preco_venda = COALESCE((p_produto_data->>'precoVenda')::numeric, preco_venda),
    custo_medio = (p_produto_data->>'custoMedio')::numeric,
    origem = COALESCE((p_produto_data->>'origem')::public.origem_produto, origem),
    ncm = COALESCE(p_produto_data->>'ncm', ncm),
    cest = COALESCE(p_produto_data->>'cest', cest),
    controlar_estoque = COALESCE((p_produto_data->>'controlarEstoque')::boolean, controlar_estoque),
    estoque_minimo = (p_produto_data->>'estoqueMinimo')::numeric,
    estoque_maximo = (p_produto_data->>'estoqueMaximo')::numeric,
    localizacao = COALESCE(p_produto_data->>'localizacao', localizacao),
    dias_preparacao = (p_produto_data->>'diasPreparacao')::integer,
    controlar_lotes = COALESCE((p_produto_data->>'controlarLotes')::boolean, controlar_lotes),
    peso_liquido = (p_produto_data->>'pesoLiquido')::numeric,
    peso_bruto = (p_produto_data->>'pesoBruto')::numeric,
    numero_volumes = (p_produto_data->>'numeroVolumes')::integer,
    largura = (p_produto_data->>'largura')::numeric,
    altura = (p_produto_data->>'altura')::numeric,
    comprimento = (p_produto_data->>'comprimento')::numeric,
    diametro = (p_produto_data->>'diametro')::numeric,
    embalagem_id = COALESCE((p_produto_data->>'embalagemId')::uuid, embalagem_id),
    marca = COALESCE(p_produto_data->>'marca', marca),
    modelo = COALESCE(p_produto_data->>'modelo', modelo),
    disponibilidade = COALESCE(p_produto_data->>'disponibilidade', disponibilidade),
    garantia = COALESCE(p_produto_data->>'garantia', garantia),
    video_url = COALESCE(p_produto_data->>'videoUrl', video_url),
    descricao_curta = COALESCE(p_produto_data->>'descricaoCurta', descricao_curta),
    descricao_complementar = COALESCE(p_produto_data->>'descricaoComplementar', descricao_complementar),
    slug = COALESCE(p_produto_data->>'slug', slug),
    titulo_seo = COALESCE(p_produto_data->>'tituloSeo', titulo_seo),
    meta_descricao_seo = COALESCE(p_produto_data->>'metaDescricaoSeo', meta_descricao_seo),
    observacoes = COALESCE(p_produto_data->>'observacoes', observacoes)
  WHERE id = p_produto_id;

  DELETE FROM public.produto_atributos WHERE produto_id = p_produto_id;
  IF p_atributos IS NOT NULL AND jsonb_array_length(p_atributos) > 0 THEN
    INSERT INTO public.produto_atributos (produto_id, atributo, valor)
    SELECT p_produto_id, item->>'atributo', item->>'valor'
    FROM jsonb_array_elements(p_atributos) AS item;
  END IF;

  DELETE FROM public.produto_fornecedores WHERE produto_id = p_produto_id;
  IF p_fornecedores IS NOT NULL AND jsonb_array_length(p_fornecedores) > 0 THEN
    INSERT INTO public.produto_fornecedores (produto_id, fornecedor_id, codigo_no_fornecedor)
    SELECT p_produto_id, (item->>'fornecedorId')::uuid, item->>'codigoNoFornecedor'
    FROM jsonb_array_elements(p_fornecedores) AS item;
  END IF;
END;
$$;


-- Harden delete_produto
CREATE OR REPLACE FUNCTION public.delete_produto(p_id uuid)
RETURNS text[]
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_image_paths text[];
BEGIN
  SELECT array_agg(storage_path) INTO v_image_paths
  FROM public.produto_imagens
  WHERE produto_id = p_id;

  DELETE FROM public.produtos WHERE id = p_id;
  
  RETURN v_image_paths;
END;
$$;
