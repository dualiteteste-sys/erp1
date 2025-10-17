-- =================================================================
-- MIGRATION: Reset do Schema `public`
--
-- DESCRIÇÃO:
-- Este script executa uma operação de "terra arrasada" no schema `public`,
-- removendo todas as tabelas, tipos e funções personalizadas criadas
-- durante o desenvolvimento. O objetivo é limpar o banco de dados de
-- qualquer inconsistência para permitir uma reconstrução limpa a partir
-- dos arquivos de migração de uma versão estável.
--
-- IMPACTO:
-- IRREVERSÍVEL. Todos os dados (clientes, produtos, pedidos, etc.)
-- contidos nas tabelas do schema `public` serão PERDIDOS.
-- As estruturas internas do Supabase (como auth.users) NÃO serão afetadas.
-- =================================================================

-- Remove todas as políticas de segurança de linha (RLS) em todas as tabelas do schema 'public'.
-- Isso é necessário para evitar erros de dependência ao remover funções como `is_member_of_empresa`.
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
        EXECUTE 'ALTER TABLE public.' || quote_ident(r.tablename) || ' DISABLE ROW LEVEL SECURITY';
    END LOOP;
END $$;

-- Remove o gatilho `on_auth_user_created` da tabela `auth.users` antes de remover a função dependente.
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Remove todas as funções personalizadas no schema `public`.
-- A cláusula `CASCADE` garante que quaisquer dependências restantes (como as políticas) sejam removidas.
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT p.proname, pg_get_function_identity_arguments(p.oid) as args
        FROM pg_proc p
        JOIN pg_namespace ns ON p.pronamespace = ns.oid
        WHERE ns.nspname = 'public'
          AND pg_catalog.pg_get_userbyid(p.proowner) NOT IN ('supabase_admin', 'postgres') -- Exclui funções gerenciadas pelo Supabase/Postgres
    ) LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS public.' || quote_ident(r.proname) || '(' || r.args || ') CASCADE';
    END LOOP;
END $$;

-- Remove todas as tabelas personalizadas no schema `public`.
-- A cláusula `CASCADE` garante que sequências, índices e chaves estrangeiras sejam removidos juntos.
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
        EXECUTE 'DROP TABLE IF EXISTS public.' || quote_ident(r.tablename) || ' CASCADE';
    END LOOP;
END $$;

-- Remove todos os tipos de dados personalizados (ENUMs) no schema `public`.
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT t.typname FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace WHERE n.nspname = 'public' AND t.typtype = 'e') LOOP
        EXECUTE 'DROP TYPE IF EXISTS public.' || quote_ident(r.typname) || ' CASCADE';
    END LOOP;
END $$;
