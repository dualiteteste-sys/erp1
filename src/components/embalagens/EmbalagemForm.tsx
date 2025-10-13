import React from 'react';
import { useForm, Controller, useWatch } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { GenericForm } from '../ui/GenericForm';
import { GlassInput } from '../ui/GlassInput';
import { InputWrapper } from '../ui/InputWrapper';
import { Embalagem, TipoEmbalagemProduto } from '../../types';
import { EmbalagemFormData, embalagemSchema } from '../../schemas/embalagemSchema';
import { EmbalagemIlustracao } from './EmbalagemIlustracao';
import { motion, AnimatePresence } from 'framer-motion';

// Sub-componente para inputs com unidades, corrigindo o problema de sobreposição.
const AdornmentInput: React.FC<{ children: React.ReactNode, unit: string }> = ({ children, unit }) => (
    <div className="relative">
        {children}
        <div className="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
            <span className="text-gray-500 text-sm">{unit}</span>
        </div>
    </div>
);

interface EmbalagemFormProps {
  embalagem?: Partial<Embalagem>;
  onSave: (data: EmbalagemFormData) => void;
  onCancel: () => void;
  loading: boolean;
}

export const EmbalagemForm: React.FC<EmbalagemFormProps> = ({ embalagem, onSave, onCancel, loading }) => {
  const form = useForm<EmbalagemFormData>({
    resolver: zodResolver(embalagemSchema),
    defaultValues: {
      descricao: embalagem?.descricao || '',
      tipo: embalagem?.tipo || TipoEmbalagemProduto.CAIXA,
      peso: embalagem?.peso || null,
      largura: embalagem?.largura || null,
      altura: embalagem?.altura || null,
      comprimento: embalagem?.comprimento || null,
      diametro: embalagem?.diametro || null,
    },
  });

  const { control, handleSubmit, register, formState: { errors } } = form;
  const tipoEmbalagem = useWatch({ control, name: 'tipo' });

  const renderDimensionFields = () => {
    const motionProps = {
      initial: { opacity: 0, y: -5 },
      animate: { opacity: 1, y: 0 },
      exit: { opacity: 0, y: 5 },
      transition: { duration: 0.2 },
    };

    switch (tipoEmbalagem) {
      case TipoEmbalagemProduto.ROLO_CILINDRO:
        return (
          <motion.div key="cilindro" {...motionProps} className="contents">
            <Controller name="comprimento" control={control} render={({ field }) => (
              <InputWrapper label="Comprimento">
                <AdornmentInput unit="cm"><GlassInput type="text" inputMode="decimal" placeholder="0,00" {...field} /></AdornmentInput>
              </InputWrapper>
            )} />
            <Controller name="diametro" control={control} render={({ field }) => (
              <InputWrapper label="Diâmetro">
                <AdornmentInput unit="cm"><GlassInput type="text" inputMode="decimal" placeholder="0,00" {...field} /></AdornmentInput>
              </InputWrapper>
            )} />
          </motion.div>
        );
      case TipoEmbalagemProduto.ENVELOPE:
        return (
          <motion.div key="envelope" {...motionProps} className="contents">
            <Controller name="largura" control={control} render={({ field }) => (
              <InputWrapper label="Largura">
                <AdornmentInput unit="cm"><GlassInput type="text" inputMode="decimal" placeholder="0,00" {...field} /></AdornmentInput>
              </InputWrapper>
            )} />
            <Controller name="comprimento" control={control} render={({ field }) => (
              <InputWrapper label="Comprimento">
                <AdornmentInput unit="cm"><GlassInput type="text" inputMode="decimal" placeholder="0,00" {...field} /></AdornmentInput>
              </InputWrapper>
            )} />
          </motion.div>
        );
      default: // Caixa ou Fardo
        return (
          <motion.div key="caixa" {...motionProps} className="contents">
            <Controller name="largura" control={control} render={({ field }) => (
              <InputWrapper label="Largura">
                <AdornmentInput unit="cm"><GlassInput type="text" inputMode="decimal" placeholder="0,00" {...field} /></AdornmentInput>
              </InputWrapper>
            )} />
            <Controller name="altura" control={control} render={({ field }) => (
              <InputWrapper label="Altura">
                <AdornmentInput unit="cm"><GlassInput type="text" inputMode="decimal" placeholder="0,00" {...field} /></AdornmentInput>
              </InputWrapper>
            )} />
            <Controller name="comprimento" control={control} render={({ field }) => (
              <InputWrapper label="Comprimento">
                <AdornmentInput unit="cm"><GlassInput type="text" inputMode="decimal" placeholder="0,00" {...field} /></AdornmentInput>
              </InputWrapper>
            )} />
          </motion.div>
        );
    }
  };

  return (
    <GenericForm
      title={embalagem?.id ? 'Editar Embalagem' : 'Nova Embalagem'}
      onSave={handleSubmit(onSave)}
      onCancel={onCancel}
      loading={loading}
      size="max-w-4xl"
    >
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className="lg:col-span-2 space-y-6">
          <InputWrapper label="Descrição *" error={errors.descricao?.message}>
            <GlassInput {...register('descricao')} />
          </InputWrapper>
          
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
            <Controller name="tipo" control={control} render={({ field }) => (
              <InputWrapper label="Tipo da embalagem">
                <select className="glass-input" {...field}>
                  {Object.values(TipoEmbalagemProduto).map(t => <option key={t} value={t}>{t}</option>)}
                </select>
              </InputWrapper>
            )} />
            <Controller name="peso" control={control} render={({ field }) => (
              <InputWrapper label="Peso">
                <AdornmentInput unit="kg"><GlassInput type="text" inputMode="decimal" placeholder="0,00" {...field} /></AdornmentInput>
              </InputWrapper>
            )} />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
            <AnimatePresence mode="wait">
              {renderDimensionFields()}
            </AnimatePresence>
          </div>
        </div>
        <div className="flex items-center justify-center lg:pt-8">
          <EmbalagemIlustracao tipo={tipoEmbalagem} />
        </div>
      </div>
    </GenericForm>
  );
};
