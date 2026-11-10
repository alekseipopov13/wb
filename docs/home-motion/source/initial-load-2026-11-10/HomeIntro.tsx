import { useEffect, useState } from 'react';
import { motion, useReducedMotion } from 'motion/react';

export type IntroPhase = 'loading' | 'loaded' | 'shrinking' | 'referral' | 'tilting' | 'ready';

/** One sequence per app mount; navigating back and changing balance mode never replay it. */
export function useHomeIntro(enabled: boolean) {
  const reduced = useReducedMotion();
  const [phase, setPhase] = useState<IntroPhase>(enabled ? 'loading' : 'ready');
  useEffect(() => {
    if (!enabled) return;
    let cancelled = false;
    const timers: number[] = [];
    const delay = (ms: number) => new Promise<void>(resolve => timers.push(window.setTimeout(resolve, ms)));
    const assets = Promise.allSettled([
      document.fonts.ready,
      ...Array.from(document.querySelectorAll<HTMLImageElement>('.home-screen img'))
        .filter(img => img.loading !== 'lazy').map(img => img.decode()),
    ]);
    void (async () => {
      // Wait for actual assets, with a bounded fallback for failed/slow requests.
      await Promise.all([delay(reduced ? 200 : 1200), Promise.race([assets, delay(3500)])]);
      if (cancelled) return;
      if (reduced) { setPhase('ready'); return; }
      setPhase('loaded');
      await delay(300);
      if (!cancelled) setPhase('shrinking');
    })();
    return () => { cancelled = true; timers.forEach(clearTimeout); };
  }, [enabled, reduced]);
  const advance = () => setPhase(current => current === 'shrinking' ? 'referral' : current === 'referral' ? 'tilting' : current === 'tilting' ? 'ready' : current);
  return { phase, advance };
}

const Block = ({ className = '' }: { className?: string }) => <span className={`intro-skeleton ${className}`}/>;

export function HomeSkeleton() {
  const reduced = useReducedMotion();
  return <motion.div className="home-skeleton" aria-hidden="true" initial={false} exit={{ opacity: 0 }} transition={{ duration: reduced ? 0 : .22 }}>
    <div className="skeleton-header">
      <div className="skeleton-benefits"><Block/><Block/></div>
      <Block className="skeleton-segment"/>
      <Block className="skeleton-balance"/>
      <div className="skeleton-accounts">{[0, 1, 2, 3].map(i => <Block key={i}/>)}</div>
    </div>
    <div className="skeleton-actions">{[0, 1, 2, 3].map(i => <div key={i}><Block className="skeleton-action-icon"/><Block className="skeleton-action-label"/><Block className="skeleton-action-label"/></div>)}</div>
    <Block className="skeleton-banner"/>
    <Block className="skeleton-history"/>
    <div className="skeleton-products">{[0, 1, 2, 3].map(i => <Block key={i}/>)}</div>
  </motion.div>;
}
