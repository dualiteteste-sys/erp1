import { z } from 'zod';
import { TipoPessoa, TipoContato } from '../types';

const requiredString = (field: string) => z.string({ required_error: `${field} é obrigatório.` }).min(1, `${field} é obrigatório.`);

export const clienteContatoSchema = z.object({
  id: z.string().uuid().optional().nullable(),
  nome: requiredString('Nome do contato'),
  setor: z.string().optional().nullable(),
  email: z.string().email('E-mail do contato inválido').or(z.literal('')).optional().nullable(),
  telefone: z.string().optional().nullable(),
  ramal: z.string().optional().nullable(),
});

export const clienteFornecedorSchema = z.object({
  id: z.string().uuid().optional().nullable(),
  empresaId: z.string().uuid({ message: "ID da empresa é obrigatório." }),
  nomeRazaoSocial: requiredString('Nome/Razão Social').max(120),
  tipoPessoa: z.nativeEnum(TipoPessoa).default(TipoPessoa.PJ),
  tipoContato: z.nativeEnum(TipoContato).default(TipoContato.CLIENTE),

  fantasia: z.string().max(60).optional().nullable(),
  cnpjCpf: z.string().optional().nullable(),
  inscricaoEstadual: z.string().optional().nullable(),
  inscricaoMunicipal: z.string().optional().nullable(),
  rg: z.string().optional().nullable(),
  rnm: z.string().optional().nullable(),

  cep: z.string().optional().nullable(),
  municipio: z.string().optional().nullable(),
  uf: z.string().max(2).optional().nullable(),
  endereco: z.string().optional().nullable(),
  bairro: z.string().optional().nullable(),
  numero: z.string().optional().nullable(),
  complemento: z.string().optional().nullable(),

  cobrancaDiferente: z.boolean().default(false),
  cobrCep: z.string().optional().nullable(),
  cobrMunicipio: z.string().optional().nullable(),
  cobrUf: z.string().max(2).optional().nullable(),
  cobrEndereco: z.string().optional().nullable(),
  cobrBairro: z.string().optional().nullable(),
  cobrNumero: z.string().optional().nullable(),
  cobrComplemento: z.string().optional().nullable(),

  telefone: z.string().optional().nullable(),
  telefoneAdicional: z.string().optional().nullable(),
  celular: z.string().optional().nullable(),
  website: z.string().url('URL do site inválida').or(z.literal('')).optional().nullable(),
  email: z.string().email('E-mail inválido').or(z.literal('')).optional().nullable(),
  emailNfe: z.string().email('E-mail NF-e inválido').or(z.literal('')).optional().nullable(),
  observacoes: z.string().optional().nullable(),

  contatos: z.array(clienteContatoSchema).optional(),
  // Permite um array de objetos complexos (File ou ClienteAnexo)
  anexos: z.array(z.any()).optional(),
}).superRefine((data, ctx) => {
    if (data.cobrancaDiferente) {
        if (!data.cobrCep) ctx.addIssue({ code: 'custom', message: 'CEP de cobrança é obrigatório', path: ['cobrCep']});
        if (!data.cobrMunicipio) ctx.addIssue({ code: 'custom', message: 'Município de cobrança é obrigatório', path: ['cobrMunicipio']});
    }
});

export type ClienteFornecedorFormData = z.infer<typeof clienteFornecedorSchema>;
export type ClienteContatoFormData = z.infer<typeof clienteContatoSchema>;
