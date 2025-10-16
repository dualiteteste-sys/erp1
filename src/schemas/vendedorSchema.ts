import { z } from 'zod';
import { SituacaoVendedor, TipoPessoaVendedor, TipoContribuinteIcms, RegraLiberacaoComissao, TipoComissao } from '../types';

const vendedorContatoSchema = z.object({
  id: z.string().uuid().optional().nullable(),
  nome: z.string().min(1, 'Nome do contato é obrigatório.'),
  setor: z.string().optional().nullable(),
  email: z.string().email('E-mail do contato inválido').or(z.literal('')).optional().nullable(),
  telefone: z.string().optional().nullable(),
  ramal: z.string().optional().nullable(),
});

export const vendedorSchema = z.object({
  id: z.string().uuid().optional().nullable(),
  empresaId: z.string().uuid().optional().nullable(),
  
  // Informações Principais
  nome: z.string().min(1, "Nome é obrigatório."),
  fantasia: z.string().optional().nullable(),
  codigo: z.string().optional().nullable(),
  tipoPessoa: z.nativeEnum(TipoPessoaVendedor).default(TipoPessoaVendedor.PESSOA_FISICA),
  cpfCnpj: z.string().optional().nullable(),
  documentoIdentificacao: z.string().optional().nullable(),
  pais: z.string().optional().nullable(),
  contribuinteIcms: z.nativeEnum(TipoContribuinteIcms).optional().nullable(),
  inscricaoEstadual: z.string().optional().nullable(),
  situacao: z.nativeEnum(SituacaoVendedor).default(SituacaoVendedor.ATIVO_COM_ACESSO),
  
  // Endereço
  cep: z.string().optional().nullable(),
  logradouro: z.string().optional().nullable(),
  numero: z.string().optional().nullable(),
  complemento: z.string().optional().nullable(),
  bairro: z.string().optional().nullable(),
  cidade: z.string().optional().nullable(),
  uf: z.string().optional().nullable(),

  // Contato
  telefone: z.string().optional().nullable(),
  celular: z.string().optional().nullable(),
  email: z.string().email('E-mail inválido.').or(z.literal('')).optional().nullable(),
  emailComunicacao: z.string().email('E-mail de comunicação inválido.').or(z.literal('')).optional().nullable(),

  // Acesso e Permissões
  depositoPadrao: z.string().optional().nullable(),
  senha: z.string().optional().nullable(),
  acessoRestritoHorario: z.boolean().default(false),
  acessoRestritoIp: z.string().optional().nullable(),
  perfilContato: z.array(z.string()).optional().nullable(),
  permissoesModulos: z.any().optional().nullable(),

  // Comissionamento
  regraLiberacaoComissao: z.nativeEnum(RegraLiberacaoComissao).optional().nullable(),
  tipoComissao: z.nativeEnum(TipoComissao).optional().nullable(),
  aliquotaComissao: z.preprocess((val) => {
    if (typeof val === 'string') {
      const num = parseFloat(val.replace('.', '').replace(',', '.'));
      return isNaN(num) ? null : num;
    }
    return val;
  }, z.number().nullable().optional()),
  desconsiderarComissionamentoLinhasProduto: z.boolean().default(false),
  observacoesComissao: z.string().optional().nullable(),

  // Contatos Adicionais
  contatos: z.array(vendedorContatoSchema).optional(),
}).passthrough();

export type VendedorFormData = z.infer<typeof vendedorSchema>;
export type VendedorContatoFormData = z.infer<typeof vendedorContatoSchema>;
