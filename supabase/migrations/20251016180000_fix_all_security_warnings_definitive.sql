-- ============================================================================
-- CORREÇÃO DEFINITIVA DE TODOS OS AVISOS DE SEGURANÇA
-- Este script remove e recria todas as funções personalizadas e políticas de RLS
-- para garantir que a configuração `search_path` seja aplicada em todo o projeto.
-- ============================================================================

-- Parte 1: Remover funções e dependências (políticas, triggers) em cascata
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.is_member_of_empresa(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.get_empresa_id_for_user(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.create_cliente_anexo(uuid,uuid,text,text,text,bigint) CASCADE;
DROP FUNCTION IF EXISTS public.create_cliente_fornecedor_completo(uuid,jsonb,jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.update_cliente_fornecedor_completo(uuid,jsonb,jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.delete_cliente_fornecedor_if_member(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.create_crm_oportunidade(uuid,jsonb,jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.update_crm_oportunidade(uuid,jsonb,jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.delete_crm_oportunidade(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.create_embalagem(uuid,text,public."TipoEmbalagemProduto",numeric,numeric,numeric,numeric,numeric) CASCADE;
DROP FUNCTION IF EXISTS public.update_embalagem(uuid,text,public."TipoEmbalagemProduto",numeric,numeric,numeric,numeric,numeric) CASCADE;
DROP FUNCTION IF EXISTS public.delete_embalagem(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.create_pedido_venda_completo(uuid,jsonb,jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.update_pedido_venda_completo(uuid,jsonb,jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.delete_pedido_venda(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.search_produtos_e_servicos(uuid,text) CASCADE;
DROP FUNCTION IF EXISTS public.create_produto_completo(uuid,jsonb,jsonb,jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.update_produto_completo(uuid,jsonb,jsonb,jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.delete_produto(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.create_produto_imagem(uuid,text,text,text,bigint) CASCADE;
DROP FUNCTION IF EXISTS public.create_servico(uuid,text,numeric,public."SituacaoServico",text,text,text,text,text,text) CASCADE;
DROP FUNCTION IF EXISTS public.update_servico(uuid,text,numeric,public."SituacaoServico",text,text,text,text,text,text) CASCADE;
DROP FUNCTION IF EXISTS public.delete_servico(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.create_vendedor(uuid,text,text,text,public."TipoPessoaVendedor",text,text,text,public."TipoContribuinteIcms",text,public."SituacaoVendedor",text,text,text,text,text,text,text,text,text,text,text,text,boolean,text,text[],jsonb,public."RegraLiberacaoComissao",public."TipoComissao",numeric,boolean,text,jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.update_vendedor(uuid,text,text,text,public."TipoPessoaVendedor",text,text,text,public."TipoContribuinteIcms",text,public."SituacaoVendedor",text,text,text,text,text,text,text,text,text,text,text,text,boolean,text,text[],jsonb,public."RegraLiberacaoComissao",public."TipoComissao",numeric,boolean,text,jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.delete_vendedor(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.check_vendedor_email_exists(uuid,text,uuid) CASCADE;
DROP FUNCTION IF EXISTS public.set_papel_permissions(uuid,text[]) CASCADE;
DROP FUNCTION IF EXISTS public.create_empresa_and_link_owner_client(text,text,text) CASCADE;
DROP FUNCTION IF EXISTS public.delete_empresa_if_member(uuid) CASCADE;

-- Parte 2: Recriar funções auxiliares de segurança com `search_path`
CREATE OR REPLACE FUNCTION public.is_member_of_empresa(p_empresa_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  SET search_path = 'public';
  RETURN EXISTS (
    SELECT 1
    FROM empresa_usuarios
    WHERE empresa_id = p_empresa_id AND user_id = auth.uid()
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_empresa_id_for_user(p_user_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  SET search_path = 'public';
  RETURN (SELECT empresa_id FROM empresa_usuarios WHERE user_id = p_user_id LIMIT 1);
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  SET search_path = 'public';
  -- Este trigger agora apenas existe, mas a lógica de criação de empresa foi movida para o frontend
  -- para permitir que o usuário preencha os dados da empresa primeiro.
  RETURN new;
END;
$$;

-- Parte 3: Recriar o trigger que foi removido em cascata
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Parte 4: Recriar todas as funções de negócio com `search_path`
-- (Incluindo todas as funções dos módulos: Clientes, Produtos, Vendedores, etc.)
-- Funções de Clientes
CREATE OR REPLACE FUNCTION public.create_cliente_fornecedor_completo(p_empresa_id uuid, p_cliente_data jsonb, p_contatos jsonb)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_cliente_id uuid;
  contato jsonb;
BEGIN
  SET search_path = 'public';
  IF NOT is_member_of_empresa(p_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não tem permissão para esta empresa';
  END IF;

  INSERT INTO clientes_fornecedores (empresa_id, nome_razao_social, fantasia, tipo_pessoa, tipo_contato, cnpj_cpf, inscricao_estadual, inscricao_municipal, rg, rnm, cep, endereco, numero, complemento, bairro, municipio, uf, cobranca_diferente, cobr_cep, cobr_endereco, cobr_numero, cobr_complemento, cobr_bairro, cobr_municipio, cobr_uf, telefone, telefone_adicional, celular, email, email_nfe, website, observacoes)
  VALUES (
    p_empresa_id,
    p_cliente_data->>'nomeRazaoSocial',
    p_cliente_data->>'fantasia',
    (p_cliente_data->>'tipoPessoa')::public."TipoPessoa",
    (p_cliente_data->>'tipoContato')::public."TipoContato",
    p_cliente_data->>'cnpjCpf',
    p_cliente_data->>'inscricaoEstadual',
    p_cliente_data->>'inscricaoMunicipal',
    p_cliente_data->>'rg',
    p_cliente_data->>'rnm',
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
    p_cliente_data->>'observacoes'
  ) RETURNING id INTO v_cliente_id;

  FOR contato IN SELECT * FROM jsonb_array_elements(p_contatos)
  LOOP
    INSERT INTO clientes_contatos (empresa_id, cliente_fornecedor_id, nome, setor, email, telefone, ramal)
    VALUES (p_empresa_id, v_cliente_id, contato->>'nome', contato->>'setor', contato->>'email', contato->>'telefone', contato->>'ramal');
  END LOOP;

  RETURN v_cliente_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_cliente_fornecedor_completo(p_cliente_id uuid, p_cliente_data jsonb, p_contatos jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_empresa_id uuid;
  contato jsonb;
BEGIN
  SET search_path = 'public';
  SELECT empresa_id INTO v_empresa_id FROM clientes_fornecedores WHERE id = p_cliente_id;
  IF NOT is_member_of_empresa(v_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não tem permissão para esta empresa';
  END IF;

  UPDATE clientes_fornecedores SET
    nome_razao_social = p_cliente_data->>'nomeRazaoSocial',
    fantasia = p_cliente_data->>'fantasia',
    tipo_pessoa = (p_cliente_data->>'tipoPessoa')::public."TipoPessoa",
    tipo_contato = (p_cliente_data->>'tipoContato')::public."TipoContato",
    cnpj_cpf = p_cliente_data->>'cnpjCpf',
    inscricao_estadual = p_cliente_data->>'inscricaoEstadual',
    inscricao_municipal = p_cliente_data->>'inscricaoMunicipal',
    rg = p_cliente_data->>'rg',
    rnm = p_cliente_data->>'rnm',
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

  DELETE FROM clientes_contatos WHERE cliente_fornecedor_id = p_cliente_id;
  FOR contato IN SELECT * FROM jsonb_array_elements(p_contatos)
  LOOP
    INSERT INTO clientes_contatos (empresa_id, cliente_fornecedor_id, nome, setor, email, telefone, ramal)
    VALUES (v_empresa_id, p_cliente_id, contato->>'nome', contato->>'setor', contato->>'email', contato->>'telefone', contato->>'ramal');
  END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_cliente_anexo(p_empresa_id uuid, p_cliente_id uuid, p_storage_path text, p_filename text, p_content_type text, p_tamanho_bytes bigint)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_anexo clientes_anexos;
BEGIN
  SET search_path = 'public';
  IF NOT is_member_of_empresa(p_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não tem permissão para esta empresa';
  END IF;

  INSERT INTO clientes_anexos (empresa_id, cliente_fornecedor_id, storage_path, filename, content_type, tamanho_bytes)
  VALUES (p_empresa_id, p_cliente_id, p_storage_path, p_filename, p_content_type, p_tamanho_bytes)
  RETURNING * INTO new_anexo;
  
  RETURN row_to_json(new_anexo);
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_cliente_fornecedor_if_member(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_empresa_id uuid;
BEGIN
  SET search_path = 'public';
  SELECT empresa_id INTO v_empresa_id FROM clientes_fornecedores WHERE id = p_id;
  IF NOT is_member_of_empresa(v_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não tem permissão para esta empresa';
  END IF;
  DELETE FROM clientes_fornecedores WHERE id = p_id;
END;
$$;

-- Funções de Produtos
CREATE OR REPLACE FUNCTION public.create_produto_completo(p_empresa_id uuid, p_produto_data jsonb, p_atributos jsonb, p_fornecedores jsonb)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_produto_id uuid;
    v_produto_criado json;
    atributo jsonb;
    fornecedor jsonb;
BEGIN
    SET search_path = 'public';
    IF NOT is_member_of_empresa(p_empresa_id) THEN
        RAISE EXCEPTION 'Usuário não tem permissão para esta empresa';
    END IF;

    INSERT INTO produtos (empresa_id, nome, tipo, situacao, codigo, codigo_barras, unidade, preco_venda, custo_medio, origem, ncm, cest, controlar_estoque, estoque_inicial, estoque_minimo, estoque_maximo, localizacao, dias_preparacao, controlar_lotes, peso_liquido, peso_bruto, numero_volumes, embalagem_id, largura, altura, comprimento, diametro, marca, modelo, disponibilidade, garantia, video_url, descricao_curta, descricao_complementar, slug, titulo_seo, meta_descricao_seo, observacoes)
    VALUES (
        p_empresa_id,
        p_produto_data->>'nome',
        (p_produto_data->>'tipo')::public."TipoProduto",
        (p_produto_data->>'situacao')::public."SituacaoProduto",
        p_produto_data->>'codigo',
        p_produto_data->>'codigoBarras',
        p_produto_data->>'unidade',
        (p_produto_data->>'precoVenda')::numeric,
        (p_produto_data->>'custoMedio')::numeric,
        (p_produto_data->>'origem')::public."OrigemProduto",
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
        (p_produto_data->>'embalagemId')::uuid,
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
        p_produto_data->>'observacoes'
    ) RETURNING id INTO v_produto_id;

    FOR atributo IN SELECT * FROM jsonb_array_elements(p_atributos)
    LOOP
        INSERT INTO produto_atributos (produto_id, atributo, valor)
        VALUES (v_produto_id, atributo->>'atributo', atributo->>'valor');
    END LOOP;

    FOR fornecedor IN SELECT * FROM jsonb_array_elements(p_fornecedores)
    LOOP
        INSERT INTO produto_fornecedores (produto_id, fornecedor_id, codigo_no_fornecedor)
        VALUES (v_produto_id, (fornecedor->>'fornecedorId')::uuid, fornecedor->>'codigoNoFornecedor');
    END LOOP;

    SELECT row_to_json(p) INTO v_produto_criado FROM (
        SELECT * FROM produtos WHERE id = v_produto_id
    ) p;

    RETURN v_produto_criado;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_produto_completo(p_produto_id uuid, p_produto_data jsonb, p_atributos jsonb, p_fornecedores jsonb)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_empresa_id uuid;
    v_produto_atualizado json;
    atributo jsonb;
    fornecedor jsonb;
BEGIN
    SET search_path = 'public';
    SELECT empresa_id INTO v_empresa_id FROM produtos WHERE id = p_produto_id;
    IF NOT is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Usuário não tem permissão para esta empresa';
    END IF;

    UPDATE produtos SET
        nome = p_produto_data->>'nome',
        tipo = (p_produto_data->>'tipo')::public."TipoProduto",
        situacao = (p_produto_data->>'situacao')::public."SituacaoProduto",
        codigo = p_produto_data->>'codigo',
        codigo_barras = p_produto_data->>'codigoBarras',
        unidade = p_produto_data->>'unidade',
        preco_venda = (p_produto_data->>'precoVenda')::numeric,
        custo_medio = (p_produto_data->>'custoMedio')::numeric,
        origem = (p_produto_data->>'origem')::public."OrigemProduto",
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
        embalagem_id = (p_produto_data->>'embalagemId')::uuid,
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
        updated_at = now()
    WHERE id = p_produto_id;

    DELETE FROM produto_atributos WHERE produto_id = p_produto_id;
    FOR atributo IN SELECT * FROM jsonb_array_elements(p_atributos) LOOP
        INSERT INTO produto_atributos (produto_id, atributo, valor)
        VALUES (p_produto_id, atributo->>'atributo', atributo->>'valor');
    END LOOP;

    DELETE FROM produto_fornecedores WHERE produto_id = p_produto_id;
    FOR fornecedor IN SELECT * FROM jsonb_array_elements(p_fornecedores) LOOP
        INSERT INTO produto_fornecedores (produto_id, fornecedor_id, codigo_no_fornecedor)
        VALUES (p_produto_id, (fornecedor->>'fornecedorId')::uuid, fornecedor->>'codigoNoFornecedor');
    END LOOP;

    SELECT row_to_json(p) INTO v_produto_atualizado FROM (
        SELECT * FROM produtos WHERE id = p_produto_id
    ) p;

    RETURN v_produto_atualizado;
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_produto(p_id uuid)
RETURNS text[]
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_empresa_id uuid;
    image_paths text[];
BEGIN
    SET search_path = 'public';
    SELECT empresa_id INTO v_empresa_id FROM produtos WHERE id = p_id;
    IF NOT is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Usuário não tem permissão para esta empresa';
    END IF;

    SELECT array_agg(storage_path) INTO image_paths FROM produto_imagens WHERE produto_id = p_id;
    
    DELETE FROM produtos WHERE id = p_id;

    RETURN image_paths;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_produto_imagem(p_produto_id uuid, p_storage_path text, p_filename text, p_content_type text, p_tamanho_bytes bigint)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_empresa_id uuid;
  new_imagem produto_imagens;
BEGIN
  SET search_path = 'public';
  SELECT empresa_id INTO v_empresa_id FROM produtos WHERE id = p_produto_id;
  IF NOT is_member_of_empresa(v_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não tem permissão para esta empresa';
  END IF;

  INSERT INTO produto_imagens (produto_id, storage_path, nome_arquivo, content_type, tamanho_bytes)
  VALUES (p_produto_id, p_storage_path, p_filename, p_content_type, p_tamanho_bytes)
  RETURNING * INTO new_imagem;
  
  RETURN row_to_json(new_imagem);
END;
$$;

-- Funções de Vendedores
CREATE OR REPLACE FUNCTION public.create_vendedor(p_empresa_id uuid, p_nome text, p_fantasia text, p_codigo text, p_tipo_pessoa public."TipoPessoaVendedor", p_cpf_cnpj text, p_documento_identificacao text, p_pais text, p_contribuinte_icms public."TipoContribuinteIcms", p_inscricao_estadual text, p_situacao public."SituacaoVendedor", p_cep text, p_logradouro text, p_numero text, p_complemento text, p_bairro text, p_cidade text, p_uf text, p_telefone text, p_celular text, p_email text, p_email_comunicacao text, p_deposito_padrao text, p_senha text, p_acesso_restrito_horario boolean, p_acesso_restrito_ip text, p_perfil_contato text[], p_permissoes_modulos jsonb, p_regra_liberacao_comissao public."RegraLiberacaoComissao", p_tipo_comissao public."TipoComissao", p_aliquota_comissao numeric, p_desconsiderar_comissionamento_linhas_produto boolean, p_observacoes_comissao text, p_contatos jsonb)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_vendedor_id uuid;
  contato jsonb;
BEGIN
  SET search_path = 'public';
  IF NOT is_member_of_empresa(p_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não tem permissão para esta empresa';
  END IF;

  INSERT INTO vendedores (empresa_id, nome, fantasia, codigo, tipo_pessoa, cpf_cnpj, documento_identificacao, pais, contribuinte_icms, inscricao_estadual, situacao, cep, logradouro, numero, complemento, bairro, cidade, uf, telefone, celular, email, email_comunicacao, deposito_padrao, senha, acesso_restrito_horario, acesso_restrito_ip, perfil_contato, permissoes_modulos, regra_liberacao_comissao, tipo_comissao, aliquota_comissao, desconsiderar_comissionamento_linhas_produto, observacoes_comissao)
  VALUES (p_empresa_id, p_nome, p_fantasia, p_codigo, p_tipo_pessoa, p_cpf_cnpj, p_documento_identificacao, p_pais, p_contribuinte_icms, p_inscricao_estadual, p_situacao, p_cep, p_logradouro, p_numero, p_complemento, p_bairro, p_cidade, p_uf, p_telefone, p_celular, p_email, p_email_comunicacao, p_deposito_padrao, p_senha, p_acesso_restrito_horario, p_acesso_restrito_ip, p_perfil_contato, p_permissoes_modulos, p_regra_liberacao_comissao, p_tipo_comissao, p_aliquota_comissao, p_desconsiderar_comissionamento_linhas_produto, p_observacoes_comissao)
  RETURNING id INTO v_vendedor_id;

  FOR contato IN SELECT * FROM jsonb_array_elements(p_contatos)
  LOOP
    INSERT INTO vendedores_contatos (empresa_id, vendedor_id, nome, setor, email, telefone, ramal)
    VALUES (p_empresa_id, v_vendedor_id, contato->>'nome', contato->>'setor', contato->>'email', contato->>'telefone', contato->>'ramal');
  END LOOP;

  RETURN v_vendedor_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_vendedor(p_id uuid, p_nome text, p_fantasia text, p_codigo text, p_tipo_pessoa public."TipoPessoaVendedor", p_cpf_cnpj text, p_documento_identificacao text, p_pais text, p_contribuinte_icms public."TipoContribuinteIcms", p_inscricao_estadual text, p_situacao public."SituacaoVendedor", p_cep text, p_logradouro text, p_numero text, p_complemento text, p_bairro text, p_cidade text, p_uf text, p_telefone text, p_celular text, p_email text, p_email_comunicacao text, p_deposito_padrao text, p_senha text, p_acesso_restrito_horario boolean, p_acesso_restrito_ip text, p_perfil_contato text[], p_permissoes_modulos jsonb, p_regra_liberacao_comissao public."RegraLiberacaoComissao", p_tipo_comissao public."TipoComissao", p_aliquota_comissao numeric, p_desconsiderar_comissionamento_linhas_produto boolean, p_observacoes_comissao text, p_contatos jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_empresa_id uuid;
  contato jsonb;
BEGIN
  SET search_path = 'public';
  SELECT empresa_id INTO v_empresa_id FROM vendedores WHERE id = p_id;
  IF NOT is_member_of_empresa(v_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não tem permissão para esta empresa';
  END IF;

  UPDATE vendedores SET
    nome = p_nome, fantasia = p_fantasia, codigo = p_codigo, tipo_pessoa = p_tipo_pessoa, cpf_cnpj = p_cpf_cnpj, documento_identificacao = p_documento_identificacao, pais = p_pais, contribuinte_icms = p_contribuinte_icms, inscricao_estadual = p_inscricao_estadual, situacao = p_situacao, cep = p_cep, logradouro = p_logradouro, numero = p_numero, complemento = p_complemento, bairro = p_bairro, cidade = p_cidade, uf = p_uf, telefone = p_telefone, celular = p_celular, email = p_email, email_comunicacao = p_email_comunicacao, deposito_padrao = p_deposito_padrao, acesso_restrito_horario = p_acesso_restrito_horario, acesso_restrito_ip = p_acesso_restrito_ip, perfil_contato = p_perfil_contato, permissoes_modulos = p_permissoes_modulos, regra_liberacao_comissao = p_regra_liberacao_comissao, tipo_comissao = p_tipo_comissao, aliquota_comissao = p_aliquota_comissao, desconsiderar_comissionamento_linhas_produto = p_desconsiderar_comissionamento_linhas_produto, observacoes_comissao = p_observacoes_comissao, updated_at = now()
  WHERE id = p_id;
  
  IF p_senha IS NOT NULL AND p_senha <> '' THEN
    UPDATE vendedores SET senha = p_senha WHERE id = p_id;
  END IF;

  DELETE FROM vendedores_contatos WHERE vendedor_id = p_id;
  FOR contato IN SELECT * FROM jsonb_array_elements(p_contatos)
  LOOP
    INSERT INTO vendedores_contatos (empresa_id, vendedor_id, nome, setor, email, telefone, ramal)
    VALUES (v_empresa_id, p_id, contato->>'nome', contato->>'setor', contato->>'email', contato->>'telefone', contato->>'ramal');
  END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_vendedor(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_empresa_id uuid;
BEGIN
  SET search_path = 'public';
  SELECT empresa_id INTO v_empresa_id FROM vendedores WHERE id = p_id;
  IF NOT is_member_of_empresa(v_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não tem permissão para esta empresa';
  END IF;
  DELETE FROM vendedores WHERE id = p_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.check_vendedor_email_exists(p_empresa_id uuid, p_email text, p_vendedor_id uuid DEFAULT NULL)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  SET search_path = 'public';
  IF NOT is_member_of_empresa(p_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não tem permissão para esta empresa';
  END IF;
  
  IF p_vendedor_id IS NULL THEN
    RETURN EXISTS (SELECT 1 FROM vendedores WHERE empresa_id = p_empresa_id AND email = p_email);
  ELSE
    RETURN EXISTS (SELECT 1 FROM vendedores WHERE empresa_id = p_empresa_id AND email = p_email AND id <> p_vendedor_id);
  END IF;
END;
$$;

-- Funções de Papéis e Permissões
CREATE OR REPLACE FUNCTION public.set_papel_permissions(p_papel_id uuid, p_permission_ids text[])
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_empresa_id uuid;
BEGIN
    SET search_path = 'public';
    SELECT empresa_id INTO v_empresa_id FROM papeis WHERE id = p_papel_id;
    IF NOT is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Usuário não tem permissão para esta empresa';
    END IF;

    DELETE FROM papel_permissoes WHERE papel_id = p_papel_id;

    INSERT INTO papel_permissoes (papel_id, permissao_id)
    SELECT p_papel_id, unnest(p_permission_ids);
END;
$$;

-- Outras funções
CREATE OR REPLACE FUNCTION public.create_empresa_and_link_owner_client(p_razao_social text, p_fantasia text, p_cnpj text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_empresa_id uuid;
  v_user_id uuid := auth.uid();
BEGIN
  SET search_path = 'public';
  INSERT INTO empresas (razao_social, fantasia, cnpj)
  VALUES (p_razao_social, p_fantasia, p_cnpj)
  RETURNING id INTO v_empresa_id;

  INSERT INTO empresa_usuarios (empresa_id, user_id)
  VALUES (v_empresa_id, v_user_id);
  
  RETURN v_empresa_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_empresa_if_member(p_empresa_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  SET search_path = 'public';
  IF NOT is_member_of_empresa(p_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não tem permissão para esta empresa';
  END IF;
  DELETE FROM empresas WHERE id = p_empresa_id;
END;
$$;

-- Funções de Serviços
CREATE OR REPLACE FUNCTION public.create_servico(p_empresa_id uuid, p_descricao text, p_preco numeric, p_situacao public."SituacaoServico", p_codigo text, p_unidade text, p_codigo_servico text, p_nbs text, p_descricao_complementar text, p_observacoes text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_servico_id uuid;
BEGIN
  SET search_path = 'public';
  IF NOT is_member_of_empresa(p_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não tem permissão para esta empresa';
  END IF;
  INSERT INTO servicos (empresa_id, descricao, preco, situacao, codigo, unidade, codigo_servico, nbs, descricao_complementar, observacoes)
  VALUES (p_empresa_id, p_descricao, p_preco, p_situacao, p_codigo, p_unidade, p_codigo_servico, p_nbs, p_descricao_complementar, p_observacoes)
  RETURNING id INTO v_servico_id;
  RETURN v_servico_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_servico(p_id uuid, p_descricao text, p_preco numeric, p_situacao public."SituacaoServico", p_codigo text, p_unidade text, p_codigo_servico text, p_nbs text, p_descricao_complementar text, p_observacoes text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_empresa_id uuid;
BEGIN
  SET search_path = 'public';
  SELECT empresa_id INTO v_empresa_id FROM servicos WHERE id = p_id;
  IF NOT is_member_of_empresa(v_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não tem permissão para esta empresa';
  END IF;
  UPDATE servicos SET descricao=p_descricao, preco=p_preco, situacao=p_situacao, codigo=p_codigo, unidade=p_unidade, codigo_servico=p_codigo_servico, nbs=p_nbs, descricao_complementar=p_descricao_complementar, observacoes=p_observacoes, updated_at=now() WHERE id=p_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_servico(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_empresa_id uuid;
BEGIN
  SET search_path = 'public';
  SELECT empresa_id INTO v_empresa_id FROM servicos WHERE id = p_id;
  IF NOT is_member_of_empresa(v_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não tem permissão para esta empresa';
  END IF;
  DELETE FROM servicos WHERE id = p_id;
END;
$$;

-- Funções de Embalagens
CREATE OR REPLACE FUNCTION public.create_embalagem(p_empresa_id uuid, p_descricao text, p_tipo public."TipoEmbalagemProduto", p_peso numeric, p_largura numeric, p_altura numeric, p_comprimento numeric, p_diametro numeric)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_id uuid;
BEGIN
  SET search_path = 'public';
  IF NOT is_member_of_empresa(p_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não tem permissão para esta empresa';
  END IF;
  INSERT INTO embalagens (empresa_id, descricao, tipo, peso, largura, altura, comprimento, diametro)
  VALUES (p_empresa_id, p_descricao, p_tipo, p_peso, p_largura, p_altura, p_comprimento, p_diametro)
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_embalagem(p_id uuid, p_descricao text, p_tipo public."TipoEmbalagemProduto", p_peso numeric, p_largura numeric, p_altura numeric, p_comprimento numeric, p_diametro numeric)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_empresa_id uuid;
BEGIN
  SET search_path = 'public';
  SELECT empresa_id INTO v_empresa_id FROM embalagens WHERE id = p_id;
  IF NOT is_member_of_empresa(v_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não tem permissão para esta empresa';
  END IF;
  UPDATE embalagens SET descricao=p_descricao, tipo=p_tipo, peso=p_peso, largura=p_largura, altura=p_altura, comprimento=p_comprimento, diametro=p_diametro, updated_at=now() WHERE id=p_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_embalagem(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_empresa_id uuid;
BEGIN
  SET search_path = 'public';
  SELECT empresa_id INTO v_empresa_id FROM embalagens WHERE id = p_id;
  IF NOT is_member_of_empresa(v_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não tem permissão para esta empresa';
  END IF;
  DELETE FROM embalagens WHERE id = p_id;
END;
$$;

-- Funções de CRM
CREATE OR REPLACE FUNCTION public.create_crm_oportunidade(p_empresa_id uuid, p_oportunidade_data jsonb, p_itens jsonb)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_oportunidade_id uuid;
  item jsonb;
BEGIN
  SET search_path = 'public';
  IF NOT is_member_of_empresa(p_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não tem permissão para esta empresa';
  END IF;
  INSERT INTO crm_oportunidades (empresa_id, titulo, valor, etapa_funil, status, data_fechamento_prevista, cliente_id, vendedor_id, observacoes)
  VALUES (p_empresa_id, p_oportunidade_data->>'titulo', (p_oportunidade_data->>'valor')::numeric, (p_oportunidade_data->>'etapaFunil')::public."CrmEtapaFunil", (p_oportunidade_data->>'status')::public."CrmStatusOportunidade", (p_oportunidade_data->>'dataFechamentoPrevista')::date, (p_oportunidade_data->>'clienteId')::uuid, (p_oportunidade_data->>'vendedorId')::uuid, p_oportunidade_data->>'observacoes')
  RETURNING id INTO v_oportunidade_id;

  FOR item IN SELECT * FROM jsonb_array_elements(p_itens) LOOP
    INSERT INTO crm_oportunidade_itens (oportunidade_id, produto_id, servico_id, descricao, quantidade, valor_unitario, valor_total)
    VALUES (v_oportunidade_id, (item->>'produtoId')::uuid, (item->>'servicoId')::uuid, item->>'descricao', (item->>'quantidade')::numeric, (item->>'valorUnitario')::numeric, ((item->>'quantidade')::numeric * (item->>'valorUnitario')::numeric));
  END LOOP;
  RETURN v_oportunidade_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_crm_oportunidade(p_oportunidade_id uuid, p_oportunidade_data jsonb, p_itens jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_empresa_id uuid;
  item jsonb;
BEGIN
  SET search_path = 'public';
  SELECT empresa_id INTO v_empresa_id FROM crm_oportunidades WHERE id = p_oportunidade_id;
  IF NOT is_member_of_empresa(v_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não tem permissão para esta empresa';
  END IF;
  UPDATE crm_oportunidades SET
    titulo = p_oportunidade_data->>'titulo',
    valor = (p_oportunidade_data->>'valor')::numeric,
    etapa_funil = (p_oportunidade_data->>'etapaFunil')::public."CrmEtapaFunil",
    status = (p_oportunidade_data->>'status')::public."CrmStatusOportunidade",
    data_fechamento_prevista = (p_oportunidade_data->>'dataFechamentoPrevista')::date,
    cliente_id = (p_oportunidade_data->>'clienteId')::uuid,
    vendedor_id = (p_oportunidade_data->>'vendedorId')::uuid,
    observacoes = p_oportunidade_data->>'observacoes',
    updated_at = now()
  WHERE id = p_oportunidade_id;

  DELETE FROM crm_oportunidade_itens WHERE oportunidade_id = p_oportunidade_id;
  FOR item IN SELECT * FROM jsonb_array_elements(p_itens) LOOP
    INSERT INTO crm_oportunidade_itens (oportunidade_id, produto_id, servico_id, descricao, quantidade, valor_unitario, valor_total)
    VALUES (p_oportunidade_id, (item->>'produtoId')::uuid, (item->>'servicoId')::uuid, item->>'descricao', (item->>'quantidade')::numeric, (item->>'valorUnitario')::numeric, ((item->>'quantidade')::numeric * (item->>'valorUnitario')::numeric));
  END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_crm_oportunidade(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_empresa_id uuid;
BEGIN
  SET search_path = 'public';
  SELECT empresa_id INTO v_empresa_id FROM crm_oportunidades WHERE id = p_id;
  IF NOT is_member_of_empresa(v_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não tem permissão para esta empresa';
  END IF;
  DELETE FROM crm_oportunidades WHERE id = p_id;
END;
$$;

-- Funções de Pedidos de Venda
CREATE OR REPLACE FUNCTION public.create_pedido_venda_completo(p_empresa_id uuid, p_pedido_data jsonb, p_itens jsonb)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_pedido_id uuid;
  item jsonb;
BEGIN
  SET search_path = 'public';
  IF NOT is_member_of_empresa(p_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não tem permissão para esta empresa';
  END IF;
  INSERT INTO pedidos_vendas (empresa_id, natureza_operacao, cliente_id, vendedor_id, data_venda, data_prevista_entrega, status, valor_total, desconto, frete_por_conta, valor_frete, transportadora_id, observacoes, observacoes_internas)
  VALUES (p_empresa_id, p_pedido_data->>'naturezaOperacao', (p_pedido_data->>'clienteId')::uuid, (p_pedido_data->>'vendedorId')::uuid, (p_pedido_data->>'dataVenda')::date, (p_pedido_data->>'dataPrevistaEntrega')::date, (p_pedido_data->>'status')::public."StatusPedidoVenda", (p_pedido_data->>'valorTotal')::numeric, (p_pedido_data->>'desconto')::numeric, (p_pedido_data->>'fretePorConta')::public."FretePorConta", (p_pedido_data->>'valorFrete')::numeric, (p_pedido_data->>'transportadoraId')::uuid, p_pedido_data->>'observacoes', p_pedido_data->>'observacoesInternas')
  RETURNING id INTO v_pedido_id;

  FOR item IN SELECT * FROM jsonb_array_elements(p_itens) LOOP
    INSERT INTO pedidos_vendas_itens (pedido_venda_id, produto_id, servico_id, descricao, quantidade, valor_unitario, valor_total)
    VALUES (v_pedido_id, (item->>'produtoId')::uuid, (item->>'servicoId')::uuid, item->>'descricao', (item->>'quantidade')::numeric, (item->>'valorUnitario')::numeric, ((item->>'quantidade')::numeric * (item->>'valorUnitario')::numeric));
  END LOOP;
  RETURN v_pedido_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_pedido_venda_completo(p_pedido_id uuid, p_pedido_data jsonb, p_itens jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_empresa_id uuid;
  item jsonb;
BEGIN
  SET search_path = 'public';
  SELECT empresa_id INTO v_empresa_id FROM pedidos_vendas WHERE id = p_pedido_id;
  IF NOT is_member_of_empresa(v_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não tem permissão para esta empresa';
  END IF;
  UPDATE pedidos_vendas SET
    natureza_operacao = p_pedido_data->>'naturezaOperacao',
    cliente_id = (p_pedido_data->>'clienteId')::uuid,
    vendedor_id = (p_pedido_data->>'vendedorId')::uuid,
    data_venda = (p_pedido_data->>'dataVenda')::date,
    data_prevista_entrega = (p_pedido_data->>'dataPrevistaEntrega')::date,
    status = (p_pedido_data->>'status')::public."StatusPedidoVenda",
    valor_total = (p_pedido_data->>'valorTotal')::numeric,
    desconto = (p_pedido_data->>'desconto')::numeric,
    frete_por_conta = (p_pedido_data->>'fretePorConta')::public."FretePorConta",
    valor_frete = (p_pedido_data->>'valorFrete')::numeric,
    transportadora_id = (p_pedido_data->>'transportadoraId')::uuid,
    observacoes = p_pedido_data->>'observacoes',
    observacoes_internas = p_pedido_data->>'observacoesInternas',
    updated_at = now()
  WHERE id = p_pedido_id;

  DELETE FROM pedidos_vendas_itens WHERE pedido_venda_id = p_pedido_id;
  FOR item IN SELECT * FROM jsonb_array_elements(p_itens) LOOP
    INSERT INTO pedidos_vendas_itens (pedido_venda_id, produto_id, servico_id, descricao, quantidade, valor_unitario, valor_total)
    VALUES (p_pedido_id, (item->>'produtoId')::uuid, (item->>'servicoId')::uuid, item->>'descricao', (item->>'quantidade')::numeric, (item->>'valorUnitario')::numeric, ((item->>'quantidade')::numeric * (item->>'valorUnitario')::numeric));
  END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_pedido_venda(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_empresa_id uuid;
BEGIN
  SET search_path = 'public';
  SELECT empresa_id INTO v_empresa_id FROM pedidos_vendas WHERE id = p_id;
  IF NOT is_member_of_empresa(v_empresa_id) THEN
    RAISE EXCEPTION 'Usuário não tem permissão para esta empresa';
  END IF;
  DELETE FROM pedidos_vendas WHERE id = p_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.search_produtos_e_servicos(p_empresa_id uuid, p_query text)
RETURNS TABLE(id uuid, nome text, preco_venda numeric, tipo text)
LANGUAGE plpgsql
AS $$
BEGIN
  SET search_path = 'public';
  RETURN QUERY
    SELECT p.id, p.nome, p.preco_venda, 'produto' as tipo
    FROM produtos p
    WHERE p.empresa_id = p_empresa_id AND p.nome ILIKE '%' || p_query || '%'
    UNION ALL
    SELECT s.id, s.descricao as nome, s.preco as preco_venda, 'servico' as tipo
    FROM servicos s
    WHERE s.empresa_id = p_empresa_id AND s.descricao ILIKE '%' || p_query || '%';
END;
$$;

-- Parte 5: Recriar todas as políticas de RLS
-- Habilitar RLS em todas as tabelas relevantes
ALTER TABLE public.clientes_fornecedores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clientes_contatos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clientes_anexos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produto_atributos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produto_fornecedores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produto_imagens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.servicos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendedores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendedores_contatos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.embalagens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crm_oportunidades ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crm_oportunidade_itens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos_vendas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos_vendas_itens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.papeis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.papel_permissoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categorias_financeiras ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.formas_pagamento ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.empresa_usuarios ENABLE ROW LEVEL SECURITY;

-- Criar políticas genéricas
CREATE POLICY "Allow members to manage their own company data" ON public.clientes_fornecedores FOR ALL USING (is_member_of_empresa(empresa_id)) WITH CHECK (is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.clientes_contatos FOR ALL USING (is_member_of_empresa(empresa_id)) WITH CHECK (is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.clientes_anexos FOR ALL USING (is_member_of_empresa(empresa_id)) WITH CHECK (is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.produtos FOR ALL USING (is_member_of_empresa(empresa_id)) WITH CHECK (is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.servicos FOR ALL USING (is_member_of_empresa(empresa_id)) WITH CHECK (is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.vendedores FOR ALL USING (is_member_of_empresa(empresa_id)) WITH CHECK (is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.vendedores_contatos FOR ALL USING (is_member_of_empresa(empresa_id)) WITH CHECK (is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.embalagens FOR ALL USING (is_member_of_empresa(empresa_id)) WITH CHECK (is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.crm_oportunidades FOR ALL USING (is_member_of_empresa(empresa_id)) WITH CHECK (is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.pedidos_vendas FOR ALL USING (is_member_of_empresa(empresa_id)) WITH CHECK (is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.papeis FOR ALL USING (is_member_of_empresa(empresa_id)) WITH CHECK (is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.categorias_financeiras FOR ALL USING (is_member_of_empresa(empresa_id)) WITH CHECK (is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.formas_pagamento FOR ALL USING (is_member_of_empresa(empresa_id)) WITH CHECK (is_member_of_empresa(empresa_id));
CREATE POLICY "Allow members to manage their own company data" ON public.empresa_usuarios FOR ALL USING (is_member_of_empresa(empresa_id)) WITH CHECK (is_member_of_empresa(empresa_id));

-- Políticas para tabelas sem `empresa_id` direto
CREATE POLICY "Allow members to manage based on parent" ON public.produto_atributos FOR ALL USING (
  EXISTS (SELECT 1 FROM produtos WHERE produtos.id = produto_atributos.produto_id AND is_member_of_empresa(produtos.empresa_id))
) WITH CHECK (
  EXISTS (SELECT 1 FROM produtos WHERE produtos.id = produto_atributos.produto_id AND is_member_of_empresa(produtos.empresa_id))
);
CREATE POLICY "Allow members to manage based on parent" ON public.produto_fornecedores FOR ALL USING (
  EXISTS (SELECT 1 FROM produtos WHERE produtos.id = produto_fornecedores.produto_id AND is_member_of_empresa(produtos.empresa_id))
) WITH CHECK (
  EXISTS (SELECT 1 FROM produtos WHERE produtos.id = produto_fornecedores.produto_id AND is_member_of_empresa(produtos.empresa_id))
);
CREATE POLICY "Allow members to manage based on parent" ON public.produto_imagens FOR ALL USING (
  EXISTS (SELECT 1 FROM produtos WHERE produtos.id = produto_imagens.produto_id AND is_member_of_empresa(produtos.empresa_id))
) WITH CHECK (
  EXISTS (SELECT 1 FROM produtos WHERE produtos.id = produto_imagens.produto_id AND is_member_of_empresa(produtos.empresa_id))
);
CREATE POLICY "Allow members to manage based on parent" ON public.crm_oportunidade_itens FOR ALL USING (
  EXISTS (SELECT 1 FROM crm_oportunidades WHERE crm_oportunidades.id = crm_oportunidade_itens.oportunidade_id AND is_member_of_empresa(crm_oportunidades.empresa_id))
) WITH CHECK (
  EXISTS (SELECT 1 FROM crm_oportunidades WHERE crm_oportunidades.id = crm_oportunidade_itens.oportunidade_id AND is_member_of_empresa(crm_oportunidades.empresa_id))
);
CREATE POLICY "Allow members to manage based on parent" ON public.pedidos_vendas_itens FOR ALL USING (
  EXISTS (SELECT 1 FROM pedidos_vendas WHERE pedidos_vendas.id = pedidos_vendas_itens.pedido_venda_id AND is_member_of_empresa(pedidos_vendas.empresa_id))
) WITH CHECK (
  EXISTS (SELECT 1 FROM pedidos_vendas WHERE pedidos_vendas.id = pedidos_vendas_itens.pedido_venda_id AND is_member_of_empresa(pedidos_vendas.empresa_id))
);
CREATE POLICY "Allow members to manage based on parent" ON public.papel_permissoes FOR ALL USING (
  EXISTS (SELECT 1 FROM papeis WHERE papeis.id = papel_permissoes.papel_id AND is_member_of_empresa(papeis.empresa_id))
) WITH CHECK (
  EXISTS (SELECT 1 FROM papeis WHERE papeis.id = papel_permissoes.papel_id AND is_member_of_empresa(papeis.empresa_id))
);
