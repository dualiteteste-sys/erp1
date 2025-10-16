/*
# [Operação de Quarentena de Funções]
Este script renomeia um conjunto de funções de banco de dados que apresentam avisos de segurança.
Ao adicionar o sufixo '_quarantined' ao nome de cada função, podemos quebrar a conexão com a aplicação
de forma segura e não destrutiva. Isso nos permite testar a aplicação e identificar quais funções
estão realmente em uso e quais podem ser resquícios de desenvolvimentos anteriores.

## Descrição da Consulta:
- O script utiliza um bloco PL/pgSQL para iterar sobre uma lista de nomes de funções.
- Ele busca dinamicamente a "assinatura" (argumentos) de cada função no catálogo do sistema (`pg_proc`).
- Para cada função encontrada, ele constrói e executa um comando `ALTER FUNCTION ... RENAME TO ...`.
- Este método é seguro, pois não deleta nenhum código. Se uma função renomeada for necessária,
  a aplicação irá falhar com um erro claro ("função não encontrada"), nos informando que ela está em uso.
- Se a aplicação continuar funcionando normalmente, as funções renomeadas são fortes candidatas a serem removidas em uma limpeza futura.
- O script inclui blocos de exceção para não falhar caso uma das funções listadas não exista no banco de dados.

## Metadados:
- Categoria do Esquema: "Estrutural"
- Nível de Impacto: "Baixo" (Ação reversível e não destrutiva)
- Requer Backup: false
- Reversível: true (Basta executar um `ALTER FUNCTION ... RENAME TO ...` com o nome original)

## Detalhes da Estrutura:
Funções afetadas (se existirem):
- public.apply_rls_policy
- public.apply_permissive_rls_to_all_tables
- public.apply_rls_policies_to_all_tables
- public.create_updated_at_trigger_if_not_exists
- public.update_produto_v2
- public.is_member_of_empresa
- public.trg_set_empresa_id_produto_imagens
- public.update_updated_by_column
- app.set_updated_at

## Implicações de Segurança:
- RLS Status: Inalterado
- Mudanças de Política: Não
- Requisitos de Autenticação: N/A

## Impacto no Desempenho:
- Índices: Nenhum
- Gatilhos: Nenhum
- Impacto Estimado: Nulo. O impacto ocorrerá na aplicação se uma função renomeada for chamada.
*/
DO $$
DECLARE
    -- Array de nomes de funções a serem colocadas em quarentena
    func_names TEXT[] := ARRAY[
        'apply_rls_policy',
        'apply_permissive_rls_to_all_tables',
        'apply_rls_policies_to_all_tables',
        'create_updated_at_trigger_if_not_exists',
        'update_produto_v2',
        'is_member_of_empresa',
        'trg_set_empresa_id_produto_imagens',
        'update_updated_by_column'
    ];
    func_name TEXT;
    r RECORD;
    alter_stmt TEXT;
BEGIN
    -- Itera sobre as funções no schema 'public'
    FOREACH func_name IN ARRAY func_names
    LOOP
        FOR r IN
            SELECT
                p.proname AS function_name,
                n.nspname AS schema_name,
                pg_get_function_identity_arguments(p.oid) AS function_args
            FROM
                pg_catalog.pg_proc p
            JOIN
                pg_catalog.pg_namespace n ON n.oid = p.pronamespace
            WHERE
                p.proname = func_name AND n.nspname = 'public'
        LOOP
            BEGIN
                alter_stmt := format(
                    'ALTER FUNCTION %I.%I(%s) RENAME TO %I;',
                    r.schema_name,
                    r.function_name,
                    r.function_args,
                    r.function_name || '_quarantined'
                );
                RAISE NOTICE 'Executando: %', alter_stmt;
                EXECUTE alter_stmt;
            EXCEPTION
                WHEN others THEN
                    RAISE WARNING 'Não foi possível renomear a função %.% (%): %', r.schema_name, r.function_name, r.function_args, SQLERRM;
            END;
        END LOOP;
    END LOOP;

    -- Trata a função no schema 'app' separadamente
    BEGIN
        FOR r IN
            SELECT
                p.proname AS function_name,
                pg_get_function_identity_arguments(p.oid) AS function_args
            FROM
                pg_catalog.pg_proc p
            JOIN
                pg_catalog.pg_namespace n ON n.oid = p.pronamespace
            WHERE
                p.proname = 'set_updated_at' AND n.nspname = 'app'
        LOOP
            alter_stmt := format(
                'ALTER FUNCTION app.set_updated_at(%s) RENAME TO set_updated_at_quarantined;',
                r.function_args
            );
            RAISE NOTICE 'Executando: %', alter_stmt;
            EXECUTE alter_stmt;
        END LOOP;
    EXCEPTION
        WHEN others THEN
            RAISE WARNING 'Não foi possível renomear a função app.set_updated_at: %', SQLERRM;
    END;

END $$;
