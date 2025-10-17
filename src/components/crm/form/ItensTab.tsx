import React, { useCallback, useEffect } from 'react';
import { Control, useFieldArray, Controller, UseFormSetValue, UseFormWatch } from 'react-hook-form';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus, Trash2 } from 'lucide-react';
import { GlassButton } from '../../ui/GlassButton';
import { InputWrapper } from '../../ui/InputWrapper';
import { OportunidadeFormData } from '../../../schemas/crmSchema';
import { AutocompleteInput } from '../../ui/AutocompleteInput';
import { useService } from '../../../hooks/useService';
import { useEmpresa } from '../../../contexts/EmpresaContext';
import { CurrencyInput } from '../../ui/CurrencyInput';
import { GlassInput } from '../../ui/GlassInput';

interface ItensTabProps {
  control: Control<OportunidadeFormData>;
  setValue: UseFormSetValue<OportunidadeFormData>;
  watch: UseFormWatch<OportunidadeFormData>;
}

export const ItensTab: React.FC<ItensTabProps> = ({ control, setValue, watch }) => {
  const { fields, append, remove, update } = useFieldArray({
    control,
    name: "itens",
  });
  const { currentEmpresa } = useEmpresa();
  const produtoService = useService('produto');

  const fetchProdutos = useCallback(async (query: string) => {
    if (!currentEmpresa?.id) return [];
    const results = await produtoService.search(currentEmpresa.id, query);
    return results.map(p => ({
      value: p.id,
      label: `${p.nome} (R$ ${p.precoVenda.toLocaleString('pt-BR')})`,
      produto: p,
    }));
  }, [produtoService, currentEmpresa]);

  const handleAddItem = () => {
    append({
      descricao: '',
      quantidade: 1,
      valorUnitario: 0,
    });
  };

  const handleProductSelect = (index: number, suggestion: any) => {
    if (suggestion && suggestion.produto) {
      const { produto } = suggestion;
      update(index, {
        ...fields[index],
        produtoId: produto.id,
        descricao: produto.nome,
        valorUnitario: produto.precoVenda,
      });
    }
  };

  const itens = watch('itens');

  useEffect(() => {
    const total = (itens || []).reduce((acc, item) => {
      const quantidade = item.quantidade || 0;
      const valorUnitario = item.valorUnitario || 0;
      return acc + (quantidade * valorUnitario);
    }, 0);
    setValue('valor', total, { shouldValidate: true });
  }, [itens, setValue]);

  return (
    <section>
      <div className="flex justify-between items-center mb-6">
        <div>
          <h3 className="text-lg font-semibold text-gray-800">Itens da Oportunidade</h3>
          <p className="text-sm text-gray-500">Adicione os produtos ou serviços relacionados.</p>
        </div>
        <GlassButton icon={Plus} onClick={handleAddItem}>Adicionar Item</GlassButton>
      </div>

      <div className="space-y-4">
        <AnimatePresence>
          {fields.map((item, index) => (
            <motion.div
              key={item.id}
              layout
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, x: -20, transition: { duration: 0.2 } }}
              className="p-4 bg-glass-50 rounded-xl border border-white/20"
            >
              <div className="grid grid-cols-1 md:grid-cols-12 gap-4 items-start">
                <div className="md:col-span-5">
                  <Controller
                    name={`itens.${index}.produtoId`}
                    control={control}
                    render={({ field }) => (
                      <InputWrapper label="Produto/Serviço">
                        <AutocompleteInput
                          value={field.value || ''}
                          onValueChange={(val, suggestions) => {
                            field.onChange(val);
                            const selectedSuggestion = suggestions.find(s => s.value === val);
                            if (selectedSuggestion) {
                              handleProductSelect(index, selectedSuggestion);
                            }
                          }}
                          fetchSuggestions={fetchProdutos}
                          placeholder="Buscar produto..."
                        />
                      </InputWrapper>
                    )}
                  />
                </div>
                <div className="md:col-span-2">
                  <Controller
                    name={`itens.${index}.quantidade`}
                    control={control}
                    render={({ field }) => (
                      <InputWrapper label="Qtd.">
                        <GlassInput type="number" {...field} value={field.value || ''} />
                      </InputWrapper>
                    )}
                  />
                </div>
                <div className="md:col-span-2">
                  <Controller
                    name={`itens.${index}.valorUnitario`}
                    control={control}
                    render={({ field }) => (
                      <InputWrapper label="Vl. Unit.">
                        <CurrencyInput value={field.value} onAccept={(value) => field.onChange(value)} />
                      </InputWrapper>
                    )}
                  />
                </div>
                <div className="md:col-span-2">
                    <InputWrapper label="Vl. Total">
                        <CurrencyInput 
                            value={(watch(`itens.${index}.quantidade`) || 0) * (watch(`itens.${index}.valorUnitario`) || 0)} 
                            onAccept={() => {}}
                            disabled 
                        />
                    </InputWrapper>
                </div>
                <div className="md:col-span-1 flex items-end h-full">
                  <GlassButton icon={Trash2} variant="danger" size="sm" onClick={() => remove(index)} />
                </div>
              </div>
            </motion.div>
          ))}
        </AnimatePresence>

        {fields.length === 0 && (
          <div className="text-center py-10 text-gray-500">
            <p>Nenhum item adicionado.</p>
          </div>
        )}
      </div>
    </section>
  );
};
