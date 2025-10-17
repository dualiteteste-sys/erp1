/*
          # [Function] `update_cliente_fornecedor_completo`
          Recria a função para atualizar um cliente/fornecedor e seus contatos.

          ## Query Description: 
          This operation recreates the function responsible for updating client/supplier records and their associated contacts. It first drops the old function to avoid conflicts and then creates a new version with the correct logic. This is a safe operation as it only affects the function definition and does not alter existing data.

          ## Metadata:
          - Schema-Category: "Structural"
          - Impact-Level: "Low"
          - Requires-Backup: false
          - Reversible: true (by restoring the previous function definition, if available)
          
          ## Structure Details:
          - Function: `public.update_cliente_fornecedor_completo`
          
          ## Security Implications:
          - RLS Status: The function uses `SECURITY DEFINER` to perform its operations.
          - Policy Changes: No
          - Auth Requirements: The function internally checks if the calling user is a member of the correct company.
          
          ## Performance Impact:
          - Indexes: None
          - Triggers: None
          - Estimated Impact: Low. The impact is limited to the execution time of the function when updating a client.
          */

DROP FUNCTION IF EXISTS public.update_cliente_fornecedor_completo(uuid, jsonb, jsonb);

CREATE OR REPLACE FUNCTION public.update_cliente_fornecedor_completo(
    p_cliente_id uuid,
    p_cliente_data jsonb,
    p_contatos jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_empresa_id uuid;
    contato jsonb;
BEGIN
    -- 1. Verificar permissão
    SELECT empresa_id INTO v_empresa_id FROM clientes_fornecedores WHERE id = p_cliente_id;
    IF NOT is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Permission denied to update client/supplier in this company.';
    END IF;

    -- 2. Atualizar a tabela principal (clientes_fornecedores)
    UPDATE clientes_fornecedores
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
        updated_at = timezone('utc'::text, now())
    WHERE id = p_cliente_id;

    -- 3. Deletar contatos antigos
    DELETE FROM clientes_contatos WHERE cliente_fornecedor_id = p_cliente_id;

    -- 4. Inserir novos contatos
    IF jsonb_array_length(p_contatos) > 0 THEN
        FOR contato IN SELECT * FROM jsonb_array_elements(p_contatos)
        LOOP
            INSERT INTO clientes_contatos (id, empresa_id, cliente_fornecedor_id, nome, setor, email, telefone, ramal)
            VALUES (
                COALESCE((contato->>'id')::uuid, gen_random_uuid()),
                v_empresa_id,
                p_cliente_id,
                contato->>'nome',
                contato->>'setor',
                contato->>'email',
                contato->>'telefone',
                contato->>'ramal'
            );
        END LOOP;
    END IF;
END;
$$;
