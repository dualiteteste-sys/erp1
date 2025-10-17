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

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipocontribuinteicms') THEN
        CREATE TYPE public.tipocontribuinteicms AS ENUM (
            'Contribuinte ICMS',
            'Contribuinte Isento',
            'Não Contribuinte'
        );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'situacaovendedor') THEN
        CREATE TYPE public.situacaovendedor AS ENUM (
            'Ativo com acesso ao sistema',
            'Ativo sem acesso ao sistema',
            'Inativo'
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
END
$$;
