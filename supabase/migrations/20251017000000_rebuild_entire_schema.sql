-- =================================================================
--  Reconstrução Completa do Schema
--  Este script recria toda a estrutura do banco de dados a partir
--  do zero, com base no código estável do frontend.
-- =================================================================

-- Parte 1: Funções Auxiliares e de Segurança
-- =================================================================

-- Função para obter o ID da empresa do usuário logado
CREATE OR REPLACE FUNCTION private.get_empresa_id_for_user(p_user_id uuid)
RETURNS uuid AS $$
DECLARE
  v_empresa_id uuid;
BEGIN
  SELECT empresa_id INTO v_empresa_id
  FROM public.empresa_usuarios
  WHERE user_id = p_user_id
  LIMIT 1;
  
  RETURN v_empresa_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION private.get_empresa_id_for_user(uuid) SET search_path = 'public';

-- Função para verificar se o usuário pertence a uma empresa
CREATE OR REPLACE FUNCTION public.is_member_of_empresa(p_empresa_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.empresa_usuarios
    WHERE user_id = auth.uid() AND empresa_id = p_empresa_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.is_member_of_empresa(uuid) SET search_path = 'public';

-- Parte 2: Gatilho de Novo Usuário (Sign Up)
-- =================================================================

-- Função para criar a primeira empresa e associar ao novo usuário
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_empresa_id uuid;
  v_user_id uuid;
BEGIN
  v_user_id := NEW.id;

  -- Cria a empresa com os dados do usuário
  INSERT INTO public.empresas (razao_social, fantasia, cnpj, created_by)
  VALUES (
    NEW.raw_user_meta_data->>'fullName',
    NEW.raw_user_meta_data->>'fullName',
    NEW.raw_user_meta_data->>'cpf_cnpj',
    v_user_id
  ) RETURNING id INTO v_empresa_id;

  -- Associa o usuário à nova empresa
  INSERT INTO public.empresa_usuarios (empresa_id, user_id)
  VALUES (v_empresa_id, v_user_id);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.handle_new_user() SET search_path = 'public';

-- Cria o gatilho que chama a função acima após um novo usuário ser criado
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Parte 3: Tipos de Dados Personalizados (ENUMs)
-- =================================================================

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
CREATE TYPE public.crm_etapa_funil AS ENUM ('Prospecção', 'Qualificação', 'Proposta', 'Negociação', 'Fechamento');
CREATE TYPE public.crm_status_oportunidade AS ENUM ('Em Aberto', 'Ganha', 'Perdida', 'Cancelada');
CREATE TYPE public.status_pedido_venda AS ENUM ('Aberto', 'Atendido', 'Cancelado', 'Faturado');
CREATE TYPE public.frete_por_conta AS ENUM ('CIF', 'FOB');
CREATE TYPE public.tipo_categoria_financeira AS ENUM ('RECEITA', 'DESPESA');

-- Parte 4: Criação das Tabelas
-- =================================================================

-- Tabela de Papeis e Permissões
CREATE TABLE public.papeis (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
  nome text NOT NULL,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT papeis_empresa_id_nome_key UNIQUE (empresa_id, nome)
);
CREATE TABLE public.papel_permissoes (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  papel_id uuid NOT NULL REFERENCES public.papeis(id) ON DELETE CASCADE,
  permissao_id text NOT NULL,
  created_at timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT papel_permissoes_papel_id_permissao_id_key UNIQUE (papel_id, permissao_id)
);

-- Tabela de Clientes e Fornecedores
CREATE TABLE public.clientes_fornecedores (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
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
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL,
  UNIQUE (empresa_id, cnpj_cpf)
);
CREATE TABLE public.clientes_contatos (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
  cliente_fornecedor_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE,
  nome text NOT NULL,
  setor text,
  email text,
  telefone text,
  ramal text,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TABLE public.clientes_anexos (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
  cliente_fornecedor_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE,
  storage_path text NOT NULL,
  filename text NOT NULL,
  content_type text,
  tamanho_bytes bigint,
  created_at timestamptz DEFAULT now() NOT NULL
);

-- Tabela de Embalagens
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
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- Tabela de Produtos
CREATE TABLE public.produtos (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
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
  controlar_estoque boolean NOT NULL DEFAULT true,
  estoque_inicial numeric,
  estoque_minimo numeric,
  estoque_maximo numeric,
  localizacao text,
  dias_preparacao integer,
  controlar_lotes boolean DEFAULT false,
  estoque_atual numeric,
  peso_liquido numeric,
  peso_bruto numeric,
  numero_volumes integer,
  embalagem_id uuid REFERENCES public.embalagens(id) ON DELETE SET NULL,
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
  UNIQUE(empresa_id, codigo)
);
CREATE TABLE public.produto_imagens (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
  storage_path text NOT NULL,
  nome_arquivo text NOT NULL,
  tamanho_bytes bigint,
  content_type text,
  created_at timestamptz DEFAULT now() NOT NULL
);
CREATE TABLE public.produto_atributos (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
  atributo text NOT NULL,
  valor text,
  created_at timestamptz DEFAULT now() NOT NULL,
  UNIQUE(produto_id, atributo)
);
CREATE TABLE public.produto_fornecedores (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  produto_id uuid NOT NULL REFERENCES public.produtos(id) ON DELETE CASCADE,
  fornecedor_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE,
  codigo_no_fornecedor text,
  created_at timestamptz DEFAULT now() NOT NULL,
  UNIQUE(produto_id, fornecedor_id)
);

-- Tabela de Serviços
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
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- Tabela de Vendedores
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
  email text,
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
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL,
  UNIQUE(empresa_id, email)
);
CREATE TABLE public.vendedores_contatos (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  vendedor_id uuid NOT NULL REFERENCES public.vendedores(id) ON DELETE CASCADE,
  nome text NOT NULL,
  setor text,
  email text,
  telefone text,
  ramal text,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- Tabelas de CRM
CREATE TABLE public.crm_oportunidades (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
  titulo text NOT NULL,
  valor numeric NOT NULL,
  etapa_funil crm_etapa_funil NOT NULL,
  status crm_status_oportunidade NOT NULL,
  data_fechamento_prevista date,
  data_fechamento_real date,
  cliente_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE,
  vendedor_id uuid REFERENCES public.vendedores(id) ON DELETE SET NULL,
  observacoes text,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TABLE public.crm_oportunidade_itens (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  oportunidade_id uuid NOT NULL REFERENCES public.crm_oportunidades(id) ON DELETE CASCADE,
  produto_id uuid REFERENCES public.produtos(id) ON DELETE SET NULL,
  servico_id uuid REFERENCES public.servicos(id) ON DELETE SET NULL,
  descricao text NOT NULL,
  quantidade numeric NOT NULL,
  valor_unitario numeric NOT NULL,
  valor_total numeric NOT NULL,
  created_at timestamptz DEFAULT now() NOT NULL
);

-- Tabelas de Pedidos de Venda
CREATE TABLE public.pedidos_vendas (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
  numero serial NOT NULL,
  cliente_id uuid NOT NULL REFERENCES public.clientes_fornecedores(id) ON DELETE CASCADE,
  vendedor_id uuid REFERENCES public.vendedores(id) ON DELETE SET NULL,
  natureza_operacao text NOT NULL,
  status status_pedido_venda NOT NULL,
  data_venda date NOT NULL,
  data_prevista_entrega date,
  valor_total numeric NOT NULL,
  desconto numeric,
  frete_por_conta frete_por_conta,
  valor_frete numeric,
  transportadora_id uuid REFERENCES public.clientes_fornecedores(id) ON DELETE SET NULL,
  observacoes text,
  observacoes_internas text,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TABLE public.pedidos_vendas_itens (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  pedido_venda_id uuid NOT NULL REFERENCES public.pedidos_vendas(id) ON DELETE CASCADE,
  produto_id uuid REFERENCES public.produtos(id) ON DELETE SET NULL,
  servico_id uuid REFERENCES public.servicos(id) ON DELETE SET NULL,
  descricao text NOT NULL,
  quantidade numeric NOT NULL,
  valor_unitario numeric NOT NULL,
  valor_total numeric NOT NULL,
  created_at timestamptz DEFAULT now() NOT NULL
);

-- Tabelas Financeiras
CREATE TABLE public.categorias_financeiras (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
  descricao text NOT NULL,
  tipo tipo_categoria_financeira NOT NULL,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);
CREATE TABLE public.formas_pagamento (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  empresa_id uuid NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
  descricao text NOT NULL,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- Parte 5: Políticas de Segurança (RLS)
-- =================================================================

ALTER TABLE public.papeis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.papel_permissoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clientes_fornecedores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clientes_contatos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clientes_anexos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.embalagens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produto_imagens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produto_atributos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produto_fornecedores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.servicos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendedores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendedores_contatos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crm_oportunidades ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crm_oportunidade_itens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos_vendas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos_vendas_itens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categorias_financeiras ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.formas_pagamento ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Permite acesso total para membros da empresa" ON public.papeis FOR ALL USING (is_member_of_empresa(empresa_id));
CREATE POLICY "Permite acesso total para membros da empresa" ON public.clientes_fornecedores FOR ALL USING (is_member_of_empresa(empresa_id));
CREATE POLICY "Permite acesso total para membros da empresa" ON public.clientes_contatos FOR ALL USING (is_member_of_empresa(empresa_id));
CREATE POLICY "Permite acesso total para membros da empresa" ON public.clientes_anexos FOR ALL USING (is_member_of_empresa(empresa_id));
CREATE POLICY "Permite acesso total para membros da empresa" ON public.embalagens FOR ALL USING (is_member_of_empresa(empresa_id));
CREATE POLICY "Permite acesso total para membros da empresa" ON public.produtos FOR ALL USING (is_member_of_empresa(empresa_id));
CREATE POLICY "Permite acesso total para membros da empresa" ON public.servicos FOR ALL USING (is_member_of_empresa(empresa_id));
CREATE POLICY "Permite acesso total para membros da empresa" ON public.vendedores FOR ALL USING (is_member_of_empresa(empresa_id));
CREATE POLICY "Permite acesso total para membros da empresa" ON public.crm_oportunidades FOR ALL USING (is_member_of_empresa(empresa_id));
CREATE POLICY "Permite acesso total para membros da empresa" ON public.pedidos_vendas FOR ALL USING (is_member_of_empresa(empresa_id));
CREATE POLICY "Permite acesso total para membros da empresa" ON public.categorias_financeiras FOR ALL USING (is_member_of_empresa(empresa_id));
CREATE POLICY "Permite acesso total para membros da empresa" ON public.formas_pagamento FOR ALL USING (is_member_of_empresa(empresa_id));

CREATE POLICY "Permite acesso se for membro da empresa do papel" ON public.papel_permissoes FOR ALL USING (
  EXISTS (
    SELECT 1 FROM papeis p
    WHERE p.id = papel_permissoes.papel_id AND is_member_of_empresa(p.empresa_id)
  )
);
CREATE POLICY "Permite acesso se for membro da empresa do produto" ON public.produto_imagens FOR ALL USING (
  EXISTS (
    SELECT 1 FROM produtos p
    WHERE p.id = produto_imagens.produto_id AND is_member_of_empresa(p.empresa_id)
  )
);
CREATE POLICY "Permite acesso se for membro da empresa do produto" ON public.produto_atributos FOR ALL USING (
  EXISTS (
    SELECT 1 FROM produtos p
    WHERE p.id = produto_atributos.produto_id AND is_member_of_empresa(p.empresa_id)
  )
);
CREATE POLICY "Permite acesso se for membro da empresa do produto" ON public.produto_fornecedores FOR ALL USING (
  EXISTS (
    SELECT 1 FROM produtos p
    WHERE p.id = produto_fornecedores.produto_id AND is_member_of_empresa(p.empresa_id)
  )
);
CREATE POLICY "Permite acesso se for membro da empresa do vendedor" ON public.vendedores_contatos FOR ALL USING (
  EXISTS (
    SELECT 1 FROM vendedores v
    WHERE v.id = vendedores_contatos.vendedor_id AND is_member_of_empresa(v.empresa_id)
  )
);
CREATE POLICY "Permite acesso se for membro da empresa da oportunidade" ON public.crm_oportunidade_itens FOR ALL USING (
  EXISTS (
    SELECT 1 FROM crm_oportunidades o
    WHERE o.id = crm_oportunidade_itens.oportunidade_id AND is_member_of_empresa(o.empresa_id)
  )
);
CREATE POLICY "Permite acesso se for membro da empresa do pedido" ON public.pedidos_vendas_itens FOR ALL USING (
  EXISTS (
    SELECT 1 FROM pedidos_vendas pv
    WHERE pv.id = pedidos_vendas_itens.pedido_venda_id AND is_member_of_empresa(pv.empresa_id)
  )
);

-- Parte 6: Storage Buckets e Políticas
-- =================================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('logos', 'logos', true, 2097152, '{"image/png", "image/jpeg", "image/svg+xml"}'),
  ('clientes_anexos', 'clientes_anexos', false, 2097152, NULL),
  ('produto-imagens', 'produto-imagens', true, 2097152, '{"image/png", "image/jpeg", "image/webp", "image/gif"}')
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Permite acesso público a logos" ON storage.objects FOR SELECT TO anon, authenticated USING (bucket_id = 'logos');
CREATE POLICY "Permite acesso a membros da empresa para anexos de clientes" ON storage.objects FOR SELECT USING (
  bucket_id = 'clientes_anexos' AND is_member_of_empresa((storage.foldername(name))[1]::uuid)
);
CREATE POLICY "Permite upload a membros da empresa para anexos de clientes" ON storage.objects FOR INSERT WITH CHECK (
  bucket_id = 'clientes_anexos' AND is_member_of_empresa((storage.foldername(name))[1]::uuid)
);
CREATE POLICY "Permite delete a membros da empresa para anexos de clientes" ON storage.objects FOR DELETE USING (
  bucket_id = 'clientes_anexos' AND is_member_of_empresa((storage.foldername(name))[1]::uuid)
);
CREATE POLICY "Permite acesso público a imagens de produtos" ON storage.objects FOR SELECT TO anon, authenticated USING (bucket_id = 'produto-imagens');
CREATE POLICY "Permite upload a membros da empresa para imagens de produtos" ON storage.objects FOR INSERT WITH CHECK (
  bucket_id = 'produto-imagens' AND is_member_of_empresa((storage.foldername(name))[1]::uuid)
);
CREATE POLICY "Permite delete a membros da empresa para imagens de produtos" ON storage.objects FOR DELETE USING (
  bucket_id = 'produto-imagens' AND is_member_of_empresa((storage.foldername(name))[1]::uuid)
);

-- Parte 7: Funções RPC (CRUD e outras)
-- =================================================================

-- Funções de Verificação
CREATE OR REPLACE FUNCTION public.check_cpf_exists(p_empresa_id uuid, p_cpf text)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.clientes_fornecedores
    WHERE empresa_id = p_empresa_id AND cnpj_cpf = p_cpf
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.check_cpf_exists(uuid, text) SET search_path = 'public';

CREATE OR REPLACE FUNCTION public.check_cnpj_exists(p_empresa_id uuid, p_cnpj text)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.clientes_fornecedores
    WHERE empresa_id = p_empresa_id AND cnpj_cpf = p_cnpj
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.check_cnpj_exists(uuid, text) SET search_path = 'public';

CREATE OR REPLACE FUNCTION public.check_vendedor_email_exists(p_empresa_id uuid, p_email text, p_vendedor_id uuid DEFAULT NULL)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.vendedores
    WHERE empresa_id = p_empresa_id AND email = p_email AND (p_vendedor_id IS NULL OR id <> p_vendedor_id)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.check_vendedor_email_exists(uuid, text, uuid) SET search_path = 'public';

-- Funções CRUD para Clientes
CREATE OR REPLACE FUNCTION public.create_cliente_fornecedor_completo(p_empresa_id uuid, p_cliente_data jsonb, p_contatos jsonb)
RETURNS uuid AS $$
DECLARE
    v_cliente_id uuid;
BEGIN
    IF NOT is_member_of_empresa(p_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada.';
    END IF;
    
    INSERT INTO public.clientes_fornecedores (empresa_id, nome_razao_social, fantasia, tipo_pessoa, tipo_contato, cnpj_cpf, rg, rnm, inscricao_estadual, inscricao_municipal, cep, endereco, numero, complemento, bairro, municipio, uf, cobranca_diferente, cobr_cep, cobr_endereco, cobr_numero, cobr_complemento, cobr_bairro, cobr_municipio, cobr_uf, telefone, telefone_adicional, celular, email, email_nfe, website, observacoes, created_by)
    VALUES (
        p_empresa_id,
        p_cliente_data->>'nomeRazaoSocial',
        p_cliente_data->>'fantasia',
        (p_cliente_data->>'tipoPessoa')::tipo_pessoa,
        (p_cliente_data->>'tipoContato')::tipo_contato,
        p_cliente_data->>'cnpjCpf',
        p_cliente_data->>'rg',
        p_cliente_data->>'rnm',
        p_cliente_data->>'inscricaoEstadual',
        p_cliente_data->>'inscricaoMunicipal',
        p_cliente_data->>'cep',
        p_cliente_data->>'endereco',
        p_cliente_data->>'numero',
        p_cliente_data->>'complemento',
        p_cliente_data->>'bairro',
        p_cliente_data->>'municipio',
        p_cliente_data->>'uf',
        (p_cliente_data->>'cobrancaDiferente')::boolean,
        p_cliente_data->>'cobrCep',
        p_cliente_data->>'cobrEndereco',
        p_cliente_data->>'cobrNumero',
        p_cliente_data->>'cobrComplemento',
        p_cliente_data->>'cobrBairro',
        p_cliente_data->>'cobrMunicipio',
        p_cliente_data->>'cobrUf',
        p_cliente_data->>'telefone',
        p_cliente_data->>'telefoneAdicional',
        p_cliente_data->>'celular',
        p_cliente_data->>'email',
        p_cliente_data->>'emailNfe',
        p_cliente_data->>'website',
        p_cliente_data->>'observacoes',
        auth.uid()
    ) RETURNING id INTO v_cliente_id;

    IF p_contatos IS NOT NULL AND jsonb_array_length(p_contatos) > 0 THEN
        INSERT INTO public.clientes_contatos (empresa_id, cliente_fornecedor_id, nome, setor, email, telefone, ramal)
        SELECT p_empresa_id, v_cliente_id, c->>'nome', c->>'setor', c->>'email', c->>'telefone', c->>'ramal'
        FROM jsonb_array_elements(p_contatos) c;
    END IF;
    
    RETURN v_cliente_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.create_cliente_fornecedor_completo(uuid, jsonb, jsonb) SET search_path = 'public';

CREATE OR REPLACE FUNCTION public.update_cliente_fornecedor_completo(p_cliente_id uuid, p_cliente_data jsonb, p_contatos jsonb)
RETURNS void AS $$
DECLARE
    v_empresa_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.clientes_fornecedores WHERE id = p_cliente_id;
    IF NOT is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada.';
    END IF;
    
    UPDATE public.clientes_fornecedores SET
        nome_razao_social = p_cliente_data->>'nomeRazaoSocial',
        fantasia = p_cliente_data->>'fantasia',
        tipo_pessoa = (p_cliente_data->>'tipoPessoa')::tipo_pessoa,
        tipo_contato = (p_cliente_data->>'tipoContato')::tipo_contato,
        cnpj_cpf = p_cliente_data->>'cnpjCpf',
        rg = p_cliente_data->>'rg',
        rnm = p_cliente_data->>'rnm',
        inscricao_estadual = p_cliente_data->>'inscricaoEstadual',
        inscricao_municipal = p_cliente_data->>'inscricaoMunicipal',
        cep = p_cliente_data->>'cep',
        endereco = p_cliente_data->>'endereco',
        numero = p_cliente_data->>'numero',
        complemento = p_cliente_data->>'complemento',
        bairro = p_cliente_data->>'bairro',
        municipio = p_cliente_data->>'municipio',
        uf = p_cliente_data->>'uf',
        cobranca_diferente = (p_cliente_data->>'cobrancaDiferente')::boolean,
        cobr_cep = p_cliente_data->>'cobrCep',
        cobr_endereco = p_cliente_data->>'cobrEndereco',
        cobr_numero = p_cliente_data->>'cobrNumero',
        cobr_complemento = p_cliente_data->>'cobrComplemento',
        cobr_bairro = p_cliente_data->>'cobrBairro',
        cobr_municipio = p_cliente_data->>'cobrMunicipio',
        cobr_uf = p_cliente_data->>'cobrUf',
        telefone = p_cliente_data->>'telefone',
        telefone_adicional = p_cliente_data->>'telefoneAdicional',
        celular = p_cliente_data->>'celular',
        email = p_cliente_data->>'email',
        email_nfe = p_cliente_data->>'emailNfe',
        website = p_cliente_data->>'website',
        observacoes = p_cliente_data->>'observacoes',
        updated_at = now()
    WHERE id = p_cliente_id;

    DELETE FROM public.clientes_contatos WHERE cliente_fornecedor_id = p_cliente_id;
    IF p_contatos IS NOT NULL AND jsonb_array_length(p_contatos) > 0 THEN
        INSERT INTO public.clientes_contatos (empresa_id, cliente_fornecedor_id, nome, setor, email, telefone, ramal)
        SELECT v_empresa_id, p_cliente_id, c->>'nome', c->>'setor', c->>'email', c->>'telefone', c->>'ramal'
        FROM jsonb_array_elements(p_contatos) c;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.update_cliente_fornecedor_completo(uuid, jsonb, jsonb) SET search_path = 'public';

CREATE OR REPLACE FUNCTION public.delete_cliente_fornecedor_if_member(p_id uuid)
RETURNS void AS $$
BEGIN
    DELETE FROM public.clientes_fornecedores WHERE id = p_id AND is_member_of_empresa(empresa_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.delete_cliente_fornecedor_if_member(uuid) SET search_path = 'public';

CREATE OR REPLACE FUNCTION public.create_cliente_anexo(p_empresa_id uuid, p_cliente_id uuid, p_storage_path text, p_filename text, p_content_type text, p_tamanho_bytes bigint)
RETURNS jsonb AS $$
DECLARE
    v_anexo_id uuid;
BEGIN
    IF NOT is_member_of_empresa(p_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada.';
    END IF;
    INSERT INTO public.clientes_anexos (empresa_id, cliente_fornecedor_id, storage_path, filename, content_type, tamanho_bytes)
    VALUES (p_empresa_id, p_cliente_id, p_storage_path, p_filename, p_content_type, p_tamanho_bytes)
    RETURNING id INTO v_anexo_id;
    RETURN (SELECT jsonb_build_object('id', id, 'createdAt', created_at) FROM public.clientes_anexos WHERE id = v_anexo_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.create_cliente_anexo(uuid, uuid, text, text, text, bigint) SET search_path = 'public';

-- Funções CRUD para Produtos
CREATE OR REPLACE FUNCTION public.create_produto_completo(p_empresa_id uuid, p_produto_data jsonb, p_atributos jsonb, p_fornecedores jsonb)
RETURNS uuid AS $$
DECLARE
    v_produto_id uuid;
BEGIN
    IF NOT is_member_of_empresa(p_empresa_id) THEN RAISE EXCEPTION 'Permissão negada.'; END IF;
    INSERT INTO public.produtos (empresa_id, nome, tipo, situacao, codigo, codigo_barras, unidade, preco_venda, custo_medio, origem, ncm, cest, controlar_estoque, estoque_inicial, estoque_minimo, estoque_maximo, localizacao, dias_preparacao, controlar_lotes, peso_liquido, peso_bruto, numero_volumes, embalagem_id, largura, altura, comprimento, diametro, marca, modelo, disponibilidade, garantia, video_url, descricao_curta, descricao_complementar, slug, titulo_seo, meta_descricao_seo, observacoes)
    VALUES (p_empresa_id, p_produto_data->>'nome', (p_produto_data->>'tipo')::tipo_produto, (p_produto_data->>'situacao')::situacao_produto, p_produto_data->>'codigo', p_produto_data->>'codigoBarras', p_produto_data->>'unidade', (p_produto_data->>'precoVenda')::numeric, (p_produto_data->>'custoMedio')::numeric, (p_produto_data->>'origem')::origem_produto, p_produto_data->>'ncm', p_produto_data->>'cest', (p_produto_data->>'controlarEstoque')::boolean, (p_produto_data->>'estoqueInicial')::numeric, (p_produto_data->>'estoqueMinimo')::numeric, (p_produto_data->>'estoqueMaximo')::numeric, p_produto_data->>'localizacao', (p_produto_data->>'diasPreparacao')::integer, (p_produto_data->>'controlarLotes')::boolean, (p_produto_data->>'pesoLiquido')::numeric, (p_produto_data->>'pesoBruto')::numeric, (p_produto_data->>'numeroVolumes')::integer, (p_produto_data->>'embalagemId')::uuid, (p_produto_data->>'largura')::numeric, (p_produto_data->>'altura')::numeric, (p_produto_data->>'comprimento')::numeric, (p_produto_data->>'diametro')::numeric, p_produto_data->>'marca', p_produto_data->>'modelo', p_produto_data->>'disponibilidade', p_produto_data->>'garantia', p_produto_data->>'videoUrl', p_produto_data->>'descricaoCurta', p_produto_data->>'descricaoComplementar', p_produto_data->>'slug', p_produto_data->>'tituloSeo', p_produto_data->>'metaDescricaoSeo', p_produto_data->>'observacoes')
    RETURNING id INTO v_produto_id;

    IF p_atributos IS NOT NULL AND jsonb_array_length(p_atributos) > 0 THEN
        INSERT INTO public.produto_atributos (produto_id, atributo, valor)
        SELECT v_produto_id, a->>'atributo', a->>'valor' FROM jsonb_array_elements(p_atributos) a;
    END IF;
    IF p_fornecedores IS NOT NULL AND jsonb_array_length(p_fornecedores) > 0 THEN
        INSERT INTO public.produto_fornecedores (produto_id, fornecedor_id, codigo_no_fornecedor)
        SELECT v_produto_id, (f->>'fornecedorId')::uuid, f->>'codigoNoFornecedor' FROM jsonb_array_elements(p_fornecedores) f;
    END IF;
    RETURN v_produto_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.create_produto_completo(uuid, jsonb, jsonb, jsonb) SET search_path = 'public';

CREATE OR REPLACE FUNCTION public.update_produto_completo(p_produto_id uuid, p_produto_data jsonb, p_atributos jsonb, p_fornecedores jsonb)
RETURNS void AS $$
DECLARE
    v_empresa_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.produtos WHERE id = p_produto_id;
    IF NOT is_member_of_empresa(v_empresa_id) THEN RAISE EXCEPTION 'Permissão negada.'; END IF;
    
    UPDATE public.produtos SET
        nome = p_produto_data->>'nome', tipo = (p_produto_data->>'tipo')::tipo_produto, situacao = (p_produto_data->>'situacao')::situacao_produto, codigo = p_produto_data->>'codigo', codigo_barras = p_produto_data->>'codigoBarras', unidade = p_produto_data->>'unidade', preco_venda = (p_produto_data->>'precoVenda')::numeric, custo_medio = (p_produto_data->>'custoMedio')::numeric, origem = (p_produto_data->>'origem')::origem_produto, ncm = p_produto_data->>'ncm', cest = p_produto_data->>'cest', controlar_estoque = (p_produto_data->>'controlarEstoque')::boolean, estoque_minimo = (p_produto_data->>'estoqueMinimo')::numeric, estoque_maximo = (p_produto_data->>'estoqueMaximo')::numeric, localizacao = p_produto_data->>'localizacao', dias_preparacao = (p_produto_data->>'diasPreparacao')::integer, controlar_lotes = (p_produto_data->>'controlarLotes')::boolean, peso_liquido = (p_produto_data->>'pesoLiquido')::numeric, peso_bruto = (p_produto_data->>'pesoBruto')::numeric, numero_volumes = (p_produto_data->>'numeroVolumes')::integer, embalagem_id = (p_produto_data->>'embalagemId')::uuid, largura = (p_produto_data->>'largura')::numeric, altura = (p_produto_data->>'altura')::numeric, comprimento = (p_produto_data->>'comprimento')::numeric, diametro = (p_produto_data->>'diametro')::numeric, marca = p_produto_data->>'marca', modelo = p_produto_data->>'modelo', disponibilidade = p_produto_data->>'disponibilidade', garantia = p_produto_data->>'garantia', video_url = p_produto_data->>'videoUrl', descricao_curta = p_produto_data->>'descricaoCurta', descricao_complementar = p_produto_data->>'descricaoComplementar', slug = p_produto_data->>'slug', titulo_seo = p_produto_data->>'tituloSeo', meta_descricao_seo = p_produto_data->>'metaDescricaoSeo', observacoes = p_produto_data->>'observacoes', updated_at = now()
    WHERE id = p_produto_id;

    DELETE FROM public.produto_atributos WHERE produto_id = p_produto_id;
    IF p_atributos IS NOT NULL AND jsonb_array_length(p_atributos) > 0 THEN
        INSERT INTO public.produto_atributos (produto_id, atributo, valor)
        SELECT p_produto_id, a->>'atributo', a->>'valor' FROM jsonb_array_elements(p_atributos) a;
    END IF;
    DELETE FROM public.produto_fornecedores WHERE produto_id = p_produto_id;
    IF p_fornecedores IS NOT NULL AND jsonb_array_length(p_fornecedores) > 0 THEN
        INSERT INTO public.produto_fornecedores (produto_id, fornecedor_id, codigo_no_fornecedor)
        SELECT p_produto_id, (f->>'fornecedorId')::uuid, f->>'codigoNoFornecedor' FROM jsonb_array_elements(p_fornecedores) f;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.update_produto_completo(uuid, jsonb, jsonb, jsonb) SET search_path = 'public';

CREATE OR REPLACE FUNCTION public.delete_produto(p_id uuid)
RETURNS text[] AS $$
DECLARE
  v_image_paths text[];
BEGIN
  IF NOT EXISTS (SELECT 1 FROM produtos WHERE id = p_id AND is_member_of_empresa(empresa_id)) THEN
    RAISE EXCEPTION 'Permissão negada ou produto não encontrado.';
  END IF;
  SELECT array_agg(storage_path) INTO v_image_paths FROM produto_imagens WHERE produto_id = p_id;
  DELETE FROM produtos WHERE id = p_id;
  RETURN v_image_paths;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.delete_produto(uuid) SET search_path = 'public';

CREATE OR REPLACE FUNCTION public.create_produto_imagem(p_produto_id uuid, p_storage_path text, p_filename text, p_content_type text, p_tamanho_bytes bigint)
RETURNS jsonb AS $$
DECLARE
    v_imagem_id uuid;
    v_empresa_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.produtos WHERE id = p_produto_id;
    IF NOT is_member_of_empresa(v_empresa_id) THEN RAISE EXCEPTION 'Permissão negada.'; END IF;
    INSERT INTO public.produto_imagens (produto_id, storage_path, nome_arquivo, content_type, tamanho_bytes)
    VALUES (p_produto_id, p_storage_path, p_filename, p_content_type, p_tamanho_bytes)
    RETURNING id INTO v_imagem_id;
    RETURN (SELECT jsonb_build_object('id', id, 'createdAt', created_at) FROM public.produto_imagens WHERE id = v_imagem_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.create_produto_imagem(uuid, text, text, text, bigint) SET search_path = 'public';

-- Funções CRUD para Serviços
CREATE OR REPLACE FUNCTION public.create_servico(p_empresa_id uuid, p_descricao text, p_preco numeric, p_situacao situacao_servico, p_codigo text, p_unidade text, p_codigo_servico text, p_nbs text, p_descricao_complementar text, p_observacoes text)
RETURNS uuid AS $$
DECLARE v_id uuid;
BEGIN
  IF NOT is_member_of_empresa(p_empresa_id) THEN RAISE EXCEPTION 'Permissão negada.'; END IF;
  INSERT INTO public.servicos (empresa_id, descricao, preco, situacao, codigo, unidade, codigo_servico, nbs, descricao_complementar, observacoes)
  VALUES (p_empresa_id, p_descricao, p_preco, p_situacao, p_codigo, p_unidade, p_codigo_servico, p_nbs, p_descricao_complementar, p_observacoes)
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.create_servico(uuid, text, numeric, situacao_servico, text, text, text, text, text, text) SET search_path = 'public';

CREATE OR REPLACE FUNCTION public.update_servico(p_id uuid, p_descricao text, p_preco numeric, p_situacao situacao_servico, p_codigo text, p_unidade text, p_codigo_servico text, p_nbs text, p_descricao_complementar text, p_observacoes text)
RETURNS void AS $$
BEGIN
  UPDATE public.servicos SET descricao=p_descricao, preco=p_preco, situacao=p_situacao, codigo=p_codigo, unidade=p_unidade, codigo_servico=p_codigo_servico, nbs=p_nbs, descricao_complementar=p_descricao_complementar, observacoes=p_observacoes, updated_at=now()
  WHERE id = p_id AND is_member_of_empresa(empresa_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.update_servico(uuid, text, numeric, situacao_servico, text, text, text, text, text, text) SET search_path = 'public';

CREATE OR REPLACE FUNCTION public.delete_servico(p_id uuid)
RETURNS void AS $$
BEGIN
  DELETE FROM public.servicos WHERE id = p_id AND is_member_of_empresa(empresa_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.delete_servico(uuid) SET search_path = 'public';

-- Funções CRUD para Vendedores
CREATE OR REPLACE FUNCTION public.create_vendedor(p_empresa_id uuid, p_nome text, p_fantasia text, p_codigo text, p_tipo_pessoa tipo_pessoa_vendedor, p_cpf_cnpj text, p_documento_identificacao text, p_pais text, p_contribuinte_icms tipo_contribuinte_icms, p_inscricao_estadual text, p_situacao situacao_vendedor, p_cep text, p_logradouro text, p_numero text, p_complemento text, p_bairro text, p_cidade text, p_uf text, p_telefone text, p_celular text, p_email text, p_email_comunicacao text, p_deposito_padrao text, p_senha text, p_acesso_restrito_horario boolean, p_acesso_restrito_ip text, p_perfil_contato text[], p_permissoes_modulos jsonb, p_regra_liberacao_comissao regra_liberacao_comissao, p_tipo_comissao tipo_comissao, p_aliquota_comissao numeric, p_desconsiderar_comissionamento_linhas_produto boolean, p_observacoes_comissao text, p_contatos jsonb)
RETURNS uuid AS $$
DECLARE
    v_vendedor_id uuid;
BEGIN
    IF NOT is_member_of_empresa(p_empresa_id) THEN RAISE EXCEPTION 'Permissão negada.'; END IF;
    INSERT INTO public.vendedores (empresa_id, nome, fantasia, codigo, tipo_pessoa, cpf_cnpj, documento_identificacao, pais, contribuinte_icms, inscricao_estadual, situacao, cep, logradouro, numero, complemento, bairro, cidade, uf, telefone, celular, email, email_comunicacao, deposito_padrao, acesso_restrito_horario, acesso_restrito_ip, perfil_contato, permissoes_modulos, regra_liberacao_comissao, tipo_comissao, aliquota_comissao, desconsiderar_comissionamento_linhas_produto, observacoes_comissao)
    VALUES (p_empresa_id, p_nome, p_fantasia, p_codigo, p_tipo_pessoa, p_cpf_cnpj, p_documento_identificacao, p_pais, p_contribuinte_icms, p_inscricao_estadual, p_situacao, p_cep, p_logradouro, p_numero, p_complemento, p_bairro, p_cidade, p_uf, p_telefone, p_celular, p_email, p_email_comunicacao, p_deposito_padrao, p_acesso_restrito_horario, p_acesso_restrito_ip, p_perfil_contato, p_permissoes_modulos, p_regra_liberacao_comissao, p_tipo_comissao, p_aliquota_comissao, p_desconsiderar_comissionamento_linhas_produto, p_observacoes_comissao)
    RETURNING id INTO v_vendedor_id;
    
    IF p_contatos IS NOT NULL AND jsonb_array_length(p_contatos) > 0 THEN
        INSERT INTO public.vendedores_contatos (vendedor_id, nome, setor, email, telefone, ramal)
        SELECT v_vendedor_id, c->>'nome', c->>'setor', c->>'email', c->>'telefone', c->>'ramal' FROM jsonb_array_elements(p_contatos) c;
    END IF;
    RETURN v_vendedor_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.create_vendedor(uuid, text, text, text, tipo_pessoa_vendedor, text, text, text, tipo_contribuinte_icms, text, situacao_vendedor, text, text, text, text, text, text, text, text, text, text, text, text, text, boolean, text, text[], jsonb, regra_liberacao_comissao, tipo_comissao, numeric, boolean, text, jsonb) SET search_path = 'public';

CREATE OR REPLACE FUNCTION public.update_vendedor(p_id uuid, p_nome text, p_fantasia text, p_codigo text, p_tipo_pessoa tipo_pessoa_vendedor, p_cpf_cnpj text, p_documento_identificacao text, p_pais text, p_contribuinte_icms tipo_contribuinte_icms, p_inscricao_estadual text, p_situacao situacao_vendedor, p_cep text, p_logradouro text, p_numero text, p_complemento text, p_bairro text, p_cidade text, p_uf text, p_telefone text, p_celular text, p_email text, p_email_comunicacao text, p_deposito_padrao text, p_senha text, p_acesso_restrito_horario boolean, p_acesso_restrito_ip text, p_perfil_contato text[], p_permissoes_modulos jsonb, p_regra_liberacao_comissao regra_liberacao_comissao, p_tipo_comissao tipo_comissao, p_aliquota_comissao numeric, p_desconsiderar_comissionamento_linhas_produto boolean, p_observacoes_comissao text, p_contatos jsonb)
RETURNS void AS $$
BEGIN
    UPDATE public.vendedores SET nome=p_nome, fantasia=p_fantasia, codigo=p_codigo, tipo_pessoa=p_tipo_pessoa, cpf_cnpj=p_cpf_cnpj, documento_identificacao=p_documento_identificacao, pais=p_pais, contribuinte_icms=p_contribuinte_icms, inscricao_estadual=p_inscricao_estadual, situacao=p_situacao, cep=p_cep, logradouro=p_logradouro, numero=p_numero, complemento=p_complemento, bairro=p_bairro, cidade=p_cidade, uf=p_uf, telefone=p_telefone, celular=p_celular, email=p_email, email_comunicacao=p_email_comunicacao, deposito_padrao=p_deposito_padrao, acesso_restrito_horario=p_acesso_restrito_horario, acesso_restrito_ip=p_acesso_restrito_ip, perfil_contato=p_perfil_contato, permissoes_modulos=p_permissoes_modulos, regra_liberacao_comissao=p_regra_liberacao_comissao, tipo_comissao=p_tipo_comissao, aliquota_comissao=p_aliquota_comissao, desconsiderar_comissionamento_linhas_produto=p_desconsiderar_comissionamento_linhas_produto, observacoes_comissao=p_observacoes_comissao, updated_at=now()
    WHERE id = p_id AND is_member_of_empresa(empresa_id);
    
    DELETE FROM public.vendedores_contatos WHERE vendedor_id = p_id;
    IF p_contatos IS NOT NULL AND jsonb_array_length(p_contatos) > 0 THEN
        INSERT INTO public.vendedores_contatos (vendedor_id, nome, setor, email, telefone, ramal)
        SELECT p_id, c->>'nome', c->>'setor', c->>'email', c->>'telefone', c->>'ramal' FROM jsonb_array_elements(p_contatos) c;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.update_vendedor(uuid, text, text, text, tipo_pessoa_vendedor, text, text, text, tipo_contribuinte_icms, text, situacao_vendedor, text, text, text, text, text, text, text, text, text, text, text, text, text, boolean, text, text[], jsonb, regra_liberacao_comissao, tipo_comissao, numeric, boolean, text, jsonb) SET search_path = 'public';

CREATE OR REPLACE FUNCTION public.delete_vendedor(p_id uuid)
RETURNS void AS $$
BEGIN
  DELETE FROM public.vendedores WHERE id = p_id AND is_member_of_empresa(empresa_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.delete_vendedor(uuid) SET search_path = 'public';

-- Funções CRUD para Embalagens
CREATE OR REPLACE FUNCTION public.create_embalagem(p_empresa_id uuid, p_descricao text, p_tipo tipo_embalagem_produto, p_peso numeric, p_largura numeric, p_altura numeric, p_comprimento numeric, p_diametro numeric)
RETURNS uuid AS $$
DECLARE v_id uuid;
BEGIN
  IF NOT is_member_of_empresa(p_empresa_id) THEN RAISE EXCEPTION 'Permissão negada.'; END IF;
  INSERT INTO public.embalagens (empresa_id, descricao, tipo, peso, largura, altura, comprimento, diametro)
  VALUES (p_empresa_id, p_descricao, p_tipo, p_peso, p_largura, p_altura, p_comprimento, p_diametro)
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.create_embalagem(uuid, text, tipo_embalagem_produto, numeric, numeric, numeric, numeric, numeric) SET search_path = 'public';

CREATE OR REPLACE FUNCTION public.update_embalagem(p_id uuid, p_descricao text, p_tipo tipo_embalagem_produto, p_peso numeric, p_largura numeric, p_altura numeric, p_comprimento numeric, p_diametro numeric)
RETURNS void AS $$
BEGIN
  UPDATE public.embalagens SET descricao=p_descricao, tipo=p_tipo, peso=p_peso, largura=p_largura, altura=p_altura, comprimento=p_comprimento, diametro=p_diametro, updated_at=now()
  WHERE id = p_id AND is_member_of_empresa(empresa_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.update_embalagem(uuid, text, tipo_embalagem_produto, numeric, numeric, numeric, numeric, numeric) SET search_path = 'public';

CREATE OR REPLACE FUNCTION public.delete_embalagem(p_id uuid)
RETURNS void AS $$
BEGIN
  DELETE FROM public.embalagens WHERE id = p_id AND is_member_of_empresa(empresa_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.delete_embalagem(uuid) SET search_path = 'public';

-- Funções CRUD para CRM
CREATE OR REPLACE FUNCTION public.create_crm_oportunidade(p_empresa_id uuid, p_oportunidade_data jsonb, p_itens jsonb)
RETURNS uuid AS $$
DECLARE v_oportunidade_id uuid;
BEGIN
    IF NOT is_member_of_empresa(p_empresa_id) THEN RAISE EXCEPTION 'Permissão negada.'; END IF;
    INSERT INTO public.crm_oportunidades (empresa_id, titulo, valor, etapa_funil, status, data_fechamento_prevista, cliente_id, vendedor_id, observacoes)
    VALUES (p_empresa_id, p_oportunidade_data->>'titulo', (p_oportunidade_data->>'valor')::numeric, (p_oportunidade_data->>'etapaFunil')::crm_etapa_funil, (p_oportunidade_data->>'status')::crm_status_oportunidade, (p_oportunidade_data->>'dataFechamentoPrevista')::date, (p_oportunidade_data->>'clienteId')::uuid, (p_oportunidade_data->>'vendedorId')::uuid, p_oportunidade_data->>'observacoes')
    RETURNING id INTO v_oportunidade_id;
    IF p_itens IS NOT NULL AND jsonb_array_length(p_itens) > 0 THEN
        INSERT INTO public.crm_oportunidade_itens (oportunidade_id, produto_id, servico_id, descricao, quantidade, valor_unitario, valor_total)
        SELECT v_oportunidade_id, (i->>'produtoId')::uuid, (i->>'servicoId')::uuid, i->>'descricao', (i->>'quantidade')::numeric, (i->>'valorUnitario')::numeric, ((i->>'quantidade')::numeric * (i->>'valorUnitario')::numeric)
        FROM jsonb_array_elements(p_itens) i;
    END IF;
    RETURN v_oportunidade_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.create_crm_oportunidade(uuid, jsonb, jsonb) SET search_path = 'public';

CREATE OR REPLACE FUNCTION public.update_crm_oportunidade(p_oportunidade_id uuid, p_oportunidade_data jsonb, p_itens jsonb)
RETURNS void AS $$
DECLARE v_empresa_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.crm_oportunidades WHERE id = p_oportunidade_id;
    IF NOT is_member_of_empresa(v_empresa_id) THEN RAISE EXCEPTION 'Permissão negada.'; END IF;
    UPDATE public.crm_oportunidades SET titulo=p_oportunidade_data->>'titulo', valor=(p_oportunidade_data->>'valor')::numeric, etapa_funil=(p_oportunidade_data->>'etapaFunil')::crm_etapa_funil, status=(p_oportunidade_data->>'status')::crm_status_oportunidade, data_fechamento_prevista=(p_oportunidade_data->>'dataFechamentoPrevista')::date, cliente_id=(p_oportunidade_data->>'clienteId')::uuid, vendedor_id=(p_oportunidade_data->>'vendedorId')::uuid, observacoes=p_oportunidade_data->>'observacoes', updated_at=now()
    WHERE id = p_oportunidade_id;
    DELETE FROM public.crm_oportunidade_itens WHERE oportunidade_id = p_oportunidade_id;
    IF p_itens IS NOT NULL AND jsonb_array_length(p_itens) > 0 THEN
        INSERT INTO public.crm_oportunidade_itens (oportunidade_id, produto_id, servico_id, descricao, quantidade, valor_unitario, valor_total)
        SELECT p_oportunidade_id, (i->>'produtoId')::uuid, (i->>'servicoId')::uuid, i->>'descricao', (i->>'quantidade')::numeric, (i->>'valorUnitario')::numeric, ((i->>'quantidade')::numeric * (i->>'valorUnitario')::numeric)
        FROM jsonb_array_elements(p_itens) i;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.update_crm_oportunidade(uuid, jsonb, jsonb) SET search_path = 'public';

CREATE OR REPLACE FUNCTION public.delete_crm_oportunidade(p_id uuid)
RETURNS void AS $$
BEGIN
  DELETE FROM public.crm_oportunidades WHERE id = p_id AND is_member_of_empresa(empresa_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.delete_crm_oportunidade(uuid) SET search_path = 'public';

-- Funções CRUD para Pedidos de Venda
CREATE OR REPLACE FUNCTION public.create_pedido_venda_completo(p_empresa_id uuid, p_pedido_data jsonb, p_itens jsonb)
RETURNS uuid AS $$
DECLARE v_pedido_id uuid;
BEGIN
    IF NOT is_member_of_empresa(p_empresa_id) THEN RAISE EXCEPTION 'Permissão negada.'; END IF;
    INSERT INTO public.pedidos_vendas (empresa_id, cliente_id, vendedor_id, natureza_operacao, status, data_venda, data_prevista_entrega, valor_total, desconto, frete_por_conta, valor_frete, transportadora_id, observacoes, observacoes_internas)
    VALUES (p_empresa_id, (p_pedido_data->>'clienteId')::uuid, (p_pedido_data->>'vendedorId')::uuid, p_pedido_data->>'naturezaOperacao', (p_pedido_data->>'status')::status_pedido_venda, (p_pedido_data->>'dataVenda')::date, (p_pedido_data->>'dataPrevistaEntrega')::date, (p_pedido_data->>'valorTotal')::numeric, (p_pedido_data->>'desconto')::numeric, (p_pedido_data->>'fretePorConta')::frete_por_conta, (p_pedido_data->>'valorFrete')::numeric, (p_pedido_data->>'transportadoraId')::uuid, p_pedido_data->>'observacoes', p_pedido_data->>'observacoesInternas')
    RETURNING id INTO v_pedido_id;
    IF p_itens IS NOT NULL AND jsonb_array_length(p_itens) > 0 THEN
        INSERT INTO public.pedidos_vendas_itens (pedido_venda_id, produto_id, servico_id, descricao, quantidade, valor_unitario, valor_total)
        SELECT v_pedido_id, (i->>'produtoId')::uuid, (i->>'servicoId')::uuid, i->>'descricao', (i->>'quantidade')::numeric, (i->>'valorUnitario')::numeric, ((i->>'quantidade')::numeric * (i->>'valorUnitario')::numeric)
        FROM jsonb_array_elements(p_itens) i;
    END IF;
    RETURN v_pedido_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.create_pedido_venda_completo(uuid, jsonb, jsonb) SET search_path = 'public';

CREATE OR REPLACE FUNCTION public.update_pedido_venda_completo(p_pedido_id uuid, p_pedido_data jsonb, p_itens jsonb)
RETURNS void AS $$
DECLARE v_empresa_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.pedidos_vendas WHERE id = p_pedido_id;
    IF NOT is_member_of_empresa(v_empresa_id) THEN RAISE EXCEPTION 'Permissão negada.'; END IF;
    UPDATE public.pedidos_vendas SET cliente_id=(p_pedido_data->>'clienteId')::uuid, vendedor_id=(p_pedido_data->>'vendedorId')::uuid, natureza_operacao=p_pedido_data->>'naturezaOperacao', status=(p_pedido_data->>'status')::status_pedido_venda, data_venda=(p_pedido_data->>'dataVenda')::date, data_prevista_entrega=(p_pedido_data->>'dataPrevistaEntrega')::date, valor_total=(p_pedido_data->>'valorTotal')::numeric, desconto=(p_pedido_data->>'desconto')::numeric, frete_por_conta=(p_pedido_data->>'fretePorConta')::frete_por_conta, valor_frete=(p_pedido_data->>'valorFrete')::numeric, transportadora_id=(p_pedido_data->>'transportadoraId')::uuid, observacoes=p_pedido_data->>'observacoes', observacoes_internas=p_pedido_data->>'observacoesInternas', updated_at=now()
    WHERE id = p_pedido_id;
    DELETE FROM public.pedidos_vendas_itens WHERE pedido_venda_id = p_pedido_id;
    IF p_itens IS NOT NULL AND jsonb_array_length(p_itens) > 0 THEN
        INSERT INTO public.pedidos_vendas_itens (pedido_venda_id, produto_id, servico_id, descricao, quantidade, valor_unitario, valor_total)
        SELECT p_pedido_id, (i->>'produtoId')::uuid, (i->>'servicoId')::uuid, i->>'descricao', (i->>'quantidade'):_numeric, (i->>'valorUnitario')::numeric, ((i->>'quantidade')::numeric * (i->>'valorUnitario')::numeric)
        FROM jsonb_array_elements(p_itens) i;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.update_pedido_venda_completo(uuid, jsonb, jsonb) SET search_path = 'public';

CREATE OR REPLACE FUNCTION public.delete_pedido_venda(p_id uuid)
RETURNS void AS $$
BEGIN
  DELETE FROM public.pedidos_vendas WHERE id = p_id AND is_member_of_empresa(empresa_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.delete_pedido_venda(uuid) SET search_path = 'public';

CREATE OR REPLACE FUNCTION public.search_produtos_e_servicos(p_empresa_id uuid, p_query text)
RETURNS TABLE(id uuid, nome text, preco_venda numeric, tipo text) AS $$
BEGIN
  RETURN QUERY
    SELECT p.id, p.nome, p.preco_venda, 'produto' as tipo
    FROM public.produtos p
    WHERE p.empresa_id = p_empresa_id AND p.situacao = 'Ativo' AND p.nome ILIKE '%' || p_query || '%'
    UNION ALL
    SELECT s.id, s.descricao as nome, s.preco as preco_venda, 'servico' as tipo
    FROM public.servicos s
    WHERE s.empresa_id = p_empresa_id AND s.situacao = 'Ativo' AND s.descricao ILIKE '%' || p_query || '%';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.search_produtos_e_servicos(uuid, text) SET search_path = 'public';

-- Funções de Papéis e Permissões
CREATE OR REPLACE FUNCTION public.set_papel_permissions(p_papel_id uuid, p_permission_ids text[])
RETURNS void AS $$
DECLARE
  v_empresa_id uuid;
BEGIN
  SELECT empresa_id INTO v_empresa_id FROM public.papeis WHERE id = p_papel_id;
  IF NOT is_member_of_empresa(v_empresa_id) THEN RAISE EXCEPTION 'Permissão negada.'; END IF;
  
  DELETE FROM public.papel_permissoes WHERE papel_id = p_papel_id;
  
  IF array_length(p_permission_ids, 1) > 0 THEN
    INSERT INTO public.papel_permissoes (papel_id, permissao_id)
    SELECT p_papel_id, unnest(p_permission_ids);
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION public.set_papel_permissions(uuid, text[]) SET search_path = 'public';
