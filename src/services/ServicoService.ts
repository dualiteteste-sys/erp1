import { Servico } from '../types';
import { IServicoService } from './interfaces';
import { IServicoRepository } from '../repositories/interfaces';

export class ServicoService implements IServicoService {
  public repository: IServicoRepository;

  constructor(repository: IServicoRepository) {
    this.repository = repository;
  }

  async getAll(empresaId: string, options: { page?: number; pageSize?: number } = {}): Promise<{ data: Servico[]; count: number }> {
    return this.repository.findAll(empresaId, options);
  }

  async findById(id: string): Promise<Servico | null> {
    return this.repository.findById(id);
  }

  async create(data: Omit<Servico, 'id' | 'createdAt' | 'updatedAt'>): Promise<Servico> {
    return this.repository.create(data);
  }

  async update(id: string, data: Partial<Servico>): Promise<Servico> {
    return this.repository.update(id, data);
  }

  async delete(id: string): Promise<void> {
    return this.repository.delete(id);
  }
}
