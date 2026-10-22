import { useEffect, useRef, useState } from 'react';
import { animate, useReducedMotion } from 'motion/react';
import { AmountDigits } from './AmountDigits';

const formatter = new Intl.NumberFormat('ru-RU');

// Like the QR bonus badge's Animatable RollingIntegerText: interpolate the
// numeric value and round each frame, rather than moving individual glyphs.
export function RollingAmount({ value }: { value: string }) {
  const target = Number(value.replace(/[^\d-]/g, ''));
  const reduced = useReducedMotion();
  const current = useRef(target);
  const [displayed, setDisplayed] = useState(target);

  useEffect(() => {
    if (reduced) {
      current.current = target;
      setDisplayed(target);
      return;
    }
    const animation = animate(current.current, target, {
      duration: .4,
      ease: [.22, 1, .36, 1],
      onUpdate: next => {
        current.current = next;
        setDisplayed(Math.round(next));
      },
      onComplete: () => {
        current.current = target;
        setDisplayed(target);
      },
    });
    // A rapid mode change continues from the visible value, without resetting.
    return () => animation.stop();
  }, [target, reduced]);

  const amount = reduced ? target : displayed;
  const text = amount === target ? value : value.replace(/-?\d[\d\s\u00a0\u202f]*\d|-?\d/, formatter.format(amount).replace(/\u00a0/g, ' '));
  const currency = text.match(/\s*₽$/)?.[0] ?? '';
  return <span className="rolling-amount"><span className="amount-digit-viewport"><AmountDigits value={currency ? text.slice(0, -currency.length) : text} minimumDigits={6}/></span><span className="amount-currency"><span className="currency-text-space">{currency ? ' ' : ''}</span>{currency.trim()}</span></span>;
}
