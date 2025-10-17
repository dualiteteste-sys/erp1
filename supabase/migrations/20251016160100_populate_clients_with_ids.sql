/*
# [Operação de Dados] Povoamento da Tabela de Clientes
Insere 10 registros de clientes falsos para teste, associados a um usuário e empresa específicos.

## Query Description: Esta operação insere novos dados na tabela `clientes_fornecedores`. Não modifica ou apaga dados existentes. É segura para ser executada.
- Schema-Category: "Data"
- Impact-Level: "Low"
- Requires-Backup: false
- Reversible: true
*/
DO $$
DECLARE
    v_user_id UUID := '530f34b1-23a4-49f8-ba9b-8dd5ddff9b54';
    v_empresa_id UUID := '6498b28c-2f3b-489e-b084-398d7c70fcb4';
    v_tipo_pessoa public.tipo_pessoa;
    v_tipo_contato public.tipo_contato;
    v_nome_razao_social TEXT;
    v_fantasia TEXT;
    v_cnpj_cpf TEXT;
BEGIN
    FOR i IN 1..10 LOOP
        -- Define o tipo de pessoa aleatoriamente
        IF random() < 0.5 THEN
            v_tipo_pessoa := 'PF';
            v_nome_razao_social := 'Cliente Físico ' || i;
            v_fantasia := 'Apelido ' || i;
            v_cnpj_cpf := (10000000000 + floor(random() * 90000000000))::bigint::text; -- CPF Falso
        ELSE
            v_tipo_pessoa := 'PJ';
            v_nome_razao_social := 'Empresa de Teste ' || i;
            v_fantasia := 'Nome Fantasia ' || i;
            v_cnpj_cpf := (10000000000000 + floor(random() * 90000000000000))::bigint::text; -- CNPJ Falso
        END IF;

        -- Define o tipo de contato aleatoriamente
        SELECT INTO v_tipo_contato CASE
            WHEN random() < 0.33 THEN 'cliente'
            WHEN random() < 0.66 THEN 'fornecedor'
            ELSE 'ambos'
        END;

        INSERT INTO public.clientes_fornecedores (
            empresa_id, nome_razao_social, fantasia, tipo_pessoa, tipo_contato, cnpj_cpf, email, celular, cep, endereco, numero, bairro, municipio, uf, cobranca_diferente, created_by
        )
        VALUES (
            v_empresa_id,
            v_nome_razao_social,
            v_fantasia,
            v_tipo_pessoa,
            v_tipo_contato,
            v_cnpj_cpf,
            'cliente' || i || '@emailteste.com',
            '(11) 9' || (10000000 + floor(random() * 90000000))::text,
            '01001-000',
            'Praça da Sé',
            i::text,
            'Sé',
            'São Paulo',
            'SP',
            false,
            v_user_id
        );
    END LOOP;
END $$;
