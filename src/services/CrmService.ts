import { Oportunidade } from '../types';
import { ICrmService } from './interfaces';
import { ICrmRepository } from '../repositories/interfaces';

export class CrmService implements ICrmService {
  public repository: ICrmRepository;

  constructor(repository: ICrmRepository) {
    this.repository = repository;
  }

  async getAll(empresaId: string, options: { page?: number; pageSize?: number } = {}): Promise<{ data: Oportunidade[]; count: number }> {
    return this.repository.findAll(empresaId, options);
  }

  async findById(id: string): Promise<Oportunidade | null> {
    return this.repository.findById(id);
  }

  async create(data: Omit<Oportunidade, 'id' | 'createdAt' | 'updatedAt'>): Promise<Oportunidade> {
    return this.repository.create(data);
  }

  async update(id: string, data: Partial<Oportunidade>): Promise<Oportunidade> {
    return this.repository.update(id, data);
  }

  async delete(id: string): Promise<void> {
    return this.repository.delete(id);
  }
}
