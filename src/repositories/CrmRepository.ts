import { BaseRepository } from './BaseRepository';
import { Oportunidade } from '../types';
import { ICrmRepository } from './interfaces';
import { RepositoryError } from './RepositoryError';
import { camelToSnake, snakeToCamel } from '../lib/utils';

export class CrmRepository extends BaseRepository<Oportunidade> implements ICrmRepository {
  constructor() {
    super('crm_oportunidades');
  }

  protected createEntity(data: Omit<Oportunidade, 'id' | 'createdAt' | 'updatedAt'>): Oportunidade {
    return {
      id: '',
      createdAt: new Date(),
      updatedAt: new Date(),
      ...data,
    } as Oportunidade;
  }

  async findById(id: string): Promise<Oportunidade | null> {
    const { data, error } = await this.supabase
      .from(this.tableName)
      .select('*, cliente:clientes_fornecedores(id, nome_razao_social), vendedor:vendedores(id, nome), itens:crm_oportunidade_itens(*, produto:produtos(id, nome), servico:servicos(id, descricao))')
      .eq('id', id)
      .single();
      
    if (error && error.code !== 'PGRST116') this.handleError('findById', error);
    return snakeToCamel(data) as Oportunidade | null;
  }

  async create(data: Partial<Omit<Oportunidade, 'id' | 'createdAt' | 'updatedAt'>>): Promise<Oportunidade> {
    const { itens, ...oportunidadeData } = data;

    const rpcParams = {
      p_empresa_id: oportunidadeData.empresaId,
      p_oportunidade_data: camelToSnake(oportunidadeData),
      p_itens: camelToSnake(itens || []),
    };

    const { data: newId, error: rpcError } = await this.supabase.rpc('create_crm_oportunidade', rpcParams);

    if (rpcError) this.handleError('create (rpc)', rpcError);
    if (!newId) throw new RepositoryError({ message: 'Falha ao criar oportunidade: RPC não retornou um ID.' });

    const newEntity = await this.findById(newId as string);
    if (!newEntity) throw new RepositoryError({ message: 'Falha ao buscar a oportunidade recém-criada.' });

    return newEntity;
  }

  async update(id: string, updates: Partial<Oportunidade>): Promise<Oportunidade> {
    const { itens, ...oportunidadeUpdates } = updates;

    const rpcParams = {
      p_oportunidade_id: id,
      p_oportunidade_data: camelToSnake(oportunidadeUpdates),
      p_itens: camelToSnake(itens || []),
    };

    const { error: rpcError } = await this.supabase.rpc('update_crm_oportunidade', rpcParams);

    if (rpcError) this.handleError('update (rpc)', rpcError);

    const updatedEntity = await this.findById(id);
    if (!updatedEntity) throw new RepositoryError({ message: 'Falha ao buscar a oportunidade recém-atualizada.' });

    return updatedEntity;
  }

  async delete(id: string): Promise<void> {
    const { error } = await this.supabase.rpc('delete_crm_oportunidade', { p_id: id });
    if (error) this.handleError('delete (rpc)', error);
  }
}
