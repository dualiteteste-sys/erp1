/*
# [Operação Estrutural] Criação de Tipos ENUM para Clientes
Cria os tipos enumerados `tipo_pessoa` e `tipo_contato` necessários para a tabela `clientes_fornecedores`.

## Query Description: Esta operação é segura e adiciona novos tipos de dados ao esquema. Não afeta dados existentes.
- Schema-Category: "Structural"
- Impact-Level: "Low"
- Requires-Backup: false
- Reversible: false
*/
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipo_pessoa') THEN
        CREATE TYPE public.tipo_pessoa AS ENUM ('PF', 'PJ');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipo_contato') THEN
        CREATE TYPE public.tipo_contato AS ENUM ('cliente', 'fornecedor', 'ambos');
    END IF;
END
$$;
