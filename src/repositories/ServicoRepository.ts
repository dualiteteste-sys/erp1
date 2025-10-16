import { BaseRepository } from './BaseRepository';
import { Servico } from '../types';
import { IServicoRepository } from './interfaces';
import { RepositoryError } from './RepositoryError';

export class ServicoRepository extends BaseRepository<Servico> implements IServicoRepository {
  constructor() {
    super('servicos');
  }

  protected createEntity(data: Omit<Servico, 'id' | 'createdAt' | 'updatedAt'>): Servico {
    return {
      id: '',
      createdAt: new Date(),
      updatedAt: new Date(),
      ...data,
    };
  }

  async create(data: Omit<Servico, 'id' | 'createdAt' | 'updatedAt'>): Promise<Servico> {
    const { data: newId, error } = await this.supabase.rpc('create_servico', {
      p_empresa_id: data.empresaId,
      p_descricao: data.descricao,
      p_preco: data.preco,
      p_situacao: data.situacao,
      p_codigo: data.codigo,
      p_unidade: data.unidade,
      p_codigo_servico: data.codigoServico,
      p_nbs: data.nbs,
      p_descricao_complementar: data.descricaoComplementar,
      p_observacoes: data.observacoes,
    });
    
    if (error) this.handleError('create (rpc)', error);
    if (!newId) throw new RepositoryError({ message: 'Falha ao criar serviço: RPC não retornou um ID.' });

    const newEntity = await this.findById(newId as string);
    if (!newEntity) throw new RepositoryError({ message: 'Falha ao buscar o serviço recém-criado.' });
    
    return newEntity;
  }

  async update(id: string, updates: Partial<Servico>): Promise<Servico> {
    const existingData = await this.findById(id);
    if (!existingData) {
      throw new RepositoryError({ message: 'Serviço não encontrado para atualização.' });
    }
    
    const fullData = { ...existingData, ...updates };

    const { error } = await this.supabase.rpc('update_servico', {
      p_id: id,
      p_descricao: fullData.descricao,
      p_preco: fullData.preco,
      p_situacao: fullData.situacao,
      p_codigo: fullData.codigo,
      p_unidade: fullData.unidade,
      p_codigo_servico: fullData.codigoServico,
      p_nbs: fullData.nbs,
      p_descricao_complementar: fullData.descricaoComplementar,
      p_observacoes: fullData.observacoes,
    });

    if (error) this.handleError('update (rpc)', error);

    const updatedEntity = await this.findById(id);
    if (!updatedEntity) {
      throw new RepositoryError({ message: 'Falha ao buscar o serviço recém-atualizado.' });
    }
    
    return updatedEntity;
  }

  async delete(id: string): Promise<void> {
    const { error } = await this.supabase.rpc('delete_servico', { p_id: id });
    if (error) this.handleError('delete (rpc)', error);
  }
}
