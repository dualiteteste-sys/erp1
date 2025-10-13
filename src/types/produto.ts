import { IEntity } from './base';
import { Embalagem } from './embalagem';

export enum TipoProduto {
    SIMPLES = 'Simples',
    COM_VARIACOES = 'Com variações',
    KIT = 'Kit',
    FABRICADO = 'Fabricado',
    MATERIA_PRIMA = 'Matéria Prima',
}

export enum SituacaoProduto {
    ATIVO = 'Ativo',
    INATIVO = 'Inativo'
}

export enum OrigemProduto {
    NACIONAL = '0 - Nacional',
    ESTRANGEIRA_DIRETA = '1 - Estrangeira (Imp. Direta)',
    ESTRANGEIRA_INTERNO = '2 - Estrangeira (Merc. Interno)',
    NACIONAL_CONTEUDO_40_70 = '3 - Nacional (Imp. > 40%)',
    NACIONAL_PROCESSO_BASICO = '4 - Nacional (Proc. Básico)',
    NACIONAL_CONTEUDO_INF_40 = '5 - Nacional (Imp. <= 40%)',
    ESTRANGEIRA_DIRETA_SEM_SIMILAR = '6 - Estrangeira (Imp. Direta, s/ similar)',
    ESTRANGEIRA_INTERNO_SEM_SIMILAR = '7 - Estrangeira (Merc. Interno, s/ similar)',
    NACIONAL_CONTEUDO_SUP_70 = '8 - Nacional (Imp. > 70%)'
}

export enum TipoEmbalagemProduto {
    CAIXA = 'Caixa',
    ROLO_CILINDRO = 'Rolo / Cilindro',
    ENVELOPE = 'Envelope',
    FARDO = 'Fardo',
}

export enum EmbalagemProduto {
    CUSTOMIZADA = 'Embalagem customizada',
    PROPRIA = 'Própria',
    TERCEIROS = 'Terceiros',
}

export interface ProdutoImagem extends IEntity {
    produtoId: string;
    storagePath: string;
    nomeArquivo: string;
    tamanhoBytes: number;
    contentType: string;
    url?: string;
}

export interface ProdutoAtributo {
    id: string;
    atributo: string;
    valor: string;
}

export interface ProdutoFornecedor {
    id: string;
    fornecedorId: string;
    codigoNoFornecedor?: string;
    fornecedor?: { nomeRazaoSocial: string };
}

export interface Produto extends IEntity {
    empresaId: string;
    nome: string;
    tipo: TipoProduto;
    situacao: SituacaoProduto;
    codigo?: string;
    codigoBarras?: string;
    unidade: string;
    precoVenda: number;
    custoMedio?: number;
    origem: OrigemProduto;
    ncm?: string;
    cest?: string;
    controlarEstoque: boolean;
    estoqueInicial?: number;
    estoqueMinimo?: number;
    estoqueMaximo?: number;
    localizacao?: string;
    diasPreparacao?: number;
    controlarLotes?: boolean;
    estoqueAtual?: number;
    pesoLiquido?: number;
    pesoBruto?: number;
    numeroVolumes?: number;
    largura?: number;
    altura?: number;
    comprimento?: number;
    diametro?: number | null;
    marca?: string;
    modelo?: string;
    disponibilidade?: string;
    garantia?: string;
    videoUrl?: string;
    descricaoCurta?: string;
    descricaoComplementar?: string;
    slug?: string;
    tituloSeo?: string;
    metaDescricaoSeo?: string;
    observacoes?: string;
    imagens: (ProdutoImagem | File)[];
    atributos?: ProdutoAtributo[];
    fornecedores?: ProdutoFornecedor[];
    embalagem?: Embalagem | null;
}
