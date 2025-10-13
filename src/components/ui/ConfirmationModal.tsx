import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, AlertTriangle } from 'lucide-react';
import { GlassButton } from './GlassButton';
import { useConfirmationStore } from '../../stores/useConfirmationStore';

export const ConfirmationModal: React.FC = () => {
  const { isOpen, title, message, onConfirm, hide } = useConfirmationStore();

  const handleConfirm = () => {
    onConfirm();
    hide();
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 bg-gray-800/50 backdrop-blur-sm flex items-center justify-center z-[100] p-4"
          onClick={hide}
        >
          <motion.div
            initial={{ scale: 0.9, opacity: 0, y: 20 }}
            animate={{ scale: 1, opacity: 1, y: 0 }}
            exit={{ scale: 0.9, opacity: 0, y: 20 }}
            transition={{ type: 'spring', stiffness: 300, damping: 25 }}
            className="bg-glass-100 rounded-2xl shadow-glass-lg border border-white/20 p-8 w-full max-w-md"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-start gap-4">
              <div className="w-12 h-12 bg-red-100 rounded-full flex-shrink-0 flex items-center justify-center">
                <AlertTriangle className="text-red-600" size={24} />
              </div>
              <div className="flex-1">
                <h3 className="text-xl font-bold text-gray-800">{title}</h3>
                <p className="text-gray-600 mt-2">{message}</p>
              </div>
              <GlassButton icon={X} variant="secondary" size="sm" onClick={hide} />
            </div>
            
            <div className="flex justify-end gap-4 mt-8">
              <GlassButton variant="secondary" onClick={hide}>
                Cancelar
              </GlassButton>
              <GlassButton variant="danger" onClick={handleConfirm}>
                Confirmar
              </GlassButton>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
};
