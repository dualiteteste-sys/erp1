-- Passo 1: Limpeza Cirúrgica de Funções Duplicadas
-- Remove ambiguidades que impediram a limpeza anterior.
DROP FUNCTION IF EXISTS public.create_produto_imagem(uuid, text, text, text, bigint) CASCADE;
DROP FUNCTION IF EXISTS public.create_cliente_fornecedor_completo(uuid, jsonb, jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.update_cliente_fornecedor_completo(uuid, jsonb, jsonb) CASCADE;

-- Passo 2: "Terra Arrasada" Segura
-- Remove todas as tabelas, tipos e funções do esquema public para garantir um estado limpo.
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT USAGE ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO anon;
GRANT ALL ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO service_role;
GRANT ALL ON SCHEMA public TO service_role;

-- Passo 3: Reconstrução Completa do Backend

-- Tipos ENUM
CREATE TYPE public.tipo_pessoa AS ENUM ('PF', 'PJ');
CREATE TYPE public.tipo_contato AS ENUM ('cliente', 'fornecedor', 'ambos');
CREATE TYPE public.tipo_produto AS ENUM ('Simples', 'Com variações', 'Kit', 'Fabricado', 'Matéria Prima');
CREATE TYPE public.situacao_produto AS ENUM ('Ativo', 'Inativo');
CREATE TYPE public.origem_produto AS ENUM ('0 - Nacional', '1 - Estrangeira (Imp. Direta)', '2 - Estrangeira (Merc. Interno)', '3 - Nacional (Imp. > 40%)', '4 - Nacional (Proc. Básico)', '5 - Nacional (Imp. <= 40%)', '6 - Estrangeira (Imp. Direta, s/ similar)', '7 - Estrangeira (Merc. Interno, s/ similar)', '8 - Nacional (Imp. > 70%)');
CREATE TYPE public.tipo_embalagem_produto AS ENUM ('Caixa', 'Rolo / Cilindro', 'Envelope', 'Fardo');
CREATE TYPE public.situacao_servico AS ENUM ('Ativo', 'Inativo');
CREATE TYPE public.situacao_vendedor AS ENUM ('Ativo com acesso ao sistema', 'Ativo sem acesso ao sistema', 'Inativo');
CREATE TYPE public.tipo_pessoa_vendedor AS ENUM ('Pessoa Física', 'Pessoa Jurídica', 'Estrangeiro', 'Estrangeiro no Brasil');
CREATE TYPE public.tipo_contribuinte_icms AS ENUM ('Contribuinte ICMS', 'Contribuinte Isento', 'Não Contribuinte');
CREATE TYPE public.regra_liberacao_comissao AS ENUM ('Liberação parcial vinculada ao pagamento de parcelas', 'Liberação integral no faturamento');
CREATE TYPE public.tipo_comissao AS ENUM ('fixa', 'variavel');
CREATE TYPE public.tipo_categoria_financeira AS ENUM ('RECEITA', 'DESPESA');

-- Tabela de Empresas
CREATE TABLE public.empresas (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    razao_social text NOT NULL,
    fantasia text,
    cnpj text UNIQUE,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    logo_url text
);
ALTER TABLE public.empresas ENABLE ROW LEVEL SECURITY;

-- Tabela de Junção: Empresa <-> Usuários
CREATE TABLE public.empresa_usuarios (
    empresa_id uuid REFERENCES public.empresas(id) ON DELETE CASCADE NOT NULL,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    PRIMARY KEY (empresa_id, user_id)
);
ALTER TABLE public.empresa_usuarios ENABLE ROW LEVEL SECURITY;

-- Tabela de Clientes e Fornecedores
CREATE TABLE public.clientes_fornecedores (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid REFERENCES public.empresas(id) ON DELETE CASCADE NOT NULL,
    nome_razao_social text NOT NULL,
    fantasia text,
    tipo_pessoa tipo_pessoa NOT NULL,
    tipo_contato tipo_contato NOT NULL,
    cnpj_cpf text,
    rg text,
    rnm text,
    inscricao_estadual text,
    inscricao_municipal text,
    cep text,
    endereco text,
    numero text,
    complemento text,
    bairro text,
    municipio text,
    uf text,
    cobranca_diferente boolean DEFAULT false NOT NULL,
    cobr_cep text,
    cobr_endereco text,
    cobr_numero text,
    cobr_complemento text,
    cobr_bairro text,
    cobr_municipio text,
    cobr_uf text,
    telefone text,
    celular text,
    email text,
    email_nfe text,
    website text,
    observacoes text,
    created_by uuid REFERENCES auth.users(id),
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
ALTER TABLE public.clientes_fornecedores ENABLE ROW LEVEL SECURITY;

-- Tabela de Contatos Adicionais (Clientes)
CREATE TABLE public.clientes_contatos (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid REFERENCES public.empresas(id) ON DELETE CASCADE NOT NULL,
    cliente_fornecedor_id uuid REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE NOT NULL,
    nome text NOT NULL,
    setor text,
    email text,
    telefone text,
    ramal text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
ALTER TABLE public.clientes_contatos ENABLE ROW LEVEL SECURITY;

-- Tabela de Anexos (Clientes)
CREATE TABLE public.clientes_anexos (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid REFERENCES public.empresas(id) ON DELETE CASCADE NOT NULL,
    cliente_fornecedor_id uuid REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE NOT NULL,
    storage_path text NOT NULL,
    filename text NOT NULL,
    content_type text,
    tamanho_bytes bigint,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
ALTER TABLE public.clientes_anexos ENABLE ROW LEVEL SECURITY;

-- Tabela de Produtos
CREATE TABLE public.produtos (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid REFERENCES public.empresas(id) ON DELETE CASCADE NOT NULL,
    nome text NOT NULL,
    tipo tipo_produto NOT NULL,
    situacao situacao_produto NOT NULL,
    codigo text,
    codigo_barras text,
    unidade text,
    preco_venda numeric NOT NULL,
    custo_medio numeric,
    origem origem_produto,
    ncm text,
    cest text,
    controlar_estoque boolean DEFAULT true,
    estoque_minimo numeric,
    estoque_maximo numeric,
    localizacao text,
    dias_preparacao integer,
    controlar_lotes boolean,
    peso_liquido numeric,
    peso_bruto numeric,
    numero_volumes integer,
    embalagem_id uuid,
    largura numeric,
    altura numeric,
    comprimento numeric,
    diametro numeric,
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
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    UNIQUE (empresa_id, codigo)
);
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;

-- Tabela de Imagens de Produtos
CREATE TABLE public.produto_imagens (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    produto_id uuid REFERENCES public.produtos(id) ON DELETE CASCADE NOT NULL,
    storage_path text NOT NULL,
    nome_arquivo text NOT NULL,
    content_type text,
    tamanho_bytes bigint,
    created_at timestamptz DEFAULT now() NOT NULL
);
ALTER TABLE public.produto_imagens ENABLE ROW LEVEL SECURITY;

-- Tabela de Vendedores
CREATE TABLE public.vendedores (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid REFERENCES public.empresas(id) ON DELETE CASCADE NOT NULL,
    nome text NOT NULL,
    fantasia text,
    codigo text,
    tipo_pessoa tipo_pessoa_vendedor,
    cpf_cnpj text,
    documento_identificacao text,
    pais text,
    contribuinte_icms tipo_contribuinte_icms,
    inscricao_estadual text,
    situacao situacao_vendedor,
    cep text,
    logradouro text,
    numero text,
    complemento text,
    bairro text,
    cidade text,
    uf text,
    telefone text,
    celular text,
    email text,
    email_comunicacao text,
    deposito_padrao text,
    acesso_restrito_horario boolean,
    acesso_restrito_ip text,
    perfil_contato text[],
    permissoes_modulos jsonb,
    regra_liberacao_comissao regra_liberacao_comissao,
    tipo_comissao tipo_comissao,
    aliquota_comissao numeric,
    desconsiderar_comissionamento_linhas_produto boolean,
    observacoes_comissao text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
ALTER TABLE public.vendedores ENABLE ROW LEVEL SECURITY;

-- Tabela de Contatos Adicionais (Vendedores)
CREATE TABLE public.vendedores_contatos (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    vendedor_id uuid REFERENCES public.vendedores(id) ON DELETE CASCADE NOT NULL,
    nome text NOT NULL,
    setor text,
    email text,
    telefone text,
    ramal text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
ALTER TABLE public.vendedores_contatos ENABLE ROW LEVEL SECURITY;

-- Tabela de Serviços
CREATE TABLE public.servicos (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid REFERENCES public.empresas(id) ON DELETE CASCADE NOT NULL,
    descricao text NOT NULL,
    preco numeric NOT NULL,
    situacao situacao_servico NOT NULL,
    codigo text,
    unidade text,
    codigo_servico text,
    nbs text,
    descricao_complementar text,
    observacoes text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
ALTER TABLE public.servicos ENABLE ROW LEVEL SECURITY;

-- Tabela de Embalagens
CREATE TABLE public.embalagens (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid REFERENCES public.empresas(id) ON DELETE CASCADE NOT NULL,
    descricao text NOT NULL,
    tipo tipo_embalagem_produto,
    peso numeric,
    largura numeric,
    altura numeric,
    comprimento numeric,
    diametro numeric,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
ALTER TABLE public.embalagens ENABLE ROW LEVEL SECURITY;

-- Tabela de Papéis (Roles)
CREATE TABLE public.papeis (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid REFERENCES public.empresas(id) ON DELETE CASCADE NOT NULL,
    nome text NOT NULL,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
ALTER TABLE public.papeis ENABLE ROW LEVEL SECURITY;

-- Tabela de Junção: Papel <-> Permissões
CREATE TABLE public.papel_permissoes (
    papel_id uuid REFERENCES public.papeis(id) ON DELETE CASCADE NOT NULL,
    permissao_id text NOT NULL,
    PRIMARY KEY (papel_id, permissao_id)
);
ALTER TABLE public.papel_permissoes ENABLE ROW LEVEL SECURITY;

-- Tabela de Categorias Financeiras
CREATE TABLE public.categorias_financeiras (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid REFERENCES public.empresas(id) ON DELETE CASCADE NOT NULL,
    descricao text NOT NULL,
    tipo tipo_categoria_financeira NOT NULL,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
ALTER TABLE public.categorias_financeiras ENABLE ROW LEVEL SECURITY;

-- Tabela de Formas de Pagamento
CREATE TABLE public.formas_pagamento (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid REFERENCES public.empresas(id) ON DELETE CASCADE NOT NULL,
    descricao text NOT NULL,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);
ALTER TABLE public.formas_pagamento ENABLE ROW LEVEL SECURITY;

-- Storage Buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('logos', 'logos', true, 2097152, '{"image/png", "image/jpeg", "image/svg+xml"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('clientes_anexos', 'clientes_anexos', false, 2097152, NULL)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('produto-imagens', 'produto-imagens', true, 2097152, '{"image/png", "image/jpeg", "image/webp", "image/gif"}')
ON CONFLICT (id) DO NOTHING;

-- Políticas de Acesso ao Storage
DROP POLICY IF EXISTS "Permite acesso público a logos" ON storage.objects;
CREATE POLICY "Permite acesso público a logos" ON storage.objects FOR SELECT USING (bucket_id = 'logos');

DROP POLICY IF EXISTS "Permite acesso a anexos para membros da empresa" ON storage.objects;
CREATE POLICY "Permite acesso a anexos para membros da empresa" ON storage.objects FOR ALL USING (
  bucket_id = 'clientes_anexos' AND auth.uid() IS NOT NULL AND
  (storage.foldername(name))[1] IN (
    SELECT e.id::text FROM public.empresas e JOIN public.empresa_usuarios eu ON e.id = eu.empresa_id WHERE eu.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Permite acesso público a imagens de produtos" ON storage.objects;
CREATE POLICY "Permite acesso público a imagens de produtos" ON storage.objects FOR SELECT USING (bucket_id = 'produto-imagens');

DROP POLICY IF EXISTS "Permite upload de imagens de produtos para membros" ON storage.objects;
CREATE POLICY "Permite upload de imagens de produtos para membros" ON storage.objects FOR INSERT WITH CHECK (
  bucket_id = 'produto-imagens' AND auth.uid() IS NOT NULL AND
  (storage.foldername(name))[1] IN (
    SELECT e.id::text FROM public.empresas e JOIN public.empresa_usuarios eu ON e.id = eu.empresa_id WHERE eu.user_id = auth.uid()
  )
);

-- Funções Auxiliares
CREATE OR REPLACE FUNCTION private.get_empresa_id_for_user(p_user_id uuid)
RETURNS uuid AS $$
BEGIN
  RETURN (SELECT empresa_id FROM public.empresa_usuarios WHERE user_id = p_user_id LIMIT 1);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION private.get_empresa_id_for_user(uuid) SET search_path = '';

CREATE OR REPLACE FUNCTION public.is_member_of_empresa(p_empresa_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.empresa_usuarios eu
    WHERE eu.empresa_id = p_empresa_id AND eu.user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.is_member_of_empresa(uuid) SET search_path = '';

-- Função para criar empresa e vincular usuário
CREATE OR REPLACE FUNCTION public.create_empresa_and_link_owner(p_razao_social text, p_fantasia text, p_cnpj text)
RETURNS uuid AS $$
DECLARE
  new_empresa_id uuid;
BEGIN
  INSERT INTO public.empresas (razao_social, fantasia, cnpj)
  VALUES (p_razao_social, p_fantasia, p_cnpj)
  RETURNING id INTO new_empresa_id;

  INSERT INTO public.empresa_usuarios (empresa_id, user_id)
  VALUES (new_empresa_id, auth.uid());

  RETURN new_empresa_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.create_empresa_and_link_owner(text, text, text) SET search_path = '';

-- Função para criar imagem de produto
CREATE OR REPLACE FUNCTION public.create_produto_imagem(p_produto_id uuid, p_storage_path text, p_filename text, p_content_type text, p_tamanho_bytes bigint)
RETURNS uuid AS $$
DECLARE
  new_imagem_id uuid;
BEGIN
  INSERT INTO public.produto_imagens (produto_id, storage_path, nome_arquivo, content_type, tamanho_bytes)
  VALUES (p_produto_id, p_storage_path, p_filename, p_content_type, p_tamanho_bytes)
  RETURNING id INTO new_imagem_id;
  RETURN new_imagem_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.create_produto_imagem(uuid, text, text, text, bigint) SET search_path = '';

-- Gatilho para criar perfil de usuário
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  empresa_id_do_convite uuid;
BEGIN
  -- Tenta encontrar um convite para este e-mail
  SELECT empresa_id INTO empresa_id_do_convite
  FROM public.vendedores
  WHERE email = new.email
  LIMIT 1;

  -- Se encontrou, vincula o usuário à empresa do convite
  IF empresa_id_do_convite IS NOT NULL THEN
    INSERT INTO public.empresa_usuarios (user_id, empresa_id)
    VALUES (new.id, empresa_id_do_convite);
  END IF;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.handle_new_user() SET search_path = '';

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Políticas de RLS
CREATE POLICY "Enable read access for members" ON public.empresas FOR SELECT USING (is_member_of_empresa(id));
CREATE POLICY "Enable insert for authenticated users" ON public.empresas FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Enable update for members" ON public.empresas FOR UPDATE USING (is_member_of_empresa(id));
CREATE POLICY "Enable delete for members" ON public.empresas FOR DELETE USING (is_member_of_empresa(id));

CREATE POLICY "Enable access for members" ON public.empresa_usuarios FOR ALL USING (is_member_of_empresa(empresa_id));

CREATE POLICY "Enable access for members" ON public.clientes_fornecedores FOR ALL USING (is_member_of_empresa(empresa_id));
CREATE POLICY "Enable access for members" ON public.clientes_contatos FOR ALL USING (is_member_of_empresa(empresa_id));
CREATE POLICY "Enable access for members" ON public.clientes_anexos FOR ALL USING (is_member_of_empresa(empresa_id));
CREATE POLICY "Enable access for members" ON public.produtos FOR ALL USING (is_member_of_empresa(empresa_id));
CREATE POLICY "Enable access for members" ON public.produto_imagens FOR ALL USING (EXISTS (SELECT 1 FROM produtos p WHERE p.id = produto_id AND is_member_of_empresa(p.empresa_id)));
CREATE POLICY "Enable access for members" ON public.vendedores FOR ALL USING (is_member_of_empresa(empresa_id));
CREATE POLICY "Enable access for members" ON public.vendedores_contatos FOR ALL USING (EXISTS (SELECT 1 FROM vendedores v WHERE v.id = vendedor_id AND is_member_of_empresa(v.empresa_id)));
CREATE POLICY "Enable access for members" ON public.servicos FOR ALL USING (is_member_of_empresa(empresa_id));
CREATE POLICY "Enable access for members" ON public.embalagens FOR ALL USING (is_member_of_empresa(empresa_id));
CREATE POLICY "Enable access for members" ON public.papeis FOR ALL USING (is_member_of_empresa(empresa_id));
CREATE POLICY "Enable access for members" ON public.papel_permissoes FOR ALL USING (EXISTS (SELECT 1 FROM papeis p WHERE p.id = papel_id AND is_member_of_empresa(p.empresa_id)));
CREATE POLICY "Enable access for members" ON public.categorias_financeiras FOR ALL USING (is_member_of_empresa(empresa_id));
CREATE POLICY "Enable access for members" ON public.formas_pagamento FOR ALL USING (is_member_of_empresa(empresa_id));
