-- Corrige todos os avisos de segurança "Function Search Path Mutable"
-- recriando todas as funções com a configuração de segurança explícita.

-- Função Auxiliar: is_member_of_empresa
CREATE OR REPLACE FUNCTION public.is_member_of_empresa(p_empresa_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM public.empresa_usuarios
        WHERE empresa_id = p_empresa_id AND user_id = auth.uid()
    );
END;
$$;

-- Função Auxiliar: get_empresa_id_for_user
CREATE OR REPLACE FUNCTION public.get_empresa_id_for_user(p_user_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_empresa_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id
    FROM public.empresa_usuarios
    WHERE user_id = p_user_id
    LIMIT 1;
    RETURN v_empresa_id;
END;
$$;

-- Função: create_empresa_and_link_owner_client
CREATE OR REPLACE FUNCTION public.create_empresa_and_link_owner_client(p_razao_social text, p_fantasia text, p_cnpj text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_empresa_id uuid;
BEGIN
    INSERT INTO public.empresas (razao_social, fantasia, cnpj)
    VALUES (p_razao_social, p_fantasia, p_cnpj)
    RETURNING id INTO v_empresa_id;

    INSERT INTO public.empresa_usuarios (empresa_id, user_id, papel)
    VALUES (v_empresa_id, auth.uid(), 'proprietario');

    RETURN v_empresa_id;
END;
$$;

-- Função: delete_empresa_if_member
CREATE OR REPLACE FUNCTION public.delete_empresa_if_member(p_empresa_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
    IF public.is_member_of_empresa(p_empresa_id) THEN
        DELETE FROM public.empresas WHERE id = p_empresa_id;
    ELSE
        RAISE EXCEPTION 'Permissão negada para excluir a empresa.';
    END IF;
END;
$$;

-- Função: create_cliente_anexo
CREATE OR REPLACE FUNCTION public.create_cliente_anexo(p_empresa_id uuid, p_cliente_id uuid, p_storage_path text, p_filename text, p_content_type text, p_tamanho_bytes bigint)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_anexo_id uuid;
    new_anexo json;
BEGIN
    IF NOT public.is_member_of_empresa(p_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada.';
    END IF;

    INSERT INTO public.clientes_anexos (empresa_id, cliente_fornecedor_id, storage_path, filename, content_type, tamanho_bytes)
    VALUES (p_empresa_id, p_cliente_id, p_storage_path, p_filename, p_content_type, p_tamanho_bytes)
    RETURNING id INTO v_anexo_id;

    SELECT to_json(a) INTO new_anexo FROM public.clientes_anexos a WHERE a.id = v_anexo_id;
    RETURN new_anexo;
END;
$$;

-- Função: create_cliente_fornecedor_completo
CREATE OR REPLACE FUNCTION public.create_cliente_fornecedor_completo(p_empresa_id uuid, p_cliente_data jsonb, p_contatos jsonb)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_cliente_id uuid;
    v_contato jsonb;
BEGIN
    IF NOT public.is_member_of_empresa(p_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada.';
    END IF;

    INSERT INTO public.clientes_fornecedores (empresa_id, nome_razao_social, fantasia, tipo_pessoa, tipo_contato, cnpj_cpf, inscricao_estadual, inscricao_municipal, rg, rnm, cep, endereco, numero, complemento, bairro, municipio, uf, cobranca_diferente, cobr_cep, cobr_endereco, cobr_numero, cobr_complemento, cobr_bairro, cobr_municipio, cobr_uf, telefone, telefone_adicional, celular, email, email_nfe, website, observacoes)
    VALUES (
        p_empresa_id,
        p_cliente_data->>'nome_razao_social',
        p_cliente_data->>'fantasia',
        (p_cliente_data->>'tipo_pessoa')::tipo_pessoa,
        (p_cliente_data->>'tipo_contato')::tipo_contato,
        p_cliente_data->>'cnpj_cpf',
        p_cliente_data->>'inscricao_estadual',
        p_cliente_data->>'inscricao_municipal',
        p_cliente_data->>'rg',
        p_cliente_data->>'rnm',
        p_cliente_data->>'cep',
        p_cliente_data->>'endereco',
        p_cliente_data->>'numero',
        p_cliente_data->>'complemento',
        p_cliente_data->>'bairro',
        p_cliente_data->>'municipio',
        p_cliente_data->>'uf',
        (p_cliente_data->>'cobranca_diferente')::boolean,
        p_cliente_data->>'cobr_cep',
        p_cliente_data->>'cobr_endereco',
        p_cliente_data->>'cobr_numero',
        p_cliente_data->>'cobr_complemento',
        p_cliente_data->>'cobr_bairro',
        p_cliente_data->>'cobr_municipio',
        p_cliente_data->>'cobr_uf',
        p_cliente_data->>'telefone',
        p_cliente_data->>'telefone_adicional',
        p_cliente_data->>'celular',
        p_cliente_data->>'email',
        p_cliente_data->>'email_nfe',
        p_cliente_data->>'website',
        p_cliente_data->>'observacoes'
    ) RETURNING id INTO v_cliente_id;

    IF jsonb_array_length(p_contatos) > 0 THEN
        FOR v_contato IN SELECT * FROM jsonb_array_elements(p_contatos)
        LOOP
            INSERT INTO public.clientes_contatos (empresa_id, cliente_fornecedor_id, nome, setor, email, telefone, ramal)
            VALUES (p_empresa_id, v_cliente_id, v_contato->>'nome', v_contato->>'setor', v_contato->>'email', v_contato->>'telefone', v_contato->>'ramal');
        END LOOP;
    END IF;

    RETURN v_cliente_id;
END;
$$;

-- Função: update_cliente_fornecedor_completo
CREATE OR REPLACE FUNCTION public.update_cliente_fornecedor_completo(p_cliente_id uuid, p_cliente_data jsonb, p_contatos jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_empresa_id uuid;
    v_contato jsonb;
    v_contato_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.clientes_fornecedores WHERE id = p_cliente_id;
    IF NOT public.is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada.';
    END IF;

    UPDATE public.clientes_fornecedores SET
        nome_razao_social = p_cliente_data->>'nome_razao_social',
        fantasia = p_cliente_data->>'fantasia',
        tipo_pessoa = (p_cliente_data->>'tipo_pessoa')::tipo_pessoa,
        tipo_contato = (p_cliente_data->>'tipo_contato')::tipo_contato,
        cnpj_cpf = p_cliente_data->>'cnpj_cpf',
        inscricao_estadual = p_cliente_data->>'inscricao_estadual',
        inscricao_municipal = p_cliente_data->>'inscricao_municipal',
        rg = p_cliente_data->>'rg',
        rnm = p_cliente_data->>'rnm',
        cep = p_cliente_data->>'cep',
        endereco = p_cliente_data->>'endereco',
        numero = p_cliente_data->>'numero',
        complemento = p_cliente_data->>'complemento',
        bairro = p_cliente_data->>'bairro',
        municipio = p_cliente_data->>'municipio',
        uf = p_cliente_data->>'uf',
        cobranca_diferente = (p_cliente_data->>'cobranca_diferente')::boolean,
        cobr_cep = p_cliente_data->>'cobr_cep',
        cobr_endereco = p_cliente_data->>'cobr_endereco',
        cobr_numero = p_cliente_data->>'cobr_numero',
        cobr_complemento = p_cliente_data->>'cobr_complemento',
        cobr_bairro = p_cliente_data->>'cobr_bairro',
        cobr_municipio = p_cliente_data->>'cobr_municipio',
        cobr_uf = p_cliente_data->>'cobr_uf',
        telefone = p_cliente_data->>'telefone',
        telefone_adicional = p_cliente_data->>'telefone_adicional',
        celular = p_cliente_data->>'celular',
        email = p_cliente_data->>'email',
        email_nfe = p_cliente_data->>'email_nfe',
        website = p_cliente_data->>'website',
        observacoes = p_cliente_data->>'observacoes',
        updated_at = now()
    WHERE id = p_cliente_id;

    DELETE FROM public.clientes_contatos WHERE cliente_fornecedor_id = p_cliente_id AND id NOT IN (
        SELECT (elem->>'id')::uuid FROM jsonb_array_elements(p_contatos) elem WHERE elem->>'id' IS NOT NULL
    );

    FOR v_contato IN SELECT * FROM jsonb_array_elements(p_contatos)
    LOOP
        v_contato_id := (v_contato->>'id')::uuid;
        IF v_contato_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.clientes_contatos WHERE id = v_contato_id) THEN
            UPDATE public.clientes_contatos SET
                nome = v_contato->>'nome',
                setor = v_contato->>'setor',
                email = v_contato->>'email',
                telefone = v_contato->>'telefone',
                ramal = v_contato->>'ramal'
            WHERE id = v_contato_id;
        ELSE
            INSERT INTO public.clientes_contatos (empresa_id, cliente_fornecedor_id, nome, setor, email, telefone, ramal)
            VALUES (v_empresa_id, p_cliente_id, v_contato->>'nome', v_contato->>'setor', v_contato->>'email', v_contato->>'telefone', v_contato->>'ramal');
        END IF;
    END LOOP;
END;
$$;

-- Função: delete_cliente_fornecedor_if_member
CREATE OR REPLACE FUNCTION public.delete_cliente_fornecedor_if_member(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_empresa_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.clientes_fornecedores WHERE id = p_id;
    IF public.is_member_of_empresa(v_empresa_id) THEN
        DELETE FROM public.clientes_fornecedores WHERE id = p_id;
    ELSE
        RAISE EXCEPTION 'Permissão negada.';
    END IF;
END;
$$;

-- Função: create_produto_imagem
CREATE OR REPLACE FUNCTION public.create_produto_imagem(p_produto_id uuid, p_storage_path text, p_filename text, p_content_type text, p_tamanho_bytes bigint)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_empresa_id uuid;
    new_imagem json;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.produtos WHERE id = p_produto_id;
    IF NOT public.is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada.';
    END IF;

    INSERT INTO public.produto_imagens (produto_id, storage_path, nome_arquivo, content_type, tamanho_bytes)
    VALUES (p_produto_id, p_storage_path, p_filename, p_content_type, p_tamanho_bytes)
    RETURNING to_json(produto_imagens) INTO new_imagem;
    
    RETURN new_imagem;
END;
$$;

-- Função: create_produto_completo
CREATE OR REPLACE FUNCTION public.create_produto_completo(p_empresa_id uuid, p_produto_data jsonb, p_atributos jsonb, p_fornecedores jsonb)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_produto_id uuid;
    v_atributo jsonb;
    v_fornecedor jsonb;
    new_produto json;
BEGIN
    IF NOT public.is_member_of_empresa(p_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada.';
    END IF;

    INSERT INTO public.produtos (empresa_id, nome, tipo, situacao, codigo, codigo_barras, unidade, preco_venda, custo_medio, origem, ncm, cest, controlar_estoque, estoque_inicial, estoque_minimo, estoque_maximo, localizacao, dias_preparacao, controlar_lotes, peso_liquido, peso_bruto, numero_volumes, embalagem_id, largura, altura, comprimento, diametro, marca, modelo, disponibilidade, garantia, video_url, descricao_curta, descricao_complementar, slug, titulo_seo, meta_descricao_seo, observacoes)
    VALUES (
        p_empresa_id,
        p_produto_data->>'nome', (p_produto_data->>'tipo')::tipo_produto, (p_produto_data->>'situacao')::situacao_produto, p_produto_data->>'codigo', p_produto_data->>'codigo_barras', p_produto_data->>'unidade', (p_produto_data->>'preco_venda')::numeric, (p_produto_data->>'custo_medio')::numeric, (p_produto_data->>'origem')::origem_produto, p_produto_data->>'ncm', p_produto_data->>'cest', (p_produto_data->>'controlar_estoque')::boolean, (p_produto_data->>'estoque_inicial')::numeric, (p_produto_data->>'estoque_minimo')::numeric, (p_produto_data->>'estoque_maximo')::numeric, p_produto_data->>'localizacao', (p_produto_data->>'dias_preparacao')::integer, (p_produto_data->>'controlar_lotes')::boolean, (p_produto_data->>'peso_liquido')::numeric, (p_produto_data->>'peso_bruto')::numeric, (p_produto_data->>'numero_volumes')::integer, (p_produto_data->>'embalagem_id')::uuid, (p_produto_data->>'largura')::numeric, (p_produto_data->>'altura')::numeric, (p_produto_data->>'comprimento')::numeric, (p_produto_data->>'diametro')::numeric, p_produto_data->>'marca', p_produto_data->>'modelo', p_produto_data->>'disponibilidade', p_produto_data->>'garantia', p_produto_data->>'video_url', p_produto_data->>'descricao_curta', p_produto_data->>'descricao_complementar', p_produto_data->>'slug', p_produto_data->>'titulo_seo', p_produto_data->>'meta_descricao_seo', p_produto_data->>'observacoes'
    ) RETURNING id INTO v_produto_id;

    IF jsonb_array_length(p_atributos) > 0 THEN
        FOR v_atributo IN SELECT * FROM jsonb_array_elements(p_atributos) LOOP
            INSERT INTO public.produto_atributos (produto_id, atributo, valor) VALUES (v_produto_id, v_atributo->>'atributo', v_atributo->>'valor');
        END LOOP;
    END IF;

    IF jsonb_array_length(p_fornecedores) > 0 THEN
        FOR v_fornecedor IN SELECT * FROM jsonb_array_elements(p_fornecedores) LOOP
            INSERT INTO public.produto_fornecedores (produto_id, fornecedor_id, codigo_no_fornecedor) VALUES (v_produto_id, (v_fornecedor->>'fornecedor_id')::uuid, v_fornecedor->>'codigo_no_fornecedor');
        END LOOP;
    END IF;

    SELECT to_json(p) INTO new_produto FROM public.produtos p WHERE p.id = v_produto_id;
    RETURN new_produto;
END;
$$;

-- Função: update_produto_completo
CREATE OR REPLACE FUNCTION public.update_produto_completo(p_produto_id uuid, p_produto_data jsonb, p_atributos jsonb, p_fornecedores jsonb)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_empresa_id uuid;
    v_atributo jsonb;
    v_fornecedor jsonb;
    updated_produto json;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.produtos WHERE id = p_produto_id;
    IF NOT public.is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada.';
    END IF;

    UPDATE public.produtos SET
        nome = p_produto_data->>'nome', tipo = (p_produto_data->>'tipo')::tipo_produto, situacao = (p_produto_data->>'situacao')::situacao_produto, codigo = p_produto_data->>'codigo', codigo_barras = p_produto_data->>'codigo_barras', unidade = p_produto_data->>'unidade', preco_venda = (p_produto_data->>'preco_venda')::numeric, custo_medio = (p_produto_data->>'custo_medio')::numeric, origem = (p_produto_data->>'origem')::origem_produto, ncm = p_produto_data->>'ncm', cest = p_produto_data->>'cest', controlar_estoque = (p_produto_data->>'controlar_estoque')::boolean, estoque_minimo = (p_produto_data->>'estoque_minimo')::numeric, estoque_maximo = (p_produto_data->>'estoque_maximo')::numeric, localizacao = p_produto_data->>'localizacao', dias_preparacao = (p_produto_data->>'dias_preparacao')::integer, controlar_lotes = (p_produto_data->>'controlar_lotes')::boolean, peso_liquido = (p_produto_data->>'peso_liquido')::numeric, peso_bruto = (p_produto_data->>'peso_bruto')::numeric, numero_volumes = (p_produto_data->>'numero_volumes')::integer, embalagem_id = (p_produto_data->>'embalagem_id')::uuid, largura = (p_produto_data->>'largura')::numeric, altura = (p_produto_data->>'altura')::numeric, comprimento = (p_produto_data->>'comprimento')::numeric, diametro = (p_produto_data->>'diametro')::numeric, marca = p_produto_data->>'marca', modelo = p_produto_data->>'modelo', disponibilidade = p_produto_data->>'disponibilidade', garantia = p_produto_data->>'garantia', video_url = p_produto_data->>'video_url', descricao_curta = p_produto_data->>'descricao_curta', descricao_complementar = p_produto_data->>'descricao_complementar', slug = p_produto_data->>'slug', titulo_seo = p_produto_data->>'titulo_seo', meta_descricao_seo = p_produto_data->>'meta_descricao_seo', observacoes = p_produto_data->>'observacoes', updated_at = now()
    WHERE id = p_produto_id;

    DELETE FROM public.produto_atributos WHERE produto_id = p_produto_id;
    IF jsonb_array_length(p_atributos) > 0 THEN
        FOR v_atributo IN SELECT * FROM jsonb_array_elements(p_atributos) LOOP
            INSERT INTO public.produto_atributos (produto_id, atributo, valor) VALUES (p_produto_id, v_atributo->>'atributo', v_atributo->>'valor');
        END LOOP;
    END IF;

    DELETE FROM public.produto_fornecedores WHERE produto_id = p_produto_id;
    IF jsonb_array_length(p_fornecedores) > 0 THEN
        FOR v_fornecedor IN SELECT * FROM jsonb_array_elements(p_fornecedores) LOOP
            INSERT INTO public.produto_fornecedores (produto_id, fornecedor_id, codigo_no_fornecedor) VALUES (p_produto_id, (v_fornecedor->>'fornecedor_id')::uuid, v_fornecedor->>'codigo_no_fornecedor');
        END LOOP;
    END IF;

    SELECT to_json(p) INTO updated_produto FROM public.produtos p WHERE p.id = p_produto_id;
    RETURN updated_produto;
END;
$$;

-- Função: delete_produto
CREATE OR REPLACE FUNCTION public.delete_produto(p_id uuid)
RETURNS text[]
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_empresa_id uuid;
    v_image_paths text[];
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.produtos WHERE id = p_id;
    IF NOT public.is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada.';
    END IF;

    SELECT array_agg(storage_path) INTO v_image_paths FROM public.produto_imagens WHERE produto_id = p_id;
    DELETE FROM public.produtos WHERE id = p_id;
    RETURN v_image_paths;
END;
$$;

-- Função: create_servico
CREATE OR REPLACE FUNCTION public.create_servico(p_empresa_id uuid, p_descricao text, p_preco numeric, p_situacao text, p_codigo text, p_unidade text, p_codigo_servico text, p_nbs text, p_descricao_complementar text, p_observacoes text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_servico_id uuid;
BEGIN
    IF NOT public.is_member_of_empresa(p_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada.';
    END IF;

    INSERT INTO public.servicos (empresa_id, descricao, preco, situacao, codigo, unidade, codigo_servico, nbs, descricao_complementar, observacoes)
    VALUES (p_empresa_id, p_descricao, p_preco, p_situacao::situacao_servico, p_codigo, p_unidade, p_codigo_servico, p_nbs, p_descricao_complementar, p_observacoes)
    RETURNING id INTO v_servico_id;

    RETURN v_servico_id;
END;
$$;

-- Função: update_servico
CREATE OR REPLACE FUNCTION public.update_servico(p_id uuid, p_descricao text, p_preco numeric, p_situacao text, p_codigo text, p_unidade text, p_codigo_servico text, p_nbs text, p_descricao_complementar text, p_observacoes text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_empresa_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.servicos WHERE id = p_id;
    IF NOT public.is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada.';
    END IF;

    UPDATE public.servicos SET
        descricao = p_descricao,
        preco = p_preco,
        situacao = p_situacao::situacao_servico,
        codigo = p_codigo,
        unidade = p_unidade,
        codigo_servico = p_codigo_servico,
        nbs = p_nbs,
        descricao_complementar = p_descricao_complementar,
        observacoes = p_observacoes,
        updated_at = now()
    WHERE id = p_id;
END;
$$;

-- Função: delete_servico
CREATE OR REPLACE FUNCTION public.delete_servico(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_empresa_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.servicos WHERE id = p_id;
    IF NOT public.is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada.';
    END IF;
    DELETE FROM public.servicos WHERE id = p_id;
END;
$$;

-- Função: check_vendedor_email_exists
CREATE OR REPLACE FUNCTION public.check_vendedor_email_exists(p_empresa_id uuid, p_email text, p_vendedor_id uuid DEFAULT NULL)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.vendedores
        WHERE empresa_id = p_empresa_id
        AND email = p_email
        AND (p_vendedor_id IS NULL OR id <> p_vendedor_id)
    );
END;
$$;

-- Função: create_vendedor
CREATE OR REPLACE FUNCTION public.create_vendedor(p_empresa_id uuid, p_nome text, p_fantasia text, p_codigo text, p_tipo_pessoa text, p_cpf_cnpj text, p_documento_identificacao text, p_pais text, p_contribuinte_icms text, p_inscricao_estadual text, p_situacao text, p_cep text, p_logradouro text, p_numero text, p_complemento text, p_bairro text, p_cidade text, p_uf text, p_telefone text, p_celular text, p_email text, p_email_comunicacao text, p_deposito_padrao text, p_senha text, p_acesso_restrito_horario boolean, p_acesso_restrito_ip text, p_perfil_contato text[], p_permissoes_modulos jsonb, p_regra_liberacao_comissao text, p_tipo_comissao text, p_aliquota_comissao numeric, p_desconsiderar_comissionamento_linhas_produto boolean, p_observacoes_comissao text, p_contatos jsonb)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_vendedor_id uuid;
    v_contato jsonb;
BEGIN
    IF NOT public.is_member_of_empresa(p_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada.';
    END IF;

    INSERT INTO public.vendedores (empresa_id, nome, fantasia, codigo, tipo_pessoa, cpf_cnpj, documento_identificacao, pais, contribuinte_icms, inscricao_estadual, situacao, cep, logradouro, numero, complemento, bairro, cidade, uf, telefone, celular, email, email_comunicacao, deposito_padrao, senha, acesso_restrito_horario, acesso_restrito_ip, perfil_contato, permissoes_modulos, regra_liberacao_comissao, tipo_comissao, aliquota_comissao, desconsiderar_comissionamento_linhas_produto, observacoes_comissao)
    VALUES (p_empresa_id, p_nome, p_fantasia, p_codigo, p_tipo_pessoa::tipo_pessoa_vendedor, p_cpf_cnpj, p_documento_identificacao, p_pais, p_contribuinte_icms::tipo_contribuinte_icms, p_inscricao_estadual, p_situacao::situacao_vendedor, p_cep, p_logradouro, p_numero, p_complemento, p_bairro, p_cidade, p_uf, p_telefone, p_celular, p_email, p_email_comunicacao, p_deposito_padrao, p_senha, p_acesso_restrito_horario, p_acesso_restrito_ip, p_perfil_contato, p_permissoes_modulos, p_regra_liberacao_comissao::regra_liberacao_comissao, p_tipo_comissao::tipo_comissao, p_aliquota_comissao, p_desconsiderar_comissionamento_linhas_produto, p_observacoes_comissao)
    RETURNING id INTO v_vendedor_id;

    IF jsonb_array_length(p_contatos) > 0 THEN
        FOR v_contato IN SELECT * FROM jsonb_array_elements(p_contatos) LOOP
            INSERT INTO public.vendedores_contatos (empresa_id, vendedor_id, nome, setor, email, telefone, ramal)
            VALUES (p_empresa_id, v_vendedor_id, v_contato->>'nome', v_contato->>'setor', v_contato->>'email', v_contato->>'telefone', v_contato->>'ramal');
        END LOOP;
    END IF;

    RETURN v_vendedor_id;
END;
$$;

-- Função: update_vendedor
CREATE OR REPLACE FUNCTION public.update_vendedor(p_id uuid, p_nome text, p_fantasia text, p_codigo text, p_tipo_pessoa text, p_cpf_cnpj text, p_documento_identificacao text, p_pais text, p_contribuinte_icms text, p_inscricao_estadual text, p_situacao text, p_cep text, p_logradouro text, p_numero text, p_complemento text, p_bairro text, p_cidade text, p_uf text, p_telefone text, p_celular text, p_email text, p_email_comunicacao text, p_deposito_padrao text, p_senha text, p_acesso_restrito_horario boolean, p_acesso_restrito_ip text, p_perfil_contato text[], p_permissoes_modulos jsonb, p_regra_liberacao_comissao text, p_tipo_comissao text, p_aliquota_comissao numeric, p_desconsiderar_comissionamento_linhas_produto boolean, p_observacoes_comissao text, p_contatos jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_empresa_id uuid;
    v_contato jsonb;
    v_contato_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.vendedores WHERE id = p_id;
    IF NOT public.is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada.';
    END IF;

    UPDATE public.vendedores SET
        nome = p_nome, fantasia = p_fantasia, codigo = p_codigo, tipo_pessoa = p_tipo_pessoa::tipo_pessoa_vendedor, cpf_cnpj = p_cpf_cnpj, documento_identificacao = p_documento_identificacao, pais = p_pais, contribuinte_icms = p_contribuinte_icms::tipo_contribuinte_icms, inscricao_estadual = p_inscricao_estadual, situacao = p_situacao::situacao_vendedor, cep = p_cep, logradouro = p_logradouro, numero = p_numero, complemento = p_complemento, bairro = p_bairro, cidade = p_cidade, uf = p_uf, telefone = p_telefone, celular = p_celular, email = p_email, email_comunicacao = p_email_comunicacao, deposito_padrao = p_deposito_padrao, acesso_restrito_horario = p_acesso_restrito_horario, acesso_restrito_ip = p_acesso_restrito_ip, perfil_contato = p_perfil_contato, permissoes_modulos = p_permissoes_modulos, regra_liberacao_comissao = p_regra_liberacao_comissao::regra_liberacao_comissao, tipo_comissao = p_tipo_comissao::tipo_comissao, aliquota_comissao = p_aliquota_comissao, desconsiderar_comissionamento_linhas_produto = p_desconsiderar_comissionamento_linhas_produto, observacoes_comissao = p_observacoes_comissao, updated_at = now()
    WHERE id = p_id;

    IF p_senha IS NOT NULL AND p_senha <> '' THEN
        UPDATE public.vendedores SET senha = p_senha WHERE id = p_id;
    END IF;

    DELETE FROM public.vendedores_contatos WHERE vendedor_id = p_id AND id NOT IN (
        SELECT (elem->>'id')::uuid FROM jsonb_array_elements(p_contatos) elem WHERE elem->>'id' IS NOT NULL
    );

    FOR v_contato IN SELECT * FROM jsonb_array_elements(p_contatos) LOOP
        v_contato_id := (v_contato->>'id')::uuid;
        IF v_contato_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.vendedores_contatos WHERE id = v_contato_id) THEN
            UPDATE public.vendedores_contatos SET nome = v_contato->>'nome', setor = v_contato->>'setor', email = v_contato->>'email', telefone = v_contato->>'telefone', ramal = v_contato->>'ramal' WHERE id = v_contato_id;
        ELSE
            INSERT INTO public.vendedores_contatos (empresa_id, vendedor_id, nome, setor, email, telefone, ramal) VALUES (v_empresa_id, p_id, v_contato->>'nome', v_contato->>'setor', v_contato->>'email', v_contato->>'telefone', v_contato->>'ramal');
        END IF;
    END LOOP;
END;
$$;

-- Função: delete_vendedor
CREATE OR REPLACE FUNCTION public.delete_vendedor(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_empresa_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.vendedores WHERE id = p_id;
    IF NOT public.is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada.';
    END IF;
    DELETE FROM public.vendedores WHERE id = p_id;
END;
$$;

-- Função: create_crm_oportunidade
CREATE OR REPLACE FUNCTION public.create_crm_oportunidade(p_empresa_id uuid, p_oportunidade_data jsonb, p_itens jsonb)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_oportunidade_id uuid;
    v_item jsonb;
BEGIN
    IF NOT public.is_member_of_empresa(p_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada.';
    END IF;

    INSERT INTO public.crm_oportunidades (empresa_id, titulo, valor, etapa_funil, status, data_fechamento_prevista, cliente_id, vendedor_id, observacoes)
    VALUES (p_empresa_id, p_oportunidade_data->>'titulo', (p_oportunidade_data->>'valor')::numeric, (p_oportunidade_data->>'etapa_funil')::crm_etapa_funil, (p_oportunidade_data->>'status')::crm_status_oportunidade, (p_oportunidade_data->>'data_fechamento_prevista')::date, (p_oportunidade_data->>'cliente_id')::uuid, (p_oportunidade_data->>'vendedor_id')::uuid, p_oportunidade_data->>'observacoes')
    RETURNING id INTO v_oportunidade_id;

    IF jsonb_array_length(p_itens) > 0 THEN
        FOR v_item IN SELECT * FROM jsonb_array_elements(p_itens) LOOP
            INSERT INTO public.crm_oportunidade_itens (oportunidade_id, produto_id, servico_id, descricao, quantidade, valor_unitario)
            VALUES (v_oportunidade_id, (v_item->>'produto_id')::uuid, (v_item->>'servico_id')::uuid, v_item->>'descricao', (v_item->>'quantidade')::numeric, (v_item->>'valor_unitario')::numeric);
        END LOOP;
    END IF;

    RETURN v_oportunidade_id;
END;
$$;

-- Função: update_crm_oportunidade
CREATE OR REPLACE FUNCTION public.update_crm_oportunidade(p_oportunidade_id uuid, p_oportunidade_data jsonb, p_itens jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_empresa_id uuid;
    v_item jsonb;
    v_item_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.crm_oportunidades WHERE id = p_oportunidade_id;
    IF NOT public.is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada.';
    END IF;

    UPDATE public.crm_oportunidades SET
        titulo = p_oportunidade_data->>'titulo', valor = (p_oportunidade_data->>'valor')::numeric, etapa_funil = (p_oportunidade_data->>'etapa_funil')::crm_etapa_funil, status = (p_oportunidade_data->>'status')::crm_status_oportunidade, data_fechamento_prevista = (p_oportunidade_data->>'data_fechamento_prevista')::date, cliente_id = (p_oportunidade_data->>'cliente_id')::uuid, vendedor_id = (p_oportunidade_data->>'vendedor_id')::uuid, observacoes = p_oportunidade_data->>'observacoes', updated_at = now()
    WHERE id = p_oportunidade_id;

    DELETE FROM public.crm_oportunidade_itens WHERE oportunidade_id = p_oportunidade_id AND id NOT IN (SELECT (elem->>'id')::uuid FROM jsonb_array_elements(p_itens) elem WHERE elem->>'id' IS NOT NULL);

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_itens) LOOP
        v_item_id := (v_item->>'id')::uuid;
        IF v_item_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.crm_oportunidade_itens WHERE id = v_item_id) THEN
            UPDATE public.crm_oportunidade_itens SET produto_id = (v_item->>'produto_id')::uuid, servico_id = (v_item->>'servico_id')::uuid, descricao = v_item->>'descricao', quantidade = (v_item->>'quantidade')::numeric, valor_unitario = (v_item->>'valor_unitario')::numeric WHERE id = v_item_id;
        ELSE
            INSERT INTO public.crm_oportunidade_itens (oportunidade_id, produto_id, servico_id, descricao, quantidade, valor_unitario) VALUES (p_oportunidade_id, (v_item->>'produto_id')::uuid, (v_item->>'servico_id')::uuid, v_item->>'descricao', (v_item->>'quantidade')::numeric, (v_item->>'valor_unitario')::numeric);
        END IF;
    END LOOP;
END;
$$;

-- Função: delete_crm_oportunidade
CREATE OR REPLACE FUNCTION public.delete_crm_oportunidade(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_empresa_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.crm_oportunidades WHERE id = p_id;
    IF NOT public.is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada.';
    END IF;
    DELETE FROM public.crm_oportunidades WHERE id = p_id;
END;
$$;

-- Função: create_pedido_venda_completo
CREATE OR REPLACE FUNCTION public.create_pedido_venda_completo(p_empresa_id uuid, p_pedido_data jsonb, p_itens jsonb)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_pedido_id uuid;
    v_item jsonb;
BEGIN
    IF NOT public.is_member_of_empresa(p_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada.';
    END IF;

    INSERT INTO public.pedidos_vendas (empresa_id, cliente_id, vendedor_id, natureza_operacao, status, data_venda, data_prevista_entrega, valor_total, desconto, frete_por_conta, valor_frete, transportadora_id, observacoes, observacoes_internas)
    VALUES (p_empresa_id, (p_pedido_data->>'cliente_id')::uuid, (p_pedido_data->>'vendedor_id')::uuid, p_pedido_data->>'natureza_operacao', (p_pedido_data->>'status')::status_pedido_venda, (p_pedido_data->>'data_venda')::date, (p_pedido_data->>'data_prevista_entrega')::date, (p_pedido_data->>'valor_total')::numeric, (p_pedido_data->>'desconto')::numeric, (p_pedido_data->>'frete_por_conta')::frete_por_conta, (p_pedido_data->>'valor_frete')::numeric, (p_pedido_data->>'transportadora_id')::uuid, p_pedido_data->>'observacoes', p_pedido_data->>'observacoes_internas')
    RETURNING id INTO v_pedido_id;

    IF jsonb_array_length(p_itens) > 0 THEN
        FOR v_item IN SELECT * FROM jsonb_array_elements(p_itens) LOOP
            INSERT INTO public.pedidos_vendas_itens (pedido_venda_id, produto_id, servico_id, descricao, quantidade, valor_unitario)
            VALUES (v_pedido_id, (v_item->>'produto_id')::uuid, (v_item->>'servico_id')::uuid, v_item->>'descricao', (v_item->>'quantidade')::numeric, (v_item->>'valor_unitario')::numeric);
        END LOOP;
    END IF;

    RETURN v_pedido_id;
END;
$$;

-- Função: update_pedido_venda_completo
CREATE OR REPLACE FUNCTION public.update_pedido_venda_completo(p_pedido_id uuid, p_pedido_data jsonb, p_itens jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_empresa_id uuid;
    v_item jsonb;
    v_item_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.pedidos_vendas WHERE id = p_pedido_id;
    IF NOT public.is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada.';
    END IF;

    UPDATE public.pedidos_vendas SET
        cliente_id = (p_pedido_data->>'cliente_id')::uuid, vendedor_id = (p_pedido_data->>'vendedor_id')::uuid, natureza_operacao = p_pedido_data->>'natureza_operacao', status = (p_pedido_data->>'status')::status_pedido_venda, data_venda = (p_pedido_data->>'data_venda')::date, data_prevista_entrega = (p_pedido_data->>'data_prevista_entrega')::date, valor_total = (p_pedido_data->>'valor_total')::numeric, desconto = (p_pedido_data->>'desconto')::numeric, frete_por_conta = (p_pedido_data->>'frete_por_conta')::frete_por_conta, valor_frete = (p_pedido_data->>'valor_frete')::numeric, transportadora_id = (p_pedido_data->>'transportadora_id')::uuid, observacoes = p_pedido_data->>'observacoes', observacoes_internas = p_pedido_data->>'observacoes_internas', updated_at = now()
    WHERE id = p_pedido_id;

    DELETE FROM public.pedidos_vendas_itens WHERE pedido_venda_id = p_pedido_id AND id NOT IN (SELECT (elem->>'id')::uuid FROM jsonb_array_elements(p_itens) elem WHERE elem->>'id' IS NOT NULL);

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_itens) LOOP
        v_item_id := (v_item->>'id')::uuid;
        IF v_item_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.pedidos_vendas_itens WHERE id = v_item_id) THEN
            UPDATE public.pedidos_vendas_itens SET produto_id = (v_item->>'produto_id')::uuid, servico_id = (v_item->>'servico_id')::uuid, descricao = v_item->>'descricao', quantidade = (v_item->>'quantidade')::numeric, valor_unitario = (v_item->>'valor_unitario')::numeric WHERE id = v_item_id;
        ELSE
            INSERT INTO public.pedidos_vendas_itens (pedido_venda_id, produto_id, servico_id, descricao, quantidade, valor_unitario) VALUES (p_pedido_id, (v_item->>'produto_id')::uuid, (v_item->>'servico_id')::uuid, v_item->>'descricao', (v_item->>'quantidade')::numeric, (v_item->>'valor_unitario')::numeric);
        END IF;
    END LOOP;
END;
$$;

-- Função: delete_pedido_venda
CREATE OR REPLACE FUNCTION public.delete_pedido_venda(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_empresa_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.pedidos_vendas WHERE id = p_id;
    IF NOT public.is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada.';
    END IF;
    DELETE FROM public.pedidos_vendas WHERE id = p_id;
END;
$$;

-- Função: search_produtos_e_servicos
CREATE OR REPLACE FUNCTION public.search_produtos_e_servicos(p_empresa_id uuid, p_query text)
RETURNS TABLE(id uuid, nome text, preco_venda numeric, tipo text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
    RETURN QUERY
    SELECT p.id, p.nome, p.preco_venda, 'produto'::text as tipo
    FROM public.produtos p
    WHERE p.empresa_id = p_empresa_id AND p.nome ILIKE '%' || p_query || '%'
    UNION ALL
    SELECT s.id, s.descricao as nome, s.preco as preco_venda, 'servico'::text as tipo
    FROM public.servicos s
    WHERE s.empresa_id = p_empresa_id AND s.descricao ILIKE '%' || p_query || '%';
END;
$$;

-- Função: create_embalagem
CREATE OR REPLACE FUNCTION public.create_embalagem(p_empresa_id uuid, p_descricao text, p_tipo text, p_peso numeric, p_largura numeric, p_altura numeric, p_comprimento numeric, p_diametro numeric)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_id uuid;
BEGIN
    IF NOT public.is_member_of_empresa(p_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada.';
    END IF;
    INSERT INTO public.embalagens (empresa_id, descricao, tipo, peso, largura, altura, comprimento, diametro)
    VALUES (p_empresa_id, p_descricao, p_tipo::tipo_embalagem_produto, p_peso, p_largura, p_altura, p_comprimento, p_diametro)
    RETURNING id INTO v_id;
    RETURN v_id;
END;
$$;

-- Função: update_embalagem
CREATE OR REPLACE FUNCTION public.update_embalagem(p_id uuid, p_descricao text, p_tipo text, p_peso numeric, p_largura numeric, p_altura numeric, p_comprimento numeric, p_diametro numeric)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_empresa_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.embalagens WHERE id = p_id;
    IF NOT public.is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada.';
    END IF;
    UPDATE public.embalagens SET descricao=p_descricao, tipo=p_tipo::tipo_embalagem_produto, peso=p_peso, largura=p_largura, altura=p_altura, comprimento=p_comprimento, diametro=p_diametro, updated_at=now() WHERE id = p_id;
END;
$$;

-- Função: delete_embalagem
CREATE OR REPLACE FUNCTION public.delete_embalagem(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_empresa_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.embalagens WHERE id = p_id;
    IF NOT public.is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada.';
    END IF;
    DELETE FROM public.embalagens WHERE id = p_id;
END;
$$;

-- Função: set_papel_permissions
CREATE OR REPLACE FUNCTION public.set_papel_permissions(p_papel_id uuid, p_permission_ids text[])
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_empresa_id uuid;
    v_permission_id text;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM public.papeis WHERE id = p_papel_id;
    IF NOT public.is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada.';
    END IF;

    DELETE FROM public.papel_permissoes WHERE papel_id = p_papel_id;

    IF array_length(p_permission_ids, 1) > 0 THEN
        FOREACH v_permission_id IN ARRAY p_permission_ids
        LOOP
            INSERT INTO public.papel_permissoes (papel_id, permissao_id)
            VALUES (p_papel_id, v_permission_id);
        END LOOP;
    END IF;
END;
$$;
