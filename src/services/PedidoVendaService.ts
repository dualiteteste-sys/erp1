import { PedidoVenda } from '../types';
import { IPedidoVendaService } from './interfaces';
import { IPedidoVendaRepository } from '../repositories/interfaces';

export class PedidoVendaService implements IPedidoVendaService {
  public repository: IPedidoVendaRepository;

  constructor(repository: IPedidoVendaRepository) {
    this.repository = repository;
  }

  async getAll(empresaId: string, options: { page?: number; pageSize?: number } = {}): Promise<{ data: PedidoVenda[]; count: number }> {
    return this.repository.findAll(empresaId, options);
  }

  async findById(id: string): Promise<PedidoVenda | null> {
    return this.repository.findById(id);
  }

  async create(data: Omit<PedidoVenda, 'id' | 'createdAt' | 'updatedAt'>): Promise<PedidoVenda> {
    return this.repository.create(data);
  }

  async update(id: string, data: Partial<PedidoVenda>): Promise<PedidoVenda> {
    return this.repository.update(id, data);
  }

  async delete(id: string): Promise<void> {
    return this.repository.delete(id);
  }

  async searchProdutosEServicos(empresaId: string, query: string): Promise<any[]> {
    return this.repository.searchProdutosEServicos(empresaId, query);
  }
}
