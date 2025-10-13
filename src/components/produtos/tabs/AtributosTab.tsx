import React from 'react';
import { Control, useFieldArray, Controller } from 'react-hook-form';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus, Trash2, Sparkles } from 'lucide-react';
import { GlassInput } from '../../ui/GlassInput';
import { GlassButton } from '../../ui/GlassButton';
import toast from 'react-hot-toast';
import { ProdutoFormData } from '../../../schemas/produtoSchema';

interface AtributosTabProps {
  control: Control<ProdutoFormData>;
}

const sugestoesAtributos = ['Cor', 'Tamanho', 'Voltagem', 'Material', 'Capacidade', 'Dimensões'];

export const AtributosTab: React.FC<AtributosTabProps> = ({ control }) => {
  const { fields, append, remove, update } = useFieldArray({
    control,
    name: "atributos",
  });

  const handleAddAtributo = () => {
    append({ id: crypto.randomUUID(), atributo: '', valor: '' });
  };

  const handleBlur = (index: number, field: 'atributo' | 'valor') => {
    const currentAtributos = control._getWatch('atributos') || [];
    const atributo = currentAtributos[index];
    if (!atributo) return;

    const trimmedValue = atributo[field].trim();
    if (trimmedValue !== atributo[field]) {
      update(index, { ...atributo, [field]: trimmedValue });
    }

    if (field === 'atributo' && trimmedValue) {
      const isDuplicate = currentAtributos.some((a, i) => i !== index && a.atributo.toLowerCase() === trimmedValue.toLowerCase());
      if (isDuplicate) {
        toast.error(`O atributo "${trimmedValue}" já existe.`);
        update(index, { ...atributo, atributo: '' });
      }
    }
  };

  const handleSugestao = () => {
    const currentAtributos = control._getWatch('atributos') || [];
    const atributosExistentes = new Set(currentAtributos.map(a => a.atributo.toLowerCase()));
    const novasSugestoes = sugestoesAtributos
      .filter(s => !atributosExistentes.has(s.toLowerCase()))
      .map(s => ({
        id: crypto.randomUUID(),
        atributo: s,
        valor: '',
      }));
    
    if (novasSugestoes.length > 0) {
        append(novasSugestoes);
        toast.success('Atributos sugeridos foram adicionados!');
    } else {
        toast.error("Todas as sugestões de atributos já foram adicionadas.");
    }
  };

  return (
    <div className="space-y-8">
      <section>
        <div className="flex justify-between items-center mb-4">
            <h3 className="text-lg font-semibold text-gray-800">Atributos do Produto</h3>
            <GlassButton icon={Sparkles} onClick={handleSugestao}>
                Sugerir Atributos
            </GlassButton>
        </div>
        <p className="text-sm text-gray-500 mb-6">
            Adicione características como cor, tamanho ou material. Estes atributos ajudam a criar variações do produto.
        </p>

        <div className="space-y-4">
            <div className="grid grid-cols-12 gap-4 px-2 pb-2 border-b border-white/20">
                <div className="col-span-5 font-medium text-gray-700">Atributo</div>
                <div className="col-span-6 font-medium text-gray-700">Valor</div>
                <div className="col-span-1"></div>
            </div>
            <AnimatePresence>
                {fields.map((item, index) => (
                    <motion.div
                        key={item.id}
                        layout
                        initial={{ opacity: 0, y: -10 }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0, x: -20, transition: { duration: 0.2 } }}
                        className="grid grid-cols-12 gap-4 items-center"
                    >
                        <div className="col-span-5">
                            <Controller name={`atributos.${index}.atributo`} control={control} render={({ field }) => (
                              <GlassInput
                                  {...field}
                                  placeholder="Ex: Cor, Tamanho..."
                                  onBlur={() => handleBlur(index, 'atributo')}
                                  maxLength={60}
                                  aria-label={`Nome do atributo ${index}`}
                              />
                            )} />
                        </div>
                        <div className="col-span-6">
                            <Controller name={`atributos.${index}.valor`} control={control} render={({ field }) => (
                              <GlassInput
                                  {...field}
                                  placeholder="Ex: Vermelho, P, M, G..."
                                  onBlur={() => handleBlur(index, 'valor')}
                                  maxLength={120}
                                  aria-label={`Valor do atributo ${index}`}
                              />
                            )} />
                        </div>
                        <div className="col-span-1 flex justify-center">
                            <GlassButton
                                icon={Trash2}
                                size="sm"
                                variant="danger"
                                onClick={() => remove(index)}
                                aria-label={`Remover atributo ${index}`}
                            />
                        </div>
                    </motion.div>
                ))}
            </AnimatePresence>

            {fields.length === 0 && (
                <p className="text-center text-gray-500 py-4">Nenhum atributo adicionado.</p>
            )}
        </div>

        <div className="mt-6">
            <GlassButton icon={Plus} onClick={handleAddAtributo}>
                Adicionar Atributo
            </GlassButton>
        </div>
      </section>
    </div>
  );
};
