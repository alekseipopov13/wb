import { useLayoutEffect, useRef, useState, type ReactNode } from 'react';
import { motion, useReducedMotion } from 'motion/react';

// Measure the target amount, not each intermediate counter value. Animating
// this flex item's width moves the adjacent eye continuously in normal layout.
export function AnimatedAmountWidth({ value, children }: { value: string; children: ReactNode }) {
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
  }, [value]);
  return <motion.span className="animated-amount-width" initial={false}
    animate={{ width }} transition={{ duration: reduced ? 0 : .5, ease: [.625, .05, 0, 1] }}>
    <span ref={measure} className="amount-width-measure" aria-hidden="true" data-value={value}/>
    {children}
  </motion.span>;
}
