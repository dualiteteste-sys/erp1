import { Produto, ProdutoImagem } from '../types';
import { IProdutoService } from './interfaces';
import { IProdutoRepository } from '../repositories/interfaces';
import { snakeToCamel } from '../lib/utils';
import { RepositoryError } from '../repositories/RepositoryError';
import toast from 'react-hot-toast';

export class ProdutoService implements IProdutoService {
  public repository: IProdutoRepository;

  constructor(repository: IProdutoRepository) {
    this.repository = repository;
  }

  async getAll(empresaId: string, options: { page?: number; pageSize?: number } = {}): Promise<{ data: Produto[]; count: number }> {
    return this.repository.findAll(empresaId, options);
  }

  async findById(id: string): Promise<Produto | null> {
    return this.repository.findById(id);
  }

  async search(empresaId: string, query: string): Promise<Pick<Produto, 'id' | 'nome' | 'precoVenda' | 'codigo' | 'unidade' | 'custoMedio'>[]> {
    return this.repository.search(empresaId, query);
  }

  async create(data: Omit<Produto, 'id' | 'createdAt' | 'updatedAt'>): Promise<Produto> {
    return this.repository.create(data);
  }

  async update(id: string, data: Partial<Produto>): Promise<Produto> {
    return this.repository.update(id, data);
  }

  async delete(id: string): Promise<void> {
    const imagePaths = await this.repository.delete(id);
    if (imagePaths && imagePaths.length > 0) {
      const { error: storageError } = await this.repository.supabase.storage
        .from('produto-imagens')
        .remove(imagePaths);
      
      if (storageError && storageError.message !== 'The resource was not found') {
        console.warn('Erro ao deletar arquivos do storage, mas o registro do DB foi removido:', storageError);
        toast.warn('Produto excluído, mas falha ao limpar imagens antigas.');
      }
    }
  }

  async uploadImagem(empresaId: string, produtoId: string, file: File): Promise<ProdutoImagem> {
    const filePath = await this.repository.uploadImagem(empresaId, produtoId, file);
    
    const rpcParams = {
      p_produto_id: produtoId,
      p_storage_path: filePath,
      p_filename: file.name,
      p_content_type: file.type,
      p_tamanho_bytes: file.size,
    };

    const { data: newImagemData, error } = await this.repository.supabase
      .rpc('create_produto_imagem', rpcParams)
      .single();

    if (error) {
      await this.repository.supabase.storage.from('produto-imagens').remove([filePath]);
      throw new RepositoryError({ message: error.message, code: error.code });
    }
    
    if (!newImagemData) {
      throw new RepositoryError({ message: 'Falha ao criar o registro da imagem: RPC não retornou dados.' });
    }
    
    return snakeToCamel(newImagemData) as ProdutoImagem;
  }

  async deleteImagem(imagemId: string, filePath: string): Promise<void> {
    return this.repository.deleteImagem(imagemId, filePath);
  }

  getImagemPublicUrl = (filePath: string): string => {
    const { data } = this.repository.supabase.storage
      .from('produto-imagens')
      .getPublicUrl(filePath);
    return data.publicUrl;
  }
}
