import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Search, Loader2 } from 'lucide-react';
import { GlassButton } from '../ui/GlassButton';
import { GlassInput } from '../ui/GlassInput';
import { useNcm } from '../../hooks/useNcm';

interface NcmSuggestionPanelProps {
  isOpen: boolean;
  onClose: () => void;
  onSelect: (ncm: string) => void;
}

export const NcmSuggestionPanel: React.FC<NcmSuggestionPanelProps> = ({ isOpen, onClose, onSelect }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const { suggestions, loading, searchNcmByDescription } = useNcm();

  useEffect(() => {
    if (!isOpen) {
      setSearchTerm('');
      searchNcmByDescription(''); // Limpa as sugestões
    }
  }, [isOpen, searchNcmByDescription]);

  useEffect(() => {
    const handler = setTimeout(() => {
      searchNcmByDescription(searchTerm);
    }, 300);
    return () => clearTimeout(handler);
  }, [searchTerm, searchNcmByDescription]);

  const handleSelect = (ncm: string) => {
    onSelect(ncm);
    onClose();
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/30 backdrop-blur-sm z-40"
            onClick={onClose}
          />
          <motion.div
            initial={{ x: '100%' }}
            animate={{ x: 0 }}
            exit={{ x: '100%' }}
            transition={{ type: 'spring', stiffness: 300, damping: 30 }}
            className="fixed top-0 right-0 h-full w-full max-w-md bg-glass-100 border-l border-white/20 shadow-2xl z-50 flex flex-col"
          >
            <header className="p-4 flex items-center justify-between border-b border-white/20 flex-shrink-0">
              <h3 className="text-lg font-bold text-gray-800">Sugerir NCM</h3>
              <GlassButton icon={X} size="sm" variant="secondary" onClick={onClose} />
            </header>
            
            <div className="p-4 flex-shrink-0">
              <GlassInput
                icon={<Search size={18} />}
                placeholder="Digite a descrição do produto..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
              <p className="text-xs text-gray-500 mt-2">Ex: Camiseta, smartphone, fone de ouvido...</p>
            </div>

            <div className="flex-1 overflow-y-auto px-4 pb-4">
              {loading && <div className="flex justify-center py-4"><Loader2 className="animate-spin text-blue-500" /></div>}
              {!loading && suggestions.length > 0 && (
                <ul className="space-y-2">
                  {suggestions.map(s => (
                    <li
                      key={s.codigo}
                      onClick={() => handleSelect(s.codigo)}
                      className="p-3 rounded-lg hover:bg-blue-100/80 cursor-pointer transition-colors"
                    >
                      <p className="font-medium text-gray-800">{s.codigo}</p>
                      <p className="text-sm text-gray-600">{s.descricao}</p>
                    </li>
                  ))}
                </ul>
              )}
              {!loading && searchTerm.length >= 3 && suggestions.length === 0 && (
                <p className="text-center text-gray-500 py-4">Nenhuma sugestão encontrada.</p>
              )}
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
};
