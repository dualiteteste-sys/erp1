import React from 'react';
import { Control, Controller } from 'react-hook-form';
import { PedidoVendaFormData } from '../../../schemas/pedidoVendaSchema';
import { CurrencyInput } from '../../ui/CurrencyInput';

interface TotaisSectionProps {
  control: Control<PedidoVendaFormData>;
}

export const TotaisSection: React.FC<TotaisSectionProps> = ({ control }) => {
  return (
    <div className="mt-8 pt-6 border-t border-white/20 flex justify-end">
      <div className="w-full max-w-sm space-y-4">
        <div className="flex justify-between items-center">
          <span className="text-gray-600">Subtotal</span>
          <Controller
            name="valorTotal"
            control={control}
            render={({ field }) => (
                <span className="font-medium text-gray-800">
                    {new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(field.value || 0)}
                </span>
            )}
          />
        </div>
        <div className="flex justify-between items-center">
          <span className="text-gray-600">Desconto</span>
          <div className="w-32">
            <Controller
              name="desconto"
              control={control}
              render={({ field }) => (
                <CurrencyInput value={field.value} onAccept={(v) => field.onChange(v)} />
              )}
            />
          </div>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-gray-600">Frete</span>
           <div className="w-32">
            <Controller
              name="valorFrete"
              control={control}
              render={({ field }) => (
                <CurrencyInput value={field.value} onAccept={(v) => field.onChange(v)} />
              )}
            />
          </div>
        </div>
        <div className="flex justify-between items-center text-lg font-bold text-gray-900 border-t border-white/30 pt-4">
          <span>Total</span>
          <Controller
            name="valorTotal"
            control={control}
            render={({ field: { value: total } }) => {
                const desconto = control._getWatch('desconto') ?? 0;
                const frete = control._getWatch('valorFrete') ?? 0;
                const finalTotal = (total ?? 0) - desconto + frete;
                return (
                    <span>
                        {new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(finalTotal)}
                    </span>
                );
            }}
          />
        </div>
      </div>
    </div>
  );
};
