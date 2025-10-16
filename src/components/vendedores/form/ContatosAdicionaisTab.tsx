import React from 'react';
import { Control, useFieldArray, Controller } from 'react-hook-form';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus, Trash2 } from 'lucide-react';
import { GlassInput } from '../../ui/GlassInput';
import { GlassButton } from '../../ui/GlassButton';
import { InputWrapper } from '../../ui/InputWrapper';
import { VendedorFormData } from '../../../schemas/vendedorSchema';
import { IMaskInput } from 'react-imask';

interface ContatosAdicionaisTabProps {
  control: Control<VendedorFormData>;
}

export const ContatosAdicionaisTab: React.FC<ContatosAdicionaisTabProps> = ({ control }) => {
  const { fields, append, remove } = useFieldArray({
    control,
    name: "contatos",
  });

  const handleAddContato = () => {
    append({ nome: '', setor: '', email: '', telefone: '', ramal: '' });
  };

  return (
    <section>
      <div className="flex justify-between items-center mb-6">
        <div>
            <h3 className="text-lg font-semibold text-gray-800">Contatos Adicionais</h3>
            <p className="text-sm text-gray-500">Gerencie os contatos secundários deste vendedor.</p>
        </div>
        <GlassButton icon={Plus} onClick={handleAddContato}>Adicionar Contato</GlassButton>
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
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 items-start">
                <Controller name={`contatos.${index}.nome`} control={control} render={({ field }) => (
                    <InputWrapper label="Nome *"><GlassInput {...field} /></InputWrapper>
                )} />
                <Controller name={`contatos.${index}.setor`} control={control} render={({ field }) => (
                    <InputWrapper label="Setor"><GlassInput {...field} /></InputWrapper>
                )} />
                <Controller name={`contatos.${index}.email`} control={control} render={({ field }) => (
                    <InputWrapper label="E-mail"><GlassInput type="email" {...field} /></InputWrapper>
                )} />
                <div className="flex items-end gap-2">
                    <Controller name={`contatos.${index}.telefone`} control={control} render={({ field }) => (
                        <InputWrapper label="Telefone" className="flex-grow">
                            <IMaskInput mask="(00) 0000[0]-0000" className="glass-input" {...field} value={field.value || ''} />
                        </InputWrapper>
                    )} />
                    <GlassButton icon={Trash2} variant="danger" size="sm" onClick={() => remove(index)} />
                </div>
              </div>
            </motion.div>
          ))}
        </AnimatePresence>

        {fields.length === 0 && (
          <div className="text-center py-10 text-gray-500">
            <p>Nenhum contato adicional cadastrado.</p>
            <p className="text-sm">Clique em "Adicionar Contato" para começar.</p>
          </div>
        )}
      </div>
    </section>
  );
};
