import React, { forwardRef } from 'react';
import { IMaskInput } from 'react-imask';

interface CurrencyInputProps {
  value: string | number | null | undefined;
  onAccept: (value: string, mask: any) => void;
  placeholder?: string;
  disabled?: boolean;
  className?: string;
}

export const CurrencyInput = forwardRef<HTMLInputElement, CurrencyInputProps>(({ value, onAccept, className, ...props }, ref) => {
  const handleFocus = (event: React.FocusEvent<HTMLInputElement>) => {
    event.target.select();
  };

  // Lógica robusta para lidar com o valor.
  // Converte null, undefined ou valores não numéricos para '0'.
  // Mantém strings numéricas e números como estão.
  // Isso evita o bug que resetava o input durante a digitação.
  const stringValue = (value === null || value === undefined || (typeof value === 'number' && isNaN(value)))
    ? '0'
    : String(value);

  return (
    <div className="relative">
      <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500">R$</span>
      <IMaskInput
        mask={Number}
        radix=","
        thousandsSeparator="."
        scale={2}
        padFractionalZeros
        normalizeZeros
        value={stringValue}
        onAccept={onAccept}
        className={`${className || 'glass-input'} text-left pl-10`}
        placeholder="0,00"
        onFocus={handleFocus}
        inputRef={ref as React.Ref<HTMLInputElement>}
        {...props}
      />
    </div>
  );
});

CurrencyInput.displayName = 'CurrencyInput';
