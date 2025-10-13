import { IEntity } from './base';
import { TipoEmbalagemProduto } from './produto';

export interface Embalagem extends IEntity {
  empresaId: string;
  descricao: string;
  tipo: TipoEmbalagemProduto;
  peso?: number;
  largura?: number;
  altura?: number;
  comprimento?: number;
  diametro?: number;
}
