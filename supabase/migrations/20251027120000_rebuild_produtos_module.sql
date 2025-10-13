/*
  # Módulo de Produtos: Reconstrução Completa

  Este script refatora o módulo de produtos do zero, seguindo as melhores práticas
  de segurança e performance com RLS e RPCs.

  ## Descrição da Operação:
  1.  **Exclusão (CASCADE):** Remove completamente a tabela `produtos` e todas as
      suas dependências (visões, chaves estrangeiras, etc.), assim como as tabelas
      relacionadas `produto_imagens`, `produto_atributos` e `produto_fornecedores`.
      Isso garante um ambiente limpo para a recriação.
  2.  **Criação de Tipos:** Define os ENUMs necessários para o módulo.
  3.  **Criação de Tabelas:** Recria as tabelas com colunas, tipos e constraints
      corretas, incluindo chaves estrangeiras com `ON DELETE CASCADE`.
  4.  **Segurança (RLS):** Ativa a Row-Level Security em todas as tabelas e aplica
      políticas estritas de acesso por `empresa_id`.
  5.  **Funções (RPC):** Cria as funções `create_produto_completo`,
      `update_produto_completo` e `delete_produto` como `SECURITY DEFINER`,
      centralizando toda a lógica de escrita no banco de dados.

  ## Metadados:
  - Categoria: Estrutural, Perigosa (exclui dados)
  - Impacto: Alto (recria toda a estrutura de produtos)
  - Requer Backup: **true** (todos os dados de produtos serão perdidos)
  - Reversível: false
*/

-- 1. LIMPEZA DO ESQUEMA ANTERIOR (COM CASCADE)
DROP TABLE IF EXISTS public.produto_imagens CASCADE;
DROP TABLE IF EXISTS public.produto_atributos CASCADE;
DROP TABLE IF EXISTS public.produto_fornecedores CASCADE;
DROP TABLE IF EXISTS public.produtos CASCADE;

DROP TYPE IF EXISTS public.tipo_produto;
DROP TYPE IF EXISTS public.situacao_produto;
DROP TYPE IF EXISTS public.origem_produto;
DROP TYPE IF EXISTS public.tipo_embalagem_produto;

-- 2. CRIAÇÃO DE TIPOS (ENUMS)
CREATE TYPE public.tipo_produto AS ENUM (
    'Simples',
    'Com variações',
    'Kit',
    'Fabricado',
    'Matéria Prima'
);

CREATE TYPE public.situacao_produto AS ENUM (
    'Ativo',
    'Inativo'
);

CREATE TYPE public.origem_produto AS ENUM (
    '0 - Nacional',
    '1 - Estrangeira (Imp. Direta)',
    '2 - Estrangeira (Merc. Interno)',
    '3 - Nacional (Imp. > 40%)',
    '4 - Nacional (Proc. Básico)',
    '5 - Nacional (Imp. <= 40%)',
    '6 - Estrangeira (Imp. Direta, s/ similar)',
    '7 - Estrangeira (Merc. Interno, s/ similar)',
    '8 - Nacional (Imp. > 70%)'
);

CREATE TYPE public.tipo_embalagem_produto AS ENUM (
    'Caixa',
    'Rolo / Cilindro',
    'Envelope',
    'Fardo'
);

-- 3. CRIAÇÃO DAS TABELAS
CREATE TABLE public.produtos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nome character varying(120) NOT NULL,
    tipo public.tipo_produto NOT NULL DEFAULT 'Simples'::tipo_produto,
    situacao public.situacao_produto NOT NULL DEFAULT 'Ativo'::situacao_produto,
    codigo character varying(50),
    codigo_barras text,
    unidade character varying(10) NOT NULL,
    preco_venda numeric(15,4) NOT NULL,
    custo_medio numeric(15,4),
    origem public.origem_produto NOT NULL DEFAULT '0 - Nacional'::origem_produto,
    ncm character varying(20),
    cest character varying(20),
    controlar_estoque boolean NOT NULL DEFAULT true,
    estoque_inicial numeric(15,4),
    estoque_minimo numeric(15,4),
    estoque_maximo numeric(15,4),
    localizacao text,
    dias_preparacao integer,
    controlar_lotes boolean NOT NULL DEFAULT false,
    peso_liquido numeric(15,4),
    peso_bruto numeric(15,4),
    numero_volumes integer,
    tipo_embalagem public.tipo_embalagem_produto,
    largura numeric(15,4),
    altura numeric(15,4),
    comprimento numeric(15,4),
    diametro numeric(15,4),
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
    observacoes text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT produtos_empresa_codigo_unique UNIQUE (empresa_id, codigo)
);
COMMENT ON TABLE public.produtos IS 'Tabela principal de produtos.';

CREATE TABLE public.produto_imagens (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    storage_path text NOT NULL,
    nome_arquivo text NOT NULL,
    tamanho_bytes integer,
    content_type text,
    ordem integer DEFAULT 0,
    created_at timestamp with time zone NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.produto_imagens IS 'Armazena as imagens associadas a um produto.';

CREATE TABLE public.produto_atributos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    atributo text NOT NULL,
    valor text NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT produto_atributos_unique UNIQUE (produto_id, atributo)
);
COMMENT ON TABLE public.produto_atributos IS 'Atributos customizados do produto (ex: Cor, Tamanho).';

CREATE TABLE public.produto_fornecedores (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    fornecedor_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE,
    codigo_no_fornecedor text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT produto_fornecedores_unique UNIQUE (produto_id, fornecedor_id)
);
COMMENT ON TABLE public.produto_fornecedores IS 'Associa produtos a seus fornecedores.';

-- Trigger para `updated_at`
CREATE TRIGGER handle_updated_at_produtos
    BEFORE UPDATE ON public.produtos
    FOR EACH ROW
    EXECUTE FUNCTION moddatetime('updated_at');

-- 4. POLÍTICAS DE RLS (ROW-LEVEL SECURITY)
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produto_imagens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produto_atributos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produto_fornecedores ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Permite acesso total para a própria empresa" ON public.produtos
    USING (empresa_id = (auth.jwt() ->> 'empresa_id')::uuid)
    WITH CHECK (empresa_id = (auth.jwt() ->> 'empresa_id')::uuid);

CREATE POLICY "Permite acesso total para a própria empresa" ON public.produto_imagens
    USING (produto_id IN (SELECT id FROM public.produtos));

CREATE POLICY "Permite acesso total para a própria empresa" ON public.produto_atributos
    USING (produto_id IN (SELECT id FROM public.produtos));

CREATE POLICY "Permite acesso total para a própria empresa" ON public.produto_fornecedores
    USING (produto_id IN (SELECT id FROM public.produtos));

-- 5. FUNÇÕES (RPC)
CREATE OR REPLACE FUNCTION public.create_produto_completo(
    p_produto_data jsonb,
    p_atributos jsonb,
    p_fornecedores jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_produto_id uuid;
BEGIN
    -- Insere o produto principal
    INSERT INTO public.produtos (
        empresa_id, nome, tipo, situacao, codigo, codigo_barras, unidade, preco_venda, custo_medio,
        origem, ncm, cest, controlar_estoque, estoque_inicial, estoque_minimo, estoque_maximo,
        localizacao, dias_preparacao, controlar_lotes, peso_liquido, peso_bruto, numero_volumes,
        tipo_embalagem, largura, altura, comprimento, diametro, marca, modelo, disponibilidade,
        garantia, video_url, descricao_curta, descricao_complementar, slug, titulo_seo,
        meta_descricao_seo, observacoes
    )
    VALUES (
        (auth.jwt() ->> 'empresa_id')::uuid,
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
        (p_produto_data->>'tipo_embalagem')::tipo_embalagem_produto,
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

    -- Insere atributos
    IF jsonb_array_length(p_atributos) > 0 THEN
        INSERT INTO public.produto_atributos (produto_id, atributo, valor)
        SELECT v_produto_id, item->>'atributo', item->>'valor'
        FROM jsonb_array_elements(p_atributos) AS item;
    END IF;

    -- Insere fornecedores
    IF jsonb_array_length(p_fornecedores) > 0 THEN
        INSERT INTO public.produto_fornecedores (produto_id, fornecedor_id, codigo_no_fornecedor)
        SELECT v_produto_id, (item->>'fornecedor_id')::uuid, item->>'codigo_no_fornecedor'
        FROM jsonb_array_elements(p_fornecedores) AS item;
    END IF;

    RETURN v_produto_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_produto_completo(
    p_produto_id uuid,
    p_produto_data jsonb,
    p_atributos jsonb,
    p_fornecedores jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Atualiza o produto principal
    UPDATE public.produtos
    SET
        nome = p_produto_data->>'nome',
        tipo = (p_produto_data->>'tipo')::tipo_produto,
        situacao = (p_produto_data->>'situacao')::situacao_produto,
        codigo = p_produto_data->>'codigo',
        codigo_barras = p_produto_data->>'codigo_barras',
        unidade = p_produto_data->>'unidade',
        preco_venda = (p_produto_data->>'preco_venda')::numeric,
        custo_medio = (p_produto_data->>'custo_medio')::numeric,
        origem = (p_produto_data->>'origem')::origem_produto,
        ncm = p_produto_data->>'ncm',
        cest = p_produto_data->>'cest',
        controlar_estoque = (p_produto_data->>'controlar_estoque')::boolean,
        estoque_minimo = (p_produto_data->>'estoque_minimo')::numeric,
        estoque_maximo = (p_produto_data->>'estoque_maximo')::numeric,
        localizacao = p_produto_data->>'localizacao',
        dias_preparacao = (p_produto_data->>'dias_preparacao')::integer,
        controlar_lotes = (p_produto_data->>'controlar_lotes')::boolean,
        peso_liquido = (p_produto_data->>'peso_liquido')::numeric,
        peso_bruto = (p_produto_data->>'peso_bruto')::numeric,
        numero_volumes = (p_produto_data->>'numero_volumes')::integer,
        tipo_embalagem = (p_produto_data->>'tipo_embalagem')::tipo_embalagem_produto,
        largura = (p_produto_data->>'largura')::numeric,
        altura = (p_produto_data->>'altura')::numeric,
        comprimento = (p_produto_data->>'comprimento')::numeric,
        diametro = (p_produto_data->>'diametro')::numeric,
        marca = p_produto_data->>'marca',
        modelo = p_produto_data->>'modelo',
        disponibilidade = p_produto_data->>'disponibilidade',
        garantia = p_produto_data->>'garantia',
        video_url = p_produto_data->>'video_url',
        descricao_curta = p_produto_data->>'descricao_curta',
        descricao_complementar = p_produto_data->>'descricao_complementar',
        slug = p_produto_data->>'slug',
        titulo_seo = p_produto_data->>'titulo_seo',
        meta_descricao_seo = p_produto_data->>'meta_descricao_seo',
        observacoes = p_produto_data->>'observacoes'
    WHERE id = p_produto_id;

    -- Sincroniza atributos (delete/insert)
    DELETE FROM public.produto_atributos WHERE produto_id = p_produto_id;
    IF jsonb_array_length(p_atributos) > 0 THEN
        INSERT INTO public.produto_atributos (produto_id, atributo, valor)
        SELECT p_produto_id, item->>'atributo', item->>'valor'
        FROM jsonb_array_elements(p_atributos) AS item;
    END IF;

    -- Sincroniza fornecedores (delete/insert)
    DELETE FROM public.produto_fornecedores WHERE produto_id = p_produto_id;
    IF jsonb_array_length(p_fornecedores) > 0 THEN
        INSERT INTO public.produto_fornecedores (produto_id, fornecedor_id, codigo_no_fornecedor)
        SELECT p_produto_id, (item->>'fornecedor_id')::uuid, item->>'codigo_no_fornecedor'
        FROM jsonb_array_elements(p_fornecedores) AS item;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_produto(p_id uuid)
RETURNS text[]
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_image_paths text[];
BEGIN
    -- Coleta os caminhos das imagens antes de deletar
    SELECT array_agg(storage_path)
    INTO v_image_paths
    FROM public.produto_imagens
    WHERE produto_id = p_id;

    -- Deleta o produto (ON DELETE CASCADE cuidará das tabelas relacionadas)
    DELETE FROM public.produtos WHERE id = p_id;

    RETURN v_image_paths;
END;
$$;

-- 6. GRANTS
GRANT EXECUTE ON FUNCTION public.create_produto_completo(jsonb, jsonb, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_produto_completo(uuid, jsonb, jsonb, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_produto(uuid) TO authenticated;
