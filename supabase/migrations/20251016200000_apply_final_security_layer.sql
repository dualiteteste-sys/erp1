-- Passo 1: Cria a função de segurança essencial no esquema 'private'.
-- Esta função verifica se um usuário pertence a uma determinada empresa.
CREATE OR REPLACE FUNCTION private.is_member_of_empresa(p_user_id uuid, p_empresa_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
-- Define um search_path seguro para a função, resolvendo o último warning.
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM empresa_usuarios
    WHERE user_id = p_user_id AND empresa_id = p_empresa_id
  );
$$;

-- Passo 2: Aplica dinamicamente as políticas de RLS em todas as tabelas relevantes.
DO $$
DECLARE
    -- Usa um nome de variável distinto para evitar ambiguidade.
    v_table_name TEXT;
BEGIN
    -- Itera sobre todas as tabelas criadas pelo usuário no esquema 'public'.
    FOR v_table_name IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_type = 'BASE TABLE'
          AND table_name NOT LIKE 'pg_%'
          AND table_name NOT LIKE 'supabase_%'
    LOOP
        -- Verifica se a Segurança em Nível de Linha (RLS) está habilitada para a tabela.
        IF (SELECT relrowsecurity FROM pg_class WHERE relname = v_table_name) THEN
            -- Caso especial para a tabela 'empresas': a verificação é contra a própria coluna 'id'.
            IF v_table_name = 'empresas' THEN
                EXECUTE 'DROP POLICY IF EXISTS "Membros podem gerenciar sua própria empresa" ON public.empresas';
                EXECUTE 'CREATE POLICY "Membros podem gerenciar sua própria empresa" ON public.empresas'
                    || ' FOR ALL USING (private.is_member_of_empresa(auth.uid(), id));';

            -- Para todas as outras tabelas, verifica se a coluna 'empresa_id' existe.
            ELSIF EXISTS (
                SELECT 1
                FROM information_schema.columns
                WHERE columns.table_schema = 'public'
                  AND columns.table_name = v_table_name -- Consulta corrigida e sem ambiguidade.
                  AND columns.column_name = 'empresa_id'
            ) THEN
                -- Remove a política antiga para evitar erros e cria a nova.
                EXECUTE 'DROP POLICY IF EXISTS "Membros podem gerenciar dados da sua empresa" ON public.' || quote_ident(v_table_name);
                EXECUTE 'CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.' || quote_ident(v_table_name)
                    || ' FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));';
            END IF;
        END IF;
    END LOOP;
END $$;
