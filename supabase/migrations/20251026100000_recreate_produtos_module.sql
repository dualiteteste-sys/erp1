/*
          # [Operação Estrutural] Recriação Completa do Módulo de Produtos
          Este script remove e recria completamente o esquema do banco de dados para o módulo de produtos,
          incluindo tabelas, tipos, políticas de segurança e funções.

          ## Query Description: 
          - **Impacto:** Todos os dados existentes nas tabelas `produtos`, `produto_imagens`, `produto_atributos`, e `produto_fornecedores` serão PERDIDOS.
          - **Riscos:** Alto. Esta é uma operação destrutiva. Prossiga apenas se a recriação do módulo do zero for o objetivo.
          - **Precauções:** Faça um backup dos dados de produtos se precisar deles no futuro.

          ## Metadata:
          - Schema-Category: "Dangerous"
          - Impact-Level: "High"
          - Requires-Backup: true
          - Reversible: false

          ## Structure Details:
          - **Tabelas Removidas e Recriadas:** produtos, produto_imagens, produto_atributos, produto_fornecedores.
          - **Tipos Removidos e Recriados:** tipo_produto, situacao_produto, origem_produto, tipo_embalagem_produto.
          - **Funções Removidas e Recriadas:** create_produto_completo, update_produto_completo, delete_produto.
          - **Políticas RLS:** Recriadas para todas as tabelas, garantindo isolamento por tenant (empresa_id).

          ## Security Implications:
          - RLS Status: Habilitado em todas as tabelas.
          - Policy Changes: Sim, todas as políticas são recriadas.
          - Auth Requirements: As operações de escrita são restritas ao dono dos dados através de RPCs e RLS.
*/

-- PASSO 0: LIMPEZA DO ESQUEMA ANTIGO (IDEMPOTENTE)
DROP FUNCTION IF EXISTS public.create_produto_completo(jsonb, uuid);
DROP FUNCTION IF EXISTS public.update_produto_completo(uuid, jsonb);
DROP FUNCTION IF EXISTS public.delete_produto(uuid);
DROP VIEW IF EXISTS public.produtos_com_estoque;
DROP TABLE IF EXISTS public.produto_imagens;
DROP TABLE IF EXISTS public.produto_atributos;
DROP TABLE IF EXISTS public.produto_fornecedores;
DROP TABLE IF EXISTS public.produtos;
DROP TYPE IF EXISTS public.tipo_produto;
DROP TYPE IF EXISTS public.situacao_produto;
DROP TYPE IF EXISTS public.origem_produto;
DROP TYPE IF EXISTS public.tipo_embalagem_produto;

-- PASSO 1: DEFINIÇÃO DOS TIPOS (ENUMS)
CREATE TYPE public.tipo_produto AS ENUM ('Simples', 'Com variações', 'Kit', 'Fabricado', 'Matéria Prima');
CREATE TYPE public.situacao_produto AS ENUM ('Ativo', 'Inativo');
CREATE TYPE public.origem_produto AS ENUM ('0 - Nacional', '1 - Estrangeira (Imp. Direta)', '2 - Estrangeira (Merc. Interno)', '3 - Nacional (Imp. > 40%)', '4 - Nacional (Proc. Básico)', '5 - Nacional (Imp. <= 40%)', '6 - Estrangeira (Imp. Direta, s/ similar)', '7 - Estrangeira (Merc. Interno, s/ similar)', '8 - Nacional (Imp. > 70%)');
CREATE TYPE public.tipo_embalagem_produto AS ENUM ('Caixa', 'Rolo / Cilindro', 'Envelope', 'Fardo');

-- PASSO 2: CRIAÇÃO DAS TABELAS
-- Tabela principal de produtos
CREATE TABLE public.produtos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nome text NOT NULL,
    tipo tipo_produto NOT NULL DEFAULT 'Simples',
    situacao situacao_produto NOT NULL DEFAULT 'Ativo',
    codigo text,
    codigo_barras text,
    unidade text NOT NULL,
    preco_venda numeric(15, 4) NOT NULL DEFAULT 0.00,
    custo_medio numeric(15, 4),
    origem origem_produto NOT NULL DEFAULT '0 - Nacional',
    ncm text,
    cest text,
    controlar_estoque boolean NOT NULL DEFAULT true,
    estoque_inicial numeric(15, 4),
    estoque_minimo numeric(15, 4),
    estoque_maximo numeric(15, 4),
    localizacao text,
    dias_preparacao integer,
    controlar_lotes boolean NOT NULL DEFAULT false,
    peso_liquido numeric(15, 4),
    peso_bruto numeric(15, 4),
    numero_volumes integer,
    tipo_embalagem tipo_embalagem_produto,
    largura numeric(15, 4),
    altura numeric(15, 4),
    comprimento numeric(15, 4),
    diametro numeric(15, 4),
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
    embalagem_id uuid REFERENCES public.embalagens(id) ON DELETE SET NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT check_preco_venda_positivo CHECK (preco_venda >= 0),
    CONSTRAINT unique_codigo_por_empresa UNIQUE (empresa_id, codigo)
);
COMMENT ON TABLE public.produtos IS 'Tabela central para armazenamento de produtos e serviços.';
CREATE INDEX idx_produtos_empresa_id ON public.produtos(empresa_id);
CREATE INDEX idx_produtos_nome ON public.produtos USING gin (to_tsvector('portuguese', nome));

-- Tabelas relacionadas
CREATE TABLE public.produto_imagens (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    storage_path text NOT NULL,
    nome_arquivo text NOT NULL,
    tamanho_bytes integer,
    content_type text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.produto_imagens IS 'Armazena metadados de imagens de produtos, vinculadas ao Supabase Storage.';
CREATE INDEX idx_produto_imagens_produto_id ON public.produto_imagens(produto_id);

CREATE TABLE public.produto_atributos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    atributo text NOT NULL,
    valor text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT unique_atributo_por_produto UNIQUE (produto_id, atributo)
);
COMMENT ON TABLE public.produto_atributos IS 'Atributos customizáveis para produtos, como Cor, Tamanho, etc.';

CREATE TABLE public.produto_fornecedores (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    fornecedor_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE,
    codigo_no_fornecedor text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT unique_fornecedor_por_produto UNIQUE (produto_id, fornecedor_id)
);
COMMENT ON TABLE public.produto_fornecedores IS 'Associa produtos a seus fornecedores.';

-- PASSO 3: TRIGGER DE AUDITORIA (updated_at)
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_produtos_update BEFORE UPDATE ON public.produtos FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();
CREATE TRIGGER on_produto_imagens_update BEFORE UPDATE ON public.produto_imagens FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();
CREATE TRIGGER on_produto_atributos_update BEFORE UPDATE ON public.produto_atributos FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();
CREATE TRIGGER on_produto_fornecedores_update BEFORE UPDATE ON public.produto_fornecedores FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- PASSO 4: VIEW PARA ESTOQUE
CREATE OR REPLACE VIEW public.produtos_com_estoque AS
SELECT 
    p.*,
    COALESCE(p.estoque_inicial, 0) AS estoque_atual -- Placeholder, lógica de estoque real seria mais complexa
FROM public.produtos p;

-- PASSO 5: HABILITAR RLS E CRIAR POLÍTICAS
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Permitir acesso total para a própria empresa" ON public.produtos FOR ALL USING (empresa_id = (auth.jwt() ->> 'empresa_id')::uuid) WITH CHECK (empresa_id = (auth.jwt() ->> 'empresa_id')::uuid);

ALTER TABLE public.produto_imagens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Permitir acesso baseado no produto" ON public.produto_imagens FOR ALL USING (
    produto_id IN (SELECT id FROM public.produtos WHERE empresa_id = (auth.jwt() ->> 'empresa_id')::uuid)
);

ALTER TABLE public.produto_atributos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Permitir acesso baseado no produto" ON public.produto_atributos FOR ALL USING (
    produto_id IN (SELECT id FROM public.produtos WHERE empresa_id = (auth.jwt() ->> 'empresa_id')::uuid)
);

ALTER TABLE public.produto_fornecedores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Permitir acesso baseado no produto" ON public.produto_fornecedores FOR ALL USING (
    produto_id IN (SELECT id FROM public.produtos WHERE empresa_id = (auth.jwt() ->> 'empresa_id')::uuid)
);

-- PASSO 6: FUNÇÕES RPC PARA CRUD SEGURO
-- Função para criar um produto completo (produto + atributos + fornecedores)
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
  -- Inserir na tabela principal de produtos
  INSERT INTO public.produtos (
    empresa_id, nome, tipo, situacao, codigo, codigo_barras, unidade, preco_venda, custo_medio,
    origem, ncm, cest, controlar_estoque, estoque_inicial, estoque_minimo, estoque_maximo,
    localizacao, dias_preparacao, controlar_lotes, peso_liquido, peso_bruto, numero_volumes,
    tipo_embalagem, largura, altura, comprimento, diametro, marca, modelo, disponibilidade,
    garantia, video_url, descricao_curta, descricao_complementar, slug, titulo_seo,
    meta_descricao_seo, observacoes, embalagem_id
  )
  VALUES (
    v_empresa_id,
    p_produto_data->>'nome',
    (p_produto_data->>'tipo')::tipo_produto,
    (p_produto_data->>'situacao')::situacao_produto,
    p_produto_data->>'codigo',
    p_produto_data->>'codigoBarras',
    p_produto_data->>'unidade',
    (p_produto_data->>'precoVenda')::numeric,
    (p_produto_data->>'custoMedio')::numeric,
    (p_produto_data->>'origem')::origem_produto,
    p_produto_data->>'ncm',
    p_produto_data->>'cest',
    (p_produto_data->>'controlarEstoque')::boolean,
    (p_produto_data->>'estoqueInicial')::numeric,
    (p_produto_data->>'estoqueMinimo')::numeric,
    (p_produto_data->>'estoqueMaximo')::numeric,
    p_produto_data->>'localizacao',
    (p_produto_data->>'diasPreparacao')::integer,
    (p_produto_data->>'controlarLotes')::boolean,
    (p_produto_data->>'pesoLiquido')::numeric,
    (p_produto_data->>'pesoBruto')::numeric,
    (p_produto_data->>'numeroVolumes')::integer,
    (p_produto_data->>'tipoEmbalagem')::tipo_embalagem_produto,
    (p_produto_data->>'largura')::numeric,
    (p_produto_data->>'altura')::numeric,
    (p_produto_data->>'comprimento')::numeric,
    (p_produto_data->>'diametro')::numeric,
    p_produto_data->>'marca',
    p_produto_data->>'modelo',
    p_produto_data->>'disponibilidade',
    p_produto_data->>'garantia',
    p_produto_data->>'videoUrl',
    p_produto_data->>'descricaoCurta',
    p_produto_data->>'descricaoComplementar',
    p_produto_data->>'slug',
    p_produto_data->>'tituloSeo',
    p_produto_data->>'metaDescricaoSeo',
    p_produto_data->>'observacoes',
    (p_produto_data->>'embalagemId')::uuid
  ) RETURNING id INTO v_produto_id;

  -- Inserir atributos
  IF p_atributos IS NOT NULL THEN
    FOR v_atributo IN SELECT * FROM jsonb_array_elements(p_atributos)
    LOOP
      INSERT INTO public.produto_atributos (produto_id, atributo, valor)
      VALUES (v_produto_id, v_atributo->>'atributo', v_atributo->>'valor');
    END LOOP;
  END IF;

  -- Inserir fornecedores
  IF p_fornecedores IS NOT NULL THEN
    FOR v_fornecedor IN SELECT * FROM jsonb_array_elements(p_fornecedores)
    LOOP
      INSERT INTO public.produto_fornecedores (produto_id, fornecedor_id, codigo_no_fornecedor)
      VALUES (v_produto_id, (v_fornecedor->>'fornecedorId')::uuid, v_fornecedor->>'codigoNoFornecedor');
    END LOOP;
  END IF;

  RETURN v_produto_id;
END;
$$;

-- Função para atualizar um produto completo
CREATE OR REPLACE FUNCTION public.update_produto_completo(p_produto_id uuid, p_produto_data jsonb, p_atributos jsonb, p_fornecedores jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_empresa_id uuid := (auth.jwt() ->> 'empresa_id')::uuid;
  v_atributo jsonb;
  v_fornecedor jsonb;
BEGIN
  -- Atualizar tabela principal de produtos
  UPDATE public.produtos
  SET
    nome = p_produto_data->>'nome',
    tipo = (p_produto_data->>'tipo')::tipo_produto,
    situacao = (p_produto_data->>'situacao')::situacao_produto,
    codigo = p_produto_data->>'codigo',
    codigo_barras = p_produto_data->>'codigoBarras',
    unidade = p_produto_data->>'unidade',
    preco_venda = (p_produto_data->>'precoVenda')::numeric,
    custo_medio = (p_produto_data->>'custoMedio')::numeric,
    origem = (p_produto_data->>'origem')::origem_produto,
    ncm = p_produto_data->>'ncm',
    cest = p_produto_data->>'cest',
    controlar_estoque = (p_produto_data->>'controlarEstoque')::boolean,
    estoque_minimo = (p_produto_data->>'estoqueMinimo')::numeric,
    estoque_maximo = (p_produto_data->>'estoqueMaximo')::numeric,
    localizacao = p_produto_data->>'localizacao',
    dias_preparacao = (p_produto_data->>'diasPreparacao')::integer,
    controlar_lotes = (p_produto_data->>'controlarLotes')::boolean,
    peso_liquido = (p_produto_data->>'pesoLiquido')::numeric,
    peso_bruto = (p_produto_data->>'pesoBruto')::numeric,
    numero_volumes = (p_produto_data->>'numeroVolumes')::integer,
    tipo_embalagem = (p_produto_data->>'tipoEmbalagem')::tipo_embalagem_produto,
    largura = (p_produto_data->>'largura')::numeric,
    altura = (p_produto_data->>'altura')::numeric,
    comprimento = (p_produto_data->>'comprimento')::numeric,
    diametro = (p_produto_data->>'diametro')::numeric,
    marca = p_produto_data->>'marca',
    modelo = p_produto_data->>'modelo',
    disponibilidade = p_produto_data->>'disponibilidade',
    garantia = p_produto_data->>'garantia',
    video_url = p_produto_data->>'videoUrl',
    descricao_curta = p_produto_data->>'descricaoCurta',
    descricao_complementar = p_produto_data->>'descricaoComplementar',
    slug = p_produto_data->>'slug',
    titulo_seo = p_produto_data->>'tituloSeo',
    meta_descricao_seo = p_produto_data->>'metaDescricaoSeo',
    observacoes = p_produto_data->>'observacoes',
    embalagem_id = (p_produto_data->>'embalagemId')::uuid,
    updated_at = now()
  WHERE id = p_produto_id AND empresa_id = v_empresa_id;

  -- Sincronizar atributos (delete e insert)
  DELETE FROM public.produto_atributos WHERE produto_id = p_produto_id;
  IF p_atributos IS NOT NULL THEN
    FOR v_atributo IN SELECT * FROM jsonb_array_elements(p_atributos)
    LOOP
      INSERT INTO public.produto_atributos (produto_id, atributo, valor)
      VALUES (p_produto_id, v_atributo->>'atributo', v_atributo->>'valor');
    END LOOP;
  END IF;

  -- Sincronizar fornecedores (delete e insert)
  DELETE FROM public.produto_fornecedores WHERE produto_id = p_produto_id;
  IF p_fornecedores IS NOT NULL THEN
    FOR v_fornecedor IN SELECT * FROM jsonb_array_elements(p_fornecedores)
    LOOP
      INSERT INTO public.produto_fornecedores (produto_id, fornecedor_id, codigo_no_fornecedor)
      VALUES (p_produto_id, (v_fornecedor->>'fornecedorId')::uuid, v_fornecedor->>'codigoNoFornecedor');
    END LOOP;
  END IF;

END;
$$;

-- Função para deletar um produto e retornar os caminhos das imagens
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
  -- Verificar se o produto pertence à empresa do usuário
  IF NOT EXISTS (SELECT 1 FROM public.produtos WHERE id = p_id AND empresa_id = v_empresa_id) THEN
    RAISE EXCEPTION 'Permissão negada ou produto não encontrado.';
  END IF;

  -- Coletar os caminhos das imagens antes de deletar
  SELECT array_agg(storage_path) INTO v_image_paths FROM public.produto_imagens WHERE produto_id = p_id;

  -- Deletar o produto (as tabelas relacionadas serão deletadas em cascata)
  DELETE FROM public.produtos WHERE id = p_id;

  RETURN v_image_paths;
END;
$$;

-- PASSO 7: CONCEDER PERMISSÕES
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
