-- Dropping the existing functions to allow recreation with a new signature.
DROP FUNCTION IF EXISTS public.create_produto_v2(uuid, jsonb, jsonb, jsonb);
DROP FUNCTION IF EXISTS public.create_produto_v2(jsonb);

-- Recreating the first version of create_produto_v2 with security fix.
CREATE OR REPLACE FUNCTION public.create_produto_v2(p_empresa_id uuid, p_produto_data jsonb, p_atributos jsonb, p_fornecedores jsonb)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_id uuid;
BEGIN
  SET search_path = public;
  
  with d as (
    select *
    from jsonb_to_record(p_produto_data) as x(
      nome                 text,
      codigo               text,
      unidade              text,
      situacao             text,
      tipo                 text,
      preco_venda          numeric,
      custo_medio          numeric,
      codigo_barras        text,
      ncm                  text,
      cest                 text,
      controlar_estoque    boolean,
      estoque_minimo       numeric,
      estoque_maximo       numeric,
      localizacao          text,
      altura               numeric,
      largura              numeric,
      comprimento          numeric,
      diametro             numeric,
      peso_liquido         numeric,
      peso_bruto           numeric,
      numero_volumes       numeric,
      embalagem_id         uuid,
      marca                text,
      modelo               text,
      descricao_curta      text,
      descricao_complementar text,
      disponibilidade      text,
      garantia             text,
      video_url            text,
      slug                 text,
      titulo_seo           text,
      meta_descricao_seo   text,
      dias_preparacao      numeric,
      rastrear_por_lotes   boolean,
      observacoes          text
    )
  )
  insert into public.produtos(
    empresa_id, nome, codigo, unidade, situacao, tipo,
    preco_venda, custo_medio, codigo_barras, ncm, cest,
    controlar_estoque, estoque_minimo, estoque_maximo, localizacao,
    altura, largura, comprimento, diametro, peso_liquido, peso_bruto,
    numero_volumes, embalagem_id,
    marca, modelo, descricao_curta, descricao_complementar,
    disponibilidade, garantia, video_url, slug,
    titulo_seo, meta_descricao_seo,
    dias_preparacao, rastrear_por_lotes, observacoes
  )
  select
    p_empresa_id,
    d.nome,
    nullif(d.codigo,''),
    d.unidade,
    coalesce(d.situacao, 'Ativo')::situacao_produto,
    coalesce(d.tipo, 'Simples')::tipo_produto,
    d.preco_venda, d.custo_medio,
    nullif(d.codigo_barras,''),
    nullif(d.ncm,''),
    nullif(d.cest,''),
    coalesce(d.controlar_estoque,false),
    d.estoque_minimo, d.estoque_maximo, d.localizacao,
    d.altura, d.largura, d.comprimento, d.diametro,
    d.peso_liquido, d.peso_bruto,
    d.numero_volumes, d.embalagem_id,
    d.marca, d.modelo, d.descricao_curta, d.descricao_complementar,
    d.disponibilidade, d.garantia, d.video_url, d.slug,
    d.titulo_seo, d.meta_descricao_seo,
    d.dias_preparacao, coalesce(d.rastrear_por_lotes,false), d.observacoes
  from d
  returning id into v_id;

  insert into public.produto_atributos(produto_id, atributo, valor)
  select v_id, (a->>'atributo')::text, (a->>'valor')::text
  from jsonb_array_elements(p_atributos) as a;

  insert into public.produto_fornecedores(produto_id, fornecedor_id, codigo_no_fornecedor)
  select v_id, (f->>'fornecedor_id')::uuid, nullif(f->>'codigo_no_fornecedor','')
  from jsonb_array_elements(p_fornecedores) as f;

  return v_id;
END;
$$;

-- Recreating the second version of create_produto_v2 with security fix.
CREATE OR REPLACE FUNCTION public.create_produto_v2(p_produto_data jsonb)
RETURNS public.produtos
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_new public.produtos;
BEGIN
  SET search_path = public;

  insert into public.produtos(
    empresa_id, nome, tipo, situacao, codigo, codigo_barras, unidade,
    origem, ncm, cest,
    preco_venda, custo_medio,
    controlar_estoque, estoque_inicial, estoque_minimo, estoque_maximo,
    localizacao, dias_preparacao,
    controlar_lotes, embalagem_id,
    peso_liquido, peso_bruto, numero_volumes,
    largura, altura, comprimento, diametro,
    marca, modelo, disponibilidade, garantia,
    video_url, descricao_curta, descricao_complementar, slug,
    titulo_seo, meta_descricao_seo, observacoes
  )
  values (
    (p_produto_data->>'empresa_id')::uuid,
    nullif(p_produto_data->>'nome',''),
    nullif(p_produto_data->>'tipo',''),
    nullif(p_produto_data->>'situacao',''),
    nullif(p_produto_data->>'codigo',''),
    nullif(p_produto_data->>'codigo_barras',''),
    nullif(p_produto_data->>'unidade',''),
    nullif(p_produto_data->>'origem',''),
    nullif(p_produto_data->>'ncm',''),
    nullif(p_produto_data->>'cest',''),
    (p_produto_data->>'preco_venda')::numeric,
    (p_produto_data->>'custo_medio')::numeric,
    coalesce((p_produto_data->>'controlar_estoque')::boolean, false),
    (p_produto_data->>'estoque_inicial')::numeric,
    (p_produto_data->>'estoque_minimo')::numeric,
    (p_produto_data->>'estoque_maximo')::numeric,
    nullif(p_produto_data->>'localizacao',''),
    (p_produto_data->>'dias_preparacao')::int,
    coalesce((p_produto_data->>'controlar_lotes')::boolean, false),
    nullif(p_produto_data->>'embalagem_id','')::uuid,
    (p_produto_data->>'peso_liquido')::numeric,
    (p_produto_data->>'peso_bruto')::numeric,
    (p_produto_data->>'numero_volumes')::int,
    (p_produto_data->>'largura')::numeric,
    (p_produto_data->>'altura')::numeric,
    (p_produto_data->>'comprimento')::numeric,
    (p_produto_data->>'diametro')::numeric,
    nullif(p_produto_data->>'marca',''),
    nullif(p_produto_data->>'modelo',''),
    nullif(p_produto_data->>'disponibilidade',''),
    nullif(p_produto_data->>'garantia',''),
    nullif(p_produto_data->>'video_url',''),
    nullif(p_produto_data->>'descricao_curta',''),
    nullif(p_produto_data->>'descricao_complementar',''),
    nullif(p_produto_data->>'slug',''),
    nullif(p_produto_data->>'titulo_seo',''),
    nullif(p_produto_data->>'meta_descricao_seo',''),
    nullif(p_produto_data->>'observacoes','')
  )
  returning * into v_new;

  return v_new;
END;
$$;
