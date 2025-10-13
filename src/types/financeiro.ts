import { IEntity } from './base';

export enum TipoCategoriaFinanceira {
  RECEITA = 'RECEITA',
  DESPESA = 'DESPESA',
}

export interface CategoriaFinanceira extends IEntity {
  empresaId: string;
  descricao: string;
  tipo: TipoCategoriaFinanceira;
}

export interface FormaPagamento extends IEntity {
  empresaId: string;
  descricao: string;
}
