/*
          # [Add Vendedor Email Check Function]
          [This script adds an RPC function to check for duplicate emails in the 'vendedores' table, preventing unique constraint violations.]
          ## Query Description: [Creates a new function 'check_vendedor_email_exists' that returns true if a given email is already in use by another vendor in the same company, improving data validation before insertion or update.]
          ## Metadata:
          - Schema-Category: ["Structural"]
          - Impact-Level: ["Low"]
          - Requires-Backup: [false]
          - Reversible: [false]
          ## Structure Details:
          - Functions created: public.check_vendedor_email_exists
          ## Security Implications:
          - RLS Status: [N/A for this function]
          - Policy Changes: [No]
          - Auth Requirements: [None, security is handled by RLS on table access if needed]
          ## Performance Impact:
          - Indexes: [Relies on existing 'vendedores_empresa_id_email_key' index for fast lookups]
          - Triggers: [No changes]
          - Estimated Impact: [Low]
*/
CREATE OR REPLACE FUNCTION public.check_vendedor_email_exists(
    p_empresa_id uuid,
    p_email text,
    p_vendedor_id uuid DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.vendedores
    WHERE empresa_id = p_empresa_id
      AND email = p_email
      AND (p_vendedor_id IS NULL OR id <> p_vendedor_id)
  );
END;
$$;
