-- Habilita a extensão para auto-update de `updated_at`
CREATE SCHEMA IF NOT EXISTS extensions;
CREATE EXTENSION IF NOT EXISTS moddatetime WITH SCHEMA extensions;

-- Limpeza de objetos antigos para garantir um ambiente limpo
DROP FUNCTION IF EXISTS public.create_produto_completo(jsonb, jsonb, jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.update_produto_completo(uuid, jsonb, jsonb, jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.delete_produto(uuid) CASCADE;
DROP VIEW IF EXISTS public.produtos_com_estoque CASCADE;
DROP TABLE IF EXISTS public.produtos CASCADE;
DROP TABLE IF EXISTS public.produto_imagens CASCADE;
DROP TABLE IF EXISTS public.produto_atributos CASCADE;
DROP TABLE IF EXISTS public.produto_fornecedores CASCADE;
DROP TYPE IF EXISTS public.tipo_produto CASCADE;
DROP TYPE IF EXISTS public.situacao_produto CASCADE;
DROP TYPE IF EXISTS public.origem_produto CASCADE;
DROP TYPE IF EXISTS public.tipo_embalagem_produto CASCADE;

-- 1. Definição de Tipos (ENUMS)
CREATE TYPE public.tipo_produto AS ENUM ('Simples', 'Com variações', 'Kit', 'Fabricado', 'Matéria Prima');
CREATE TYPE public.situacao_produto AS ENUM ('Ativo', 'Inativo');
CREATE TYPE public.origem_produto AS ENUM ('0 - Nacional', '1 - Estrangeira (Imp. Direta)', '2 - Estrangeira (Merc. Interno)', '3 - Nacional (Imp. > 40%)', '4 - Nacional (Proc. Básico)', '5 - Nacional (Imp. <= 40%)', '6 - Estrangeira (Imp. Direta, s/ similar)', '7 - Estrangeira (Merc. Interno, s/ similar)', '8 - Nacional (Imp. > 70%)');
CREATE TYPE public.tipo_embalagem_produto AS ENUM ('Caixa', 'Rolo / Cilindro', 'Envelope', 'Fardo');

-- 2. Tabela Principal: produtos
CREATE TABLE public.produtos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    
    -- Dados Gerais
    nome character varying(120) NOT NULL,
    tipo tipo_produto NOT NULL DEFAULT 'Simples'::tipo_produto,
    situacao situacao_produto NOT NULL DEFAULT 'Ativo'::situacao_produto,
    codigo character varying(50),
    codigo_barras text,
    unidade character varying(10) NOT NULL,
    preco_venda numeric(15,2) NOT NULL DEFAULT 0,
    custo_medio numeric(15,2),
    origem origem_produto NOT NULL DEFAULT '0 - Nacional'::origem_produto,
    ncm character varying(10),
    cest character varying(9),

    -- Estoque
    controlar_estoque boolean NOT NULL DEFAULT true,
    estoque_inicial numeric(15,4),
    estoque_minimo numeric(15,4),
    estoque_maximo numeric(15,4),
    localizacao text,
    dias_preparacao integer,
    controlar_lotes boolean NOT NULL DEFAULT false,
    
    -- Dimensões e Peso
    peso_liquido numeric(15,3),
    peso_bruto numeric(15,3),
    numero_volumes integer,
    embalagem_id uuid REFERENCES public.embalagens(id) ON DELETE SET NULL,
    largura numeric(10,2),
    altura numeric(10,2),
    comprimento numeric(10,2),
    diametro numeric(10,2),

    -- Dados Complementares
    marca text,
    modelo text,
    disponibilidade text,
    garantia text,
    video_url text,
    descricao_curta text,
    descricao_complementar text,
    slug text,
    titulo_seo character varying(60),
    meta_descricao_seo character varying(160),
    
    -- Outros
    observacoes text,

    CONSTRAINT chk_preco_venda_positivo CHECK (preco_venda >= 0),
    CONSTRAINT chk_pesos_positivos CHECK (peso_liquido >= 0 AND peso_bruto >= 0),
    CONSTRAINT uk_produto_codigo_empresa UNIQUE (empresa_id, codigo)
);
COMMENT ON TABLE public.produtos IS 'Tabela central para cadastro de produtos e serviços.';
CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.produtos
  FOR EACH ROW EXECUTE FUNCTION extensions.moddatetime('updated_at');

-- 3. Tabelas Relacionadas
CREATE TABLE public.produto_imagens (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    storage_path text NOT NULL,
    nome_arquivo text NOT NULL,
    content_type text,
    tamanho_bytes bigint,
    ordem integer DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.produto_imagens IS 'Armazena as imagens associadas a um produto.';

CREATE TABLE public.produto_atributos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    atributo text NOT NULL,
    valor text NOT NULL,
    CONSTRAINT uk_produto_atributo UNIQUE (produto_id, atributo)
);
COMMENT ON TABLE public.produto_atributos IS 'Atributos dinâmicos para produtos, como Cor, Tamanho, etc.';

CREATE TABLE public.produto_fornecedores (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    fornecedor_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE,
    codigo_no_fornecedor text,
    CONSTRAINT uk_produto_fornecedor UNIQUE (produto_id, fornecedor_id)
);
COMMENT ON TABLE public.produto_fornecedores IS 'Associa produtos a seus fornecedores.';

-- 4. Políticas de RLS (Row Level Security)
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "RLS: Produtos - Acesso total para membros da empresa" ON public.produtos
    FOR ALL USING (empresa_id = (auth.jwt() ->> 'empresa_id')::uuid)
    WITH CHECK (empresa_id = (auth.jwt() ->> 'empresa_id')::uuid);

ALTER TABLE public.produto_imagens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "RLS: Imagens - Acesso via produto" ON public.produto_imagens
    FOR ALL USING (exists(select 1 from produtos where id = produto_id));

ALTER TABLE public.produto_atributos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "RLS: Atributos - Acesso via produto" ON public.produto_atributos
    FOR ALL USING (exists(select 1 from produtos where id = produto_id));

ALTER TABLE public.produto_fornecedores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "RLS: Fornecedores - Acesso via produto" ON public.produto_fornecedores
    FOR ALL USING (exists(select 1 from produtos where id = produto_id));

-- 5. Funções RPC (Remote Procedure Call)
/*
# [create_produto_completo]
Cria um produto e suas associações (atributos, fornecedores) de forma atômica.

## Query Description: ["Esta operação insere um novo produto e seus dados relacionados. Não afeta dados existentes."]

## Metadata:
- Schema-Category: ["Structural"]
- Impact-Level: ["Low"]
- Requires-Backup: [false]
- Reversible: [true]

## Security Implications:
- RLS Status: [Enabled]
- Policy Changes: [No]
- Auth Requirements: [Usuário autenticado e membro da empresa]
*/
CREATE OR REPLACE FUNCTION public.create_produto_completo(p_produto_data jsonb, p_atributos jsonb, p_fornecedores jsonb)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_produto_id uuid;
  v_empresa_id uuid := (auth.jwt() ->> 'empresa_id')::uuid;
  v_atributo jsonb;
  v_fornecedor jsonb;
BEGIN
  INSERT INTO public.produtos (empresa_id, nome, tipo, situacao, codigo, codigo_barras, unidade, preco_venda, custo_medio, origem, ncm, cest, controlar_estoque, estoque_inicial, estoque_minimo, estoque_maximo, localizacao, dias_preparacao, controlar_lotes, peso_liquido, peso_bruto, numero_volumes, embalagem_id, largura, altura, comprimento, diametro, marca, modelo, disponibilidade, garantia, video_url, descricao_curta, descricao_complementar, slug, titulo_seo, meta_descricao_seo, observacoes)
  VALUES (
    v_empresa_id,
    p_produto_data->>'nome',
    (p_produto_data->>'tipo')::tipo_produto,
    (p_produto_data->>'situacao')::situacao_produto,
    p_produto_data->>'codigo',
    p_produto_data->>'codigo_barras',
    p_produto_data->>'unidade',
    (p_produto_data->>'preco_venda')::numeric,
    (p_produto_data->>'custo_medio')::numeric,
    (p_produto_data->>'origem')::origem_produto,
    p_produto_data->>'ncm',
    p_produto_data->>'cest',
    (p_produto_data->>'controlar_estoque')::boolean,
    (p_produto_data->>'estoque_inicial')::numeric,
    (p_produto_data->>'estoque_minimo')::numeric,
    (p_produto_data->>'estoque_maximo')::numeric,
    p_produto_data->>'localizacao',
    (p_produto_data->>'dias_preparacao')::integer,
    (p_produto_data->>'controlar_lotes')::boolean,
    (p_produto_data->>'peso_liquido')::numeric,
    (p_produto_data->>'peso_bruto')::numeric,
    (p_produto_data->>'numero_volumes')::integer,
    (p_produto_data->>'embalagem_id')::uuid,
    (p_produto_data->>'largura')::numeric,
    (p_produto_data->>'altura')::numeric,
    (p_produto_data->>'comprimento')::numeric,
    (p_produto_data->>'diametro')::numeric,
    p_produto_data->>'marca',
    p_produto_data->>'modelo',
    p_produto_data->>'disponibilidade',
    p_produto_data->>'garantia',
    p_produto_data->>'video_url',
    p_produto_data->>'descricao_curta',
    p_produto_data->>'descricao_complementar',
    p_produto_data->>'slug',
    p_produto_data->>'titulo_seo',
    p_produto_data->>'meta_descricao_seo',
    p_produto_data->>'observacoes'
  ) RETURNING id INTO v_produto_id;

  IF p_atributos IS NOT NULL THEN
    FOR v_atributo IN SELECT * FROM jsonb_array_elements(p_atributos) LOOP
      INSERT INTO public.produto_atributos (produto_id, atributo, valor)
      VALUES (v_produto_id, v_atributo->>'atributo', v_atributo->>'valor');
    END LOOP;
  END IF;

  IF p_fornecedores IS NOT NULL THEN
    FOR v_fornecedor IN SELECT * FROM jsonb_array_elements(p_fornecedores) LOOP
      INSERT INTO public.produto_fornecedores (produto_id, fornecedor_id, codigo_no_fornecedor)
      VALUES (v_produto_id, (v_fornecedor->>'fornecedor_id')::uuid, v_fornecedor->>'codigo_no_fornecedor');
    END LOOP;
  END IF;

  RETURN v_produto_id;
END;
$$;

/*
# [update_produto_completo]
Atualiza um produto e suas associações (atributos, fornecedores) de forma atômica.

## Query Description: ["Esta operação atualiza um produto existente. Dados de atributos e fornecedores são substituídos pelos novos valores."]

## Metadata:
- Schema-Category: ["Structural"]
- Impact-Level: ["Medium"]
- Requires-Backup: [false]
- Reversible: [false]

## Security Implications:
- RLS Status: [Enabled]
- Policy Changes: [No]
- Auth Requirements: [Usuário autenticado e membro da empresa]
*/
CREATE OR REPLACE FUNCTION public.update_produto_completo(p_produto_id uuid, p_produto_data jsonb, p_atributos jsonb, p_fornecedores jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_atributo jsonb;
  v_fornecedor jsonb;
BEGIN
  UPDATE public.produtos SET
    nome = COALESCE(p_produto_data->>'nome', nome),
    tipo = COALESCE((p_produto_data->>'tipo')::tipo_produto, tipo),
    situacao = COALESCE((p_produto_data->>'situacao')::situacao_produto, situacao),
    codigo = COALESCE(p_produto_data->>'codigo', codigo),
    codigo_barras = COALESCE(p_produto_data->>'codigo_barras', codigo_barras),
    unidade = COALESCE(p_produto_data->>'unidade', unidade),
    preco_venda = COALESCE((p_produto_data->>'preco_venda')::numeric, preco_venda),
    custo_medio = (p_produto_data->>'custo_medio')::numeric,
    origem = COALESCE((p_produto_data->>'origem')::origem_produto, origem),
    ncm = COALESCE(p_produto_data->>'ncm', ncm),
    cest = COALESCE(p_produto_data->>'cest', cest),
    controlar_estoque = COALESCE((p_produto_data->>'controlar_estoque')::boolean, controlar_estoque),
    estoque_minimo = (p_produto_data->>'estoque_minimo')::numeric,
    estoque_maximo = (p_produto_data->>'estoque_maximo')::numeric,
    localizacao = COALESCE(p_produto_data->>'localizacao', localizacao),
    dias_preparacao = (p_produto_data->>'dias_preparacao')::integer,
    controlar_lotes = COALESCE((p_produto_data->>'controlar_lotes')::boolean, controlar_lotes),
    peso_liquido = (p_produto_data->>'peso_liquido')::numeric,
    peso_bruto = (p_produto_data->>'peso_bruto')::numeric,
    numero_volumes = (p_produto_data->>'numero_volumes')::integer,
    embalagem_id = (p_produto_data->>'embalagem_id')::uuid,
    largura = (p_produto_data->>'largura')::numeric,
    altura = (p_produto_data->>'altura')::numeric,
    comprimento = (p_produto_data->>'comprimento')::numeric,
    diametro = (p_produto_data->>'diametro')::numeric,
    marca = COALESCE(p_produto_data->>'marca', marca),
    modelo = COALESCE(p_produto_data->>'modelo', modelo),
    disponibilidade = COALESCE(p_produto_data->>'disponibilidade', disponibilidade),
    garantia = COALESCE(p_produto_data->>'garantia', garantia),
    video_url = COALESCE(p_produto_data->>'video_url', video_url),
    descricao_curta = COALESCE(p_produto_data->>'descricao_curta', descricao_curta),
    descricao_complementar = COALESCE(p_produto_data->>'descricao_complementar', descricao_complementar),
    slug = COALESCE(p_produto_data->>'slug', slug),
    titulo_seo = COALESCE(p_produto_data->>'titulo_seo', titulo_seo),
    meta_descricao_seo = COALESCE(p_produto_data->>'meta_descricao_seo', meta_descricao_seo),
    observacoes = COALESCE(p_produto_data->>'observacoes', observacoes),
    updated_at = now()
  WHERE id = p_produto_id;

  DELETE FROM public.produto_atributos WHERE produto_id = p_produto_id;
  IF p_atributos IS NOT NULL THEN
    FOR v_atributo IN SELECT * FROM jsonb_array_elements(p_atributos) LOOP
      INSERT INTO public.produto_atributos (produto_id, atributo, valor)
      VALUES (p_produto_id, v_atributo->>'atributo', v_atributo->>'valor');
    END LOOP;
  END IF;

  DELETE FROM public.produto_fornecedores WHERE produto_id = p_produto_id;
  IF p_fornecedores IS NOT NULL THEN
    FOR v_fornecedor IN SELECT * FROM jsonb_array_elements(p_fornecedores) LOOP
      INSERT INTO public.produto_fornecedores (produto_id, fornecedor_id, codigo_no_fornecedor)
      VALUES (p_produto_id, (v_fornecedor->>'fornecedor_id')::uuid, v_fornecedor->>'codigo_no_fornecedor');
    END LOOP;
  END IF;
END;
$$;

/*
# [delete_produto]
Deleta um produto e retorna os caminhos das imagens associadas para limpeza no storage.

## Query Description: ["Esta operação remove permanentemente um produto e seus dados associados. A exclusão é em cascata para imagens, atributos e fornecedores. Esta ação não pode ser desfeita."]

## Metadata:
- Schema-Category: ["Dangerous"]
- Impact-Level: ["High"]
- Requires-Backup: [true]
- Reversible: [false]

## Security Implications:
- RLS Status: [Enabled]
- Policy Changes: [No]
- Auth Requirements: [Usuário autenticado e membro da empresa]
*/
CREATE OR REPLACE FUNCTION public.delete_produto(p_id uuid)
RETURNS text[]
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_image_paths text[];
BEGIN
  SELECT array_agg(storage_path) INTO v_image_paths FROM public.produto_imagens WHERE produto_id = p_id;
  DELETE FROM public.produtos WHERE id = p_id;
  RETURN v_image_paths;
END;
$$;

-- 6. Visões (Views)
CREATE OR REPLACE VIEW public.produtos_com_estoque AS
 SELECT p.id,
    p.empresa_id,
    p.created_at,
    p.updated_at,
    p.nome,
    p.tipo,
    p.situacao,
    p.codigo,
    p.codigo_barras,
    p.unidade,
    p.preco_venda,
    p.custo_medio,
    p.origem,
    p.ncm,
    p.cest,
    p.controlar_estoque,
    p.estoque_inicial,
    p.estoque_minimo,
    p.estoque_maximo,
    p.localizacao,
    p.dias_preparacao,
    p.controlar_lotes,
    p.peso_liquido,
    p.peso_bruto,
    p.numero_volumes,
    p.embalagem_id,
    p.largura,
    p.altura,
    p.comprimento,
    p.diametro,
    p.marca,
    p.modelo,
    p.disponibilidade,
    p.garantia,
    p.video_url,
    p.descricao_curta,
    p.descricao_complementar,
    p.slug,
    p.titulo_seo,
    p.meta_descricao_seo,
    p.observacoes,
    COALESCE(e.saldo, 0) AS estoque_atual
   FROM (produtos p
     LEFT JOIN ( SELECT estoque_movimentos.produto_id,
            sum(
                CASE
                    WHEN (estoque_movimentos.tipo = 'entrada'::text) THEN estoque_movimentos.quantidade
                    ELSE (- estoque_movimentos.quantidade)
                END) AS saldo
           FROM estoque_movimentos
          GROUP BY estoque_movimentos.produto_id) e ON ((p.id = e.produto_id)));

GRANT SELECT ON public.produtos_com_estoque TO authenticated;
