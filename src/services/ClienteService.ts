import { ClienteFornecedor, ClienteAnexo } from '../types';
import { IClienteService } from './interfaces';
import { IClienteRepository } from '../repositories/interfaces';
import { snakeToCamel } from '../lib/utils';
import { RepositoryError } from '../repositories/RepositoryError';

/**
 * Service para a entidade ClienteFornecedor.
 * Orquestra a lógica de negócio e interage com o repositório.
 * Segue o princípio de Injeção de Dependência, recebendo o repositório no construtor.
 */
export class ClienteService implements IClienteService {
  public repository: IClienteRepository;

  constructor(repository: IClienteRepository) {
    this.repository = repository;
  }

  async getAll(empresaId: string, options: { page?: number; pageSize?: number } = {}): Promise<{ data: ClienteFornecedor[]; count: number }> {
    return this.repository.findAll(empresaId, options);
  }

  async findById(id: string): Promise<ClienteFornecedor | null> {
    return this.repository.findById(id);
  }

  async search(empresaId: string, query: string, type?: 'cliente' | 'fornecedor'): Promise<Pick<ClienteFornecedor, 'id' | 'nomeRazaoSocial'>[]> {
    return this.repository.search(empresaId, query, type);
  }

  async create(data: Omit<ClienteFornecedor, 'id' | 'createdAt' | 'updatedAt'>): Promise<ClienteFornecedor> {
    return this.repository.create(data);
  }

  async update(id: string, data: Partial<ClienteFornecedor>): Promise<ClienteFornecedor> {
    return this.repository.update(id, data);
  }

  async delete(id: string): Promise<void> {
    // A lógica de deleção em cascata (contatos, anexos) é tratada pela RPC no repositório.
    return this.repository.delete(id);
  }

  /**
   * Orquestra o upload de um anexo:
   * 1. Envia o arquivo para o Storage.
   * 2. Chama a RPC `create_cliente_anexo` para criar o registro no banco de dados de forma segura.
   * @param empresaId - ID da empresa.
   * @param clienteId - ID do cliente.
   * @param file - O arquivo a ser enviado.
   * @returns O objeto do anexo criado.
   */
  async uploadAnexo(empresaId: string, clienteId: string, file: File): Promise<ClienteAnexo> {
    const filePath = await this.repository.uploadAnexo(empresaId, clienteId, file);
    
    const rpcParams = {
      p_empresa_id: empresaId,
      p_cliente_id: clienteId,
      p_storage_path: filePath,
      p_filename: file.name,
      p_content_type: file.type,
      p_tamanho_bytes: file.size,
    };

    const { data: newAnexoData, error } = await this.repository.supabase
      .rpc('create_cliente_anexo', rpcParams)
      .single();

    if (error) {
      // Rollback: se falhar ao salvar no DB, remove o arquivo do storage.
      await this.repository.supabase.storage.from('clientes_anexos').remove([filePath]);
      throw new RepositoryError({ message: error.message, code: error.code });
    }
    
    if (!newAnexoData) {
      throw new RepositoryError({ message: 'Falha ao criar o registro do anexo: RPC não retornou dados.' });
    }
    
    return snakeToCamel(newAnexoData) as ClienteAnexo;
  }

  async deleteAnexo(anexoId: string, filePath: string): Promise<void> {
    return this.repository.deleteAnexo(anexoId, filePath);
  }

  getAnexoPublicUrl = (filePath: string): string => {
    const { data } = this.repository.supabase.storage
      .from('clientes_anexos')
      .getPublicUrl(filePath);
    return data.publicUrl;
  }
}
