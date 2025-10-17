-- Recria a função 'create_vendedor' com o search_path seguro
CREATE OR REPLACE FUNCTION public.create_vendedor(p_empresa_id uuid, p_nome text, p_fantasia text, p_codigo text, p_tipo_pessoa public.tipopessoavendedor, p_cpf_cnpj text, p_documento_identificacao text, p_pais text, p_contribuinte_icms public.tipocontribuinteicms, p_inscricao_estadual text, p_situacao public.situacaovendedor, p_cep text, p_logradouro text, p_numero text, p_complemento text, p_bairro text, p_cidade text, p_uf text, p_telefone text, p_celular text, p_email text, p_email_comunicacao text, p_deposito_padrao text, p_senha text, p_acesso_restrito_horario boolean, p_acesso_restrito_ip text, p_perfil_contato text[], p_permissoes_modulos jsonb, p_regra_liberacao_comissao public.regraliberacaocomissao, p_tipo_comissao public.tipocomissao, p_aliquota_comissao numeric, p_desconsiderar_comissionamento_linhas_produto boolean, p_observacoes_comissao text, p_contatos jsonb)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  v_vendedor_id uuid;
  v_user_id uuid;
  contato_item jsonb;
BEGIN
  -- Cria o usuário no Supabase Auth se uma senha for fornecida
  IF p_senha IS NOT NULL AND p_senha <> '' THEN
    v_user_id := auth.uid(); -- Temporário, será substituído pelo ID do novo usuário
    
    INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, recovery_token, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_sent_at, confirmed_at)
    VALUES (current_setting('app.instance_id')::uuid, uuid_generate_v4(), 'authenticated', 'authenticated', p_email, crypt(p_senha, gen_salt('bf')), now(), '', null, null, '{"provider":"email","providers":["email"]}', jsonb_build_object('nome', p_nome), now(), now(), '', '', null, now())
    RETURNING id INTO v_user_id;
  ELSE
    v_user_id := NULL;
  END IF;

  -- Insere o vendedor
  INSERT INTO vendedores (
    empresa_id, user_id, nome, fantasia, codigo, tipo_pessoa, cpf_cnpj, documento_identificacao, pais, contribuinte_icms, inscricao_estadual, situacao,
    cep, logradouro, numero, complemento, bairro, cidade, uf, telefone, celular, email, email_comunicacao,
    deposito_padrao, acesso_restrito_horario, acesso_restrito_ip, perfil_contato, permissoes_modulos,
    regra_liberacao_comissao, tipo_comissao, aliquota_comissao, desconsiderar_comissionamento_linhas_produto, observacoes_comissao
  ) VALUES (
    p_empresa_id, v_user_id, p_nome, p_fantasia, p_codigo, p_tipo_pessoa, p_cpf_cnpj, p_documento_identificacao, p_pais, p_contribuinte_icms, p_inscricao_estadual, p_situacao,
    p_cep, p_logradouro, p_numero, p_complemento, p_bairro, p_cidade, p_uf, p_telefone, p_celular, p_email, p_email_comunicacao,
    p_deposito_padrao, p_acesso_restrito_horario, p_acesso_restrito_ip, p_perfil_contato, p_permissoes_modulos,
    p_regra_liberacao_comissao, p_tipo_comissao, p_aliquota_comissao, p_desconsiderar_comissionamento_linhas_produto, p_observacoes_comissao
  ) RETURNING id INTO v_vendedor_id;

  -- Insere os contatos
  IF p_contatos IS NOT NULL AND jsonb_array_length(p_contatos) > 0 THEN
    FOR contato_item IN SELECT * FROM jsonb_array_elements(p_contatos)
    LOOP
      INSERT INTO vendedores_contatos (empresa_id, vendedor_id, nome, setor, email, telefone, ramal)
      VALUES (
        p_empresa_id,
        v_vendedor_id,
        contato_item->>'nome',
        contato_item->>'setor',
        contato_item->>'email',
        contato_item->>'telefone',
        contato_item->>'ramal'
      );
    END LOOP;
  END IF;

  RETURN v_vendedor_id;
END;
$$;

-- Recria a função 'update_vendedor' com o search_path seguro
CREATE OR REPLACE FUNCTION public.update_vendedor(p_id uuid, p_nome text, p_fantasia text, p_codigo text, p_tipo_pessoa public.tipopessoavendedor, p_cpf_cnpj text, p_documento_identificacao text, p_pais text, p_contribuinte_icms public.tipocontribuinteicms, p_inscricao_estadual text, p_situacao public.situacaovendedor, p_cep text, p_logradouro text, p_numero text, p_complemento text, p_bairro text, p_cidade text, p_uf text, p_telefone text, p_celular text, p_email text, p_email_comunicacao text, p_deposito_padrao text, p_senha text, p_acesso_restrito_horario boolean, p_acesso_restrito_ip text, p_perfil_contato text[], p_permissoes_modulos jsonb, p_regra_liberacao_comissao public.regraliberacaocomissao, p_tipo_comissao public.tipocomissao, p_aliquota_comissao numeric, p_desconsiderar_comissionamento_linhas_produto boolean, p_observacoes_comissao text, p_contatos jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  v_vendedor record;
  contato_item jsonb;
  contato_id_text text;
  contato_id uuid;
  existing_contact_ids uuid[];
BEGIN
  -- Busca o vendedor para obter o user_id
  SELECT * INTO v_vendedor FROM vendedores WHERE id = p_id;

  -- Atualiza a senha no Supabase Auth se fornecida
  IF p_senha IS NOT NULL AND p_senha <> '' AND v_vendedor.user_id IS NOT NULL THEN
    UPDATE auth.users SET encrypted_password = crypt(p_senha, gen_salt('bf')) WHERE id = v_vendedor.user_id;
  END IF;

  -- Atualiza os dados do vendedor
  UPDATE vendedores SET
    nome = p_nome,
    fantasia = p_fantasia,
    codigo = p_codigo,
    tipo_pessoa = p_tipo_pessoa,
    cpf_cnpj = p_cpf_cnpj,
    documento_identificacao = p_documento_identificacao,
    pais = p_pais,
    contribuinte_icms = p_contribuinte_icms,
    inscricao_estadual = p_inscricao_estadual,
    situacao = p_situacao,
    cep = p_cep,
    logradouro = p_logradouro,
    numero = p_numero,
    complemento = p_complemento,
    bairro = p_bairro,
    cidade = p_cidade,
    uf = p_uf,
    telefone = p_telefone,
    celular = p_celular,
    email = p_email,
    email_comunicacao = p_email_comunicacao,
    deposito_padrao = p_deposito_padrao,
    acesso_restrito_horario = p_acesso_restrito_horario,
    acesso_restrito_ip = p_acesso_restrito_ip,
    perfil_contato = p_perfil_contato,
    permissoes_modulos = p_permissoes_modulos,
    regra_liberacao_comissao = p_regra_liberacao_comissao,
    tipo_comissao = p_tipo_comissao,
    aliquota_comissao = p_aliquota_comissao,
    desconsiderar_comissionamento_linhas_produto = p_desconsiderar_comissionamento_linhas_produto,
    observacoes_comissao = p_observacoes_comissao,
    updated_at = now()
  WHERE id = p_id;

  -- Gerencia contatos
  IF p_contatos IS NOT NULL THEN
    -- Coleta os IDs dos contatos que vieram do frontend
    SELECT array_agg((c->>'id')::uuid) INTO existing_contact_ids
    FROM jsonb_array_elements(p_contatos) c
    WHERE c->>'id' IS NOT NULL;

    -- Deleta os contatos que não vieram do frontend
    DELETE FROM vendedores_contatos
    WHERE vendedor_id = p_id AND id NOT IN (SELECT unnest(existing_contact_ids));

    -- Itera sobre os contatos para inserir ou atualizar
    FOR contato_item IN SELECT * FROM jsonb_array_elements(p_contatos)
    LOOP
      contato_id_text := contato_item->>'id';
      
      IF contato_id_text IS NULL OR NOT public.is_valid_uuid(contato_id_text) THEN
        -- Insere novo contato
        INSERT INTO vendedores_contatos (empresa_id, vendedor_id, nome, setor, email, telefone, ramal)
        VALUES (v_vendedor.empresa_id, p_id, contato_item->>'nome', contato_item->>'setor', contato_item->>'email', contato_item->>'telefone', contato_item->>'ramal');
      ELSE
        contato_id := contato_id_text::uuid;
        -- Atualiza contato existente
        UPDATE vendedores_contatos SET
          nome = contato_item->>'nome',
          setor = contato_item->>'setor',
          email = contato_item->>'email',
          telefone = contato_item->>'telefone',
          ramal = contato_item->>'ramal',
          updated_at = now()
        WHERE id = contato_id;
      END IF;
    END LOOP;
  END IF;
END;
$$;

-- Recria a função 'delete_vendedor' com o search_path seguro
CREATE OR REPLACE FUNCTION public.delete_vendedor(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  v_user_id uuid;
BEGIN
  -- Encontra o user_id associado ao vendedor
  SELECT user_id INTO v_user_id FROM vendedores WHERE id = p_id;

  -- Deleta o vendedor da tabela 'vendedores'
  DELETE FROM vendedores WHERE id = p_id;

  -- Se houver um usuário associado no Supabase Auth, deleta-o
  IF v_user_id IS NOT NULL THEN
    DELETE FROM auth.users WHERE id = v_user_id;
  END IF;
END;
$$;


-- Recria a função 'check_vendedor_email_exists' com o search_path seguro
CREATE OR REPLACE FUNCTION public.check_vendedor_email_exists(p_empresa_id uuid, p_email text, p_vendedor_id uuid DEFAULT NULL)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  IF p_vendedor_id IS NOT NULL THEN
    -- Se estiver editando, verifica se o e-mail existe em OUTRO vendedor
    RETURN EXISTS (
      SELECT 1
      FROM vendedores
      WHERE empresa_id = p_empresa_id
        AND email = p_email
        AND id <> p_vendedor_id
    );
  ELSE
    -- Se estiver criando, verifica se o e-mail já existe
    RETURN EXISTS (
      SELECT 1
      FROM vendedores
      WHERE empresa_id = p_empresa_id
        AND email = p_email
    );
  END IF;
END;
$$;

-- Recria a função 'is_valid_uuid' com o search_path seguro
CREATE OR REPLACE FUNCTION public.is_valid_uuid(text)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  RETURN $1 ~* '^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$';
EXCEPTION
  WHEN others THEN
    RETURN false;
END;
$$;
