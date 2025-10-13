/*
  # [RECREATE] Módulo de Produtos
  Recria completamente o esquema do módulo de produtos, incluindo tabelas, tipos, políticas de RLS e funções RPC.

  ## Descrição da Query:
  Esta operação é DESTRUTIVA. Ela removerá permanentemente as tabelas `produtos`, `produto_imagens`, `produto_atributos`, `produto_fornecedores` e todos os dados associados. As tabelas e funções serão recriadas do zero com a estrutura correta e segura. É recomendado fazer um backup antes de aplicar esta migração se houver dados importantes.

  ## Metadados:
  - Categoria-Schema: "Dangerous"
  - Nível de Impacto: "High"
  - Requer-Backup: true
  - Reversível: false

  ## Detalhes da Estrutura:
  - Tabelas afetadas: produtos, produto_imagens, produto_atributos, produto_fornecedores.
  - Tipos afetados: tipo_produto, situacao_produto, origem_produto, tipo_embalagem_produto.
  - Funções afetadas: create_produto_completo, update_produto_completo, delete_produto.

  ## Implicações de Segurança:
  - Status RLS: Ativado para todas as tabelas.
  - Mudanças de Política: Políticas de acesso por `empresa_id` serão recriadas.
  - Requisitos de Auth: As operações exigem um JWT de usuário autenticado com `empresa_id`.

  ## Impacto de Performance:
  - Índices: Índices serão recriados para otimizar consultas.
  - Triggers: Triggers de `updated_at` serão recriados.
  - Impacto Estimado: Mínimo após a migração.
*/

-- =============================================
-- 1. LIMPEZA COMPLETA (DROP)
-- Remove objetos antigos para garantir um ambiente limpo.
-- O uso de CASCADE remove automaticamente objetos dependentes.
-- =============================================
BEGIN;

DROP FUNCTION IF EXISTS public.create_produto_completo(jsonb, jsonb, jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.update_produto_completo(uuid, jsonb, jsonb, jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.update_produto_completo(uuid, jsonb, jsonb) CASCADE; -- Assinatura antiga que causou o erro
DROP FUNCTION IF EXISTS public.delete_produto(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.create_produto_imagem(uuid, text, text, text, integer) CASCADE;
DROP FUNCTION IF EXISTS public.normalize_tipo_produto(text) CASCADE;

DROP VIEW IF EXISTS public.v_produtos_form CASCADE;
DROP VIEW IF EXISTS public.saldos_estoque CASCADE;
DROP VIEW IF EXISTS public.produtos_com_estoque CASCADE;

DROP TABLE IF EXISTS public.produtos CASCADE;
DROP TABLE IF EXISTS public.produto_imagens CASCADE;
DROP TABLE IF EXISTS public.produto_atributos CASCADE;
DROP TABLE IF EXISTS public.produto_fornecedores CASCADE;

DROP TYPE IF EXISTS public.tipo_produto CASCADE;
DROP TYPE IF EXISTS public.situacao_produto CASCADE;
DROP TYPE IF EXISTS public.origem_produto CASCADE;
DROP TYPE IF EXISTS public.tipo_embalagem_produto CASCADE;

COMMIT;

-- =============================================
-- 2. CRIAÇÃO DOS TIPOS (ENUMS)
-- =============================================
BEGIN;

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

COMMIT;

-- =============================================
-- 3. CRIAÇÃO DAS TABELAS
-- =============================================
BEGIN;

CREATE TABLE public.produtos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nome text NOT NULL,
    tipo public.tipo_produto NOT NULL DEFAULT 'Simples',
    situacao public.situacao_produto NOT NULL DEFAULT 'Ativo',
    codigo text,
    codigo_barras text,
    unidade text NOT NULL,
    preco_venda numeric(10, 2) NOT NULL,
    custo_medio numeric(10, 2),
    origem public.origem_produto NOT NULL DEFAULT '0 - Nacional',
    ncm text,
    cest text,
    controlar_estoque boolean NOT NULL DEFAULT true,
    estoque_inicial numeric(10, 3),
    estoque_minimo numeric(10, 3),
    estoque_maximo numeric(10, 3),
    localizacao text,
    dias_preparacao integer,
    controlar_lotes boolean NOT NULL DEFAULT false,
    peso_liquido numeric(10, 3),
    peso_bruto numeric(10, 3),
    numero_volumes integer,
    tipo_embalagem public.tipo_embalagem_produto,
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
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (empresa_id, codigo)
);
COMMENT ON TABLE public.produtos IS 'Tabela principal para cadastro de produtos.';

CREATE TABLE public.produto_imagens (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    storage_path text NOT NULL,
    nome_arquivo text NOT NULL,
    content_type text,
    tamanho_bytes integer,
    ordem integer,
    created_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.produto_imagens IS 'Armazena as imagens associadas a um produto.';

CREATE TABLE public.produto_atributos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    atributo text NOT NULL,
    valor text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(produto_id, atributo)
);
COMMENT ON TABLE public.produto_atributos IS 'Atributos customizáveis para produtos, como Cor, Tamanho, etc.';

CREATE TABLE public.produto_fornecedores (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    fornecedor_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE,
    codigo_no_fornecedor text,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(produto_id, fornecedor_id)
);
COMMENT ON TABLE public.produto_fornecedores IS 'Tabela de associação entre produtos e seus fornecedores.';

COMMIT;

-- =============================================
-- 4. ÍNDICES E TRIGGERS
-- =============================================
BEGIN;

CREATE INDEX idx_produtos_empresa_id ON public.produtos(empresa_id);
CREATE INDEX idx_produto_imagens_produto_id ON public.produto_imagens(produto_id);
CREATE INDEX idx_produto_atributos_produto_id ON public.produto_atributos(produto_id);
CREATE INDEX idx_produto_fornecedores_produto_id ON public.produto_fornecedores(produto_id);
CREATE INDEX idx_produto_fornecedores_fornecedor_id ON public.produto_fornecedores(fornecedor_id);

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.produtos
  FOR EACH ROW EXECUTE PROCEDURE moddatetime (updated_at);

COMMIT;

-- =============================================
-- 5. ROW LEVEL SECURITY (RLS)
-- =============================================
BEGIN;

ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produto_imagens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produto_atributos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produto_fornecedores ENABLE ROW LEVEL SECURITY;

CREATE POLICY select_produtos ON public.produtos FOR SELECT USING (empresa_id = (auth.jwt() ->> 'empresa_id')::uuid);
CREATE POLICY insert_produtos ON public.produtos FOR INSERT WITH CHECK (empresa_id = (auth.jwt() ->> 'empresa_id')::uuid);
CREATE POLICY update_produtos ON public.produtos FOR UPDATE USING (empresa_id = (auth.jwt() ->> 'empresa_id')::uuid);
CREATE POLICY delete_produtos ON public.produtos FOR DELETE USING (empresa_id = (auth.jwt() ->> 'empresa_id')::uuid);

CREATE POLICY manage_produto_imagens ON public.produto_imagens USING (
    (SELECT empresa_id FROM public.produtos WHERE id = produto_id) = (auth.jwt() ->> 'empresa_id')::uuid
);
CREATE POLICY manage_produto_atributos ON public.produto_atributos USING (
    (SELECT empresa_id FROM public.produtos WHERE id = produto_id) = (auth.jwt() ->> 'empresa_id')::uuid
);
CREATE POLICY manage_produto_fornecedores ON public.produto_fornecedores USING (
    (SELECT empresa_id FROM public.produtos WHERE id = produto_id) = (auth.jwt() ->> 'empresa_id')::uuid
);

COMMIT;

-- =============================================
-- 6. FUNÇÕES RPC (Remote Procedure Call)
-- =============================================
BEGIN;

-- Função para criar um produto completo (com atributos e fornecedores)
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
  v_empresa_id uuid := (auth.jwt() ->> 'empresa_id')::uuid;
  v_atributo jsonb;
  v_fornecedor jsonb;
BEGIN
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

  FOR v_atributo IN SELECT * FROM jsonb_array_elements(p_atributos)
  LOOP
    INSERT INTO public.produto_atributos (produto_id, atributo, valor)
    VALUES (v_produto_id, v_atributo->>'atributo', v_atributo->>'valor');
  END LOOP;

  FOR v_fornecedor IN SELECT * FROM jsonb_array_elements(p_fornecedores)
  LOOP
    INSERT INTO public.produto_fornecedores (produto_id, fornecedor_id, codigo_no_fornecedor)
    VALUES (v_produto_id, (v_fornecedor->>'fornecedor_id')::uuid, v_fornecedor->>'codigo_no_fornecedor');
  END LOOP;

  RETURN v_produto_id;
END;
$$;

-- Função para atualizar um produto completo
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
DECLARE
  v_atributo jsonb;
  v_fornecedor jsonb;
BEGIN
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
  WHERE id = p_produto_id AND empresa_id = (auth.jwt() ->> 'empresa_id')::uuid;

  DELETE FROM public.produto_atributos WHERE produto_id = p_produto_id;
  FOR v_atributo IN SELECT * FROM jsonb_array_elements(p_atributos)
  LOOP
    INSERT INTO public.produto_atributos (produto_id, atributo, valor)
    VALUES (p_produto_id, v_atributo->>'atributo', v_atributo->>'valor');
  END LOOP;

  DELETE FROM public.produto_fornecedores WHERE produto_id = p_produto_id;
  FOR v_fornecedor IN SELECT * FROM jsonb_array_elements(p_fornecedores)
  LOOP
    INSERT INTO public.produto_fornecedores (produto_id, fornecedor_id, codigo_no_fornecedor)
    VALUES (p_produto_id, (v_fornecedor->>'fornecedor_id')::uuid, v_fornecedor->>'codigo_no_fornecedor');
  END LOOP;
END;
$$;

-- Função para deletar um produto e retornar os caminhos das imagens para limpeza no storage
CREATE OR REPLACE FUNCTION public.delete_produto(p_id uuid)
RETURNS text[]
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_image_paths text[];
BEGIN
  -- Verifica se o usuário pertence à empresa do produto
  IF NOT EXISTS (SELECT 1 FROM public.produtos WHERE id = p_id AND empresa_id = (auth.jwt() ->> 'empresa_id')::uuid) THEN
    RAISE EXCEPTION 'Permissão negada ou produto não encontrado.';
  END IF;

  SELECT array_agg(storage_path) INTO v_image_paths FROM public.produto_imagens WHERE produto_id = p_id;
  
  DELETE FROM public.produtos WHERE id = p_id;

  RETURN v_image_paths;
END;
$$;

-- Função para criar um registro de imagem de produto
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
SET search_path = public
AS $$
DECLARE
  v_new_imagem record;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.produtos WHERE id = p_produto_id AND empresa_id = (auth.jwt() ->> 'empresa_id')::uuid) THEN
    RAISE EXCEPTION 'Permissão negada ou produto não encontrado.';
  END IF;

  INSERT INTO public.produto_imagens (produto_id, storage_path, nome_arquivo, content_type, tamanho_bytes)
  VALUES (p_produto_id, p_storage_path, p_filename, p_content_type, p_tamanho_bytes)
  RETURNING * INTO v_new_imagem;

  RETURN row_to_json(v_new_imagem);
END;
$$;

COMMIT;

-- =============================================
-- 7. CRIAÇÃO DE VIEWS
-- =============================================
BEGIN;

CREATE OR REPLACE VIEW public.produtos_com_estoque AS
SELECT 
    p.*,
    COALESCE(em.saldo_atual, 0) AS estoque_atual
FROM 
    public.produtos p
LEFT JOIN 
    public.saldos_estoque em ON p.id = em.produto_id;

COMMIT;
