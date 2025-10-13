import React from 'react';
import { useDropzone } from 'react-dropzone';
import { motion, AnimatePresence } from 'framer-motion';
import { UploadCloud, FileText, Trash2, Image as ImageIcon } from 'lucide-react';
import { GlassButton } from './GlassButton';
import { IEntity } from '../../types';
import toast from 'react-hot-toast';

interface AnexoGenerico extends IEntity {
  nomeArquivo: string;
  path: string;
  tamanho: number;
  tipo: string;
}

interface AttachmentManagerProps<T extends AnexoGenerico> {
  attachments: (T | File)[];
  onAttachmentsChange: (attachments: (T | File)[]) => void;
  getPublicUrlService: (filePath: string) => string;
}

// Type guard para diferenciar File de AnexoGenerico
const isFile = (item: AnexoGenerico | File): item is File => {
  return item instanceof File;
};

export const AttachmentManager = <T extends AnexoGenerico>({
  attachments,
  onAttachmentsChange,
  getPublicUrlService,
}: AttachmentManagerProps<T>) => {

  const onDrop = React.useCallback((acceptedFiles: File[]) => {
    const validFiles = acceptedFiles.filter(file => {
      if (file.size > 2 * 1024 * 1024) { // 2MB
        toast.error(`Arquivo "${file.name}" excede o tamanho máximo de 2MB.`);
        return false;
      }
      return true;
    });

    if (validFiles.length > 0) {
      onAttachmentsChange([...attachments, ...validFiles]);
    }
  }, [attachments, onAttachmentsChange]);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    multiple: true,
  });

  const handleDelete = (itemToDelete: T | File) => {
    const newAttachments = attachments.filter(item => item !== itemToDelete);
    onAttachmentsChange(newAttachments);
  };

  const formatBytes = (bytes: number, decimals = 2) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
  };

  const getFileIcon = (item: T | File) => {
    const type = isFile(item) ? item.type : item.tipo;
    if (type.startsWith('image/')) {
        const url = isFile(item) ? URL.createObjectURL(item) : getPublicUrlService(item.path);
        return <img src={url} alt={isFile(item) ? item.name : item.nomeArquivo} className="w-10 h-10 object-cover rounded-md flex-shrink-0" />;
    }
    return <FileText className="text-gray-500 w-10 h-10 flex-shrink-0" size={24} />;
  }

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
          <p className="font-semibold">Arraste e solte arquivos aqui, ou clique para selecionar</p>
          <p className="text-sm">Tamanho máximo por arquivo: 2MB</p>
        </div>
      </div>

      <div>
        <h3 className="text-lg font-medium text-gray-800 mb-4">Arquivos</h3>
        <div className="space-y-3">
          <AnimatePresence>
            {attachments.map((item, index) => (
              <motion.div
                key={isFile(item) ? item.name + item.lastModified : item.id}
                layout
                initial={{ opacity: 0, y: -10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: 10 }}
                transition={{ duration: 0.2, delay: index * 0.05 }}
                className="flex items-center gap-4 p-3 rounded-lg bg-glass-50"
              >
                {getFileIcon(item)}
                <div className="flex-1 min-w-0">
                  {isFile(item) ? (
                    <p className="text-sm font-medium text-gray-800 truncate">{item.name}</p>
                  ) : (
                    <a
                      href={getPublicUrlService((item as T).path)}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-sm font-medium text-blue-600 hover:underline truncate"
                    >
                      {(item as T).nomeArquivo}
                    </a>
                  )}
                  <div className="flex items-center gap-2 text-xs text-gray-500">
                    <span>{formatBytes(isFile(item) ? item.size : item.tamanho)}</span>
                    {!isFile(item) && (
                      <>
                        <span>•</span>
                        <span>{new Date(item.createdAt).toLocaleDateString('pt-BR')}</span>
                      </>
                    )}
                  </div>
                </div>
                {isFile(item) && <span className="text-xs font-semibold text-blue-600 bg-blue-100 px-2 py-1 rounded-full">Pendente</span>}
                <GlassButton icon={Trash2} size="sm" variant="danger" onClick={() => handleDelete(item)} />
              </motion.div>
            ))}
          </AnimatePresence>
          {attachments.length === 0 && (
            <p className="text-sm text-center text-gray-500 py-4">Nenhum anexo adicionado.</p>
          )}
        </div>
      </div>
    </div>
  );
};
