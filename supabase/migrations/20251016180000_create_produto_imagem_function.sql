/*
          # Operation: Create Missing Function `create_produto_imagem`
          [This script creates the missing RPC function required to save product image metadata to the database after an upload to storage. This function was missing, causing errors when trying to add images to products.]

          ## Query Description: [This operation creates a new database function. It is a safe, non-destructive operation and will not impact any existing data. It simply adds the required logic for a feature to work correctly.]
          
          ## Metadata:
          - Schema-Category: ["Structural"]
          - Impact-Level: ["Low"]
          - Requires-Backup: [false]
          - Reversible: [true]
          
          ## Structure Details:
          - Function: `public.create_produto_imagem`
          
          ## Security Implications:
          - RLS Status: [Not Applicable]
          - Policy Changes: [No]
          - Auth Requirements: [The function checks if the user is a member of the company associated with the product.]
          
          ## Performance Impact:
          - Indexes: [Not Applicable]
          - Triggers: [Not Applicable]
          - Estimated Impact: [None]
          */
CREATE OR REPLACE FUNCTION public.create_produto_imagem(
    p_produto_id uuid,
    p_storage_path text,
    p_filename text,
    p_content_type text,
    p_tamanho_bytes bigint
)
RETURNS produto_imagens -- Return the full row
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_empresa_id uuid;
    new_imagem produto_imagens;
BEGIN
    -- Get the empresa_id from the product to enforce RLS-like checks
    SELECT empresa_id INTO v_empresa_id FROM public.produtos WHERE id = p_produto_id;

    -- Check if the current user is a member of the product's company
    IF NOT private.is_member_of_empresa(auth.uid(), v_empresa_id) THEN
        RAISE EXCEPTION 'Permission denied: User is not a member of the company.';
    END IF;

    -- Insert the new image record
    INSERT INTO public.produto_imagens (produto_id, storage_path, nome_arquivo, content_type, tamanho_bytes, created_by)
    VALUES (p_produto_id, p_storage_path, p_filename, p_content_type, p_tamanho_bytes, auth.uid())
    RETURNING * INTO new_imagem;

    RETURN new_imagem;
END;
$$;
