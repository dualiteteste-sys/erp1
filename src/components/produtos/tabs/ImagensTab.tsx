import React from 'react';
import { UseFormSetValue } from 'react-hook-form';
import { ProdutoImagem } from '../../../types';
import { ImageManager } from '../../ui/ImageManager';
import { useService } from '../../../hooks/useService';
import { ProdutoFormData } from '../../../schemas/produtoSchema';

interface ImagensTabProps {
  images: (File | ProdutoImagem)[];
  setValue: UseFormSetValue<ProdutoFormData>;
}

export const ImagensTab: React.FC<ImagensTabProps> = ({ images, setValue }) => {
  const produtoService = useService('produto');

  return (
    <ImageManager
      images={images}
      onImagesChange={(newImages) => setValue('imagens', newImages, { shouldDirty: true })}
      getPublicUrlService={produtoService.getImagemPublicUrl}
    />
  );
};
