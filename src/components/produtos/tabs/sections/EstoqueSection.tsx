import React from 'react';
import { Control, Controller, useWatch } from 'react-hook-form';
import { motion, AnimatePresence } from 'framer-motion';
import { InputWrapper } from '../../../ui/InputWrapper';
import { GlassInput } from '../../../ui/GlassInput';
import { ProdutoFormData } from '../../../../schemas/produtoSchema';

interface EstoqueSectionProps {
  control: Control<ProdutoFormData>;
  isEditing: boolean;
}

const AdornmentInput: React.FC<{ children: React.ReactNode, unit: string }> = ({ children, unit }) => (
    <div className="relative">
        {children}
        <div className="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
            <span className="text-gray-500 text-sm">{unit}</span>
        </div>
    </div>
);

export const EstoqueSection: React.FC<EstoqueSectionProps> = ({ control, isEditing }) => {
  const controlarEstoque = useWatch({ control, name: 'controlarEstoque' });

  return (
    <section>
      <h3 className="text-lg font-semibold text-gray-800 mb-4 border-b border-white/30 pb-2">Estoque</h3>
      <div className="space-y-4">
        <Controller
          name="controlarEstoque"
          control={control}
          render={({ field }) => (
            <InputWrapper label="Controlar estoque deste produto?">
              <label className="flex items-center gap-2 cursor-pointer">
                <input type="checkbox" className="form-checkbox" checked={field.value} onChange={e => field.onChange(e.target.checked)} />
                <span className="text-sm text-gray-700">Sim, gerenciar o estoque</span>
              </label>
            </InputWrapper>
          )}
        />
        <AnimatePresence>
          {controlarEstoque && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
              className="overflow-hidden"
            >
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6 pt-4">
                {!isEditing && (
                  <Controller name="estoqueInicial" control={control} render={({ field }) => (
                    <InputWrapper label="Estoque inicial" helpText="Primeiro saldo do produto.">
                      <GlassInput type="text" inputMode="decimal" placeholder="0" {...field} />
                    </InputWrapper>
                  )} />
                )}
                <Controller name="estoqueMinimo" control={control} render={({ field }) => (
                  <InputWrapper label="Estoque mínimo" helpText="Alerta de reposição.">
                    <GlassInput type="text" inputMode="decimal" placeholder="0" {...field} />
                  </InputWrapper>
                )} />
                <Controller name="estoqueMaximo" control={control} render={({ field }) => (
                  <InputWrapper label="Estoque máximo" helpText="Limite de compra/armazenamento.">
                    <GlassInput type="text" inputMode="decimal" placeholder="0" {...field} />
                  </InputWrapper>
                )} />
                <Controller name="localizacao" control={control} render={({ field }) => (
                  <InputWrapper label="Localização no estoque" helpText="Ex: Prateleira A, Corredor 3.">
                    <GlassInput {...field} />
                  </InputWrapper>
                )} />
                <Controller name="diasPreparacao" control={control} render={({ field }) => (
                  <InputWrapper label="Dias para preparação">
                     <AdornmentInput unit="dias"><GlassInput type="text" inputMode="decimal" placeholder="0" {...field} /></AdornmentInput>
                  </InputWrapper>
                )} />
                <Controller
                  name="controlarLotes"
                  control={control}
                  render={({ field }) => (
                    <InputWrapper label="Rastreabilidade">
                        <label className="flex items-center gap-2 cursor-pointer mt-2">
                            <input type="checkbox" className="form-checkbox" checked={field.value} onChange={e => field.onChange(e.target.checked)} />
                            <span className="text-sm text-gray-700">Controlar por lotes</span>
                        </label>
                    </InputWrapper>
                  )}
                />
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </section>
  );
};
