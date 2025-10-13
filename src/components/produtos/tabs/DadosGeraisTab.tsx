import React from 'react';
import { Control, UseFormWatch, UseFormSetValue, Controller } from 'react-hook-form';
import { IMaskInput } from 'react-imask';
import { TipoProduto, OrigemProduto, SituacaoProduto } from '../../../types';
import { CurrencyInput } from '../../ui/CurrencyInput';
import { InputWrapper } from '../../ui/InputWrapper';
import { ProdutoFormData } from '../../../schemas/produtoSchema';
import { DimensoesPesoSection } from './sections/DimensoesPesoSection';
import { EstoqueSection } from './sections/EstoqueSection';
import { useNcm } from '../../../hooks/useNcm';
import { motion, AnimatePresence } from 'framer-motion';
import { Loader2, Sparkles } from 'lucide-react';
import { GlassButton } from '../../ui/GlassButton';
import { GlassInput } from '../../ui/GlassInput';

interface DadosGeraisTabProps {
  control: Control<ProdutoFormData>;
  watch: UseFormWatch<ProdutoFormData>;
  setValue: UseFormSetValue<ProdutoFormData>;
  onSuggestNcm: () => void;
  isEditing: boolean;
}

export const DadosGeraisTab: React.FC<DadosGeraisTabProps> = ({ control, watch, setValue, onSuggestNcm, isEditing }) => {
  const ncmCode = watch('ncm');
  const { description: ncmDescription, loading: ncmLoading, fetchNcmDescription, clearDescription } = useNcm();
  const [showNcmTooltip, setShowNcmTooltip] = React.useState(false);

  const handleNcmHover = () => {
    if (ncmCode) {
      setShowNcmTooltip(true);
      fetchNcmDescription(ncmCode);
    }
  };

  const handleNcmLeave = () => {
    setShowNcmTooltip(false);
    clearDescription();
  };

  return (
    <div className="space-y-8">
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <Controller name="tipo" control={control} render={({ field }) => (
          <InputWrapper label="Tipo do Produto">
            <select className="glass-input" {...field}>
              {Object.values(TipoProduto).map(t => <option key={t} value={t}>{t}</option>)}
            </select>
          </InputWrapper>
        )} />
         <Controller name="situacao" control={control} render={({ field }) => (
          <InputWrapper label="Situação">
            <select className="glass-input" {...field}>
              {Object.values(SituacaoProduto).map(s => <option key={s} value={s}>{s}</option>)}
            </select>
          </InputWrapper>
        )} />
      </div>
      
      <hr className="border-white/20" />

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Controller name="nome" control={control} render={({ field, fieldState }) => (
          <InputWrapper label="Nome do produto *" helpText="Necessário para emissão de Nota Fiscal" error={fieldState.error?.message}>
            <GlassInput {...field} maxLength={120} placeholder="Descrição completa do produto" />
          </InputWrapper>
        )} />
        <Controller name="codigoBarras" control={control} render={({ field }) => (
          <InputWrapper label="Código de barras (GTIN)" helpText="Global Trade Item Number">
            <GlassInput {...field} placeholder="Código de barras" />
          </InputWrapper>
        )} />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Controller name="origem" control={control} render={({ field }) => (
          <InputWrapper label="Origem do produto *" helpText="Conforme tabela ICMS">
            <select className="glass-input" {...field}>
              {Object.values(OrigemProduto).map(o => <option key={o} value={o}>{o}</option>)}
            </select>
          </InputWrapper>
        )} />
        <Controller name="unidade" control={control} render={({ field, fieldState }) => (
          <InputWrapper label="Unidade de medida *" helpText="Ex: Pç, Kg, Un, etc." error={fieldState.error?.message}>
            <GlassInput {...field} maxLength={10} placeholder="Un" />
          </InputWrapper>
        )} />
        
        <div className="relative">
          <Controller name="ncm" control={control} render={({ field }) => (
            <InputWrapper label="NCM">
              <div onMouseEnter={handleNcmHover} onMouseLeave={handleNcmLeave} className="flex items-center gap-2">
                <IMaskInput mask="0000.00.00" value={field.value || ''} onAccept={(v) => field.onChange(v)} className="glass-input flex-1" placeholder="Ex: 1001.10.10" />
                <GlassButton type="button" icon={Sparkles} onClick={onSuggestNcm}>Sugerir</GlassButton>
              </div>
            </InputWrapper>
          )} />
          <AnimatePresence>
          {showNcmTooltip && (
            <motion.div 
              initial={{ opacity: 0, y: 5 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 5 }}
              className="absolute bottom-full left-0 mb-2 w-full p-2 bg-gray-800 text-white text-xs rounded-md shadow-lg z-10"
            >
              {ncmLoading ? <Loader2 size={14} className="animate-spin" /> : ncmDescription}
            </motion.div>
          )}
          </AnimatePresence>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Controller name="codigo" control={control} render={({ field }) => (
          <InputWrapper label="Código (SKU)" helpText="Opcional">
            <GlassInput {...field} maxLength={50} placeholder="Referência interna" />
          </InputWrapper>
        )} />
        <Controller name="cest" control={control} render={({ field }) => (
          <InputWrapper label="Código CEST" helpText="Substituição Tributária">
            <IMaskInput mask="00.000.00" value={field.value || ''} onAccept={(v) => field.onChange(v)} className="glass-input" placeholder="Ex: 01.003.00" />
          </InputWrapper>
        )} />
      </div>
      
      <hr className="border-white/20" />
      
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Controller name="precoVenda" control={control} render={({ field, fieldState }) => (
          <InputWrapper label="Preço de venda *" error={fieldState.error?.message}>
              <CurrencyInput 
                value={field.value} 
                onAccept={(value) => field.onChange(value)}
              />
          </InputWrapper>
        )} />
        <Controller name="custoMedio" control={control} render={({ field, fieldState }) => (
          <InputWrapper label="Custo médio" error={fieldState.error?.message}>
              <CurrencyInput 
                value={field.value} 
                onAccept={(value) => field.onChange(value)}
              />
          </InputWrapper>
        )} />
      </div>

      <hr className="border-white/20" />

      <DimensoesPesoSection control={control} />

      <hr className="border-white/20" />

      <EstoqueSection control={control} isEditing={isEditing} />
    </div>
  );
};
