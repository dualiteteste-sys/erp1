CREATE OR REPLACE FUNCTION public.update_cliente_fornecedor_completo(p_cliente_id uuid, p_cliente_data jsonb, p_contatos jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    contato_item jsonb;
    v_empresa_id uuid;
BEGIN
    -- Obter o empresa_id do cliente que está sendo atualizado
    SELECT empresa_id INTO v_empresa_id FROM public.clientes_fornecedores WHERE id = p_cliente_id;

    -- Se não encontrar a empresa, levanta um erro
    IF v_empresa_id IS NULL THEN
        RAISE EXCEPTION 'Cliente com ID % não encontrado', p_cliente_id;
    END IF;

    -- Atualizar os dados principais do cliente/fornecedor
    UPDATE public.clientes_fornecedores
    SET
        nome_razao_social = p_cliente_data->>'nomeRazaoSocial',
        fantasia = p_cliente_data->>'fantasia',
        tipo_pessoa = (p_cliente_data->>'tipoPessoa')::tipo_pessoa,
        tipo_contato = (p_cliente_data->>'tipoContato')::tipo_contato,
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

    -- Deletar os contatos antigos
    DELETE FROM public.clientes_contatos WHERE cliente_fornecedor_id = p_cliente_id;

    -- Inserir os novos contatos, se houver
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
$function$
;
