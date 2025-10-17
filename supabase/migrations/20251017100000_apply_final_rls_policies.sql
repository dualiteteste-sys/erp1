-- Passo 1: Criar a função de verificação de membro da empresa de forma segura.
-- Esta função será usada por todas as políticas de segurança.
CREATE OR REPLACE FUNCTION private.is_member_of_empresa(p_user_id uuid, p_empresa_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = '';
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.empresa_usuarios
    WHERE user_id = p_user_id AND empresa_id = p_empresa_id
  );
END;
$$;

-- Passo 2: Aplicar dinamicamente as políticas de RLS a todas as tabelas relevantes.
DO $$
DECLARE
    v_table_name TEXT;
BEGIN
    -- Política especial para a tabela 'empresas', permitindo que usuários vejam as empresas das quais são membros.
    DROP POLICY IF EXISTS "Membros podem gerenciar suas próprias empresas" ON public.empresas;
    CREATE POLICY "Membros podem gerenciar suas próprias empresas"
    ON public.empresas FOR ALL
    USING (id IN (SELECT empresa_id FROM public.empresa_usuarios WHERE user_id = auth.uid()));

    -- Loop através de todas as outras tabelas no esquema 'public'.
    FOR v_table_name IN
        SELECT table_name FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_type = 'BASE TABLE'
          AND table_name != 'empresas' -- Já tratada acima
          AND table_name NOT LIKE 'pg_%'
          AND table_name NOT LIKE 'supabase_%'
          AND table_name != 'empresa_usuarios' -- Tabela de junção geralmente tem regras diferentes ou nenhuma.
    LOOP
        -- Verifica se a tabela tem a coluna 'empresa_id' e se a RLS está habilitada.
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = v_table_name AND column_name = 'empresa_id')
           AND EXISTS (SELECT 1 FROM pg_class WHERE relname = v_table_name AND relrowsecurity = true)
        THEN
            -- Remove a política antiga se existir e cria a nova.
            EXECUTE format('DROP POLICY IF EXISTS "Membros podem gerenciar dados da sua empresa" ON public.%I;', v_table_name);
            EXECUTE format(
                'CREATE POLICY "Membros podem gerenciar dados da sua empresa" ' ||
                'ON public.%I FOR ALL ' ||
                'USING (private.is_member_of_empresa(auth.uid(), empresa_id));',
                v_table_name
            );
        END IF;
    END LOOP;
END;
$$;
