import { BaseRepository } from './BaseRepository';
import { ClienteFornecedor, ClienteContato, ClienteAnexo } from '../types';
import { camelToSnake, snakeToCamel } from '../lib/utils';
import { IClienteRepository } from './interfaces';
import { RepositoryError } from './RepositoryError';

/**
 * Repositório para a entidade ClienteFornecedor.
 * Segue o padrão de repositório, abstraindo o acesso direto ao Supabase.
 * Todas as interações com as tabelas `clientes_fornecedores`, `clientes_contatos`
 * e `clientes_anexos` são centralizadas aqui.
 */
export class ClienteRepository extends BaseRepository<ClienteFornecedor> implements IClienteRepository {
  constructor() {
    super('clientes_fornecedores');
  }

  protected createEntity(data: Omit<ClienteFornecedor, 'id' | 'createdAt' | 'updatedAt'>): ClienteFornecedor {
    // Este método é um placeholder e não é usado para inserts diretos.
    return {
      id: '',
      empresaId: '',
      nomeRazaoSocial: '',
      tipoPessoa: data.tipoPessoa,
      tipoContato: data.tipoContato,
      cobrancaDiferente: false,
      createdAt: new Date(),
      updatedAt: new Date(),
      ...data,
    };
  }

  /**
   * Busca um Cliente/Fornecedor pelo ID, incluindo seus contatos e anexos.
   * @param id - O UUID do cliente/fornecedor.
   * @returns O cliente/fornecedor encontrado ou null.
   */
  async findById(id: string): Promise<ClienteFornecedor | null> {
    const { data, error } = await this.supabase
      .from(this.tableName)
      .select('*, contatos:clientes_contatos(*), anexos:clientes_anexos(*)')
      .eq('id', id)
      .single();
      
    if (error && error.code !== 'PGRST116') this.handleError('findById', error);
    return snakeToCamel(data) as ClienteFornecedor | null;
  }
  
  /**
   * Realiza uma busca por nome/razão social.
   * @param empresaId - O ID da empresa atual.
   * @param query - O termo de busca.
   * @param tipoContato - Filtra por 'cliente' ou 'fornecedor'.
   * @returns Uma lista de clientes/fornecedores correspondentes.
   */
  async search(empresaId: string, query: string, tipoContato?: 'cliente' | 'fornecedor'): Promise<Pick<ClienteFornecedor, 'id' | 'nomeRazaoSocial'>[]> {
    let request = this.supabase
      .from(this.tableName)
      .select('id, nome_razao_social')
      .eq('empresa_id', empresaId)
      .ilike('nome_razao_social', `%${query}%`);

    if (tipoContato) {
      request = request.in('tipo_contato', [tipoContato, 'ambos']);
    }

    const { data, error } = await request.limit(10);
    this.handleError(`search (tipo: ${tipoContato})`, error);
    return snakeToCamel(data || []) as Pick<ClienteFornecedor, 'id' | 'nomeRazaoSocial'>[];
  }

  /**
   * Cria um novo cliente/fornecedor com seus contatos usando a função RPC segura.
   * @param data - Dados do cliente/fornecedor a ser criado.
   * @returns O novo cliente/fornecedor criado.
   */
  async create(data: Partial<Omit<ClienteFornecedor, 'id' | 'createdAt' | 'updatedAt'>>): Promise<ClienteFornecedor> {
    const { contatos, anexos, ...clienteData } = data;

    const rpcParams = {
      p_empresa_id: clienteData.empresaId,
      p_cliente_data: camelToSnake(clienteData),
      p_contatos: camelToSnake(contatos || []),
    };

    const { data: newId, error: rpcError } = await this.supabase.rpc(
      'create_cliente_fornecedor_completo',
      rpcParams
    );

    if (rpcError) {
      this.handleError('create (rpc)', rpcError);
    }
    if (!newId) {
      throw new RepositoryError({ message: 'Falha ao criar: RPC não retornou um ID.' });
    }

    const newEntity = await this.findById(newId as string);
    if (!newEntity) {
      throw new RepositoryError({ message: 'Falha ao buscar o registro recém-criado após RPC.' });
    }
    
    newEntity.anexos = [];

    return newEntity;
  }

  /**
   * Atualiza um cliente/fornecedor e seus contatos usando a função RPC segura.
   * @param id - O ID do cliente a ser atualizado.
   * @param updates - Os dados a serem atualizados.
   * @returns O cliente/fornecedor atualizado.
   */
  async update(id: string, updates: Partial<ClienteFornecedor>): Promise<ClienteFornecedor> {
    const { contatos, anexos, ...clienteUpdates } = updates;

    const rpcParams = {
      p_cliente_id: id,
      p_cliente_data: camelToSnake(clienteUpdates),
      p_contatos: camelToSnake(contatos || []),
    };

    const { error: rpcError } = await this.supabase.rpc(
      'update_cliente_fornecedor_completo',
      rpcParams
    );

    if (rpcError) {
      this.handleError('update (rpc)', rpcError);
    }

    const updatedEntity = await this.findById(id);
    if (!updatedEntity) {
      throw new RepositoryError({ message: 'Falha ao buscar o registro recém-atualizado após RPC.' });
    }
    
    updatedEntity.anexos = anexos || [];

    return updatedEntity;
  }

  /**
   * Deleta um cliente/fornecedor usando a RPC segura.
   * @param id - O ID do cliente a ser deletado.
   */
  async delete(id: string): Promise<void> {
    const { error } = await this.supabase.rpc('delete_cliente_fornecedor_if_member', { p_id: id });
    if (error) this.handleError('delete (rpc)', error);
  }

  /**
   * Faz o upload de um anexo para o Supabase Storage.
   * @param empresaId - ID da empresa.
   * @param clienteId - ID do cliente.
   * @param file - O arquivo a ser enviado.
   * @returns O caminho do arquivo no storage.
   */
  async uploadAnexo(empresaId: string, clienteId: string, file: File): Promise<string> {
    const sanitizedFileName = file.name.normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-zA-Z0-9._-]/g, '_').replace(/\s+/g, '_');
    const filePath = `${empresaId}/${clienteId}/${Date.now()}-${sanitizedFileName}`;
    const { error } = await this.supabase.storage
      .from('clientes_anexos')
      .upload(filePath, file);

    if (error) {
      this.handleError('uploadAnexo', error);
    }
    return filePath;
  }

  /**
   * Deleta um anexo do banco de dados e do Supabase Storage.
   * @param anexoId - ID do registro do anexo na tabela.
   * @param filePath - Caminho do arquivo no storage.
   */
  async deleteAnexo(anexoId: string, filePath: string): Promise<void> {
    const { error: dbError } = await this.supabase
      .from('clientes_anexos')
      .delete()
      .eq('id', anexoId);
    this.handleError('deleteAnexo (db)', dbError);

    const { error: storageError } = await this.supabase.storage
      .from('clientes_anexos')
      .remove([filePath]);
    // Não lança erro se o arquivo já não existir no storage
    if (storageError && storageError.message !== 'The resource was not found') {
        this.handleError('deleteAnexo (storage)', storageError);
    }
  }
}
