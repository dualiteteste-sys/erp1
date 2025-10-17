-- Habilita a extensão pgcrypto se ainda não estiver habilitada
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Recria a função de verificação de membro da empresa
DROP FUNCTION IF EXISTS private.is_member_of_empresa(uuid, uuid);
CREATE OR REPLACE FUNCTION private.is_member_of_empresa(p_user_id uuid, p_empresa_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.empresa_usuarios eu
    WHERE eu.user_id = p_user_id AND eu.empresa_id = p_empresa_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Corrige o warning de search_path
ALTER FUNCTION private.is_member_of_empresa(uuid, uuid) SET search_path = 'public';

-- Garante que a função de obter empresa do usuário exista
CREATE OR REPLACE FUNCTION private.get_empresa_id_for_user(p_user_id uuid)
RETURNS uuid AS $$
DECLARE
    v_empresa_id uuid;
BEGIN
    SELECT empresa_id INTO v_empresa_id
    FROM public.empresa_usuarios
    WHERE user_id = p_user_id
    LIMIT 1;
    RETURN v_empresa_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
ALTER FUNCTION private.get_empresa_id_for_user(uuid) SET search_path = 'public';


-- Aplica as políticas de RLS a todas as tabelas relevantes
DO $$
DECLARE
    t_name TEXT;
BEGIN
    FOR t_name IN 
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
          AND table_name NOT LIKE 'pg_%' 
          AND table_name NOT LIKE 'sql_%'
          AND table_name != 'empresa_usuarios' -- A tabela de junção tem regras diferentes
    LOOP
        -- Habilita RLS se ainda não estiver
        EXECUTE 'ALTER TABLE public.' || quote_ident(t_name) || ' ENABLE ROW LEVEL SECURITY;';
        
        -- Remove política antiga para evitar conflitos
        EXECUTE 'DROP POLICY IF EXISTS "Membros podem gerenciar dados da sua empresa" ON public.' || quote_ident(t_name) || ';';

        -- Cria a política padrão
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = t_name AND column_name = 'empresa_id') THEN
            EXECUTE 'CREATE POLICY "Membros podem gerenciar dados da sua empresa" ON public.' || quote_ident(t_name) || 
                    ' FOR ALL USING (private.is_member_of_empresa(auth.uid(), empresa_id));';
        END IF;
    END LOOP;
END;
$$;

-- Política específica para a tabela de junção empresa_usuarios
DROP POLICY IF EXISTS "Usuários podem ver suas próprias associações de empresa" ON public.empresa_usuarios;
CREATE POLICY "Usuários podem ver suas próprias associações de empresa"
ON public.empresa_usuarios FOR SELECT
USING (auth.uid() = user_id);
