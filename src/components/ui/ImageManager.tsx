import React from 'react';
import { useDropzone } from 'react-dropzone';
import { motion, AnimatePresence } from 'framer-motion';
import { UploadCloud, Trash2 } from 'lucide-react';
import { GlassButton } from './GlassButton';
import { IEntity } from '../../types';
import toast from 'react-hot-toast';

interface ImagemGenerica extends IEntity {
  nomeArquivo: string;
  storagePath: string;
  tamanhoBytes: number;
  contentType: string;
  url?: string;
}

interface ImageManagerProps<T extends ImagemGenerica> {
  images: (T | File)[];
  onImagesChange: (images: (T | File)[]) => void;
  getPublicUrlService: (filePath: string) => string;
}

const isFile = (item: ImagemGenerica | File): item is File => {
  return item instanceof File;
};

export const ImageManager = <T extends ImagemGenerica>({
  images,
  onImagesChange,
  getPublicUrlService,
}: ImageManagerProps<T>) => {

  const onDrop = React.useCallback((acceptedFiles: File[]) => {
    const validFiles = acceptedFiles.filter(file => {
      if (file.size > 2 * 1024 * 1024) { // 2MB
        toast.error(`Arquivo "${file.name}" excede o tamanho máximo de 2MB.`);
        return false;
      }
      if (!file.type.startsWith('image/')) {
        toast.error(`Arquivo "${file.name}" não é uma imagem válida.`);
        return false;
      }
      return true;
    });

    if (validFiles.length > 0) {
      onImagesChange([...images, ...validFiles]);
    }
  }, [images, onImagesChange]);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    multiple: true,
    accept: { 'image/*': ['.jpeg', '.png', '.gif', '.webp'] }
  });

  const handleDelete = (itemToDelete: T | File) => {
    const newImages = images.filter(item => item !== itemToDelete);
    onImagesChange(newImages);
  };

  return (
    <div className="space-y-6">
      <div
        {...getRootProps()}
        className={`p-10 border-2 border-dashed rounded-xl text-center cursor-pointer transition-colors
          ${isDragActive ? 'border-blue-500 bg-blue-50' : 'border-gray-300 hover:border-blue-400'}
        `}
      >
        <input {...getInputProps()} />
        <div className="flex flex-col items-center justify-center gap-4 text-gray-600">
          <UploadCloud size={48} className="text-gray-400" />
          <p className="font-semibold">Arraste e solte imagens aqui, ou clique para selecionar</p>
          <p className="text-sm">Tamanho máximo por arquivo: 2MB</p>
        </div>
      </div>

      <div>
        <h3 className="text-lg font-medium text-gray-800 mb-4">Imagens do Produto</h3>
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
          <AnimatePresence>
            {images.map((item, index) => (
              <motion.div
                key={isFile(item) ? item.name + item.lastModified : item.id}
                layout
                initial={{ opacity: 0, scale: 0.8 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.8 }}
                transition={{ duration: 0.2, delay: index * 0.05 }}
                className="relative group aspect-square bg-glass-50 rounded-xl overflow-hidden border border-white/20"
              >
                <img 
                    src={isFile(item) ? URL.createObjectURL(item) : getPublicUrlService((item as T).storagePath)} 
                    alt={isFile(item) ? item.name : (item as T).nomeArquivo}
                    className="w-full h-full object-cover"
                />
                <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                    <GlassButton icon={Trash2} size="sm" variant="danger" onClick={() => handleDelete(item)} />
                </div>
                {isFile(item) && <span className="absolute top-2 right-2 text-xs font-semibold text-blue-600 bg-white/80 px-2 py-1 rounded-full">Pendente</span>}
              </motion.div>
            ))}
          </AnimatePresence>
        </div>
        {images.length === 0 && (
          <p className="text-sm text-center text-gray-500 py-4">Nenhuma imagem adicionada.</p>
        )}
      </div>
    </div>
  );
};
