import React from 'react';
import { Control, Controller } from 'react-hook-form';
import { InputWrapper } from '../../../ui/InputWrapper';
import { GlassInput } from '../../../ui/GlassInput';
import { ProdutoFormData } from '../../../../schemas/produtoSchema';
import { useCrud } from '../../../../hooks/useCrud';
import { Embalagem } from '../../../../types';

interface DimensoesPesoSectionProps {
  control: Control<ProdutoFormData>;
}

const AdornmentInput: React.FC<{ children: React.ReactNode, unit: string }> = ({ children, unit }) => (
    <div className="relative">
        {children}
        <div className="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
            <span className="text-gray-500 text-sm">{unit}</span>
        </div>
    </div>
);

export const DimensoesPesoSection: React.FC<DimensoesPesoSectionProps> = ({ control }) => {
  const { items: embalagens, loading: loadingEmbalagens } = useCrud<Embalagem>({
    entityName: 'embalagem',
    initialPageSize: 1000, // Fetch all for dropdown
  });

  return (
    <section>
      <h3 className="text-lg font-semibold text-gray-800 mb-4 border-b border-white/30 pb-2">Dimensões e peso</h3>
      <div className="space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              <Controller name="pesoLiquido" control={control} render={({ field }) => (
                  <InputWrapper label="Peso Líquido">
                      <AdornmentInput unit="kg"><GlassInput type="text" inputMode="decimal" placeholder="0,00" {...field} /></AdornmentInput>
                  </InputWrapper>
              )} />
              <Controller name="pesoBruto" control={control} render={({ field }) => (
                  <InputWrapper label="Peso Bruto">
                      <AdornmentInput unit="kg"><GlassInput type="text" inputMode="decimal" placeholder="0,00" {...field} /></AdornmentInput>
                  </InputWrapper>
              )} />
              <Controller name="numeroVolumes" control={control} render={({ field }) => (
                  <InputWrapper label="Nº de volumes"><GlassInput type="text" inputMode="decimal" {...field} /></InputWrapper>
              )} />
              <Controller
                name="embalagemId"
                control={control}
                render={({ field }) => (
                  <InputWrapper label="Embalagem Padrão">
                    <select className="glass-input" {...field} value={field.value || ''} disabled={loadingEmbalagens}>
                      <option value="">{loadingEmbalagens ? 'Carregando...' : 'Nenhuma'}</option>
                      {embalagens.map(emb => (
                        <option key={emb.id} value={emb.id}>{emb.descricao}</option>
                      ))}
                    </select>
                  </InputWrapper>
                )}
              />
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
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
            <Controller name="diametro" control={control} render={({ field }) => (
              <InputWrapper label="Diâmetro">
                <AdornmentInput unit="cm"><GlassInput type="text" inputMode="decimal" placeholder="0,00" {...field} /></AdornmentInput>
              </InputWrapper>
            )} />
          </div>
      </div>
    </section>
  );
};
