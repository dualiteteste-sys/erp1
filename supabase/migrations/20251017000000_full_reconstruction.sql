-- Passo 1: A verdadeira "Terra Arrasada". Remove tudo no esquema public.
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

-- Passo 2: Restaura as permissões padrão para o novo esquema.
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO anon;
GRANT ALL ON SCHEMA public TO authenticated;
GRANT ALL ON SCHEMA public TO service_role;

-- Passo 3: Recriação completa da estrutura do banco de dados.

-- 3.1: Criação dos Tipos (ENUMs)
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

-- 3.2: Criação das Tabelas
CREATE TABLE public.empresas (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    razao_social text NOT NULL,
    nome_completo text,
    fantasia text,
    cep text,
    logradouro text,
    numero text,
    sem_numero boolean DEFAULT false,
    complemento text,
    bairro text,
    cidade text,
    uf text,
    fone text,
    fax text,
    celular text,
    email text,
    website text,
    segmento text,
    tipo_pessoa text,
    cnpj text UNIQUE,
    cpf text UNIQUE,
    ie text,
    ie_isento boolean DEFAULT false,
    im text,
    cnae text,
    crt text,
    preferencias_contato jsonb,
    administrador jsonb,
    logo_url text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.empresas ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.empresa_usuarios (
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    PRIMARY KEY (empresa_id, user_id)
);
ALTER TABLE public.empresa_usuarios ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.clientes_fornecedores (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nome_razao_social text NOT NULL,
    fantasia text,
    tipo_pessoa tipo_pessoa NOT NULL,
    tipo_contato tipo_contato NOT NULL,
    cnpj_cpf text,
    inscricao_estadual text,
    inscricao_municipal text,
    rg text,
    rnm text,
    cep text,
    endereco text,
    numero text,
    complemento text,
    bairro text,
    municipio text,
    uf text,
    cobranca_diferente boolean NOT NULL DEFAULT false,
    cobr_cep text,
    cobr_endereco text,
    cobr_numero text,
    cobr_complemento text,
    cobr_bairro text,
    cobr_municipio text,
    cobr_uf text,
    telefone text,
    telefone_adicional text,
    celular text,
    email text,
    email_nfe text,
    website text,
    observacoes text,
    created_by uuid REFERENCES auth.users(id),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    UNIQUE (empresa_id, cnpj_cpf)
);
ALTER TABLE public.clientes_fornecedores ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.clientes_contatos (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    cliente_fornecedor_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE,
    nome text NOT NULL,
    setor text,
    email text,
    telefone text,
    ramal text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.clientes_contatos ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.clientes_anexos (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    cliente_fornecedor_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE,
    storage_path text NOT NULL,
    filename text NOT NULL,
    content_type text,
    tamanho_bytes bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.clientes_anexos ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.embalagens (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    descricao text NOT NULL,
    tipo tipo_embalagem_produto NOT NULL,
    peso numeric,
    largura numeric,
    altura numeric,
    comprimento numeric,
    diametro numeric,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.embalagens ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.produtos (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nome text NOT NULL,
    tipo tipo_produto NOT NULL,
    situacao situacao_produto NOT NULL,
    codigo text,
    codigo_barras text,
    unidade text NOT NULL,
    preco_venda numeric NOT NULL,
    custo_medio numeric,
    origem origem_produto NOT NULL,
    ncm text,
    cest text,
    controlar_estoque boolean DEFAULT true NOT NULL,
    estoque_inicial numeric,
    estoque_minimo numeric,
    estoque_maximo numeric,
    localizacao text,
    dias_preparacao integer,
    controlar_lotes boolean DEFAULT false,
    peso_liquido numeric,
    peso_bruto numeric,
    numero_volumes integer,
    embalagem_id uuid REFERENCES public.embalagens(id),
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
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    UNIQUE (empresa_id, codigo)
);
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.produto_imagens (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    storage_path text NOT NULL,
    nome_arquivo text NOT NULL,
    tamanho_bytes bigint,
    content_type text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.produto_imagens ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.produto_atributos (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    atributo text NOT NULL,
    valor text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    UNIQUE (produto_id, atributo)
);
ALTER TABLE public.produto_atributos ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.produto_fornecedores (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
    fornecedor_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE,
    codigo_no_fornecedor text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    UNIQUE (produto_id, fornecedor_id)
);
ALTER TABLE public.produto_fornecedores ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.servicos (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    descricao text NOT NULL,
    preco numeric NOT NULL,
    situacao situacao_servico NOT NULL,
    codigo text,
    unidade text,
    codigo_servico text,
    nbs text,
    descricao_complementar text,
    observacoes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.servicos ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.vendedores (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nome text NOT NULL,
    fantasia text,
    codigo text,
    tipo_pessoa tipo_pessoa_vendedor NOT NULL,
    cpf_cnpj text,
    documento_identificacao text,
    pais text,
    contribuinte_icms tipo_contribuinte_icms,
    inscricao_estadual text,
    situacao situacao_vendedor NOT NULL,
    cep text,
    logradouro text,
    numero text,
    complemento text,
    bairro text,
    cidade text,
    uf text,
    telefone text,
    celular text,
    email text UNIQUE,
    email_comunicacao text,
    deposito_padrao text,
    acesso_restrito_horario boolean DEFAULT false,
    acesso_restrito_ip text,
    perfil_contato text[],
    permissoes_modulos jsonb,
    regra_liberacao_comissao regra_liberacao_comissao,
    tipo_comissao tipo_comissao,
    aliquota_comissao numeric,
    desconsiderar_comissionamento_linhas_produto boolean DEFAULT false,
    observacoes_comissao text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.vendedores ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.vendedores_contatos (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    vendedor_id uuid NOT NULL REFERENCES public.vendedores(id) ON DELETE CASCADE,
    nome text NOT NULL,
    setor text,
    email text,
    telefone text,
    ramal text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.vendedores_contatos ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.papeis (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nome text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    UNIQUE(empresa_id, nome)
);
ALTER TABLE public.papeis ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.papel_permissoes (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    papel_id uuid NOT NULL REFERENCES public.papeis(id) ON DELETE CASCADE,
    permissao_id text NOT NULL,
    UNIQUE(papel_id, permissao_id)
);
ALTER TABLE public.papel_permissoes ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.categorias_financeiras (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    descricao text NOT NULL,
    tipo tipo_categoria_financeira NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.categorias_financeiras ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.formas_pagamento (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    descricao text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.formas_pagamento ENABLE ROW LEVEL SECURITY;

-- 3.3: Funções Auxiliares e de Segurança
CREATE OR REPLACE FUNCTION private.get_empresa_id_for_user(p_user_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN (SELECT empresa_id FROM empresa_usuarios WHERE user_id = p_user_id LIMIT 1);
END;
$$;

CREATE OR REPLACE FUNCTION private.is_member_of_empresa(p_user_id uuid, p_empresa_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM empresa_usuarios
    WHERE empresa_id = p_empresa_id AND user_id = p_user_id
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_empresa_id uuid;
  v_cpf text;
BEGIN
  -- Tenta extrair o CPF do metadata
  v_cpf := NEW.raw_user_meta_data ->> 'cpf_cnpj';

  -- Cria uma nova empresa para o usuário
  INSERT INTO public.empresas (razao_social, cpf)
  VALUES (NEW.raw_user_meta_data ->> 'fullName', v_cpf)
  RETURNING id INTO v_empresa_id;

  -- Vincula o usuário à nova empresa
  INSERT INTO public.empresa_usuarios (empresa_id, user_id)
  VALUES (v_empresa_id, NEW.id);

  RETURN NEW;
END;
$$;

-- 3.4: Gatilhos (Triggers)
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 3.5: Políticas de Segurança (RLS)
-- Empresas
CREATE POLICY "Membros podem ver sua própria empresa" ON public.empresas FOR SELECT USING (private.is_member_of_empresa(auth.uid(), id));
CREATE POLICY "Membros podem atualizar sua própria empresa" ON public.empresas FOR UPDATE USING (private.is_member_of_empresa(auth.uid(), id));
-- EmpresaUsuarios
CREATE POLICY "Usuários podem ver seus próprios vínculos" ON public.empresa_usuarios FOR SELECT USING (user_id = auth.uid());
-- Demais tabelas
CREATE POLICY "Acesso total para membros da empresa" ON public.clientes_fornecedores FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));
CREATE POLICY "Acesso total para membros da empresa" ON public.clientes_contatos FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));
CREATE POLICY "Acesso total para membros da empresa" ON public.clientes_anexos FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));
CREATE POLICY "Acesso total para membros da empresa" ON public.embalagens FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));
CREATE POLICY "Acesso total para membros da empresa" ON public.produtos FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));
CREATE POLICY "Acesso total para membros da empresa" ON public.produto_imagens FOR ALL USING (EXISTS (SELECT 1 FROM produtos WHERE produtos.id = produto_imagens.produto_id AND private.is_member_of_empresa(auth.uid(), produtos.empresa_id)));
CREATE POLICY "Acesso total para membros da empresa" ON public.produto_atributos FOR ALL USING (EXISTS (SELECT 1 FROM produtos WHERE produtos.id = produto_atributos.produto_id AND private.is_member_of_empresa(auth.uid(), produtos.empresa_id)));
CREATE POLICY "Acesso total para membros da empresa" ON public.produto_fornecedores FOR ALL USING (EXISTS (SELECT 1 FROM produtos WHERE produtos.id = produto_fornecedores.produto_id AND private.is_member_of_empresa(auth.uid(), produtos.empresa_id)));
CREATE POLICY "Acesso total para membros da empresa" ON public.servicos FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));
CREATE POLICY "Acesso total para membros da empresa" ON public.vendedores FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));
CREATE POLICY "Acesso total para membros da empresa" ON public.vendedores_contatos FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));
CREATE POLICY "Acesso total para membros da empresa" ON public.papeis FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));
CREATE POLICY "Acesso total para membros da empresa" ON public.papel_permissoes FOR ALL USING (EXISTS (SELECT 1 FROM papeis WHERE papeis.id = papel_permissoes.papel_id AND private.is_member_of_empresa(auth.uid(), papeis.empresa_id)));
CREATE POLICY "Acesso total para membros da empresa" ON public.categorias_financeiras FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));
CREATE POLICY "Acesso total para membros da empresa" ON public.formas_pagamento FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));

-- 3.6: Storage Buckets e Políticas
INSERT INTO storage.buckets (id, name, public)
VALUES ('logos', 'logos', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('clientes_anexos', 'clientes_anexos', false)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('produto-imagens', 'produto-imagens', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Permite acesso público a logos" ON storage.objects;
CREATE POLICY "Permite acesso público a logos" ON storage.objects FOR SELECT USING (bucket_id = 'logos');

DROP POLICY IF EXISTS "Permite acesso a imagens de produtos" ON storage.objects;
CREATE POLICY "Permite acesso a imagens de produtos" ON storage.objects FOR SELECT USING (bucket_id = 'produto-imagens');

DROP POLICY IF EXISTS "Permite acesso a anexos de clientes" ON storage.objects;
CREATE POLICY "Permite acesso a anexos de clientes" ON storage.objects FOR ALL USING (
  bucket_id = 'clientes_anexos' AND
  private.is_member_of_empresa(auth.uid(), (storage.foldername(name))[1]::uuid)
);
