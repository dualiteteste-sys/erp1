import { BaseRepository } from './BaseRepository';
import { FormaPagamento } from '../types';
import { IFormaPagamentoRepository } from './interfaces';

export class FormaPagamentoRepository extends BaseRepository<FormaPagamento> implements IFormaPagamentoRepository {
  constructor() {
    super('formas_pagamento');
  }

  protected createEntity(data: Omit<FormaPagamento, 'id' | 'createdAt' | 'updatedAt'>): FormaPagamento {
    return {
      id: '',
      createdAt: new Date(),
      updatedAt: new Date(),
      ...data,
    };
  }
}
