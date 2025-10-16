import { IEntity } from './base';

export enum SituacaoVendedor {
    ATIVO_COM_ACESSO = 'Ativo com acesso ao sistema',
    ATIVO_SEM_ACESSO = 'Ativo sem acesso ao sistema',
    INATIVO = 'Inativo'
}

export enum TipoPessoaVendedor {
    PESSOA_FISICA = 'Pessoa Física',
    PESSOA_JURIDICA = 'Pessoa Jurídica',
    ESTRANGEIRO = 'Estrangeiro',
    ESTRANGEIRO_NO_BRASIL = 'Estrangeiro no Brasil'
}

export enum TipoContribuinteIcms {
    CONTRIBUINTE = 'Contribuinte ICMS',
    ISENTO = 'Contribuinte Isento',
    NAO_CONTRIBUINTE = 'Não Contribuinte'
}

export enum RegraLiberacaoComissao {
    PARCIAL = 'Liberação parcial vinculada ao pagamento de parcelas',
    INTEGRAL = 'Liberação integral no faturamento'
}

export enum TipoComissao {
    FIXA = 'fixa',
    VARIAVEL = 'variavel'
}

export interface VendedorContato extends IEntity {
  empresaId: string;
  vendedorId: string;
  nome: string;
  setor?: string;
  email?: string;
  telefone?: string;
  ramal?: string;
}

export interface Vendedor extends IEntity {
  empresaId: string;
  // Informações Principais
  nome: string;
  fantasia?: string;
  codigo?: string;
  tipoPessoa: TipoPessoaVendedor;
  cpfCnpj?: string;
  documentoIdentificacao?: string;
  pais?: string;
  contribuinteIcms?: TipoContribuinteIcms;
  inscricaoEstadual?: string;
  situacao: SituacaoVendedor;
  // Endereço
  cep?: string;
  logradouro?: string;
  numero?: string;
  complemento?: string;
  bairro?: string;
  cidade?: string;
  uf?: string;
  // Contato
  telefone?: string;
  celular?: string;
  email?: string;
  emailComunicacao?: string;
  // Acesso e Permissões
  depositoPadrao?: string;
  senha?: string;
  acessoRestritoHorario: boolean;
  acessoRestritoIp?: string;
  perfilContato?: string[];
  permissoesModulos?: any; // JSONB
  // Comissionamento
  regraLiberacaoComissao?: RegraLiberacaoComissao;
  tipoComissao?: TipoComissao;
  aliquotaComissao?: number;
  desconsiderarComissionamentoLinhasProduto: boolean;
  observacoesComissao?: string;
  // Relações
  contatos?: VendedorContato[];
}
