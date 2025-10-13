import { BaseRepository } from './BaseRepository';
import { Produto } from '../types';
import { camelToSnake, snakeToCamel } from '../lib/utils';
import { IProdutoRepository } from './interfaces';
import { RepositoryError } from './RepositoryError';

export class ProdutoRepository extends BaseRepository<Produto> implements IProdutoRepository {
  constructor() {
    super('produtos');
  }

  protected createEntity(data: Omit<Produto, 'id' | 'createdAt' | 'updatedAt'>): Produto {
    return {
      ...data,
      id: '',
      createdAt: new Date(),
      updatedAt: new Date(),
      imagens: [],
      fornecedores: [],
      atributos: [],
    };
  }

  // ---- utils ---------------------------------------------------------------

  /** String vazia -> null */
  private emptyToNull(v: any): string | null {
    if (v === null || v === undefined) return null;
    const s = String(v).trim();
    return s === '' ? null : s;
  }

  /** Converte strings pt-BR/en-US de moeda/decimal para number. */
  private normalizeNumberFromLocale(value: unknown): number | null {
    if (value === null || value === undefined) return null;
    if (typeof value === 'number') return Number.isFinite(value) ? value : null;

    const raw = String(value).trim();
    if (raw === '') return null;

    let normalized = raw;
    if (/,/.test(raw) && /\./.test(raw)) {
      normalized = raw.replace(/\./g, '').replace(',', '.'); // "1.234,56" -> "1234.56"
    } else if (/,/.test(raw)) {
      normalized = raw.replace(',', '.'); // "1234,56" -> "1234.56"
    }
    const num = Number(normalized);
    return Number.isFinite(num) ? num : null;
  }

  /** Garante preco_venda válido (number >= 0) no payload snake_case. */
  private enforcePrecoVendaOnPayload(payload: Record<string, any>) {
    const val = payload.preco_venda;
    const normalized = this.normalizeNumberFromLocale(val);
    if (normalized === null || Number.isNaN(normalized)) {
      throw new RepositoryError({ message: '[Guard] preco_venda inválido (vazio ou não numérico).' });
    }
    if (normalized < 0) {
      throw new RepositoryError({ message: '[Guard] preco_venda não pode ser negativo.' });
    }
    payload.preco_venda = normalized;
  }

  /** Copia/normaliza GTIN/NCM para o payload snake_case antes do RPC. */
  private adaptGtinENcm(payloadSnake: Record<string, any>, originalCamel: any) {
    const gtinFromForm = (originalCamel as any)?.gtin;
    const codigoBarrasCamel = (originalCamel as any)?.codigoBarras;

    if (gtinFromForm !== undefined && payloadSnake.codigo_barras === undefined) {
      payloadSnake.codigo_barras = String(gtinFromForm);
    }
    if (codigoBarrasCamel !== undefined && payloadSnake.codigo_barras === undefined) {
      payloadSnake.codigo_barras = String(codigoBarrasCamel);
    }

    if (payloadSnake.codigo_barras !== undefined && payloadSnake.codigo_barras !== null) {
      payloadSnake.codigo_barras = String(payloadSnake.codigo_barras).replace(/\D/g, '') || null;
    }

    const ncmFromCamel = (originalCamel as any)?.ncm;
    if (ncmFromCamel !== undefined && payloadSnake.ncm === undefined) {
      payloadSnake.ncm = ncmFromCamel;
    }
    if (payloadSnake.ncm !== undefined && payloadSnake.ncm !== null) {
      payloadSnake.ncm = String(payloadSnake.ncm).replace(/\D/g, '') || null;
    }
  }

  private normalizeSituacao(v: any): 'Ativo' | 'Inativo' | undefined {
    if (v == null) return undefined;
    const s = String(v).trim().toLowerCase();
    if (s === 'ativo') return 'Ativo';
    if (s === 'inativo') return 'Inativo';
    return undefined;
  }

  private normalizeTipo(v: any): 'Simples' | 'Com variações' | undefined {
    if (v == null) return undefined;
    const s = String(v).trim().toLowerCase();
    if (s === 'simples') return 'Simples';
    if (s === 'com variações' || s === 'com variacoes' || s === 'variacoes' || s === 'variações') {
      return 'Com variações';
    }
    return undefined;
  }

  // ---- consultas -----------------------------------------------------------

  async search(
    empresaId: string,
    query: string
  ): Promise<Pick<Produto, 'id' | 'nome' | 'precoVenda' | 'codigo' | 'unidade' | 'custoMedio'>[]> {
    const { data, error } = await this.supabase
      .from(this.tableName)
      .select('id, nome, preco_venda, codigo, unidade, custo_medio')
      .eq('empresa_id', empresaId)
      .or(`nome.ilike.%${query}%,codigo.eq.${query},codigo_barras.eq.${query}`)
      .eq('situacao', 'Ativo')
      .limit(10);

    if (error) this.handleError('search', error);
    return snakeToCamel(data || []) as Pick<
      Produto,
      'id' | 'nome' | 'precoVenda' | 'codigo' | 'unidade' | 'custoMedio'
    >[];
  }

  async findAll(
    empresaId: string,
    options: { page?: number; pageSize?: number } = {}
  ): Promise<{ data: Produto[]; count: number }> {
    const { page = 1, pageSize = 10 } = options;
    const from = (page - 1) * pageSize;
    const to = from + pageSize - 1;

    const selectString = 'id, nome, codigo, preco_venda, controlar_estoque, situacao, unidade';

    const { data, error, count } = await this.supabase
      .from(this.tableName)
      .select(selectString, { count: 'exact' })
      .eq('empresa_id', empresaId)
      .order('nome', { ascending: true })
      .range(from, to);

    if (error) this.handleError('findAll', error);

    return {
      data: (snakeToCamel(data || []) as Produto[]),
      count: count || 0,
    };
  }

  async findById(id: string): Promise<Produto | null> {
    const { data, error } = await this.supabase
      .from(this.tableName)
      .select(
        '*, atributos:produto_atributos(*), fornecedores:produto_fornecedores(*, fornecedor:clientes_fornecedores(id, nome_razao_social)), embalagem:embalagens(*)'
      )
      .eq('id', id)
      .single();

    if (error && error.code !== 'PGRST116') {
      this.handleError('findById', error);
    }
    if (!data) return null;

    return snakeToCamel(data) as Produto;
  }

  // ---- create/update/delete ------------------------------------------------

  async create(data: Partial<Omit<Produto, 'id' | 'createdAt' | 'updatedAt'>>): Promise<Produto> {
    const { atributos, fornecedores, ...produtoData } = data;

    const produtoDataSnake = camelToSnake(produtoData) as Record<string, any>;

    // GTIN/NCM
    this.adaptGtinENcm(produtoDataSnake, produtoData);

    // preco_venda
    const precoCandidate =
      (produtoData as any).precoVenda ??
      (produtoData as any).preco ??
      produtoDataSnake.preco_venda ??
      null;
    produtoDataSnake.preco_venda = this.normalizeNumberFromLocale(precoCandidate);
    this.enforcePrecoVendaOnPayload(produtoDataSnake);

    // empresa_id
    const empresaIdSnake =
      produtoDataSnake.empresa_id ??
      (produtoData as any).empresaId ??
      null;
    if (!empresaIdSnake) {
      throw new RepositoryError({ message: '[Guard] empresa_id é obrigatório.' });
    }

    // ✅ normalizações de domínio
    produtoDataSnake.situacao = this.normalizeSituacao((produtoData as any).situacao) ?? 'Ativo';
    produtoDataSnake.tipo = this.normalizeTipo((produtoData as any).tipo) ?? 'Simples';

    // ✅ código em branco -> NULL (evita conflito do índice único)
    const codigoCandidate = (produtoData as any).codigo ?? produtoDataSnake.codigo ?? null;
    produtoDataSnake.codigo = this.emptyToNull(codigoCandidate);

    const rpcParams = {
      p_empresa_id: empresaIdSnake,
      p_produto_data: produtoDataSnake,
      p_atributos: camelToSnake(atributos || []),
      p_fornecedores: camelToSnake(fornecedores || []),
    };

    const { data: created, error: rpcError } = await this.supabase.rpc('create_produto_completo', rpcParams);
    if (rpcError) this.handleError('create (rpc)', rpcError);

    if (created && typeof created === 'object') {
      return snakeToCamel(created) as Produto;
    }
    if (created && typeof created === 'string') {
      const newEntity = await this.findById(created as string);
      if (!newEntity) throw new RepositoryError({ message: 'Falha ao buscar o produto recém-criado após RPC.' });
      return newEntity;
    }

    throw new RepositoryError({ message: 'Falha ao criar produto: RPC não retornou dados.' });
  }

  async update(id: string, updates: Partial<Produto>): Promise<Produto> {
    const { atributos, fornecedores, ...produtoUpdates } = updates;

    const updatesSnake = camelToSnake(produtoUpdates) as Record<string, any>;

    // GTIN/NCM
    this.adaptGtinENcm(updatesSnake, produtoUpdates);

    // preco_venda (somente se veio)
    if (
      Object.prototype.hasOwnProperty.call(produtoUpdates, 'precoVenda') ||
      Object.prototype.hasOwnProperty.call(produtoUpdates as any, 'preco') ||
      Object.prototype.hasOwnProperty.call(updatesSnake, 'preco_venda')
    ) {
      const precoCandidateUpd =
        (produtoUpdates as any).precoVenda ??
        (produtoUpdates as any).preco ??
        updatesSnake.preco_venda ??
        null;

      updatesSnake.preco_venda = this.normalizeNumberFromLocale(precoCandidateUpd);
      this.enforcePrecoVendaOnPayload(updatesSnake);
    }

    // ✅ situacao/tipo (se vierem)
    const situacaoUpd = this.normalizeSituacao((produtoUpdates as any).situacao);
    if (situacaoUpd) updatesSnake.situacao = situacaoUpd;

    const tipoUpd = this.normalizeTipo((produtoUpdates as any).tipo);
    if (tipoUpd) updatesSnake.tipo = tipoUpd;

    // ✅ código em branco -> NULL (evita conflito)
    if (
      Object.prototype.hasOwnProperty.call(produtoUpdates, 'codigo') ||
      Object.prototype.hasOwnProperty.call(updatesSnake, 'codigo')
    ) {
      const codigoUpd =
        (produtoUpdates as any).codigo ??
        updatesSnake.codigo ??
        null;
      updatesSnake.codigo = this.emptyToNull(codigoUpd);
    }

    const rpcParams = {
      p_produto_id: id,
      p_produto_data: updatesSnake,
      p_atributos: camelToSnake(atributos || []),
      p_fornecedores: camelToSnake(fornecedores || []),
    };

    const { data: updated, error: rpcError } = await this.supabase.rpc('update_produto_completo', rpcParams);
    if (rpcError) this.handleError('update (rpc)', rpcError);

    if (updated && typeof updated === 'object') {
      return snakeToCamel(updated) as Produto;
    }

    const reloaded = await this.findById(id);
    if (!reloaded) throw new RepositoryError({ message: 'Falha ao recarregar produto após atualização' });
    return reloaded;
  }

  async delete(id: string): Promise<string[]> {
    const { error: rpcError } = await this.supabase.rpc('delete_produto', { p_id: id });
    if (rpcError) this.handleError('delete (rpc)', rpcError);
    return [];
  }
}
