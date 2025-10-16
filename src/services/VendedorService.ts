import { Vendedor } from '../types';
import { IVendedorService } from './interfaces';
import { IVendedorRepository } from '../repositories/interfaces';

export class VendedorService implements IVendedorService {
  public repository: IVendedorRepository;

  constructor(repository: IVendedorRepository) {
    this.repository = repository;
  }

  async getAll(empresaId: string, options: { page?: number; pageSize?: number } = {}): Promise<{ data: Vendedor[]; count: number }> {
    return this.repository.findAll(empresaId, options);
  }

  async findById(id: string): Promise<Vendedor | null> {
    return this.repository.findById(id);
  }

  async create(data: Omit<Vendedor, 'id' | 'createdAt' | 'updatedAt'>): Promise<Vendedor> {
    return this.repository.create(data);
  }

  async update(id: string, data: Partial<Vendedor>): Promise<Vendedor> {
    return this.repository.update(id, data);
  }

  async delete(id: string): Promise<void> {
    return this.repository.delete(id);
  }

  async checkEmailExists(empresaId: string, email: string, vendedorId?: string): Promise<boolean> {
    return this.repository.checkEmailExists(empresaId, email, vendedorId);
  }
}
