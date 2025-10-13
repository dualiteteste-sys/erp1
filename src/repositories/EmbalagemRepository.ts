import { BaseRepository } from './BaseRepository';
import { Embalagem } from '../types';
import { IEmbalagemRepository } from './interfaces';
import { RepositoryError } from './RepositoryError';

export class EmbalagemRepository extends BaseRepository<Embalagem> implements IEmbalagemRepository {
  constructor() {
    super('embalagens');
  }

  protected createEntity(data: Omit<Embalagem, 'id' | 'createdAt' | 'updatedAt'>): Embalagem {
    // Este método é um placeholder agora que usamos RPCs para escrita.
    return {
      id: '',
      createdAt: new Date(),
      updatedAt: new Date(),
      ...data,
    };
  }

  async create(data: Omit<Embalagem, 'id' | 'createdAt' | 'updatedAt'>): Promise<Embalagem> {
    const rpcParams = {
      p_empresa_id: data.empresaId,
      p_descricao: data.descricao,
      p_tipo: data.tipo,
      p_peso: data.peso,
      p_largura: data.largura,
      p_altura: data.altura,
      p_comprimento: data.comprimento,
      p_diametro: data.diametro,
    };

    const { data: newId, error: rpcError } = await this.supabase.rpc('create_embalagem', rpcParams);

    if (rpcError) {
      this.handleError('create (rpc)', rpcError);
    }
    if (!newId) {
      throw new RepositoryError({ message: 'Falha ao criar embalagem: RPC não retornou um ID.' });
    }

    const newEntity = await this.findById(newId as string);
    if (!newEntity) {
      throw new RepositoryError({ message: 'Falha ao buscar a embalagem recém-criada.' });
    }

    return newEntity;
  }

  async update(id: string, updates: Partial<Embalagem>): Promise<Embalagem> {
    const rpcParams = {
      p_id: id,
      p_descricao: updates.descricao,
      p_tipo: updates.tipo,
      p_peso: updates.peso,
      p_largura: updates.largura,
      p_altura: updates.altura,
      p_comprimento: updates.comprimento,
      p_diametro: updates.diametro,
    };

    const { error: rpcError } = await this.supabase.rpc('update_embalagem', rpcParams);

    if (rpcError) {
      this.handleError('update (rpc)', rpcError);
    }

    const updatedEntity = await this.findById(id);
    if (!updatedEntity) {
      throw new RepositoryError({ message: 'Falha ao buscar a embalagem recém-atualizada.' });
    }

    return updatedEntity;
  }

  async delete(id: string): Promise<void> {
    const { error } = await this.supabase.rpc('delete_embalagem', { p_id: id });
    if (error) this.handleError('delete (rpc)', error);
  }
}
