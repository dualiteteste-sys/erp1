import React from 'react';
import { useSortable, SortableContext, verticalListSortingStrategy } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import { Oportunidade } from '../../types';
import { OportunidadeCard } from './OportunidadeCard';

interface KanbanColumnProps {
  id: string;
  title: string;
  oportunidades: Oportunidade[];
  onCardClick: (oportunidade: Oportunidade) => void;
}

export const KanbanColumn: React.FC<KanbanColumnProps> = ({ id, title, oportunidades, onCardClick }) => {
  const { setNodeRef } = useSortable({ id });

  const totalValor = oportunidades.reduce((sum, op) => sum + op.valor, 0);

  return (
    <div
      ref={setNodeRef}
      className="flex flex-col w-80 flex-shrink-0"
    >
      <div className="p-4 bg-glass-100/80 backdrop-blur-md rounded-t-2xl border-b border-white/20">
        <div className="flex justify-between items-center">
          <h3 className="font-semibold text-gray-800">{title}</h3>
          <span className="text-sm font-medium text-gray-500 bg-glass-200 px-2 py-1 rounded-full">
            {oportunidades.length}
          </span>
        </div>
        <p className="text-sm text-gray-600 mt-1">
          R$ {totalValor.toLocaleString('pt-BR', { minimumFractionDigits: 2 })}
        </p>
      </div>
      <div className="flex-1 bg-glass-50 backdrop-blur-sm rounded-b-2xl p-4 space-y-4 overflow-y-auto h-[calc(100vh-22rem)] scrollbar-styled">
        <SortableContext items={oportunidades.map(op => op.id)} strategy={verticalListSortingStrategy}>
          {oportunidades.map(op => (
            <OportunidadeCard key={op.id} oportunidade={op} onClick={() => onCardClick(op)} />
          ))}
        </SortableContext>
      </div>
    </div>
  );
};
