import { BaseRepository } from './BaseRepository';
import { Vendedor } from '../types';
import { IVendedorRepository } from './interfaces';
import { RepositoryError } from './RepositoryError';
import { snakeToCamel } from '../lib/utils';
import { VendedorFormData } from '../schemas/vendedorSchema';

export class VendedorRepository extends BaseRepository<Vendedor> implements IVendedorRepository {
  constructor() {
    super('vendedores');
  }

  protected createEntity(data: Omit<Vendedor, 'id' | 'createdAt' | 'updatedAt'>): Vendedor {
    return {
      id: '',
      createdAt: new Date(),
      updatedAt: new Date(),
      acessoRestritoHorario: false,
      desconsiderarComissionamentoLinhasProduto: false,
      ...data,
    };
  }

  async findById(id: string): Promise<Vendedor | null> {
    const { data, error } = await this.supabase
      .from(this.tableName)
      .select('*, contatos:vendedores_contatos(*)')
      .eq('id', id)
      .single();
      
    if (error && error.code !== 'PGRST116') this.handleError('findById', error);
    return snakeToCamel(data) as Vendedor | null;
  }

  private buildRpcParams(data: Partial<VendedorFormData>, id?: string) {
    const params: { [key: string]: any } = {};
    
    if (!id) {
      params.p_empresa_id = data.empresaId ?? null;
    }
    if (id) {
      params.p_id = id;
    }
    
    // Mapeamento explícito para garantir a ordem e os nomes corretos
    params.p_nome = data.nome ?? null;
    params.p_fantasia = data.fantasia ?? null;
    params.p_codigo = data.codigo ?? null;
    params.p_tipo_pessoa = data.tipoPessoa ?? null;
    params.p_cpf_cnpj = data.cpfCnpj ?? null;
    params.p_documento_identificacao = data.documentoIdentificacao ?? null;
    params.p_pais = data.pais ?? null;
    params.p_contribuinte_icms = data.contribuinteIcms ?? null;
    params.p_inscricao_estadual = data.inscricaoEstadual ?? null;
    params.p_situacao = data.situacao ?? null;
    params.p_cep = data.cep ?? null;
    params.p_logradouro = data.logradouro ?? null;
    params.p_numero = data.numero ?? null;
    params.p_complemento = data.complemento ?? null;
    params.p_bairro = data.bairro ?? null;
    params.p_cidade = data.cidade ?? null;
    params.p_uf = data.uf ?? null;
    params.p_telefone = data.telefone ?? null;
    params.p_celular = data.celular ?? null;
    params.p_email = data.email ?? null;
    params.p_email_comunicacao = data.emailComunicacao ?? null;
    params.p_deposito_padrao = data.depositoPadrao ?? null;
    params.p_senha = data.senha ?? null;
    params.p_acesso_restrito_horario = data.acessoRestritoHorario ?? false;
    params.p_acesso_restrito_ip = data.acessoRestritoIp ?? null;
    params.p_perfil_contato = data.perfilContato ?? null;
    params.p_permissoes_modulos = data.permissoesModulos ?? null;
    params.p_regra_liberacao_comissao = data.regraLiberacaoComissao ?? null;
    params.p_tipo_comissao = data.tipoComissao ?? null;
    params.p_aliquota_comissao = data.aliquotaComissao ?? null;
    params.p_desconsiderar_comissionamento_linhas_produto = data.desconsiderarComissionamentoLinhasProduto ?? false;
    params.p_observacoes_comissao = data.observacoesComissao ?? null;
    params.p_contatos = data.contatos ?? [];

    return params;
  }

  async create(data: Partial<Omit<Vendedor, 'id' | 'createdAt' | 'updatedAt'>>): Promise<Vendedor> {
    const rpcParams = this.buildRpcParams(data);

    const { data: newId, error } = await this.supabase.rpc('create_vendedor', rpcParams);
    
    if (error) this.handleError('create (rpc)', error);
    if (!newId) throw new RepositoryError({ message: 'Falha ao criar vendedor: RPC não retornou um ID.' });

    const newEntity = await this.findById(newId as string);
    if (!newEntity) throw new RepositoryError({ message: 'Falha ao buscar o vendedor recém-criado.' });
    
    return newEntity;
  }

  async update(id: string, updates: Partial<Vendedor>): Promise<Vendedor> {
    const rpcParams = this.buildRpcParams(updates, id);
    
    const { error } = await this.supabase.rpc('update_vendedor', rpcParams);

    if (error) this.handleError('update (rpc)', error);

    const updatedEntity = await this.findById(id);
    if (!updatedEntity) throw new RepositoryError({ message: 'Falha ao buscar o vendedor recém-atualizado.' });
    
    return updatedEntity;
  }

  async delete(id: string): Promise<void> {
    const { error } = await this.supabase.rpc('delete_vendedor', { p_id: id });
    if (error) this.handleError('delete (rpc)', error);
  }

  async checkEmailExists(empresaId: string, email: string, vendedorId?: string): Promise<boolean> {
    const { data, error } = await this.supabase.rpc('check_vendedor_email_exists', {
      p_empresa_id: empresaId,
      p_email: email,
      p_vendedor_id: vendedorId
    });
    
    if (error) this.handleError('checkEmailExists (rpc)', error);
    return data;
  }

  async findAll(
    empresaId: string,
    options: { page?: number; pageSize?: number } = {}
  ): Promise<{ data: Vendedor[]; count: number }> {
    const select = 'id, nome, email, cpf_cnpj, situacao';
    return super.findAll(empresaId, options, select);
  }
}
