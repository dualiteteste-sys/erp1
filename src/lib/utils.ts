// Função para converter uma string de camelCase para snake_case
const toSnakeCase = (str: string) =>
  str.replace(/[A-Z]/g, (letter) => `_${letter.toLowerCase()}`);

// Função recursiva para converter as chaves de um objeto de camelCase para snake_case
export const camelToSnake = (obj: any): any => {
  // Se não for um objeto (ou for nulo ou uma data), retorna o valor original
  if (obj === null || typeof obj !== 'object' || obj instanceof Date) {
    return obj;
  }

  // Se for um array, aplica a função a cada item
  if (Array.isArray(obj)) {
    return obj.map(camelToSnake);
  }

  // Se for um objeto, converte suas chaves
  return Object.keys(obj).reduce((acc, key) => {
    const newKey = toSnakeCase(key);
    const value = obj[key];
    // A chave só é adicionada se o valor não for undefined
    if (value !== undefined) {
      acc[newKey] = camelToSnake(value); // Chamada recursiva para o valor
    }
    return acc;
  }, {} as { [key: string]: any });
};

// Função para converter uma string de snake_case para camelCase
const toCamelCase = (str: string) =>
  str.replace(/([-_][a-z])/g, (group) =>
    group.toUpperCase().replace('-', '').replace('_', '')
  );

// Função recursiva para converter as chaves de um objeto de snake_case para camelCase
export const snakeToCamel = (obj: any): any => {
    // Se não for um objeto (ou for nulo ou uma data), retorna o valor original
    if (obj === null || typeof obj !== 'object' || obj instanceof Date) {
        return obj;
    }

    // Se for um array, aplica a função a cada item
    if (Array.isArray(obj)) {
        return obj.map(snakeToCamel);
    }

    // Se for um objeto, converte suas chaves
    return Object.keys(obj).reduce((acc, key) => {
        const newKey = toCamelCase(key);
        const value = obj[key];
        if (value !== undefined) {
            acc[newKey] = snakeToCamel(value); // Chamada recursiva para o valor
        }
        return acc;
    }, {} as { [key: string]: any });
};

// Função para obter valor aninhado de um objeto de forma segura
export const getNestedValue = (obj: any, path: string) => {
    return path.split('.').reduce((acc, part) => acc && acc[part], obj);
};

// Função para validar CPF
export const isValidCPF = (cpf: string): boolean => {
  if (typeof cpf !== 'string') return false;
  cpf = cpf.replace(/[^\d]+/g, '');
  if (cpf.length !== 11 || !!cpf.match(/(\d)\1{10}/)) return false;
  
  const cpfArr = cpf.split('').map(el => +el);
  
  const rest = (count: number): number => {
    return (cpfArr.slice(0, count-12).reduce((soma, el, index) => soma + el * (count - index), 0) * 10) % 11 % 10;
  };

  return rest(10) === cpfArr[9] && rest(11) === cpfArr[10];
};

// Função para validar CNPJ
export const isValidCNPJ = (cnpj: string): boolean => {
    if (typeof cnpj !== 'string') return false;
    cnpj = cnpj.replace(/[^\d]+/g, '');

    if (cnpj.length !== 14 || !!cnpj.match(/(\d)\1{13}/)) return false;

    let tamanho = cnpj.length - 2;
    let numeros = cnpj.substring(0, tamanho);
    let digitos = cnpj.substring(tamanho);
    let soma = 0;
    let pos = tamanho - 7;

    for (let i = tamanho; i >= 1; i--) {
        soma += parseInt(numeros.charAt(tamanho - i)) * pos--;
        if (pos < 2) pos = 9;
    }

    let resultado = soma % 11 < 2 ? 0 : 11 - (soma % 11);
    if (resultado !== parseInt(digitos.charAt(0))) return false;

    tamanho = tamanho + 1;
    numeros = cnpj.substring(0, tamanho);
    soma = 0;
    pos = tamanho - 7;

    for (let i = tamanho; i >= 1; i--) {
        soma += parseInt(numeros.charAt(tamanho - i)) * pos--;
        if (pos < 2) pos = 9;
    }

    resultado = soma % 11 < 2 ? 0 : 11 - (soma % 11);
    return resultado === parseInt(digitos.charAt(1));
};
