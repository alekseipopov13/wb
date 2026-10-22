import { useLayoutEffect, useRef, useState, type ReactNode } from 'react';
import { motion, useReducedMotion } from 'motion/react';
import { AmountDigits } from './AmountDigits';

// Measure only the final value. Resize concurrently with the counter so the
// group moves smoothly once, independently of intermediate digit widths.
export function AnimatedAmountWidth({ value, children, fixedDigits = false }: { value: string; children: ReactNode; fixedDigits?: boolean }) {
  const measure = useRef<HTMLSpanElement>(null);
  const [width, setWidth] = useState<number>();
  const reduced = useReducedMotion();
  useLayoutEffect(() => {
    const element = measure.current!;
    const update = () => setWidth(element.getBoundingClientRect().width);
    update();
    const observer = new ResizeObserver(update);
    observer.observe(element);
    return () => observer.disconnect();
  }, [value, width === undefined]);
  const digits = value.replace(/\s*₽$/, '');
  return <motion.span key={width === undefined ? 'measuring' : 'ready'} className="animated-amount-width" initial={false}
    animate={{ width }} transition={{ duration: reduced ? 0 : fixedDigits ? .4 : .5, ease: fixedDigits ? [.22, 1, .36, 1] : [.625, .05, 0, 1] }}>
    <span ref={measure} className={`amount-width-measure${fixedDigits ? ' fixed-amount-measure' : ''}`} aria-hidden="true" data-value={fixedDigits ? undefined : value}>{fixedDigits && <><AmountDigits value={digits} measurement/><span className="amount-currency" data-glyph="₽"/></>}</span>
    {children}
  </motion.span>;
}
