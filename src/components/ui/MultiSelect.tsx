import React, { useState, useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, ChevronDown } from 'lucide-react';

interface MultiSelectProps {
  options: string[];
  value: string[];
  onChange: (selected: string[]) => void;
  placeholder?: string;
}

export const MultiSelect: React.FC<MultiSelectProps> = ({ options, value, onChange, placeholder = "Selecione..." }) => {
  const [isOpen, setIsOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleToggle = (option: string) => {
    const newValue = value.includes(option)
      ? value.filter(item => item !== option)
      : [...value, option];
    onChange(newValue);
  };

  const handleRemove = (option: string) => {
    onChange(value.filter(item => item !== option));
  };

  return (
    <div className="relative w-full" ref={containerRef}>
      <div className="glass-input flex items-center justify-between cursor-pointer" onClick={() => setIsOpen(!isOpen)}>
        <span className={value.length > 0 ? "text-gray-800" : "text-gray-500"}>
          {value.length > 0 ? `${value.length} selecionado(s)` : placeholder}
        </span>
        <ChevronDown size={20} className={`text-gray-500 transition-transform ${isOpen ? 'rotate-180' : ''}`} />
      </div>

      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            className="absolute z-10 w-full mt-1 bg-glass-50 backdrop-blur-lg border border-white/20 rounded-xl shadow-lg max-h-60 overflow-y-auto p-2"
          >
            {options.map(option => (
              <label key={option} className="flex items-center gap-3 p-2 rounded-lg hover:bg-white/50 cursor-pointer">
                <input
                  type="checkbox"
                  className="form-checkbox"
                  checked={value.includes(option)}
                  onChange={() => handleToggle(option)}
                />
                <span className="text-sm text-gray-800">{option}</span>
              </label>
            ))}
          </motion.div>
        )}
      </AnimatePresence>

      {value.length > 0 && (
        <div className="flex flex-wrap gap-2 mt-2">
          {value.map(item => (
            <div key={item} className="flex items-center gap-1 bg-blue-100 text-blue-800 text-xs font-medium px-2 py-1 rounded-full">
              <span>{item}</span>
              <button type="button" onClick={() => handleRemove(item)} className="hover:text-red-600">
                <X size={14} />
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
