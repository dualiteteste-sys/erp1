/*
  # Recriação da Função 'update_cliente_fornecedor_completo'
  [Recria a função essencial para atualizar clientes e seus contatos, corrigindo o erro "Could not find function".]

  ## Query Description: [Este script recria a função `update_cliente_fornecedor_completo`. A função anterior foi perdida durante as tentativas de corrigir os avisos de segurança. Esta versão garante que a edição de clientes e fornecedores volte a funcionar corretamente, atualizando os dados principais e sincronizando os contatos adicionais em uma única transação.]

  ## Metadata:
  - Schema-Category: ["Structural"]
  - Impact-Level: ["Medium"]
  - Requires-Backup: [false]
  - Reversible: [false]

  ## Structure Details:
  - Cria a função: `update_cliente_fornecedor_completo(p_cliente_id uuid, p_cliente_data jsonb, p_contatos jsonb)`

  ## Security Implications:
  - RLS Status: [N/A]
  - Policy Changes: [No]
  - Auth Requirements: [A função verifica a permissão do usuário internamente.]

  ## Performance Impact:
  - Indexes: [N/A]
  - Triggers: [N/A]
  - Estimated Impact: [Nenhum impacto negativo. Corrige uma funcionalidade quebrada.]
*/
CREATE OR REPLACE FUNCTION public.update_cliente_fornecedor_completo(p_cliente_id uuid, p_cliente_data jsonb, p_contatos jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_empresa_id uuid;
    contato_record jsonb;
BEGIN
    -- Garante que o usuário pertence à empresa do cliente
    SELECT empresa_id INTO v_empresa_id FROM public.clientes_fornecedores WHERE id = p_cliente_id;

    IF v_empresa_id IS NULL OR NOT public.is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Permissão negada: você não pode modificar este cliente.';
    END IF;

    -- Atualiza a tabela principal de clientes_fornecedores
    UPDATE public.clientes_fornecedores
    SET
        nome_razao_social = p_cliente_data->>'nome_razao_social',
        fantasia = p_cliente_data->>'fantasia',
        tipo_pessoa = (p_cliente_data->>'tipo_pessoa')::public.tipo_pessoa,
        tipo_contato = (p_cliente_data->>'tipo_contato')::public.tipo_contato,
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

    -- Deleta contatos antigos
    DELETE FROM public.clientes_contatos WHERE cliente_fornecedor_id = p_cliente_id;

    -- Insere os novos contatos
    IF jsonb_array_length(p_contatos) > 0 THEN
        FOR contato_record IN SELECT * FROM jsonb_array_elements(p_contatos)
        LOOP
            INSERT INTO public.clientes_contatos (empresa_id, cliente_fornecedor_id, nome, setor, email, telefone, ramal)
            VALUES (
                v_empresa_id,
                p_cliente_id,
                contato_record->>'nome',
                contato_record->>'setor',
                contato_record->>'email',
                contato_record->>'telefone',
                contato_record->>'ramal'
            );
        END LOOP;
    END IF;
END;
$$;
