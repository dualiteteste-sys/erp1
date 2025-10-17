/*
# [Schema] Criação de Tipos para Módulo de Vendedores
Cria os tipos de dados (ENUMs) necessários para o funcionamento do módulo de Vendedores, evitando erros de "type does not exist".

## Query Description: [Este script adiciona novos tipos de dados (ENUMs) ao banco de dados. É uma operação segura e não afeta dados existentes, mas é crucial para a criação correta da tabela de vendedores.]

## Metadata:
- Schema-Category: ["Structural"]
- Impact-Level: ["Low"]
- Requires-Backup: [false]
- Reversible: [false]

## Structure Details:
- Cria o tipo `public.tipopessoavendedor`
- Cria o tipo `public.situacaovendedor`
- Cria o tipo `public.tipocontribuinteicms`
- Cria o tipo `public.regraliberacaocomissao`
- Cria o tipo `public.tipocomissao`

## Security Implications:
- RLS Status: [Not Applicable]
- Policy Changes: [No]
- Auth Requirements: [None]

## Performance Impact:
- Indexes: [None]
- Triggers: [None]
- Estimated Impact: [Nenhum impacto de performance esperado.]
*/

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipopessoavendedor') THEN
        CREATE TYPE public.tipopessoavendedor AS ENUM (
            'Pessoa Física',
            'Pessoa Jurídica',
            'Estrangeiro',
            'Estrangeiro no Brasil'
        );
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'situacaovendedor') THEN
        CREATE TYPE public.situacaovendedor AS ENUM (
            'Ativo com acesso ao sistema',
            'Ativo sem acesso ao sistema',
            'Inativo'
        );
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipocontribuinteicms') THEN
        CREATE TYPE public.tipocontribuinteicms AS ENUM (
            'Contribuinte ICMS',
            'Contribuinte Isento',
            'Não Contribuinte'
        );
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'regraliberacaocomissao') THEN
        CREATE TYPE public.regraliberacaocomissao AS ENUM (
            'Liberação parcial vinculada ao pagamento de parcelas',
            'Liberação integral no faturamento'
        );
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipocomissao') THEN
        CREATE TYPE public.tipocomissao AS ENUM (
            'fixa',
            'variavel'
        );
    END IF;
END $$;
