/*
          # [Fix] Remove Duplicate Function `create_cliente_anexo`
          This migration removes a duplicate version of the `create_cliente_anexo` function that was causing ambiguity errors. The duplicate function used an `integer` type for the file size, while the correct version uses `bigint`. This change ensures that the correct function is always called.

          ## Query Description: [This operation removes a redundant database function. It is a safe cleanup operation and does not affect any stored data. It resolves a function overload ambiguity that was preventing new attachments from being saved.]
          
          ## Metadata:
          - Schema-Category: ["Structural"]
          - Impact-Level: ["Low"]
          - Requires-Backup: [false]
          - Reversible: [false]
          
          ## Structure Details:
          - Function Removed: `public.create_cliente_anexo(uuid, uuid, text, text, text, integer)`
          
          ## Security Implications:
          - RLS Status: [Not Applicable]
          - Policy Changes: [No]
          - Auth Requirements: [None]
          
          ## Performance Impact:
          - Indexes: [None]
          - Triggers: [None]
          - Estimated Impact: [None. This is a metadata change.]
          */
DROP FUNCTION IF EXISTS public.create_cliente_anexo(uuid, uuid, text, text, text, integer);
