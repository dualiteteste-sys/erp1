import React from 'react';
import { TipoEmbalagemProduto } from '../../types';
import { motion, AnimatePresence } from 'framer-motion';

interface EmbalagemIlustracaoProps {
  tipo?: TipoEmbalagemProduto | null;
}

const motionProps = {
  initial: { opacity: 0, scale: 0.8 },
  animate: { opacity: 1, scale: 1 },
  exit: { opacity: 0, scale: 0.8 },
  transition: { duration: 0.3, ease: 'backOut' },
};

const CaixaShoeboxIlustracao: React.FC = () => (
  <motion.div {...motionProps} className="relative w-48 h-40">
    <svg viewBox="0 0 120 80" className="w-full h-full text-gray-300">
      {/* Top face (more rectangular) */}
      <path d="M10 25 L60 10 L110 25 L60 40 Z" fill="rgba(0,0,0,0.02)" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
      {/* Left face */}
      <path d="M10 25 L10 50 L60 65 L60 40 Z" fill="rgba(0,0,0,0.04)" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
      {/* Right face */}
      <path d="M60 40 L60 65 L110 50 L110 25 Z" fill="rgba(0,0,0,0.06)" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
    </svg>
    <span className="absolute text-xs font-mono" style={{ top: '40%', left: '-5px' }}>A</span>
    <span className="absolute text-xs font-mono" style={{ bottom: '20px', left: '25%' }}>L</span>
    <span className="absolute text-xs font-mono" style={{ bottom: '30px', right: '25%' }}>C</span>
  </motion.div>
);

const CilindroIlustracao: React.FC = () => (
  <motion.div {...motionProps} className="relative w-48 h-40 flex items-center justify-center">
    <svg viewBox="0 0 120 60" className="w-full h-auto text-gray-300">
      <ellipse cx="30" cy="30" rx="20" ry="20" fill="rgba(0,0,0,0.02)" stroke="currentColor" strokeWidth="1.5" />
      <ellipse cx="90" cy="30" rx="20" ry="20" fill="rgba(0,0,0,0.04)" stroke="currentColor" strokeWidth="1.5" />
      <path d="M30 10 L90 10" stroke="currentColor" strokeWidth="1.5" />
      <path d="M30 50 L90 50" stroke="currentColor" strokeWidth="1.5" />
      <path d="M30 30 L90 30" stroke="currentColor" strokeWidth="1" strokeDasharray="2,2" />
      <path d="M90 20 L90 40" stroke="currentColor" strokeWidth="1" strokeDasharray="2,2" />
    </svg>
    <span className="absolute text-xs font-mono" style={{ bottom: '5px', left: '48%' }}>C</span>
    <span className="absolute text-xs font-mono" style={{ top: '45%', right: '5px' }}>D</span>
  </motion.div>
);

const EnvelopeIlustracao: React.FC = () => (
  <motion.div {...motionProps} className="relative w-48 h-40 flex items-center justify-center">
    <svg viewBox="0 0 120 80" className="w-full h-auto text-gray-300">
      <path d="M10 10 L110 10 L110 70 L10 70 Z" fill="rgba(0,0,0,0.02)" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
      <path d="M10 10 L60 40 L110 10" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
    </svg>
    <span className="absolute text-xs font-mono" style={{ top: '45%', left: '-5px' }}>L</span>
    <span className="absolute text-xs font-mono" style={{ bottom: '0px', left: '48%' }}>C</span>
  </motion.div>
);

const FardoIlustracao3D: React.FC = () => (
    <motion.div {...motionProps} className="relative w-48 h-40">
        <svg viewBox="0 0 120 100" className="w-full h-full text-gray-300">
            {/* Box shape */}
            <path d="M10 30 L60 10 L110 30 L60 50 Z" fill="rgba(0,0,0,0.02)" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
            <path d="M10 30 L10 70 L60 90 L60 50 Z" fill="rgba(0,0,0,0.04)" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
            <path d="M60 50 L60 90 L110 70 L110 30 Z" fill="rgba(0,0,0,0.06)" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
            {/* Straps */}
            <path d="M20 28 L20 68" stroke="currentColor" strokeWidth="1" />
            <path d="M40 24 L40 64" stroke="currentColor" strokeWidth="1" />
            <path d="M80 24 L80 64" stroke="currentColor" strokeWidth="1" />
            <path d="M100 28 L100 68" stroke="currentColor" strokeWidth="1" />
        </svg>
        <span className="absolute text-xs font-mono" style={{ top: '45%', left: '-5px' }}>A</span>
        <span className="absolute text-xs font-mono" style={{ bottom: '20px', left: '25%' }}>L</span>
        <span className="absolute text-xs font-mono" style={{ bottom: '20px', right: '25%' }}>C</span>
    </motion.div>
);


export const EmbalagemIlustracao: React.FC<EmbalagemIlustracaoProps> = ({ tipo }) => {
  const renderIlustracao = () => {
    switch (tipo) {
      case TipoEmbalagemProduto.ROLO_CILINDRO:
        return <CilindroIlustracao key="cilindro" />;
      case TipoEmbalagemProduto.ENVELOPE:
        return <EnvelopeIlustracao key="envelope" />;
      case TipoEmbalagemProduto.FARDO:
        return <FardoIlustracao3D key="fardo" />;
      case TipoEmbalagemProduto.CAIXA:
      default:
        return <CaixaShoeboxIlustracao key="caixa-pacote" />;
    }
  };

  return (
    <AnimatePresence mode="wait">
      {renderIlustracao()}
    </AnimatePresence>
  );
};
