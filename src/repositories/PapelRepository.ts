import { BaseRepository } from './BaseRepository';
import { Papel } from '../types';
import { IPapelRepository } from './interfaces';
import { snakeToCamel } from '../lib/utils';

export class PapelRepository extends BaseRepository<Papel> implements IPapelRepository {
  constructor() {
    super('papeis');
  }

  protected createEntity(data: Omit<Papel, 'id' | 'createdAt' | 'updatedAt'>): Papel {
    return {
      id: '',
      createdAt: new Date(),
      updatedAt: new Date(),
      ...data,
    };
  }
  
  async findById(id: string): Promise<Papel | null> {
    const { data, error } = await this.supabase
      .from(this.tableName)
      .select('*, permissoes:papel_permissoes(permissao_id)')
      .eq('id', id)
      .single();

    if (error && error.code !== 'PGRST116') {
      this.handleError('findById', error);
    }
    if (!data) return null;

    const papel = snakeToCamel(data) as any;
    // Transforma o array de objetos { permissaoId: '...'} em um array de strings
    papel.permissoes = papel.permissoes?.map((p: any) => p.permissaoId) || [];
    
    return papel as Papel;
  }

  async setPermissions(papelId: string, permissionIds: string[]): Promise<void> {
    const { error } = await this.supabase.rpc('set_papel_permissions', {
      p_papel_id: papelId,
      p_permission_ids: permissionIds,
    });

    if (error) {
      this.handleError('setPermissions (rpc)', error);
    }
  }
}
