/*
  # [Recriação Módulo Produtos]
  Este script apaga e recria completamente o esquema do módulo de produtos,
  incluindo tabelas, tipos, funções e políticas de segurança.

  ## Alerta de Risco:
  - Esta operação é DESTRUTIVA para os dados do módulo de produtos.
  - Todas as informações em `produtos`, `produto_imagens`, `produto_atributos`,
    `produto_fornecedores` e visões relacionadas serão PERMANENTEMENTE APAGADAS.
  - Faça um backup completo antes de executar este script.

  ## Metadata:
  - Schema-Category: "Dangerous"
  - Impact-Level: "High"
  - Requires-Backup: true
  - Reversible: false
*/

-- Habilita a extensão para auto-update de `updated_at`
CREATE EXTENSION IF NOT EXISTS moddatetime;

-- 1. Limpeza do ambiente (DROP)
DROP VIEW IF EXISTS public.v_produtos_form CASCADE;
DROP VIEW IF EXISTS public.saldos_estoque CASCADE;
DROP FUNCTION IF EXISTS public.create_produto_completo(jsonb, jsonb, jsonb);
DROP FUNCTION IF EXISTS public.update_produto_completo(uuid, jsonb, jsonb, jsonb);
DROP FUNCTION IF EXISTS public.delete_produto(uuid);
DROP TABLE IF EXISTS public.produtos CASCADE;
DROP TABLE IF EXISTS public.produto_imagens CASCADE;
DROP TABLE IF EXISTS public.produto_atributos CASCADE;
DROP TABLE IF EXISTS public.produto_fornecedores CASCADE;
DROP TYPE IF EXISTS public.tipo_produto CASCADE;
DROP TYPE IF EXISTS public.situacao_produto CASCADE;
DROP TYPE IF EXISTS public.origem_produto CASCADE;
DROP TYPE IF EXISTS public.tipo_embalagem_produto CASCADE;

-- 2. Criação dos Tipos (ENUMS)
CREATE TYPE public.tipo_produto AS ENUM ('Simples', 'Com variações', 'Kit', 'Fabricado', 'Matéria Prima');
CREATE TYPE public.situacao_produto AS ENUM ('Ativo', 'Inativo');
CREATE TYPE public.origem_produto AS ENUM ('0 - Nacional', '1 - Estrangeira (Imp. Direta)', '2 - Estrangeira (Merc. Interno)', '3 - Nacional (Imp. > 40%)', '4 - Nacional (Proc. Básico)', '5 - Nacional (Imp. &lt;= 40%)', '6 - Estrangeira (Imp. Direta, s/ similar)', '7 - Estrangeira (Merc. Interno, s/ similar)', '8 - Nacional (Imp. > 70%)');
CREATE TYPE public.tipo_embalagem_produto AS ENUM ('Caixa', 'Rolo / Cilindro', 'Envelope', 'Fardo');

-- 3. Criação da Tabela Principal `produtos`
CREATE TABLE public.produtos (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    empresa_id uuid NOT NULL,
    nome text NOT NULL,
    tipo public.tipo_produto NOT NULL DEFAULT 'Simples'::public.tipo_produto,
    situacao public.situacao_produto NOT NULL DEFAULT 'Ativo'::public.situacao_produto,
    codigo text,
    codigo_barras text,
    unidade text NOT NULL,
    preco_venda numeric NOT NULL,
    custo_medio numeric,
    origem public.origem_produto NOT NULL DEFAULT '0 - Nacional'::public.origem_produto,
    ncm text,
    cest text,
    controlar_estoque boolean NOT NULL DEFAULT true,
    estoque_inicial numeric,
    estoque_minimo numeric,
    estoque_maximo numeric,
    localizacao text,
    dias_preparacao integer,
    controlar_lotes boolean NOT NULL DEFAULT false,
    peso_liquido numeric,
    peso_bruto numeric,
    numero_volumes integer,
    embalagem_id uuid,
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
    CONSTRAINT produtos_pkey PRIMARY KEY (id),
    CONSTRAINT produtos_empresa_id_fkey FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    CONSTRAINT produtos_embalagem_id_fkey FOREIGN KEY (embalagem_id) REFERENCES embalagens(id) ON DELETE SET NULL,
    CONSTRAINT produtos_codigo_empresa_id_key UNIQUE (codigo, empresa_id)
);
COMMENT ON TABLE public.produtos IS 'Tabela principal para cadastro de produtos.';

-- 4. Criação das Tabelas Relacionadas
CREATE TABLE public.produto_imagens (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    produto_id uuid NOT NULL,
    storage_path text NOT NULL,
    nome_arquivo text NOT NULL,
    tamanho_bytes integer NOT NULL,
    content_type text NOT NULL,
    CONSTRAINT produto_imagens_pkey PRIMARY KEY (id),
    CONSTRAINT produto_imagens_produto_id_fkey FOREIGN KEY (produto_id) REFERENCES produtos(id) ON DELETE CASCADE
);

CREATE TABLE public.produto_atributos (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    produto_id uuid NOT NULL,
    atributo text NOT NULL,
    valor text NOT NULL,
    CONSTRAINT produto_atributos_pkey PRIMARY KEY (id),
    CONSTRAINT produto_atributos_produto_id_fkey FOREIGN KEY (produto_id) REFERENCES produtos(id) ON DELETE CASCADE,
    CONSTRAINT produto_atributos_produto_id_atributo_key UNIQUE (produto_id, atributo)
);

CREATE TABLE public.produto_fornecedores (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    produto_id uuid NOT NULL,
    fornecedor_id uuid NOT NULL,
    codigo_no_fornecedor text,
    CONSTRAINT produto_fornecedores_pkey PRIMARY KEY (id),
    CONSTRAINT produto_fornecedores_produto_id_fkey FOREIGN KEY (produto_id) REFERENCES produtos(id) ON DELETE CASCADE,
    CONSTRAINT produto_fornecedores_fornecedor_id_fkey FOREIGN KEY (fornecedor_id) REFERENCES clientes_fornecedores(id) ON DELETE CASCADE
);

-- 5. Gatilhos (Triggers) para `updated_at`
CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.produtos FOR EACH ROW EXECUTE FUNCTION moddatetime (updated_at);
CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.produto_imagens FOR EACH ROW EXECUTE FUNCTION moddatetime (updated_at);
CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.produto_atributos FOR EACH ROW EXECUTE FUNCTION moddatetime (updated_at);
CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.produto_fornecedores FOR EACH ROW EXECUTE FUNCTION moddatetime (updated_at);

-- 6. Políticas de Segurança (RLS)
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "RLS: Produtos (SELECT)" ON public.produtos FOR SELECT USING (empresa_id = (auth.jwt() ->> 'empresa_id')::uuid);
CREATE POLICY "RLS: Produtos (INSERT)" ON public.produtos FOR INSERT WITH CHECK (empresa_id = (auth.jwt() ->> 'empresa_id')::uuid);
CREATE POLICY "RLS: Produtos (UPDATE)" ON public.produtos FOR UPDATE USING (empresa_id = (auth.jwt() ->> 'empresa_id')::uuid);
CREATE POLICY "RLS: Produtos (DELETE)" ON public.produtos FOR DELETE USING (empresa_id = (auth.jwt() ->> 'empresa_id')::uuid);

ALTER TABLE public.produto_imagens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "RLS: Imagens (ALL)" ON public.produto_imagens FOR ALL USING (
    (SELECT empresa_id FROM produtos WHERE id = produto_id) = (auth.jwt() ->> 'empresa_id')::uuid
);

ALTER TABLE public.produto_atributos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "RLS: Atributos (ALL)" ON public.produto_atributos FOR ALL USING (
    (SELECT empresa_id FROM produtos WHERE id = produto_id) = (auth.jwt() ->> 'empresa_id')::uuid
);

ALTER TABLE public.produto_fornecedores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "RLS: Fornecedores (ALL)" ON public.produto_fornecedores FOR ALL USING (
    (SELECT empresa_id FROM produtos WHERE id = produto_id) = (auth.jwt() ->> 'empresa_id')::uuid
);

-- 7. Funções RPC
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
    INSERT INTO public.produtos (
        empresa_id, nome, tipo, situacao, codigo, codigo_barras, unidade, preco_venda, custo_medio,
        origem, ncm, cest, controlar_estoque, estoque_inicial, estoque_minimo, estoque_maximo,
        localizacao, dias_preparacao, controlar_lotes, peso_liquido, peso_bruto, numero_volumes,
        embalagem_id, marca, modelo, disponibilidade, garantia, video_url, descricao_curta,
        descricao_complementar, slug, titulo_seo, meta_descricao_seo, observacoes
    )
    VALUES (
        v_empresa_id,
        p_produto_data->>'nome',
        (p_produto_data->>'tipo')::public.tipo_produto,
        (p_produto_data->>'situacao')::public.situacao_produto,
        p_produto_data->>'codigo',
        p_produto_data->>'codigo_barras',
        p_produto_data->>'unidade',
        (p_produto_data->>'preco_venda')::numeric,
        (p_produto_data->>'custo_medio')::numeric,
        (p_produto_data->>'origem')::public.origem_produto,
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
        tipo = COALESCE((p_produto_data->>'tipo')::public.tipo_produto, tipo),
        situacao = COALESCE((p_produto_data->>'situacao')::public.situacao_produto, situacao),
        codigo = COALESCE(p_produto_data->>'codigo', codigo),
        codigo_barras = COALESCE(p_produto_data->>'codigo_barras', codigo_barras),
        unidade = COALESCE(p_produto_data->>'unidade', unidade),
        preco_venda = COALESCE((p_produto_data->>'preco_venda')::numeric, preco_venda),
        custo_medio = COALESCE((p_produto_data->>'custo_medio')::numeric, custo_medio),
        origem = COALESCE((p_produto_data->>'origem')::public.origem_produto, origem),
        ncm = COALESCE(p_produto_data->>'ncm', ncm),
        cest = COALESCE(p_produto_data->>'cest', cest),
        controlar_estoque = COALESCE((p_produto_data->>'controlar_estoque')::boolean, controlar_estoque),
        estoque_minimo = COALESCE((p_produto_data->>'estoque_minimo')::numeric, estoque_minimo),
        estoque_maximo = COALESCE((p_produto_data->>'estoque_maximo')::numeric, estoque_maximo),
        localizacao = COALESCE(p_produto_data->>'localizacao', localizacao),
        dias_preparacao = COALESCE((p_produto_data->>'dias_preparacao')::integer, dias_preparacao),
        controlar_lotes = COALESCE((p_produto_data->>'controlar_lotes')::boolean, controlar_lotes),
        peso_liquido = COALESCE((p_produto_data->>'peso_liquido')::numeric, peso_liquido),
        peso_bruto = COALESCE((p_produto_data->>'peso_bruto')::numeric, peso_bruto),
        numero_volumes = COALESCE((p_produto_data->>'numero_volumes')::integer, numero_volumes),
        embalagem_id = COALESCE((p_produto_data->>'embalagem_id')::uuid, embalagem_id),
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
        observacoes = COALESCE(p_produto_data->>'observacoes', observacoes)
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

CREATE OR REPLACE FUNCTION public.create_produto_imagem(p_produto_id uuid, p_storage_path text, p_filename text, p_content_type text, p_tamanho_bytes integer)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_new_imagem record;
BEGIN
    INSERT INTO public.produto_imagens (produto_id, storage_path, nome_arquivo, content_type, tamanho_bytes)
    VALUES (p_produto_id, p_storage_path, p_filename, p_content_type, p_tamanho_bytes)
    RETURNING * INTO v_new_imagem;
    RETURN row_to_json(v_new_imagem);
END;
$$;

-- 8. Permissões para o RLS
GRANT EXECUTE ON FUNCTION public.create_produto_completo(jsonb, jsonb, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_produto_completo(uuid, jsonb, jsonb, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_produto(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_produto_imagem(uuid, text, text, text, integer) TO authenticated;
