import React from 'react';
import { Control, Controller } from 'react-hook-form';
import { InputWrapper } from '../../ui/InputWrapper';
import { GlassInput } from '../../ui/GlassInput';
import { ProdutoFormData } from '../../../schemas/produtoSchema';

interface DadosComplementaresTabProps {
  control: Control<ProdutoFormData>;
}

export const DadosComplementaresTab: React.FC<DadosComplementaresTabProps> = ({ control }) => {
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Controller name="marca" control={control} render={({ field }) => (
          <InputWrapper label="Marca">
            <GlassInput {...field} />
          </InputWrapper>
        )} />
        <Controller name="modelo" control={control} render={({ field }) => (
          <InputWrapper label="Modelo">
            <GlassInput {...field} />
          </InputWrapper>
        )} />
      </div>

      <Controller name="descricaoCurta" control={control} render={({ field }) => (
        <InputWrapper label="Descrição curta" helpText="Ideal para listagens e resumos.">
          <textarea {...field} className="glass-input h-24 resize-y" />
        </InputWrapper>
      )} />

      <Controller name="descricaoComplementar" control={control} render={({ field }) => (
        <InputWrapper label="Descrição complementar" helpText="Use este espaço para detalhes técnicos, benefícios e outras informações relevantes.">
          <textarea {...field} className="glass-input h-48 resize-y" />
        </InputWrapper>
      )} />

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Controller name="disponibilidade" control={control} render={({ field }) => (
          <InputWrapper label="Disponibilidade" helpText="Ex: Imediata, 7 dias úteis.">
            <GlassInput {...field} />
          </InputWrapper>
        )} />
        <Controller name="garantia" control={control} render={({ field }) => (
          <InputWrapper label="Garantia" helpText="Ex: 12 meses, 3 anos.">
            <GlassInput {...field} />
          </InputWrapper>
        )} />
      </div>

      <Controller name="videoUrl" control={control} render={({ field, fieldState }) => (
        <InputWrapper label="Link do vídeo do produto" error={fieldState.error?.message}>
          <GlassInput {...field} placeholder="https://youtube.com/watch?v=..." />
        </InputWrapper>
      )} />

      <hr className="border-white/20" />

      <h3 className="text-lg font-semibold text-gray-800">SEO (Otimização para Buscadores)</h3>
      <div className="space-y-6">
        <Controller name="slug" control={control} render={({ field }) => (
          <InputWrapper label="URL amigável (slug)" helpText="Ex: nome-do-produto-modelo. Deixe em branco para gerar automaticamente.">
            <GlassInput {...field} />
          </InputWrapper>
        )} />
        <Controller name="tituloSeo" control={control} render={({ field }) => (
          <InputWrapper label="Título para SEO" helpText="O título que aparecerá nos buscadores. Máx 60 caracteres.">
            <GlassInput {...field} maxLength={60} />
          </InputWrapper>
        )} />
        <Controller name="metaDescricaoSeo" control={control} render={({ field }) => (
          <InputWrapper label="Meta Descrição para SEO" helpText="A descrição que aparecerá nos buscadores. Máx 160 caracteres.">
            <textarea {...field} className="glass-input h-24 resize-y" maxLength={160} />
          </InputWrapper>
        )} />
      </div>
    </div>
  );
};
