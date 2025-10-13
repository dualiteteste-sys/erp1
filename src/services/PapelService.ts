import { Papel } from '../types';
import { IPapelService } from './interfaces';
import { IPapelRepository } from '../repositories/interfaces';

export class PapelService implements IPapelService {
  public repository: IPapelRepository;

  constructor(repository: IPapelRepository) {
    this.repository = repository;
  }

  async getAll(empresaId: string, options: { page?: number; pageSize?: number } = {}): Promise<{ data: Papel[]; count: number }> {
    return this.repository.findAll(empresaId, options);
  }

  async findById(id: string): Promise<Papel | null> {
    return this.repository.findById(id);
  }

  async create(data: Omit<Papel, 'id' | 'createdAt' | 'updatedAt'>): Promise<Papel> {
    return this.repository.create(data);
  }

  async update(id: string, data: Partial<Papel>): Promise<Papel> {
    return this.repository.update(id, data);
  }

  async delete(id: string): Promise<void> {
    return this.repository.delete(id);
  }

  async setPermissions(papelId: string, permissionIds: string[]): Promise<void> {
    return this.repository.setPermissions(papelId, permissionIds);
  }
}
