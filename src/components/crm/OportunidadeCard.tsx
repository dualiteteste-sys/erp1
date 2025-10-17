import React from 'react';
import { useSortable } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import { Oportunidade } from '../../types';
import { User, DollarSign } from 'lucide-react';

interface OportunidadeCardProps {
  oportunidade: Oportunidade;
  onClick?: () => void;
  isOverlay?: boolean;
}

export const OportunidadeCard: React.FC<OportunidadeCardProps> = ({ oportunidade, onClick, isOverlay = false }) => {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({ id: oportunidade.id });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
    boxShadow: isOverlay ? '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)' : undefined,
    cursor: isOverlay ? 'grabbing' : 'grab',
  };

  const formatCurrency = (value: number) => new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(value);

  return (
    <div
      ref={setNodeRef}
      style={style}
      {...attributes}
      {...listeners}
      onClick={onClick}
      className="bg-white/80 backdrop-blur-sm p-4 rounded-xl border border-white/30 shadow-sm cursor-pointer"
    >
      <h4 className="font-semibold text-gray-800 text-sm mb-2">{oportunidade.titulo}</h4>
      <p className="text-xs text-gray-600 mb-3">{oportunidade.cliente?.nomeRazaoSocial || 'Cliente não definido'}</p>
      
      <div className="flex justify-between items-center text-xs text-gray-700">
        <div className="flex items-center gap-1">
          <User size={12} />
          <span>{oportunidade.vendedor?.nome || 'Sem vendedor'}</span>
        </div>
        <div className="flex items-center gap-1 font-medium text-green-700">
          <DollarSign size={12} />
          <span>{formatCurrency(oportunidade.valor)}</span>
        </div>
      </div>
    </div>
  );
};
