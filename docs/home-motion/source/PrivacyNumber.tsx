import { useLayoutEffect, useRef, useState } from 'react';
import { AnimatePresence, motion, useReducedMotion } from 'motion/react';
import { SlideUpText } from './SlideUpText';
import { RollingAmount } from './RollingAmount';

// Port of PrivacyNumberText / PrivacyStrikethroughShape from Банк/Редизайн наполовину.
function randomSeed() {
  const words = crypto.getRandomValues(new Uint32Array(2));
  return (BigInt(words[0]) << 32n) | BigInt(words[1]);
}
function strikePath(seed: bigint, width: number, height: number) {
  const wrap = (n: bigint) => BigInt.asUintN(64, n);
  const unit = (index: number) => {
    let v = wrap(seed + BigInt(index) * 0x9E3779B97F4A7C15n);
    v = wrap((v ^ (v >> 30n)) * 0xBF58476D1CE4E5B9n);
    v = wrap((v ^ (v >> 27n)) * 0x94D049BB133111EBn);
    return Number((v ^ (v >> 31n)) & 0xFFFFn) / 65535;
  };
  const frequency = 1.45 + unit(0) * .9;
  const phase = unit(1) * Math.PI * 2;
  const amplitude = .24 + unit(2) * .12;
  const secondAmplitude = .04 + unit(3) * .06;
  const tilt = (unit(4) - .5) * .28;
  const baseline = .5 + (unit(5) - .5) * .12;
  const points = Array.from({ length: 10 }, (_, i) => {
    const progress = i / 9;
    const primary = Math.sin(progress * Math.PI * 2 * frequency + phase) * amplitude;
    const secondary = Math.sin(progress * Math.PI * 4.6 + phase * .63) * secondAmplitude;
    const jitter = (unit(i + 6) - .5) * .16;
    const y = Math.min(.88, Math.max(.12, baseline + primary + secondary + jitter + tilt * (progress - .5)));
    return { x: (.025 + progress * .95) * width, y: y * height };
  });
  let path = `M ${points[0].x} ${points[0].y}`;
  for (let i = 1; i < points.length; i++) {
    const prev = points[i - 1], point = points[i];
    path += ` Q ${prev.x} ${prev.y} ${(prev.x + point.x) / 2} ${(prev.y + point.y) / 2}`;
  }
  const last = points[9], previous = points[8];
  return path + ` Q ${previous.x} ${previous.y} ${last.x} ${last.y}`;
}
export function PrivacyNumber({ value, hidden, animateValue = false, rolling = false }: { value: string; hidden: boolean; animateValue?: boolean; rolling?: boolean }) {
  const ref = useRef<HTMLSpanElement>(null);
  const [size, setSize] = useState({ width: 0, height: 0 });
  const [seed] = useState(randomSeed);
  const reduced = useReducedMotion();
  useLayoutEffect(() => {
    if (!ref.current) return;
    const update = () => setSize({ width: ref.current!.offsetWidth, height: ref.current!.offsetHeight });
    update();
    const observer = new ResizeObserver(update);
    observer.observe(ref.current);
    return () => observer.disconnect();
  }, []);
  return <span ref={ref} className={`privacy-number${rolling ? ' privacy-number-rolling' : ''}`} data-hidden={hidden} role="img" aria-label={hidden ? 'Значение скрыто' : value}>
    <motion.span aria-hidden="true" className="privacy-value" initial={false}
      animate={{ opacity: hidden ? 0 : 1 }}
      transition={{ duration: reduced ? .25 : .4, ease: [.4, 0, .2, 1], delay: hidden ? 0 : .12 }}>
      {rolling ? <RollingAmount value={value}/> : animateValue ? <span className="amount-transition"><AnimatePresence initial={false} mode="popLayout">
        <SlideUpText key={value}>{value}</SlideUpText>
      </AnimatePresence></span> : value}
    </motion.span>
    {size.width > 0 && <svg aria-hidden="true" className="privacy-strike" width={size.width} height={size.height} viewBox={`0 0 ${size.width} ${size.height}`}>
      <motion.path d={strikePath(seed, size.width, size.height)} fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" initial={false} animate={{ pathLength: hidden ? 1 : 0, opacity: hidden ? 1 : 0 }} transition={{ pathLength: { duration: reduced ? 0 : hidden ? .65 : .5, ease: 'easeInOut' }, opacity: { duration: reduced ? .25 : .4 } }}/>
    </svg>}
  </span>;
}
