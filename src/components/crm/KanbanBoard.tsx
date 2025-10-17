import React, { useState } from 'react';
import { DndContext, closestCenter, PointerSensor, useSensor, useSensors, DragEndEvent, DragStartEvent, DragOverlay } from '@dnd-kit/core';
import { SortableContext, horizontalListSortingStrategy } from '@dnd-kit/sortable';
import { KanbanColumn } from './KanbanColumn';
import { Oportunidade, CrmEtapaFunil } from '../../types';
import { OportunidadeCard } from './OportunidadeCard';

interface KanbanBoardProps {
  stages: CrmEtapaFunil[];
  oportunidadesPorEtapa: { [key in CrmEtapaFunil]?: Oportunidade[] };
  onDragEnd: (oportunidadeId: string, novaEtapa: CrmEtapaFunil) => void;
  onCardClick: (oportunidade: Oportunidade) => void;
}

export const KanbanBoard: React.FC<KanbanBoardProps> = ({ stages, oportunidadesPorEtapa, onDragEnd, onCardClick }) => {
  const [activeId, setActiveId] = useState<string | null>(null);

  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: {
        distance: 8,
      },
    })
  );

  const handleDragStart = (event: DragStartEvent) => {
    setActiveId(event.active.id as string);
  };

  const handleDragEnd = (event: DragEndEvent) => {
    const { active, over } = event;
    setActiveId(null);

    if (over && active.id !== over.id) {
      const activeContainer = active.data.current?.sortable.containerId;
      const overContainer = over.data.current?.sortable.containerId;

      if (activeContainer !== overContainer) {
        onDragEnd(active.id as string, overContainer as CrmEtapaFunil);
      }
    }
  };
  
  const getActiveOportunidade = () => {
    if (!activeId) return null;
    for (const stage of stages) {
      const op = oportunidadesPorEtapa[stage]?.find(o => o.id === activeId);
      if (op) return op;
    }
    return null;
  };

  return (
    <DndContext
      sensors={sensors}
      collisionDetection={closestCenter}
      onDragStart={handleDragStart}
      onDragEnd={handleDragEnd}
    >
      <div className="flex gap-6 overflow-x-auto pb-4 -mx-8 px-8">
        <SortableContext items={stages} strategy={horizontalListSortingStrategy}>
          {stages.map(stage => (
            <KanbanColumn
              key={stage}
              id={stage}
              title={stage}
              oportunidades={oportunidadesPorEtapa[stage] || []}
              onCardClick={onCardClick}
            />
          ))}
        </SortableContext>
      </div>
       <DragOverlay>
        {activeId ? (
          <OportunidadeCard oportunidade={getActiveOportunidade()!} isOverlay />
        ) : null}
      </DragOverlay>
    </DndContext>
  );
};
