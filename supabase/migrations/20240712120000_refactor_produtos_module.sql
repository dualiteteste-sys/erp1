-- =================================================================
-- MIGRATION: Refatoração completa do Módulo de Produtos
-- Descrição: Recria tabelas, tipos, RLS e funções para o módulo de produtos.
-- =================================================================

-- Inicia uma transação
BEGIN;

-- =================================================================
-- ETAPA 1: LIMPEZA DO ESQUEMA ANTIGO
-- Remove tabelas, tipos e funções antigas para garantir um estado limpo.
-- O uso de CASCADE garante que objetos dependentes também sejam removidos.
-- =================================================================

-- Remove funções antigas
DROP FUNCTION IF EXISTS public.create_produto_completo(jsonb, jsonb, jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.update_produto_completo(uuid, jsonb, jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.delete_produto(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.create_produto_imagem(uuid, text, text, text, integer) CASCADE;
DROP FUNCTION IF EXISTS public.normalize_tipo_produto(text) CASCADE;

-- Remove tabelas antigas
DROP TABLE IF EXISTS public.produto_fornecedores CASCADE;
DROP TABLE IF EXISTS public.produto_atributos CASCADE;
DROP TABLE IF EXISTS public.produto_imagens CASCADE;
DROP TABLE IF EXISTS public.produtos CASCADE;

-- Remove tipos antigos
DROP TYPE IF EXISTS public.tipo_produto CASCADE;
DROP TYPE IF EXISTS public.situacao_produto CASCADE;
DROP TYPE IF EXISTS public.origem_produto CASCADE;
DROP TYPE IF EXISTS public.tipo_embalagem_produto CASCADE;

-- =================================================================
-- ETAPA 2: CRIAÇÃO DOS TIPOS (ENUMS)
-- Define os tipos de dados customizados para o módulo.
-- =================================================================

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


-- =================================================================
-- ETAPA 3: CRIAÇÃO DAS TABELAS
-- Define a estrutura principal das tabelas do módulo de produtos.
-- =================================================================

-- Tabela principal de produtos
CREATE TABLE public.produtos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    -- Dados Gerais
    nome text NOT NULL,
    tipo tipo_produto NOT NULL DEFAULT 'Simples',
    situacao situacao_produto NOT NULL DEFAULT 'Ativo',
    codigo text,
    codigo_barras text,
    unidade text NOT NULL,
    preco_venda numeric(10, 2) NOT NULL,
    custo_medio numeric(10, 2),
    origem origem_produto NOT NULL DEFAULT '0 - Nacional',
    ncm text,
    cest text,

    -- Estoque
    controlar_estoque boolean NOT NULL DEFAULT true,
    estoque_inicial numeric(15, 4),
    estoque_minimo numeric(15, 4),
    estoque_maximo numeric(15, 4),
    localizacao text,
    dias_preparacao integer,
    controlar_lotes boolean NOT NULL DEFAULT false,

    -- Dimensões e Peso
    peso_liquido numeric(10, 3),
    peso_bruto numeric(10, 3),
    numero_volumes integer,
    tipo_embalagem tipo_embalagem_produto,
    embalagem_id uuid REFERENCES public.embalagens(id) ON DELETE SET NULL,
    largura numeric(10, 2),
    altura numeric(10, 2),
    comprimento numeric(10, 2),
    diametro numeric(10, 2),

    -- Dados Complementares
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

    -- Outros
    observacoes text,

    CONSTRAINT produtos_empresa_id_codigo_key UNIQUE (empresa_id, codigo)
);
COMMENT ON TABLE public.produtos IS 'Tabela principal para cadastro de produtos e serviços.';

-- Tabela de imagens dos produtos
CREATE TABLE public.produto_imagens (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    storage_path text NOT NULL,
    nome_arquivo text NOT NULL,
    tamanho_bytes integer,
    content_type text,
    ordem integer,
    created_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.produto_imagens IS 'Armazena as imagens associadas a um produto.';

-- Tabela de atributos (variações)
CREATE TABLE public.produto_atributos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    atributo text NOT NULL,
    valor text NOT NULL,
    CONSTRAINT produto_atributos_produto_id_atributo_key UNIQUE (produto_id, atributo)
);
COMMENT ON TABLE public.produto_atributos IS 'Atributos customizados para produtos, como Cor, Tamanho, etc.';

-- Tabela de fornecedores associados
CREATE TABLE public.produto_fornecedores (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    fornecedor_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE,
    codigo_no_fornecedor text,
    CONSTRAINT produto_fornecedores_produto_id_fornecedor_id_key UNIQUE (produto_id, fornecedor_id)
);
COMMENT ON TABLE public.produto_fornecedores IS 'Associa produtos a seus fornecedores.';

-- =================================================================
-- ETAPA 4: ÍNDICES
-- Cria índices para otimizar as consultas.
-- =================================================================

CREATE INDEX idx_produtos_empresa_id ON public.produtos(empresa_id);
CREATE INDEX idx_produtos_nome ON public.produtos(nome);
CREATE INDEX idx_produto_imagens_produto_id ON public.produto_imagens(produto_id);
CREATE INDEX idx_produto_atributos_produto_id ON public.produto_atributos(produto_id);
CREATE INDEX idx_produto_fornecedores_produto_id ON public.produto_fornecedores(produto_id);

-- =================================================================
-- ETAPA 5: ROW LEVEL SECURITY (RLS)
-- Ativa e define as políticas de segurança para garantir o isolamento dos dados por empresa.
-- =================================================================

-- Tabela `produtos`
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Produtos são visíveis apenas para membros da empresa" ON public.produtos FOR SELECT USING (empresa_id = (auth.jwt() ->> 'empresa_id')::uuid);
CREATE POLICY "Membros podem criar produtos para sua empresa" ON public.produtos FOR INSERT WITH CHECK (empresa_id = (auth.jwt() ->> 'empresa_id')::uuid);
CREATE POLICY "Membros podem atualizar produtos da sua empresa" ON public.produtos FOR UPDATE USING (empresa_id = (auth.jwt() ->> 'empresa_id')::uuid);
CREATE POLICY "Membros podem deletar produtos da sua empresa" ON public.produtos FOR DELETE USING (empresa_id = (auth.jwt() ->> 'empresa_id')::uuid);

-- Tabelas relacionadas
ALTER TABLE public.produto_imagens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Imagens visíveis apenas para membros da empresa do produto" ON public.produto_imagens FOR ALL USING (
  (SELECT empresa_id FROM public.produtos WHERE id = produto_id) = (auth.jwt() ->> 'empresa_id')::uuid
);

ALTER TABLE public.produto_atributos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Atributos visíveis apenas para membros da empresa do produto" ON public.produto_atributos FOR ALL USING (
  (SELECT empresa_id FROM public.produtos WHERE id = produto_id) = (auth.jwt() ->> 'empresa_id')::uuid
);

ALTER TABLE public.produto_fornecedores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Fornecedores visíveis apenas para membros da empresa do produto" ON public.produto_fornecedores FOR ALL USING (
  (SELECT empresa_id FROM public.produtos WHERE id = produto_id) = (auth.jwt() ->> 'empresa_id')::uuid
);

-- =================================================================
-- ETAPA 6: FUNÇÕES RPC (Remote Procedure Call)
-- Centraliza a lógica de negócio complexa no banco de dados para garantir atomicidade e segurança.
-- =================================================================

-- Função para CRIAR um produto completo (produto + atributos + fornecedores)
CREATE OR REPLACE FUNCTION public.create_produto_completo(
  p_produto_data jsonb,
  p_atributos jsonb,
  p_fornecedores jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_produto_id uuid;
  v_empresa_id uuid := (p_produto_data->>'empresa_id')::uuid;
  attr jsonb;
  forn jsonb;
BEGIN
  -- Verifica se o usuário pertence à empresa
  IF v_empresa_id <> (auth.jwt() ->> 'empresa_id')::uuid THEN
    RAISE EXCEPTION 'Operação não permitida: você não pertence a esta empresa.';
  END IF;

  -- Inserir o produto principal
  INSERT INTO public.produtos (empresa_id, nome, tipo, situacao, codigo, codigo_barras, unidade, preco_venda, custo_medio, origem, ncm, cest, controlar_estoque, estoque_inicial, estoque_minimo, estoque_maximo, localizacao, dias_preparacao, controlar_lotes, peso_liquido, peso_bruto, numero_volumes, tipo_embalagem, embalagem_id, largura, altura, comprimento, diametro, marca, modelo, disponibilidade, garantia, video_url, descricao_curta, descricao_complementar, slug, titulo_seo, meta_descricao_seo, observacoes)
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

  -- Inserir atributos
  IF jsonb_array_length(p_atributos) > 0 THEN
    FOR attr IN SELECT * FROM jsonb_array_elements(p_atributos)
    LOOP
      INSERT INTO public.produto_atributos (produto_id, atributo, valor)
      VALUES (v_produto_id, attr->>'atributo', attr->>'valor');
    END LOOP;
  END IF;

  -- Inserir fornecedores
  IF jsonb_array_length(p_fornecedores) > 0 THEN
    FOR forn IN SELECT * FROM jsonb_array_elements(p_fornecedores)
    LOOP
      INSERT INTO public.produto_fornecedores (produto_id, fornecedor_id, codigo_no_fornecedor)
      VALUES (v_produto_id, (forn->>'fornecedor_id')::uuid, forn->>'codigo_no_fornecedor');
    END LOOP;
  END IF;

  RETURN v_produto_id;
END;
$$;

-- Função para ATUALIZAR um produto completo
CREATE OR REPLACE FUNCTION public.update_produto_completo(
  p_produto_id uuid,
  p_produto_data jsonb,
  p_atributos jsonb,
  p_fornecedores jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  attr jsonb;
  forn jsonb;
BEGIN
  -- Verifica se o produto pertence à empresa do usuário
  IF NOT EXISTS (SELECT 1 FROM public.produtos WHERE id = p_produto_id AND empresa_id = (auth.jwt() ->> 'empresa_id')::uuid) THEN
    RAISE EXCEPTION 'Operação não permitida: produto não encontrado ou não pertence à sua empresa.';
  END IF;

  -- Atualizar o produto principal
  UPDATE public.produtos SET
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
    embalagem_id = (p_produto_data->>'embalagem_id')::uuid,
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
  WHERE id = p_produto_id;

  -- Sincronizar atributos (delete/insert)
  DELETE FROM public.produto_atributos WHERE produto_id = p_produto_id;
  IF jsonb_array_length(p_atributos) > 0 THEN
    FOR attr IN SELECT * FROM jsonb_array_elements(p_atributos)
    LOOP
      INSERT INTO public.produto_atributos (produto_id, atributo, valor)
      VALUES (p_produto_id, attr->>'atributo', attr->>'valor');
    END LOOP;
  END IF;

  -- Sincronizar fornecedores (delete/insert)
  DELETE FROM public.produto_fornecedores WHERE produto_id = p_produto_id;
  IF jsonb_array_length(p_fornecedores) > 0 THEN
    FOR forn IN SELECT * FROM jsonb_array_elements(p_fornecedores)
    LOOP
      INSERT INTO public.produto_fornecedores (produto_id, fornecedor_id, codigo_no_fornecedor)
      VALUES (p_produto_id, (forn->>'fornecedor_id')::uuid, forn->>'codigo_no_fornecedor');
    END LOOP;
  END IF;
END;
$$;

-- Função para DELETAR um produto e retornar os caminhos das imagens para limpeza no storage
CREATE OR REPLACE FUNCTION public.delete_produto(p_id uuid)
RETURNS text[]
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_image_paths text[];
BEGIN
  -- Verifica se o produto pertence à empresa do usuário
  IF NOT EXISTS (SELECT 1 FROM public.produtos WHERE id = p_id AND empresa_id = (auth.jwt() ->> 'empresa_id')::uuid) THEN
    RAISE EXCEPTION 'Operação não permitida: produto não encontrado ou não pertence à sua empresa.';
  END IF;

  -- Coleta os caminhos das imagens antes de deletar
  SELECT array_agg(storage_path) INTO v_image_paths FROM public.produto_imagens WHERE produto_id = p_id;

  -- Deleta o produto (em cascata deletará imagens, atributos, etc.)
  DELETE FROM public.produtos WHERE id = p_id;

  -- Retorna os caminhos para o frontend lidar com a exclusão no storage
  RETURN v_image_paths;
END;
$$;

-- Função para criar um anexo de produto de forma segura
CREATE OR REPLACE FUNCTION public.create_produto_imagem(
  p_produto_id uuid,
  p_storage_path text,
  p_filename text,
  p_content_type text,
  p_tamanho_bytes integer
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public AS $$
DECLARE
  v_empresa_id uuid;
  new_imagem record;
BEGIN
  -- Verifica se o produto pertence à empresa do usuário
  SELECT empresa_id INTO v_empresa_id FROM public.produtos WHERE id = p_produto_id;
  IF v_empresa_id IS NULL OR v_empresa_id <> (auth.jwt() ->> 'empresa_id')::uuid THEN
    RAISE EXCEPTION 'Operação não permitida: produto não encontrado ou não pertence à sua empresa.';
  END IF;

  -- Insere o anexo
  INSERT INTO public.produto_imagens (produto_id, storage_path, nome_arquivo, content_type, tamanho_bytes)
  VALUES (p_produto_id, p_storage_path, p_filename, p_content_type, p_tamanho_bytes)
  RETURNING * INTO new_imagem;

  RETURN row_to_json(new_imagem);
END;
$$;


-- =================================================================
-- ETAPA 7: GRANTS
-- Concede permissão de execução nas funções para o role `authenticated`.
-- =================================================================

GRANT EXECUTE ON FUNCTION public.create_produto_completo(jsonb, jsonb, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_produto_completo(uuid, jsonb, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_produto(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_produto_imagem(uuid, text, text, text, integer) TO authenticated;

-- Finaliza a transação
COMMIT;
