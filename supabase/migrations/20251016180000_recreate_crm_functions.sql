-- Garante que o usuário autenticado é membro da empresa antes de executar a operação.
CREATE OR REPLACE FUNCTION is_member_of_empresa(p_empresa_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM empresa_usuarios
    WHERE empresa_id = p_empresa_id
      AND user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

/*
# [Function] create_crm_oportunidade
Cria uma nova oportunidade de CRM e seus itens associados.

## Query Description:
Esta função insere um novo registro na tabela `crm_oportunidades` e, em seguida, itera sobre um array JSON para inserir os itens correspondentes na tabela `crm_oportunidade_itens`. A operação é transacional e segura, verificando se o usuário pertence à empresa antes de executar a inserção.

## Metadata:
- Schema-Category: "Structural"
- Impact-Level: "Low"
- Requires-Backup: false
- Reversible: false

## Structure Details:
- Tables affected: `crm_oportunidades`, `crm_oportunidade_itens`
- Columns affected: All columns in the mentioned tables.

## Security Implications:
- RLS Status: Enabled
- Policy Changes: No
- Auth Requirements: O usuário deve estar autenticado e ser membro da empresa (`empresa_usuarios`).

## Performance Impact:
- Indexes: Utiliza chaves primárias e estrangeiras.
- Triggers: Nenhum.
- Estimated Impact: Baixo impacto, operações de inserção simples.
*/
CREATE OR REPLACE FUNCTION public.create_crm_oportunidade(
    p_empresa_id uuid,
    p_oportunidade_data jsonb,
    p_itens jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_oportunidade_id uuid;
    item_data jsonb;
BEGIN
    IF NOT is_member_of_empresa(p_empresa_id) THEN
        RAISE EXCEPTION 'Usuário não autorizado para esta empresa.';
    END IF;

    INSERT INTO crm_oportunidades (
        empresa_id,
        titulo,
        valor,
        etapa_funil,
        status,
        data_fechamento_prevista,
        cliente_id,
        vendedor_id,
        observacoes,
        created_by
    )
    VALUES (
        p_empresa_id,
        p_oportunidade_data->>'titulo',
        (p_oportunidade_data->>'valor')::numeric,
        (p_oportunidade_data->>'etapaFunil')::crm_etapa_funil,
        (p_oportunidade_data->>'status')::crm_status_oportunidade,
        (p_oportunidade_data->>'dataFechamentoPrevista')::date,
        (p_oportunidade_data->>'clienteId')::uuid,
        (p_oportunidade_data->>'vendedorId')::uuid,
        p_oportunidade_data->>'observacoes',
        auth.uid()
    )
    RETURNING id INTO v_oportunidade_id;

    IF p_itens IS NOT NULL AND jsonb_array_length(p_itens) > 0 THEN
        FOR item_data IN SELECT * FROM jsonb_array_elements(p_itens)
        LOOP
            INSERT INTO crm_oportunidade_itens (
                oportunidade_id,
                produto_id,
                servico_id,
                descricao,
                quantidade,
                valor_unitario,
                created_by
            )
            VALUES (
                v_oportunidade_id,
                (item_data->>'produtoId')::uuid,
                (item_data->>'servicoId')::uuid,
                item_data->>'descricao',
                (item_data->>'quantidade')::numeric,
                (item_data->>'valorUnitario')::numeric,
                auth.uid()
            );
        END LOOP;
    END IF;

    RETURN v_oportunidade_id;
END;
$$;

/*
# [Function] update_crm_oportunidade
Atualiza uma oportunidade de CRM existente e seus itens.

## Query Description:
Esta função atualiza os dados principais de uma oportunidade e substitui completamente seus itens. Primeiro, ela verifica a permissão do usuário. Em seguida, atualiza a tabela `crm_oportunidades`, remove todos os itens antigos de `crm_oportunidade_itens` e insere os novos itens fornecidos.

## Metadata:
- Schema-Category: "Structural"
- Impact-Level: "Medium"
- Requires-Backup: true
- Reversible: false

## Structure Details:
- Tables affected: `crm_oportunidades`, `crm_oportunidade_itens`
- Columns affected: All columns in the mentioned tables.

## Security Implications:
- RLS Status: Enabled
- Policy Changes: No
- Auth Requirements: O usuário deve estar autenticado e ser membro da empresa.

## Performance Impact:
- Indexes: Utiliza chaves primárias e estrangeiras.
- Triggers: Nenhum.
- Estimated Impact: Médio, pois envolve operações de UPDATE, DELETE e INSERT.
*/
CREATE OR REPLACE FUNCTION public.update_crm_oportunidade(
    p_oportunidade_id uuid,
    p_oportunidade_data jsonb,
    p_itens jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_empresa_id uuid;
    item_data jsonb;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM crm_oportunidades WHERE id = p_oportunidade_id;
    IF NOT is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Usuário não autorizado para esta empresa.';
    END IF;

    UPDATE crm_oportunidades
    SET
        titulo = p_oportunidade_data->>'titulo',
        valor = (p_oportunidade_data->>'valor')::numeric,
        etapa_funil = (p_oportunidade_data->>'etapaFunil')::crm_etapa_funil,
        status = (p_oportunidade_data->>'status')::crm_status_oportunidade,
        data_fechamento_prevista = (p_oportunidade_data->>'dataFechamentoPrevista')::date,
        cliente_id = (p_oportunidade_data->>'clienteId')::uuid,
        vendedor_id = (p_oportunidade_data->>'vendedorId')::uuid,
        observacoes = p_oportunidade_data->>'observacoes',
        updated_at = now()
    WHERE id = p_oportunidade_id;

    DELETE FROM crm_oportunidade_itens WHERE oportunidade_id = p_oportunidade_id;

    IF p_itens IS NOT NULL AND jsonb_array_length(p_itens) > 0 THEN
        FOR item_data IN SELECT * FROM jsonb_array_elements(p_itens)
        LOOP
            INSERT INTO crm_oportunidade_itens (
                oportunidade_id,
                produto_id,
                servico_id,
                descricao,
                quantidade,
                valor_unitario,
                created_by
            )
            VALUES (
                p_oportunidade_id,
                (item_data->>'produtoId')::uuid,
                (item_data->>'servicoId')::uuid,
                item_data->>'descricao',
                (item_data->>'quantidade')::numeric,
                (item_data->>'valorUnitario')::numeric,
                auth.uid()
            );
        END LOOP;
    END IF;
END;
$$;

/*
# [Function] delete_crm_oportunidade
Deleta uma oportunidade de CRM.

## Query Description:
Esta função remove uma oportunidade da tabela `crm_oportunidades`. Graças à configuração `ON DELETE CASCADE` na chave estrangeira da tabela `crm_oportunidade_itens`, todos os itens associados são automaticamente excluídos. A função verifica a permissão do usuário antes da exclusão.

## Metadata:
- Schema-Category: "Dangerous"
- Impact-Level: "High"
- Requires-Backup: true
- Reversible: false

## Structure Details:
- Tables affected: `crm_oportunidades`, `crm_oportunidade_itens`

## Security Implications:
- RLS Status: Enabled
- Policy Changes: No
- Auth Requirements: O usuário deve estar autenticado e ser membro da empresa.

## Performance Impact:
- Indexes: Utiliza chave primária.
- Triggers: Nenhum.
- Estimated Impact: Baixo, operação de deleção simples.
*/
CREATE OR REPLACE FUNCTION public.delete_crm_oportunidade(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_empresa_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id FROM crm_oportunidades WHERE id = p_id;
    IF NOT is_member_of_empresa(v_empresa_id) THEN
        RAISE EXCEPTION 'Usuário não autorizado para esta empresa.';
    END IF;

    DELETE FROM crm_oportunidades WHERE id = p_id;
END;
$$;
