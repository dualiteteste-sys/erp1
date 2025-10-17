/*
# [SECURITY] Fix All Remaining Search Path Warnings
This script dynamically identifies all user-created functions in the 'public' schema and applies a secure `search_path` to them. This is the definitive fix for the "Function Search Path Mutable" security advisories.

## Query Description:
- This operation is safe and does not modify data.
- It alters the metadata of existing functions to enhance security.
- It iterates through functions you own and sets their search path to `public`, preventing potential hijacking vulnerabilities.

## Metadata:
- Schema-Category: "Security"
- Impact-Level: "Low"
- Requires-Backup: false
- Reversible: true (manually, by altering each function again)
*/
DO $$
DECLARE
    function_signature TEXT;
BEGIN
    -- This query finds all user-owned functions in the 'public' schema.
    -- The condition `NOT p.proisagg` was removed for compatibility with this PostgreSQL version.
    -- `p.prokind = 'f'` already ensures we are only targeting normal functions.
    FOR function_signature IN
        SELECT
            -- Format is: schema_name.function_name(arg_types)
            ns.nspname || '.' || p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')'
        FROM
            pg_proc p
            JOIN pg_namespace ns ON p.pronamespace = ns.oid
        WHERE
            ns.nspname = 'public' -- Only functions in the public schema
            AND p.prokind = 'f' -- 'f' for normal functions
            AND p.proname NOT LIKE 'pg_%' -- Exclude internal pg functions
            AND pg_catalog.pg_get_userbyid(p.proowner) NOT IN ('supabase_admin', 'postgres') -- Exclude functions owned by Supabase/Postgres
    LOOP
        -- Sets a secure search_path for each identified function.
        EXECUTE 'ALTER FUNCTION ' || function_signature || ' SET search_path = public;';
    END LOOP;
END;
$$;
