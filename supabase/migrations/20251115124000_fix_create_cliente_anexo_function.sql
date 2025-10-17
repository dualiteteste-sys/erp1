/*
          # [Fix] Recria a função create_cliente_anexo
          Corrige o erro "cannot change return type of existing function" ao dropar e recriar a função com o tipo de retorno correto.

          ## Query Description: [Esta operação remove e recria uma função do banco de dados. Não há risco de perda de dados, mas a função ficará indisponível por um instante durante a migração.]
          
          ## Metadata:
          - Schema-Category: ["Structural"]
          - Impact-Level: ["Low"]
          - Requires-Backup: [false]
          - Reversible: [false]
          
          ## Structure Details:
          - Afeta a função: public.create_cliente_anexo
          
          ## Security Implications:
          - RLS Status: [N/A]
          - Policy Changes: [No]
          - Auth Requirements: [N/A]
          
          ## Performance Impact:
          - Indexes: [N/A]
          - Triggers: [N/A]
          - Estimated Impact: [Nenhum impacto de performance esperado.]
          */

-- Remove a função existente que está com o tipo de retorno incorreto.
DROP FUNCTION IF EXISTS public.create_cliente_anexo(uuid,uuid,text,text,text,bigint);

-- Recria a função com o tipo de retorno correto (a tabela clientes_anexos) e a configuração de segurança.
CREATE OR REPLACE FUNCTION public.create_cliente_anexo(
    p_empresa_id uuid,
    p_cliente_id uuid,
    p_storage_path text,
    p_filename text,
    p_content_type text,
    p_tamanho_bytes bigint
)
RETURNS clientes_anexos
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    new_anexo clientes_anexos;
BEGIN
    -- Verifica se o usuário é membro da empresa
    IF NOT is_member_of_empresa(p_empresa_id) THEN
        RAISE EXCEPTION 'Acesso negado: Você não é membro da empresa especificada.';
    END IF;

    INSERT INTO clientes_anexos (empresa_id, cliente_fornecedor_id, storage_path, filename, content_type, tamanho_bytes)
    VALUES (p_empresa_id, p_cliente_id, p_storage_path, p_filename, p_content_type, p_tamanho_bytes)
    RETURNING * INTO new_anexo;

    RETURN new_anexo;
END;
$$;
