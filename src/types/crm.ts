import { IEntity } from './base';
import { ClienteFornecedor, Vendedor, Produto, Servico } from '.';

export enum CrmEtapaFunil {
  PROSPECCAO = 'Prospecção',
  QUALIFICACAO = 'Qualificação',
  PROPOSTA = 'Proposta',
  NEGOCIACAO = 'Negociação',
  FECHAMENTO = 'Fechamento',
}

export enum CrmStatusOportunidade {
  EM_ABERTO = 'Em Aberto',
  GANHA = 'Ganha',
  PERDIDA = 'Perdida',
  CANCELADA = 'Cancelada',
}

export interface OportunidadeItem extends IEntity {
  oportunidadeId: string;
  produtoId?: string;
  servicoId?: string;
  descricao: string;
  quantidade: number;
  valorUnitario: number;
  valorTotal: number;
  produto?: Produto;
  servico?: Servico;
}

export interface Oportunidade extends IEntity {
  empresaId: string;
  titulo: string;
  valor: number;
  etapaFunil: CrmEtapaFunil;
  status: CrmStatusOportunidade;
  dataFechamentoPrevista?: Date;
  dataFechamentoReal?: Date;
  clienteId: string;
  vendedorId?: string;
  observacoes?: string;
  
  // Relações
  cliente?: ClienteFornecedor;
  vendedor?: Vendedor;
  itens?: OportunidadeItem[];
}
