import { IEntity } from './base';

// Enums alinhados com o playbook
export enum TipoPessoa {
  PF = 'PF',
  PJ = 'PJ',
}

export enum TipoContato {
  CLIENTE = 'cliente',
  FORNECEDOR = 'fornecedor',
  AMBOS = 'ambos',
}

// Entidade para a tabela `clientes_contatos`
export interface ClienteContato extends IEntity {
  empresaId: string;
  clienteFornecedorId: string;
  nome: string;
  setor?: string;
  email?: string;
  telefone?: string;
  ramal?: string;
}

// Entidade para a tabela `clientes_anexos`
export interface ClienteAnexo extends IEntity {
  empresaId: string;
  clienteFornecedorId: string;
  bucket: string;
  storagePath: string;
  filename: string;
  contentType?: string;
  tamanhoBytes?: number;
  url?: string;
}

// Entidade principal para a tabela `clientes_fornecedores`
export interface ClienteFornecedor extends IEntity {
  empresaId: string;
  nomeRazaoSocial: string;
  tipoPessoa: TipoPessoa;
  tipoContato: TipoContato;

  // Identificação opcional
  fantasia?: string;
  cnpjCpf?: string;
  inscricaoEstadual?: string;
  inscricaoMunicipal?: string;
  rg?: string;
  rnm?: string;

  // Endereço principal
  cep?: string;
  municipio?: string;
  uf?: string;
  endereco?: string;
  bairro?: string;
  numero?: string;
  complemento?: string;

  // Cobrança
  cobrancaDiferente: boolean;
  cobrCep?: string;
  cobrMunicipio?: string;
  cobrUf?: string;
  cobrEndereco?: string;
  cobrBairro?: string;
  cobrNumero?: string;
  cobrComplemento?: string;

  // Contatos principais
  telefone?: string;
  telefoneAdicional?: string;
  celular?: string;
  website?: string;
  email?: string;
  emailNfe?: string;
  observacoes?: string;

  // Relações (carregadas sob demanda)
  contatos?: ClienteContato[];
  anexos?: (ClienteAnexo | File)[];
}
