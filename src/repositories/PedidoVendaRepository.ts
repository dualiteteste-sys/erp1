import { BaseRepository } from './BaseRepository';
import { PedidoVenda } from '../types';
import { IPedidoVendaRepository } from './interfaces';
import { RepositoryError } from './RepositoryError';
import { camelToSnake, snakeToCamel } from '../lib/utils';

export class PedidoVendaRepository extends BaseRepository<PedidoVenda> implements IPedidoVendaRepository {
  constructor() {
    super('pedidos_vendas');
  }

  protected createEntity(data: Omit<PedidoVenda, 'id' | 'createdAt' | 'updatedAt'>): PedidoVenda {
    return {
      id: '',
      createdAt: new Date(),
      updatedAt: new Date(),
      ...data,
    } as PedidoVenda;
  }

  async findById(id: string): Promise<PedidoVenda | null> {
    const { data, error } = await this.supabase
      .from(this.tableName)
      .select('*, cliente:clientes_fornecedores(id, nome_razao_social), vendedor:vendedores(id, nome), itens:pedidos_vendas_itens(*, produto:produtos(id, nome), servico:servicos(id, descricao))')
      .eq('id', id)
      .single();
      
    if (error && error.code !== 'PGRST116') this.handleError('findById', error);
    return snakeToCamel(data) as PedidoVenda | null;
  }

  async create(data: Partial<Omit<PedidoVenda, 'id' | 'createdAt' | 'updatedAt'>>): Promise<PedidoVenda> {
    const { itens, ...pedidoData } = data;

    const rpcParams = {
      p_empresa_id: pedidoData.empresaId,
      p_pedido_data: camelToSnake(pedidoData),
      p_itens: camelToSnake(itens || []),
    };

    const { data: newId, error: rpcError } = await this.supabase.rpc('create_pedido_venda_completo', rpcParams);

    if (rpcError) this.handleError('create (rpc)', rpcError);
    if (!newId) throw new RepositoryError({ message: 'Falha ao criar pedido: RPC não retornou um ID.' });

    const newEntity = await this.findById(newId as string);
    if (!newEntity) throw new RepositoryError({ message: 'Falha ao buscar o pedido recém-criado.' });

    return newEntity;
  }

  async update(id: string, updates: Partial<PedidoVenda>): Promise<PedidoVenda> {
    const { itens, ...pedidoUpdates } = updates;

    const rpcParams = {
      p_pedido_id: id,
      p_pedido_data: camelToSnake(pedidoUpdates),
      p_itens: camelToSnake(itens || []),
    };

    const { error: rpcError } = await this.supabase.rpc('update_pedido_venda_completo', rpcParams);

    if (rpcError) this.handleError('update (rpc)', rpcError);

    const updatedEntity = await this.findById(id);
    if (!updatedEntity) throw new RepositoryError({ message: 'Falha ao buscar o pedido recém-atualizado.' });

    return updatedEntity;
  }

  async delete(id: string): Promise<void> {
    const { error } = await this.supabase.rpc('delete_pedido_venda', { p_id: id });
    if (error) this.handleError('delete (rpc)', error);
  }

  async searchProdutosEServicos(empresaId: string, query: string): Promise<any[]> {
    const { data, error } = await this.supabase.rpc('search_produtos_e_servicos', {
      p_empresa_id: empresaId,
      p_query: query,
    });
    if (error) this.handleError('searchProdutosEServicos', error);
    return snakeToCamel(data || []) as any[];
  }
}
