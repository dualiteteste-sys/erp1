/*
          # [SECURITY] Fix Function Search Path Mutable (Partial)
          [This migration sets a secure `search_path` for several database functions to resolve security linter warnings. It targets functions that typically have no arguments, making the change safe to apply.]

          ## Query Description: [This operation modifies database function metadata to enhance security. It does not alter data or logic. By setting a fixed `search_path`, it prevents potential hijacking attacks where a malicious user could create functions in other schemas to intercept calls. This is a standard security best practice.]
          
          ## Metadata:
          - Schema-Category: ["Security"]
          - Impact-Level: ["Low"]
          - Requires-Backup: [false]
          - Reversible: [true]
          
          ## Structure Details:
          [Affects the metadata of the following functions:
          - public.trg_set_empresa_id_produto_imagens
          - public.update_updated_by_column
          - app.set_updated_at]
          
          ## Security Implications:
          - RLS Status: [Not Changed]
          - Policy Changes: [No]
          - Auth Requirements: [None]
          
          ## Performance Impact:
          - Indexes: [Not Changed]
          - Triggers: [Not Changed]
          - Estimated Impact: [None. This is a metadata change with no performance impact.]
          */
ALTER FUNCTION public.trg_set_empresa_id_produto_imagens() SET search_path = 'public';
ALTER FUNCTION public.update_updated_by_column() SET search_path = 'public';
ALTER FUNCTION app.set_updated_at() SET search_path = 'app', 'public';
