/*
  # [Data Operation] Povoar Tabela de Clientes
  [Este script insere 10 registros de clientes e fornecedores falsos na tabela `clientes_fornecedores` para fins de teste e desenvolvimento.]

  ## Query Description: [Este script insere dados de teste e não afeta dados de produção existentes. É seguro para ser executado em um ambiente de desenvolvimento. Ele assume que o usuário e a empresa especificados já existem.]
  
  ## Metadata:
  - Schema-Category: "Data"
  - Impact-Level: "Low"
  - Requires-Backup: false
  - Reversible: false
  
  ## Structure Details:
  - Tabela afetada: `clientes_fornecedores`
  - Tabela afetada: `clientes_contatos`
  
  ## Security Implications:
  - RLS Status: Habilitado (o script usa o ID do usuário para garantir a propriedade correta dos dados)
  - Policy Changes: Não
  - Auth Requirements: Requer o `user_id` e `empresa_id` do usuário que está executando a operação.
  
  ## Performance Impact:
  - Indexes: N/A
  - Triggers: Ativará triggers de `INSERT` na tabela `clientes_fornecedores`.
  - Estimated Impact: Baixo. Inserção de poucos registros.
*/
DO $$
DECLARE
    v_user_id UUID;
    v_empresa_id UUID;
    v_cliente_id UUID;
    v_tipo_pessoa TEXT;
    v_nome_razao_social TEXT;
    v_fantasia TEXT;
    v_cnpj_cpf TEXT;
BEGIN
    -- Substitua 'COLE_SEU_USER_ID_AQUI' pelo ID do seu usuário autenticado
    v_user_id := 'COLE_SEU_USER_ID_AQUI';

    -- Encontra a primeira empresa associada ao usuário
    SELECT empresa_id INTO v_empresa_id
    FROM empresa_usuarios
    WHERE user_id = v_user_id
    LIMIT 1;

    IF v_empresa_id IS NULL THEN
        RAISE EXCEPTION 'Nenhuma empresa encontrada para o usuário com ID %', v_user_id;
    END IF;

    -- Inserir 10 clientes/fornecedores
    FOR i IN 1..10 LOOP
        v_tipo_pessoa := CASE WHEN random() < 0.5 THEN 'PF' ELSE 'PJ' END;

        IF v_tipo_pessoa = 'PF' THEN
            v_nome_razao_social := 'Cliente Físico ' || i;
            v_fantasia := '';
            v_cnpj_cpf := (10000000000 + floor(random() * 90000000000))::text; -- CPF aleatório (sem validação)
        ELSE
            v_nome_razao_social := 'Empresa Cliente ' || i;
            v_fantasia := 'Fantasia ' || i;
            v_cnpj_cpf := (10000000000000 + floor(random() * 90000000000000))::text; -- CNPJ aleatório (sem validação)
        END IF;

        -- Inserir na tabela principal
        INSERT INTO public.clientes_fornecedores (
            empresa_id, nome_razao_social, fantasia, tipo_pessoa, tipo_contato, cnpj_cpf, email, celular, cep, endereco, numero, bairro, municipio, uf, cobranca_diferente, created_by
        )
        VALUES (
            v_empresa_id,
            v_nome_razao_social,
            v_fantasia,
            v_tipo_pessoa::tipo_pessoa,
            CASE WHEN random() < 0.33 THEN 'cliente'::tipo_contato WHEN random() < 0.66 THEN 'fornecedor'::tipo_contato ELSE 'ambos'::tipo_contato END,
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
        )
        RETURNING id INTO v_cliente_id;

        -- Inserir contatos adicionais aleatórios
        IF random() < 0.5 THEN
            INSERT INTO public.clientes_contatos (empresa_id, cliente_fornecedor_id, nome, setor, email, telefone)
            VALUES (
                v_empresa_id,
                v_cliente_id,
                'Contato Adicional ' || i,
                'Financeiro',
                'contato' || i || '@emailteste.com',
                '(11) 5555-' || (1000 + floor(random() * 9000))::text
            );
        END IF;

    END LOOP;
END $$;
