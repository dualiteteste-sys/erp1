-- Corrige a função de atualização de clientes, garantindo que todos os campos,
-- incluindo 'nome_razao_social', sejam corretamente atualizados.
-- Também adiciona a configuração de segurança para resolver os warnings.

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
    contato_item jsonb;
    v_empresa_id uuid;
BEGIN
    -- Garante que a operação seja feita na empresa correta
    SELECT empresa_id INTO v_empresa_id FROM public.clientes_fornecedores WHERE id = p_cliente_id;
    IF v_empresa_id IS NULL OR NOT is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada ou cliente não encontrado.';
    END IF;

    -- Atualiza a tabela principal, usando COALESCE para manter o valor antigo se o novo for nulo.
    UPDATE public.clientes_fornecedores
    SET
        nome_razao_social = COALESCE(p_cliente_data->>'nome_razao_social', nome_razao_social),
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

    -- Limpa contatos antigos
    DELETE FROM public.clientes_contatos WHERE cliente_fornecedor_id = p_cliente_id;

    -- Insere novos contatos, se houver
    IF jsonb_array_length(p_contatos) > 0 THEN
        FOR contato_item IN SELECT * FROM jsonb_array_elements(p_contatos)
        LOOP
            INSERT INTO public.clientes_contatos (empresa_id, cliente_fornecedor_id, nome, setor, email, telefone, ramal)
            VALUES (
                v_empresa_id,
                p_cliente_id,
                contato_item->>'nome',
                contato_item->>'setor',
                contato_item->>'email',
                contato_item->>'telefone',
                contato_item->>'ramal'
            );
        END LOOP;
    END IF;
END;
$$;
