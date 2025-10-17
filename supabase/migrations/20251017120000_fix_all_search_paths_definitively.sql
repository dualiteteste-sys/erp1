DO $$
DECLARE
    function_signature TEXT;
BEGIN
    -- Loop through all user-defined functions in the 'public' schema
    FOR function_signature IN
        SELECT
            -- Format is: function_name(arg_types)
            p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')'
        FROM
            pg_proc p
            JOIN pg_namespace ns ON p.pronamespace = ns.oid
        WHERE
            ns.nspname = 'public' -- Only functions in the public schema
            AND p.prokind = 'f' -- 'f' for normal functions, avoids issues with older pg_proc columns
            -- Exclude functions owned by supabase system roles
            AND pg_catalog.pg_get_userbyid(p.proowner) NOT IN ('supabase_admin', 'postgres', 'supabase_auth_admin')
            -- Exclude PostGIS functions which are managed by the extension
            AND p.proname NOT LIKE 'st_%'
            -- Exclude pgcrypto functions
            AND p.proname NOT IN ('armor', 'dearmor', 'decrypt', 'decrypt_iv', 'digest', 'encrypt', 'encrypt_iv', 'gen_random_bytes', 'gen_random_uuid', 'gen_salt', 'hmac', 'pgp_armor_headers', 'pgp_key_id', 'pgp_pub_decrypt', 'pgp_pub_decrypt_bytea', 'pgp_pub_encrypt', 'pgp_pub_encrypt_bytea', 'pgp_sym_decrypt', 'pgp_sym_decrypt_bytea', 'pgp_sym_encrypt', 'pgp_sym_encrypt_bytea')
    LOOP
        -- Construct and execute the ALTER FUNCTION statement
        EXECUTE 'ALTER FUNCTION public.' || function_signature || ' SET search_path = public, pg_temp;';
    END LOOP;
END;
$$;
