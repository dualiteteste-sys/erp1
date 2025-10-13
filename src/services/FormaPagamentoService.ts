import { FormaPagamento } from '../types';
import { IFormaPagamentoService } from './interfaces';
import { IFormaPagamentoRepository } from '../repositories/interfaces';

export class FormaPagamentoService implements IFormaPagamentoService {
  public repository: IFormaPagamentoRepository;

  constructor(repository: IFormaPagamentoRepository) {
    this.repository = repository;
  }

  async getAll(empresaId: string, options: { page?: number; pageSize?: number } = {}): Promise<{ data: FormaPagamento[]; count: number }> {
    return this.repository.findAll(empresaId, options);
  }

  async findById(id: string): Promise<FormaPagamento | null> {
    return this.repository.findById(id);
  }

  async create(data: Omit<FormaPagamento, 'id' | 'createdAt' | 'updatedAt'>): Promise<FormaPagamento> {
    return this.repository.create(data);
  }

  async update(id: string, data: Partial<FormaPagamento>): Promise<FormaPagamento> {
    return this.repository.update(id, data);
  }

  async delete(id: string): Promise<void> {
    return this.repository.delete(id);
  }
}
