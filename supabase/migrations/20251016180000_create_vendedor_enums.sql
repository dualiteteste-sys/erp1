DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipo_pessoa_vendedor') THEN
        CREATE TYPE public.tipo_pessoa_vendedor AS ENUM (
            'Pessoa Física',
            'Pessoa Jurídica',
            'Estrangeiro',
            'Estrangeiro no Brasil'
        );
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipo_contribuinte_icms') THEN
        CREATE TYPE public.tipo_contribuinte_icms AS ENUM (
            'Contribuinte ICMS',
            'Contribuinte Isento',
            'Não Contribuinte'
        );
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'situacao_vendedor') THEN
        CREATE TYPE public.situacao_vendedor AS ENUM (
            'Ativo com acesso ao sistema',
            'Ativo sem acesso ao sistema',
            'Inativo'
        );
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'regra_liberacao_comissao') THEN
        CREATE TYPE public.regra_liberacao_comissao AS ENUM (
            'Liberação parcial vinculada ao pagamento de parcelas',
            'Liberação integral no faturamento'
        );
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipo_comissao') THEN
        CREATE TYPE public.tipo_comissao AS ENUM (
            'fixa',
            'variavel'
        );
    END IF;
END
$$;
