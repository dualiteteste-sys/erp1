// src/schemas/produtoSchema.ts
import { z } from 'zod';

/**
 * Schema do formulário de Produto.
 * - Mantém TODOS os campos das abas.
 * - Usa `.passthrough()` para não podar chaves desconhecidas.
 * - Converte valores numéricos pt-BR para number onde faz sentido.
 */

const numericNullable = z
  .union([z.number(), z.nan(), z.string()])
  .transform((v) => {
    if (v === '' || v === null || v === undefined) return null;
    if (typeof v === 'number') return Number.isFinite(v) ? v : null;
    const s = String(v).trim();
    if (s === '') return null;
    // "1.234,56" -> 1234.56 ; "1234,56" -> 1234.56 ; "1234.56" -> 1234.56
    const normalized =
      /,/.test(s) && /\./.test(s) ? s.replace(/\./g, '').replace(',', '.') : s.replace(',', '.');
    const n = Number(normalized);
    return Number.isFinite(n) ? n : null;
  })
  .nullable()
  .optional();

const precoField = z
  .union([z.number(), z.string()])
  .transform((v) => {
    if (typeof v === 'number') return Number.isFinite(v) ? v : 0;
    const s = String(v ?? '').trim();
    if (!s) return 0;
    const normalized =
      /,/.test(s) && /\./.test(s) ? s.replace(/\./g, '').replace(',', '.') : s.replace(',', '.');
    const n = Number(normalized);
    return Number.isFinite(n) ? n : 0;
  });

export const produtoSchema = z
  .object({
    // Metadados
    id: z.string().uuid().optional(),
    empresaId: z.string().uuid().optional(),

    // Dados Gerais
    nome: z.string().min(1, 'Informe o nome do produto'),
    tipo: z.string().nullable().optional(),              // "Simples", "Com variações", etc.
    situacao: z.string().nullable().optional(),          // "Ativo" / "Inativo"
    codigo: z.string().optional(),                       // SKU interno
    codigoBarras: z.string().optional(),                 // alias UI; será copiado para codigo_barras
    gtin: z.string().optional(),                         // aceita como alias também
    unidade: z.string().optional(),
    origem: z.string().nullable().optional(),
    ncm: z.string().optional(),
    cest: z.string().optional(),

    precoVenda: precoField,      // R$ pt-BR -> number
    custoMedio: numericNullable, // number | null

    controlarEstoque: z.boolean().optional(),
    estoqueInicial: numericNullable,
    estoqueMinimo: numericNullable,
    estoqueMaximo: numericNullable,
    localizacao: z.string().optional(),
    diasPreparacao: z.number().int().nullable().optional(),

    // Embalagem / Pesos / Dimensões
    controlarLotes: z.boolean().optional(),
    embalagemId: z.string().uuid().nullable().optional(),
    pesoLiquido: numericNullable,
    pesoBruto: numericNullable,
    numeroVolumes: z.number().int().nullable().optional(),
    largura: numericNullable,
    altura: numericNullable,
    comprimento: numericNullable,
    diametro: numericNullable,

    // Dados Complementares / Marketing / SEO / Conteúdo
    marca: z.string().optional(),
    modelo: z.string().optional(),
    disponibilidade: z.string().optional(), // ex.: "7 dias úteis"
    garantia: z.string().optional(),        // ex.: "3 anos"
    videoUrl: z.string().url().or(z.literal('')).optional(),
    descricaoCurta: z.string().optional(),
    descricaoComplementar: z.string().optional(),

    slug: z.string().optional(),
    tituloSeo: z.string().optional(),
    metaDescricaoSeo: z.string().optional(),

    observacoes: z.string().optional(),

    // Atributos relacionados
    atributos: z
      .array(
        z.object({
          id: z.string().optional(),
          atributo: z.string().min(1, 'Informe o nome do atributo'),
          valor: z.string().optional().default(''),
        })
      )
      .optional(),

    fornecedores: z
      .array(
        z.object({
          id: z.string().optional(),
          fornecedorId: z.string().uuid(),
          codigoNoFornecedor: z.string().optional(),
        })
      )
      .optional(),

    // (Imagens foram desabilitadas no front, mas deixo aqui para compatibilidade)
    imagens: z.array(z.any()).optional(),
  })
  // MUITO IMPORTANTE: não remover chaves desconhecidas (campos de outras abas)
  .passthrough();

export type ProdutoFormData = z.infer<typeof produtoSchema>;
