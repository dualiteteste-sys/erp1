-- Migration to add RG/RNM to clients and fix related functions

-- Step 1: Add missing columns to the table
-- This makes the script safe to re-run.
ALTER TABLE public.clientes_fornecedores
ADD COLUMN IF NOT EXISTS rg TEXT,
ADD COLUMN IF NOT EXISTS rnm TEXT;

-- Step 2: Recreate the 'create' function to include the new fields and set a secure search_path.
DROP FUNCTION IF EXISTS public.create_cliente_fornecedor_completo(uuid, jsonb, jsonb);
CREATE OR REPLACE FUNCTION public.create_cliente_fornecedor_completo(
    p_empresa_id uuid,
    p_cliente_data jsonb,
    p_contatos jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
    v_cliente_id uuid;
BEGIN
    -- Insert the main client/supplier record
    INSERT INTO public.clientes_fornecedores (
        empresa_id, nome_razao_social, fantasia, tipo_pessoa, tipo_contato, cnpj_cpf,
        inscricao_estadual, inscricao_municipal, rg, rnm,
        cep, endereco, numero, complemento, bairro, municipio, uf,
        cobranca_diferente, cobr_cep, cobr_endereco, cobr_numero, cobr_complemento, cobr_bairro, cobr_municipio, cobr_uf,
        telefone, telefone_adicional, celular, email, email_nfe, website,
        observacoes, created_by
    )
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
        p_cliente_data->>'observacoes',
        auth.uid()
    ) RETURNING id INTO v_cliente_id;

    -- Insert additional contacts if any
    IF jsonb_array_length(p_contatos) > 0 THEN
        INSERT INTO public.clientes_contatos (empresa_id, cliente_fornecedor_id, nome, setor, email, telefone, ramal, created_by)
        SELECT
            p_empresa_id,
            v_cliente_id,
            c->>'nome',
            c->>'setor',
            c->>'email',
            c->>'telefone',
            c->>'ramal',
            auth.uid()
        FROM jsonb_array_elements(p_contatos) AS c;
    END IF;

    RETURN v_cliente_id;
END;
$$;

-- Step 3: Recreate the 'update' function to include the new fields and set a secure search_path.
DROP FUNCTION IF EXISTS public.update_cliente_fornecedor_completo(uuid, jsonb, jsonb);
CREATE OR REPLACE FUNCTION public.update_cliente_fornecedor_completo(
    p_cliente_id uuid,
    p_cliente_data jsonb,
    p_contatos jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
    contato_item jsonb;
    contato_id_uuid uuid;
BEGIN
    -- Update the main client/supplier record
    UPDATE public.clientes_fornecedores
    SET
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

    -- Sync additional contacts
    -- Delete contacts that are no longer in the list
    DELETE FROM public.clientes_contatos
    WHERE cliente_fornecedor_id = p_cliente_id
      AND id NOT IN (SELECT (c->>'id')::uuid FROM jsonb_array_elements(p_contatos) AS c WHERE c->>'id' IS NOT NULL);

    -- Upsert contacts
    FOR contato_item IN SELECT * FROM jsonb_array_elements(p_contatos)
    LOOP
        contato_id_uuid := (contato_item->>'id')::uuid;

        IF contato_id_uuid IS NOT NULL AND EXISTS (SELECT 1 FROM public.clientes_contatos WHERE id = contato_id_uuid) THEN
            -- Update existing contact
            UPDATE public.clientes_contatos
            SET
                nome = contato_item->>'nome',
                setor = contato_item->>'setor',
                email = contato_item->>'email',
                telefone = contato_item->>'telefone',
                ramal = contato_item->>'ramal',
                updated_at = now()
            WHERE id = contato_id_uuid;
        ELSE
            -- Insert new contact
            INSERT INTO public.clientes_contatos (empresa_id, cliente_fornecedor_id, nome, setor, email, telefone, ramal, created_by)
            VALUES (
                (SELECT empresa_id FROM public.clientes_fornecedores WHERE id = p_cliente_id),
                p_cliente_id,
                contato_item->>'nome',
                contato_item->>'setor',
                contato_item->>'email',
                contato_item->>'telefone',
                contato_item->>'ramal',
                auth.uid()
            );
        END IF;
    END LOOP;
END;
$$;
