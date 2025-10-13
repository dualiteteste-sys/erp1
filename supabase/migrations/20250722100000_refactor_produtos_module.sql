/*
  # [Refactor] Módulo de Produtos
  Este script refatora completamente o módulo de produtos, alinhando-o com as melhores práticas de segurança e arquitetura (DB-first, RLS, RPCs).
  ## Descrição da Query:
  - **PERIGO**: Remove tabelas e tipos existentes (`produtos`, etc.) usando `DROP ... CASCADE` para garantir uma limpeza completa.
  - **BACKUP RECOMENDADO**: Faça um backup dos dados de produtos se precisar restaurá-los manualmente.
  - Cria o schema `extensions` para isolar extensões.
  - Habilita a extensão `moddatetime` e `uuid-ossp`.
  - Recria as tabelas `produtos`, `produto_imagens`, `produto_atributos`, e `produto_fornecedores` com estrutura otimizada, incluindo colunas de auditoria (`created_by`, `updated_by`).
  - Adiciona gatilhos (`triggers`) para `updated_at` e `updated_by`.
  - Ativa RLS e aplica políticas de multi-tenant.
  - Cria funções RPC (`create_produto_completo`, `update_produto_completo`, `delete_produto`) como `SECURITY DEFINER` para CRUD seguro, incluindo lógica de auditoria.
  ## Metadados:
  - Schema-Category: "Dangerous" (contém DROP CASCADE)
  - Impact-Level: "High"
  - Requires-Backup: true
  - Reversible: false
  ## Implicações de Segurança:
  - RLS Status: Habilitado em todas as tabelas do módulo.
  - Policy Changes: Sim, políticas de multi-tenant são criadas.
  - Auth Requirements: Requer um JWT válido com `empresa_id` e `user_id`.
*/
-- 1. Limpeza do ambiente
DROP VIEW IF EXISTS public.produtos_com_estoque CASCADE;
DROP TABLE IF EXISTS public.produtos CASCADE;
DROP TABLE IF EXISTS public.produto_imagens CASCADE;
DROP TABLE IF EXISTS public.produto_atributos CASCADE;
DROP TABLE IF EXISTS public.produto_fornecedores CASCADE;
DROP FUNCTION IF EXISTS public.create_produto_completo(uuid, jsonb, jsonb, jsonb);
DROP FUNCTION IF EXISTS public.update_produto_completo(uuid, jsonb, jsonb, jsonb);
DROP FUNCTION IF EXISTS public.delete_produto(uuid);
DROP FUNCTION IF EXISTS public.update_updated_by_column();
DROP TYPE IF EXISTS public.tipo_produto CASCADE;
DROP TYPE IF EXISTS public.situacao_produto CASCADE;
DROP TYPE IF EXISTS public.origem_produto CASCADE;
DROP TYPE IF EXISTS public.tipo_embalagem_produto CASCADE;

-- 2. Criação do Schema para Extensões
CREATE SCHEMA IF NOT EXISTS extensions;

-- 3. Habilitação de Extensões
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
-- 'moddatetime' é mantido no schema public para compatibilidade com triggers.
CREATE EXTENSION IF NOT EXISTS moddatetime;

-- 4. Criação de Tipos (ENUMs)
CREATE TYPE public.tipo_produto AS ENUM ('Simples', 'Com variações', 'Kit', 'Fabricado', 'Matéria Prima');
CREATE TYPE public.situacao_produto AS ENUM ('Ativo', 'Inativo');
CREATE TYPE public.origem_produto AS ENUM ('0 - Nacional', '1 - Estrangeira (Imp. Direta)', '2 - Estrangeira (Merc. Interno)', '3 - Nacional (Imp. > 40%)', '4 - Nacional (Proc. Básico)', '5 - Nacional (Imp. <= 40%)', '6 - Estrangeira (Imp. Direta, s/ similar)', '7 - Estrangeira (Merc. Interno, s/ similar)', '8 - Nacional (Imp. > 70%)');
CREATE TYPE public.tipo_embalagem_produto AS ENUM ('Caixa', 'Rolo / Cilindro', 'Envelope', 'Fardo');

-- 5. Função e Gatilhos (Triggers) para auditoria
CREATE OR REPLACE FUNCTION public.update_updated_by_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_by = auth.uid();
   RETURN NEW;
END;
$$ language 'plpgsql' SECURITY DEFINER;

-- 6. Criação da Tabela Principal `produtos`
CREATE TABLE public.produtos (
    id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid REFERENCES auth.users(id),
    updated_by uuid REFERENCES auth.users(id),
    nome character varying(120) NOT NULL,
    tipo public.tipo_produto DEFAULT 'Simples'::public.tipo_produto,
    situacao public.situacao_produto DEFAULT 'Ativo'::public.situacao_produto,
    codigo character varying(50),
    codigo_barras text,
    unidade character varying(10) NOT NULL,
    preco_venda numeric(15,2) NOT NULL DEFAULT 0.00,
    custo_medio numeric(15,2),
    origem public.origem_produto,
    ncm character varying(10),
    cest character varying(9),
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
    largura numeric(15,4),
    altura numeric(15,4),
    comprimento numeric(15,4),
    diametro numeric(15,4),
    embalagem_id uuid REFERENCES public.embalagens(id) ON DELETE SET NULL,
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
    UNIQUE(empresa_id, codigo)
);
COMMENT ON TABLE public.produtos IS 'Tabela principal para armazenamento de produtos.';

-- 7. Criação de Tabelas Relacionadas
CREATE TABLE public.produto_imagens (
    id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    storage_path text NOT NULL,
    nome_arquivo text NOT NULL,
    tamanho_bytes integer,
    content_type text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.produto_imagens IS 'Armazena as imagens associadas a um produto.';

CREATE TABLE public.produto_atributos (
    id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    atributo text NOT NULL,
    valor text NOT NULL,
    UNIQUE(produto_id, atributo)
);
COMMENT ON TABLE public.produto_atributos IS 'Atributos customizados para produtos (ex: Cor, Tamanho).';

CREATE TABLE public.produto_fornecedores (
    id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    fornecedor_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE,
    codigo_no_fornecedor text,
    UNIQUE(produto_id, fornecedor_id)
);
COMMENT ON TABLE public.produto_fornecedores IS 'Tabela de associação entre produtos e fornecedores.';

-- 8. Criação de Índices
CREATE INDEX idx_produtos_empresa_id ON public.produtos(empresa_id);
CREATE INDEX idx_produto_imagens_produto_id ON public.produto_imagens(produto_id);
CREATE INDEX idx_produto_atributos_produto_id ON public.produto_atributos(produto_id);
CREATE INDEX idx_produto_fornecedores_produto_id ON public.produto_fornecedores(produto_id);
CREATE INDEX idx_produto_fornecedores_fornecedor_id ON public.produto_fornecedores(fornecedor_id);

-- 9. Gatilhos (Triggers) para auditoria
CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.produtos FOR EACH ROW EXECUTE FUNCTION moddatetime('updated_at');
CREATE TRIGGER set_updated_by BEFORE UPDATE ON public.produtos FOR EACH ROW EXECUTE FUNCTION public.update_updated_by_column();
CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.produto_imagens FOR EACH ROW EXECUTE FUNCTION moddatetime('updated_at');

-- 10. Ativação de RLS (Row-Level Security)
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produto_imagens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produto_atributos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produto_fornecedores ENABLE ROW LEVEL SECURITY;

-- 11. Políticas de Segurança (Multi-tenant)
CREATE POLICY "Empresa pode gerenciar seus próprios produtos" ON public.produtos
    FOR ALL USING (empresa_id = (auth.jwt() ->> 'empresa_id')::uuid)
    WITH CHECK (empresa_id = (auth.jwt() ->> 'empresa_id')::uuid);
CREATE POLICY "Empresa pode gerenciar imagens de seus produtos" ON public.produto_imagens
    FOR ALL USING (
        (SELECT empresa_id FROM public.produtos WHERE id = produto_id) = (auth.jwt() ->> 'empresa_id')::uuid
    );
CREATE POLICY "Empresa pode gerenciar atributos de seus produtos" ON public.produto_atributos
    FOR ALL USING (
        (SELECT empresa_id FROM public.produtos WHERE id = produto_id) = (auth.jwt() ->> 'empresa_id')::uuid
    );
CREATE POLICY "Empresa pode gerenciar fornecedores de seus produtos" ON public.produto_fornecedores
    FOR ALL USING (
        (SELECT empresa_id FROM public.produtos WHERE id = produto_id) = (auth.jwt() ->> 'empresa_id')::uuid
    );

-- 12. Funções RPC (Remote Procedure Call) para CRUD seguro
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
  v_atributo jsonb;
  v_fornecedor jsonb;
BEGIN
  INSERT INTO public.produtos (empresa_id, created_by, nome, tipo, situacao, codigo, codigo_barras, unidade, preco_venda, custo_medio, origem, ncm, cest, controlar_estoque, estoque_inicial, estoque_minimo, estoque_maximo, localizacao, dias_preparacao, controlar_lotes, peso_liquido, peso_bruto, numero_volumes, largura, altura, comprimento, diametro, embalagem_id, marca, modelo, disponibilidade, garantia, video_url, descricao_curta, descricao_complementar, slug, titulo_seo, meta_descricao_seo, observacoes)
  VALUES (
    p_empresa_id,
    auth.uid(),
    p_produto_data->>'nome',
    (p_produto_data->>'tipo')::public.tipo_produto,
    (p_produto_data->>'situacao')::public.situacao_produto,
    p_produto_data->>'codigo',
    p_produto_data->>'codigoBarras',
    p_produto_data->>'unidade',
    (p_produto_data->>'precoVenda')::numeric,
    (p_produto_data->>'custoMedio')::numeric,
    (p_produto_data->>'origem')::public.origem_produto,
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
    (p_produto_data->>'largura')::numeric,
    (p_produto_data->>'altura')::numeric,
    (p_produto_data->>'comprimento')::numeric,
    (p_produto_data->>'diametro')::numeric,
    (p_produto_data->>'embalagemId')::uuid,
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
    p_produto_data->>'observacoes'
  ) RETURNING id INTO v_produto_id;

  IF p_atributos IS NOT NULL THEN
    FOR v_atributo IN SELECT * FROM jsonb_array_elements(p_atributos)
    LOOP
      INSERT INTO public.produto_atributos (produto_id, atributo, valor)
      VALUES (v_produto_id, v_atributo->>'atributo', v_atributo->>'valor');
    END LOOP;
  END IF;

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
  v_empresa_id uuid := (auth.jwt() ->> 'empresa_id')::uuid;
  v_atributo jsonb;
  v_fornecedor jsonb;
BEGIN
  UPDATE public.produtos
  SET
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
    embalagem_id = (p_produto_data->>'embalagemId')::uuid,
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
  WHERE id = p_produto_id AND empresa_id = v_empresa_id;

  DELETE FROM public.produto_atributos WHERE produto_id = p_produto_id;
  IF p_atributos IS NOT NULL THEN
    FOR v_atributo IN SELECT * FROM jsonb_array_elements(p_atributos)
    LOOP
      INSERT INTO public.produto_atributos (produto_id, atributo, valor)
      VALUES (p_produto_id, v_atributo->>'atributo', v_atributo->>'valor');
    END LOOP;
  END IF;

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

CREATE OR REPLACE FUNCTION public.delete_produto(p_id uuid)
RETURNS text[]
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_empresa_id uuid := (auth.jwt() ->> 'empresa_id')::uuid;
  v_image_paths text[];
BEGIN
  SELECT array_agg(storage_path) INTO v_image_paths FROM public.produto_imagens WHERE produto_id = p_id;
  
  DELETE FROM public.produtos WHERE id = p_id AND empresa_id = v_empresa_id;
  
  RETURN v_image_paths;
END;
$$;

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
SET search_path = public, extensions
AS $$
DECLARE
    new_imagem record;
BEGIN
    INSERT INTO public.produto_imagens(produto_id, storage_path, nome_arquivo, content_type, tamanho_bytes)
    VALUES (p_produto_id, p_storage_path, p_filename, p_content_type, p_tamanho_bytes)
    RETURNING * INTO new_imagem;
    
    RETURN row_to_json(new_imagem);
END;
$$;
