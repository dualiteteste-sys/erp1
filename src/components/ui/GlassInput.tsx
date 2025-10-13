import React, { forwardRef } from 'react';

interface GlassInputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  icon?: React.ReactNode;
}

export const GlassInput = forwardRef<HTMLInputElement, GlassInputProps>(({
  label,
  icon,
  className = '',
  placeholder,
  ...props
}, ref) => {
  
  const inputProps = { ...props };

  // Garante que o input seja sempre controlado se 'value' estiver presente,
  // evitando o warning do React.
  if ('value' in inputProps && (inputProps.value === null || inputProps.value === undefined)) {
    inputProps.value = '';
  }

  return (
    <div className={`relative w-full ${className}`}>
      {label && (
         <label className="text-sm text-gray-600 mb-1 block">{label}</label>
      )}
      <div className="relative">
        {icon && (
          <div className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400">
            {icon}
          </div>
        )}
        <input
          ref={ref}
          // Adiciona um placeholder (pode ser um espaço) se nenhum for fornecido.
          // Isso é crucial para o seletor CSS `:not(:placeholder-shown)` funcionar corretamente.
          placeholder={placeholder ?? ' '}
          className={`glass-input ${icon ? 'pl-10' : ''}`}
          {...inputProps}
        />
      </div>
    </div>
  );
});

GlassInput.displayName = 'GlassInput';
