import { useEffect, useLayoutEffect, useRef, useState } from 'react';
import { animate, motion, useMotionValue, useReducedMotion } from 'motion/react';

type Banner = { id: string; title: string; text: string; image: string; width: number };
const banners: Banner[] = [
  { id: 'savings', title: 'Кстати, с нами удобно копить', text: 'Откройте вклад и получайте до 15,1% годовых', image: 'banner-savings.webp', width: 358 },
  { id: 'games', title: 'Всё для игр', text: 'Платите за Steam, PC Store, Roblox, и не только', image: 'b1c29.webp', width: 346 },
  { id: 'subscriptions', title: 'Кстати, что с подписками', text: 'Оплатить AppStore, ChatGPT и другие зарубежные сервисы удобно у нас', image: 'banner-subscriptions.webp', width: 358 },
];
export function BannerCarousel({ open, active }: { open: (detail: { title: string; text: string }) => void; active: boolean }) {
  const ref = useRef<HTMLElement>(null);
  const [width, setWidth] = useState(390);
  const items = banners;
  const [page, setPage] = useState(4); // Middle repeat, initially games.
  const [visible, setVisible] = useState(!document.hidden);
  const [interacting, setInteracting] = useState(false);
  const [focused, setFocused] = useState(false);
  const [hovered, setHovered] = useState(false);
  const [timerKey, resetTimer] = useState(0);
  const reduced = useReducedMotion();
  const x = useMotionValue(0);
  const animation = useRef<ReturnType<typeof animate> | null>(null);
  const ready = useRef(false);
  const transitioning = useRef(false);
  const dragging = useRef(false);
  const count = items.length;
  const scale = width / 390;
  const pages = Array.from({ length: count * 3 }, (_, index) => items[index % count]);
  const offsetFor = (index: number) => {
    const previousWidth = pages.slice(0, index).reduce((total, item) => total + item.width * scale + 8, 0);
    return width / 2 - previousWidth - pages[index].width * scale / 2;
  };
  useLayoutEffect(() => {
    const observer = new ResizeObserver(entries => setWidth(entries[0].contentRect.width));
    if (ref.current) observer.observe(ref.current);
    return () => observer.disconnect();
  }, []);
  useEffect(() => {
    const handle = () => setVisible(!document.hidden);
    document.addEventListener('visibilitychange', handle);
    return () => document.removeEventListener('visibilitychange', handle);
  }, []);
  useLayoutEffect(() => {
    animation.current?.stop();
    const target = offsetFor(page);
    if (!ready.current || reduced) {
      x.set(target); ready.current = true; transitioning.current = false;
      if (reduced && (page < count || page >= count * 2)) {
        const normalized = count + page % count;
        x.set(offsetFor(normalized)); setPage(normalized);
      }
      return;
    }
    transitioning.current = true;
    animation.current = animate(x, target, { duration: .42, ease: [.4, 0, .2, 1], onComplete: () => {
      transitioning.current = false;
      if (page < count || page >= count * 2) {
        const normalized = count + page % count;
        x.set(offsetFor(normalized)); ready.current = false; setPage(normalized);
      }
    } });
    return () => animation.current?.stop();
  }, [page, width, items, reduced]);
  const advance = (direction: number) => {
    if (transitioning.current || count < 2) return;
    setPage(p => Math.max(0, Math.min(count * 3 - 1, p + direction)));
    resetTimer(k => k + 1);
  };
  useEffect(() => {
    if (!active || !visible || interacting || focused || hovered || reduced || count < 2) return;
    const timer = window.setTimeout(() => advance(1), 6000);
    return () => clearTimeout(timer);
  }, [page, active, visible, interacting, focused, hovered, reduced, timerKey, count]);
  return <section ref={ref} className="banner-carousel" aria-label="Предложения — карусель баннеров" aria-roledescription="карусель" data-current={items[page % count].id} tabIndex={0}
    onKeyDown={e => { if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') { e.preventDefault(); advance(e.key === 'ArrowRight' ? 1 : -1); } }}
    onFocusCapture={e => setFocused((e.target as HTMLElement).matches(':focus-visible'))} onBlurCapture={e => { if (!e.currentTarget.contains(e.relatedTarget)) setFocused(false); }}
    onPointerEnter={e => { if (e.pointerType === 'mouse') setHovered(true); }} onPointerLeave={() => setHovered(false)}>
    <motion.div className="banner-track" style={{ x }} drag="x" dragMomentum={false} dragElastic={0} dragConstraints={{ left: offsetFor(count * 3 - 1), right: offsetFor(0) }}
      onPointerDown={() => { dragging.current = false; setInteracting(true); }}
      onPointerUp={() => setInteracting(false)} onPointerCancel={() => setInteracting(false)}
      onDragStart={() => { dragging.current = true; animation.current?.stop(); transitioning.current = false; setInteracting(true); }}
      onDragEnd={(_, info) => {
        setInteracting(false);
        const travel = info.offset.x + info.velocity.x * .15;
        if (Math.abs(travel) > 36) advance(travel < 0 ? 1 : -1);
        else animation.current = animate(x, offsetFor(page), { duration: reduced ? 0 : .3, ease: [.22, 1, .36, 1] });
        resetTimer(k => k + 1);
      }} onClickCapture={e => { if (dragging.current) { e.preventDefault(); e.stopPropagation(); dragging.current = false; } }}>
      {pages.map((banner, index) => <div key={`${banner.id}-${index}`} className={`banner-slide banner-${banner.id}`} style={{ width: banner.width * scale }} aria-hidden={index !== page} inert={index !== page}>
        <button className="banner-open" tabIndex={index === page ? 0 : -1} aria-label={banner.title} onClick={() => open(banner)}>
          <span className="banner-copy"><strong>{banner.title}</strong><span>{banner.text}</span></span><img src={`${import.meta.env.BASE_URL}assets/${banner.image}`} alt="" draggable={false}/>
        </button>
      </div>)}
    </motion.div>
  </section>;
}
