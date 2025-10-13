import React from 'react';
import { Control, Controller, useFieldArray } from 'react-hook-form';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus, Trash2 } from 'lucide-react';
import { GlassInput } from '../../ui/GlassInput';
import { GlassButton } from '../../ui/GlassButton';
import { InputWrapper } from '../../ui/InputWrapper';
import { ProdutoFormData } from '../../../schemas/produtoSchema';
import { AutocompleteInput } from '../../ui/AutocompleteInput';
import { useService } from '../../../hooks/useService';
import { useEmpresa } from '../../../contexts/EmpresaContext';

interface OutrosTabProps {
  control: Control<ProdutoFormData>;
}

export const OutrosTab: React.FC<OutrosTabProps> = ({ control }) => {
  const clienteService = useService('cliente');
  const { currentEmpresa } = useEmpresa();
  
  const { fields, append, remove } = useFieldArray({
    control,
    name: "fornecedores",
  });

  const fetchFornecedores = React.useCallback(async (query: string) => {
    if (!currentEmpresa?.id) return [];
    const results = await clienteService.search(currentEmpresa.id, query, 'fornecedor');
    return results.map(f => ({ value: f.id, label: f.nomeRazaoSocial }));
  }, [clienteService, currentEmpresa]);

  return (
    <div className="space-y-8">
      <section>
        <h3 className="text-lg font-semibold text-gray-800 mb-4 border-b border-white/30 pb-2">Fornecedores</h3>
        <div className="space-y-4">
          <AnimatePresence>
            {fields.map((item, index) => (
              <motion.div
                key={item.id}
                layout
                initial={{ opacity: 0, y: -10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, x: -20, transition: { duration: 0.2 } }}
                className="grid grid-cols-12 gap-4 items-end p-4 bg-glass-50 rounded-xl border border-white/20"
              >
                <div className="col-span-12 md:col-span-6">
                  <Controller name={`fornecedores.${index}.fornecedorId`} control={control} render={({ field }) => (
                    <InputWrapper label="Fornecedor *">
                      <AutocompleteInput
                        value={field.value}
                        onValueChange={(val) => field.onChange(val)}
                        fetchSuggestions={fetchFornecedores}
                        placeholder="Buscar fornecedor..."
                      />
                    </InputWrapper>
                  )} />
                </div>
                <div className="col-span-12 md:col-span-5">
                  <Controller name={`fornecedores.${index}.codigoNoFornecedor`} control={control} render={({ field }) => (
                    <InputWrapper label="Código no Fornecedor">
                      <GlassInput {...field} />
                    </InputWrapper>
                  )} />
                </div>
                <div className="col-span-12 md:col-span-1 flex justify-end">
                  <GlassButton icon={Trash2} variant="danger" size="sm" onClick={() => remove(index)} />
                </div>
              </motion.div>
            ))}
          </AnimatePresence>
          {fields.length === 0 && (
            <p className="text-center text-gray-500 py-4">Nenhum fornecedor associado.</p>
          )}
        </div>
        <div className="mt-6">
            <GlassButton icon={Plus} onClick={() => append({ id: crypto.randomUUID(), fornecedorId: '', codigoNoFornecedor: '' })}>
                Adicionar Fornecedor
            </GlassButton>
        </div>
      </section>
      <section>
        <h3 className="text-lg font-semibold text-gray-800 mb-4 border-b border-white/30 pb-2">Observações</h3>
        <Controller name="observacoes" control={control} render={({ field }) => (
          <InputWrapper label="Observações gerais sobre o produto">
            <textarea {...field} className="glass-input h-32 resize-y" />
          </InputWrapper>
        )} />
      </section>
    </div>
  );
};
