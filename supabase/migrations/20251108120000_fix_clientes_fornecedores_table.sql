-- Migration to add missing columns and fix client update function

-- Add missing columns to clientes_fornecedores
ALTER TABLE public.clientes_fornecedores ADD COLUMN IF NOT EXISTS rg TEXT;
ALTER TABLE public.clientes_fornecedores ADD COLUMN IF NOT EXISTS rnm TEXT;

-- Recreate the create function to include new columns and security settings
CREATE OR REPLACE FUNCTION public.create_cliente_fornecedor_completo(
    p_empresa_id uuid,
    p_cliente_data jsonb,
    p_contatos jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_cliente_id uuid;
    contato jsonb;
BEGIN
    -- Ensure the user is a member of the company
    IF NOT is_member_of_empresa(p_empresa_id) THEN
        RAISE EXCEPTION 'Permission denied: User is not a member of the specified company.';
    END IF;

    INSERT INTO public.clientes_fornecedores (
        empresa_id, nome_razao_social, fantasia, tipo_pessoa, tipo_contato, cnpj_cpf,
        inscricao_estadual, inscricao_municipal, rg, rnm, cep, endereco, numero, complemento,
        bairro, municipio, uf, cobranca_diferente, cobr_cep, cobr_endereco, cobr_numero,
        cobr_complemento, cobr_bairro, cobr_municipio, cobr_uf, telefone, telefone_adicional,
        celular, email, email_nfe, website, observacoes, created_by
    )
    VALUES (
        p_empresa_id,
        p_cliente_data->>'nomeRazaoSocial',
        p_cliente_data->>'fantasia',
        (p_cliente_data->>'tipoPessoa')::tipo_pessoa,
        (p_cliente_data->>'tipoContato')::tipo_contato,
        p_cliente_data->>'cnpjCpf',
        p_cliente_data->>'inscricaoEstadual',
        p_cliente_data->>'inscricaoMunicipal',
        p_cliente_data->>'rg', -- Added column
        p_cliente_data->>'rnm', -- Added column
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
    )
    RETURNING id INTO v_cliente_id;

    -- Insert contatos
    IF p_contatos IS NOT NULL AND jsonb_array_length(p_contatos) > 0 THEN
        FOR contato IN SELECT * FROM jsonb_array_elements(p_contatos)
        LOOP
            INSERT INTO public.clientes_contatos (empresa_id, cliente_fornecedor_id, nome, setor, email, telefone, ramal, created_by)
            VALUES (
                p_empresa_id,
                v_cliente_id,
                contato->>'nome',
                contato->>'setor',
                contato->>'email',
                contato->>'telefone',
                contato->>'ramal',
                auth.uid()
            );
        END LOOP;
    END IF;

    RETURN v_cliente_id;
END;
$$;

-- Recreate the update function to include new columns and security settings
CREATE OR REPLACE FUNCTION public.update_cliente_fornecedor_completo(
    p_cliente_id uuid,
    p_cliente_data jsonb,
    p_contatos jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_empresa_id uuid;
    contato jsonb;
BEGIN
    -- Get the empresa_id from the existing record to check ownership
    SELECT empresa_id INTO v_empresa_id FROM public.clientes_fornecedores WHERE id = p_cliente_id;

    IF v_empresa_id IS NULL THEN
        RAISE EXCEPTION 'Cliente/Fornecedor com ID % não encontrado.', p_cliente_id;
    END IF;

    -- Ensure the user is a member of the company
    IF NOT is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Permission denied: User is not a member of the company.';
    END IF;

    UPDATE public.clientes_fornecedores
    SET
        nome_razao_social = p_cliente_data->>'nomeRazaoSocial',
        fantasia = p_cliente_data->>'fantasia',
        tipo_pessoa = (p_cliente_data->>'tipoPessoa')::tipo_pessoa,
        tipo_contato = (p_cliente_data->>'tipoContato')::tipo_contato,
        cnpj_cpf = p_cliente_data->>'cnpjCpf',
        inscricao_estadual = p_cliente_data->>'inscricaoEstadual',
        inscricao_municipal = p_cliente_data->>'inscricaoMunicipal',
        rg = p_cliente_data->>'rg', -- Added column
        rnm = p_cliente_data->>'rnm', -- Added column
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

    -- Delete old contatos
    DELETE FROM public.clientes_contatos WHERE cliente_fornecedor_id = p_cliente_id;

    -- Insert new contatos
    IF p_contatos IS NOT NULL AND jsonb_array_length(p_contatos) > 0 THEN
        FOR contato IN SELECT * FROM jsonb_array_elements(p_contatos)
        LOOP
            INSERT INTO public.clientes_contatos (empresa_id, cliente_fornecedor_id, nome, setor, email, telefone, ramal, created_by)
            VALUES (
                v_empresa_id,
                p_cliente_id,
                contato->>'nome',
                contato->>'setor',
                contato->>'email',
                contato->>'telefone',
                contato->>'ramal',
                auth.uid()
            );
        END LOOP;
    END IF;
END;
$$;
