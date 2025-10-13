/*
# Módulo de Produtos - Recriação Completa

Este script recria todo o esquema do módulo de produtos, incluindo tabelas, tipos, políticas de segurança e funções RPC para CRUD.

## Query Description:
- **DROP...CASCADE**: Remove tabelas, tipos, funções e seus dependentes (views, foreign keys). Isso é necessário para uma recriação limpa e para resolver erros de dependência.
- **CREATE TYPE**: Define os enums para padronizar os tipos de dados.
- **CREATE TABLE**: Cria as tabelas `produtos`, `produto_imagens`, `produto_atributos`, `produto_fornecedores`.
- **RLS Policies**: Aplica segurança em nível de linha para garantir o isolamento de dados por `empresa_id`.
- **RPC Functions**: Cria funções `create_produto_completo`, `update_produto_completo`, `delete_produto` como `SECURITY DEFINER` para encapsular a lógica de negócio e garantir a segurança.

## Metadata:
- Schema-Category: "Structural"
- Impact-Level: "High"
- Requires-Backup: true
- Reversible: false
*/

-- 1. Limpeza de objetos antigos (agora com CASCADE para resolver dependências)
DROP TABLE IF EXISTS public.produtos CASCADE;
DROP TABLE IF EXISTS public.produto_imagens CASCADE;
DROP TABLE IF EXISTS public.produto_atributos CASCADE;
DROP TABLE IF EXISTS public.produto_fornecedores CASCADE;

DROP FUNCTION IF EXISTS public.create_produto_completo(jsonb, jsonb, jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.update_produto_completo(uuid, jsonb, jsonb, jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.delete_produto(uuid) CASCADE;

DROP TYPE IF EXISTS public.tipo_produto CASCADE;
DROP TYPE IF EXISTS public.situacao_produto CASCADE;
DROP TYPE IF EXISTS public.origem_produto CASCADE;
DROP TYPE IF EXISTS public.tipo_embalagem_produto CASCADE;

-- 2. Criação de Tipos (Enums)
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

-- 3. Criação de Tabelas
CREATE TABLE public.produtos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nome text NOT NULL,
    tipo tipo_produto,
    situacao situacao_produto DEFAULT 'Ativo',
    codigo text,
    codigo_barras text,
    unidade text NOT NULL,
    preco_venda numeric(10, 2) NOT NULL,
    custo_medio numeric(10, 2),
    origem origem_produto,
    ncm text,
    cest text,
    controlar_estoque boolean DEFAULT true,
    estoque_inicial numeric(10, 3),
    estoque_minimo numeric(10, 3),
    estoque_maximo numeric(10, 3),
    localizacao text,
    dias_preparacao integer,
    controlar_lotes boolean DEFAULT false,
    peso_liquido numeric(10, 3),
    peso_bruto numeric(10, 3),
    numero_volumes integer,
    tipo_embalagem tipo_embalagem_produto,
    largura numeric(10, 2),
    altura numeric(10, 2),
    comprimento numeric(10, 2),
    diametro numeric(10, 2),
    marca text,
    modelo text,
    disponibilidade text,
    garantia text,
    video_url text,
    descricao_curta text,
    descricao_complementar text,
    slug text,
    titulo_seo text,
    meta_descricao_seo text,
    observacoes text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),

    CONSTRAINT idx_produto_empresa_codigo UNIQUE (empresa_id, codigo)
);
COMMENT ON TABLE public.produtos IS 'Tabela principal para cadastro de produtos.';

CREATE TABLE public.produto_imagens (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    storage_path text NOT NULL,
    nome_arquivo text NOT NULL,
    tamanho_bytes integer,
    content_type text,
    ordem integer DEFAULT 0,
    created_at timestamptz DEFAULT now()
);
COMMENT ON TABLE public.produto_imagens IS 'Armazena as imagens associadas a um produto.';

CREATE TABLE public.produto_atributos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    atributo text NOT NULL,
    valor text NOT NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    UNIQUE (produto_id, atributo)
);
COMMENT ON TABLE public.produto_atributos IS 'Atributos customizados para produtos, como Cor, Tamanho, etc.';

CREATE TABLE public.produto_fornecedores (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    fornecedor_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE,
    codigo_no_fornecedor text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    UNIQUE (produto_id, fornecedor_id)
);
COMMENT ON TABLE public.produto_fornecedores IS 'Associa produtos a seus fornecedores.';

-- 4. Habilitar RLS e criar Políticas
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produto_imagens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produto_atributos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produto_fornecedores ENABLE ROW LEVEL SECURITY;

CREATE POLICY select_produtos ON public.produtos FOR SELECT USING (empresa_id = (auth.jwt() ->> 'empresa_id')::uuid);
CREATE POLICY insert_produtos ON public.produtos FOR INSERT WITH CHECK (empresa_id = (auth.jwt() ->> 'empresa_id')::uuid);
CREATE POLICY update_produtos ON public.produtos FOR UPDATE USING (empresa_id = (auth.jwt() ->> 'empresa_id')::uuid);
CREATE POLICY delete_produtos ON public.produtos FOR DELETE USING (empresa_id = (auth.jwt() ->> 'empresa_id')::uuid);

CREATE POLICY manage_produto_imagens ON public.produto_imagens USING (
    (auth.jwt() ->> 'empresa_id')::uuid = (SELECT empresa_id FROM produtos WHERE id = produto_id)
);
CREATE POLICY manage_produto_atributos ON public.produto_atributos USING (
    (auth.jwt() ->> 'empresa_id')::uuid = (SELECT empresa_id FROM produtos WHERE id = produto_id)
);
CREATE POLICY manage_produto_fornecedores ON public.produto_fornecedores USING (
    (auth.jwt() ->> 'empresa_id')::uuid = (SELECT empresa_id FROM produtos WHERE id = produto_id)
);

-- 5. Funções RPC (SECURITY DEFINER para encapsular lógica e segurança)
CREATE OR REPLACE FUNCTION public.create_produto_completo(
    p_produto_data jsonb,
    p_atributos jsonb,
    p_fornecedores jsonb
) RETURNS uuid
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
    -- Inserir produto principal
    INSERT INTO public.produtos (empresa_id, nome, tipo, situacao, codigo, codigo_barras, unidade, preco_venda, custo_medio, origem, ncm, cest, controlar_estoque, estoque_inicial, estoque_minimo, estoque_maximo, localizacao, dias_preparacao, controlar_lotes, peso_liquido, peso_bruto, numero_volumes, tipo_embalagem, largura, altura, comprimento, diametro, marca, modelo, disponibilidade, garantia, video_url, descricao_curta, descricao_complementar, slug, titulo_seo, meta_descricao_seo, observacoes)
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

    -- Inserir atributos
    IF p_atributos IS NOT NULL THEN
        FOR v_atributo IN SELECT * FROM jsonb_array_elements(p_atributos) LOOP
            INSERT INTO public.produto_atributos (produto_id, atributo, valor)
            VALUES (v_produto_id, v_atributo->>'atributo', v_atributo->>'valor');
        END LOOP;
    END IF;

    -- Inserir fornecedores
    IF p_fornecedores IS NOT NULL THEN
        FOR v_fornecedor IN SELECT * FROM jsonb_array_elements(p_fornecedores) LOOP
            INSERT INTO public.produto_fornecedores (produto_id, fornecedor_id, codigo_no_fornecedor)
            VALUES (v_produto_id, (v_fornecedor->>'fornecedor_id')::uuid, v_fornecedor->>'codigo_no_fornecedor');
        END LOOP;
    END IF;

    RETURN v_produto_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_produto_completo(
    p_produto_id uuid,
    p_produto_data jsonb,
    p_atributos jsonb,
    p_fornecedores jsonb
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_empresa_id uuid := (auth.jwt() ->> 'empresa_id')::uuid;
    v_atributo jsonb;
    v_fornecedor jsonb;
BEGIN
    -- Atualizar produto principal
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
        observacoes = p_produto_data->>'observacoes',
        updated_at = now()
    WHERE id = p_produto_id AND empresa_id = v_empresa_id;

    -- Sincronizar atributos (delete/insert)
    DELETE FROM public.produto_atributos WHERE produto_id = p_produto_id;
    IF p_atributos IS NOT NULL THEN
        FOR v_atributo IN SELECT * FROM jsonb_array_elements(p_atributos) LOOP
            INSERT INTO public.produto_atributos (produto_id, atributo, valor)
            VALUES (p_produto_id, v_atributo->>'atributo', v_atributo->>'valor');
        END LOOP;
    END IF;

    -- Sincronizar fornecedores (delete/insert)
    DELETE FROM public.produto_fornecedores WHERE produto_id = p_produto_id;
    IF p_fornecedores IS NOT NULL THEN
        FOR v_fornecedor IN SELECT * FROM jsonb_array_elements(p_fornecedores) LOOP
            INSERT INTO public.produto_fornecedores (produto_id, fornecedor_id, codigo_no_fornecedor)
            VALUES (p_produto_id, (v_fornecedor->>'fornecedor_id')::uuid, v_fornecedor->>'codigo_no_fornecedor');
        END LOOP;
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
    v_empresa_id uuid := (auth.jwt() ->> 'empresa_id')::uuid;
    v_image_paths text[];
BEGIN
    -- Coleta os caminhos das imagens antes de deletar
    SELECT array_agg(storage_path) INTO v_image_paths
    FROM public.produto_imagens
    WHERE produto_id = p_id AND (SELECT empresa_id FROM produtos WHERE id = p_id) = v_empresa_id;

    -- Deleta o produto (em cascata deletará imagens, atributos, etc. do DB)
    DELETE FROM public.produtos WHERE id = p_id AND empresa_id = v_empresa_id;

    -- Retorna os caminhos para o frontend deletar do storage
    RETURN v_image_paths;
END;
$$;

-- 6. Conceder permissões para as funções
GRANT EXECUTE ON FUNCTION public.create_produto_completo(jsonb, jsonb, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_produto_completo(uuid, jsonb, jsonb, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_produto(uuid) TO authenticated;
