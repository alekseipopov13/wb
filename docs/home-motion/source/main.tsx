import React, { useEffect, useRef, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { AnimatePresence, MotionConfig, motion, useReducedMotion } from 'motion/react';
import './styles.css';
import { PrivacyNumber } from './PrivacyNumber';
import { AnimatedAmountWidth } from './AnimatedAmountWidth';
import { BannerCarousel } from './BannerCarousel';
import { CategorySlider } from './CategorySlider';

const unified = location.pathname === '/' || /^\/wb-test(?:-1)?\/?$/.test(location.pathname);
const variant = location.pathname.startsWith('/wb-test-chris') ? 'chris' : (unified || location.pathname.startsWith('/wb-test-2')) ? 'compact' : 'original';
const A = `${import.meta.env.BASE_URL}assets/`;
const money = (n: number) => Math.round(n).toLocaleString('ru-RU').replace(/\u00a0/g, ' ');
const ease = [0.22, 1, 0.36, 1] as const;
type Mode = 'shopping' | 'accounts';
type Detail = { title: string; text: string; amount?: number; image?: string };
function Asset({ name, className = '' }: { name: string; className?: string }) {
  return <img className={className} src={A + name} alt="" draggable={false} />;
}
function MiniCards() {
  return unified ? <div className="mini-cards card-stack" aria-hidden="true"><span/><span><b>2387</b><Asset name="621b8.svg"/></span></div> : <div className="mini-cards" aria-hidden="true"><Asset name="wallet-cards.svg" /></div>;
}
function PromoCards({ open, hidden, active }: { active: boolean; open: (detail: Detail) => void; hidden: boolean }) {
  const reduced = useReducedMotion();
  const entrance = (delay: number, angle: number) => { const rotate = variant === 'compact' ? (angle === 3.34 ? -10 : 0) : variant === 'original' ? (angle === -5.12 ? -2.43 : angle === 7 ? 4.89 : -5.89) : angle; return ({ initial: { opacity: 0, y: reduced ? 0 : 12, rotate: variant === 'chris' ? 0 : reduced ? rotate : rotate - 3, scale: reduced ? 1 : .96 }, animate: { opacity: 1, y: 0, rotate: variant === 'chris' ? 0 : rotate, scale: 1 }, transition: { duration: reduced ? 0 : .4, ease, delay: reduced ? 0 : delay } }); };
  return <section className="promos" aria-label="Предложения банка">
    <CategorySlider active={active} open={title=>open({title,text:''})}/>
    <motion.button className="points" {...entrance(.12, 7)} onClick={() => open({ title: 'Ваши баллы', text: 'Используйте баллы для покупок на Wildberries.', amount: 1543 })}><span className="points-title">{unified ? 'Кешбэк' : 'У вас'}{unified&&<span className="points-chevron"><Asset name="cashback-chevron.svg"/></span>}</span><span className="points-amount"><PrivacyNumber value="1 543" hidden={hidden}/><span className="points-currency"><Asset name={unified ? "points-pink-v2.svg" : "points-white-v2.svg"} /></span></span></motion.button>
    <motion.button className="friends" {...entrance(.2, 3.34)} onClick={() => open({ title: 'Баллы за друзей', text: 'Приглашайте друзей в WB Банк и получайте 1 000 баллов за друга.', amount: 1000 })}>
      <span>Зовите друзей</span><span>+1 000<span className="points-currency"><Asset name="points-pink-v2.svg" /></span></span>
    </motion.button>
  </section>;
}
const defaultShoppingAccounts = [{title:'Накопления',amount:41054,image:'9bd54.svg',text:'Накопления для покупок на Wildberries.'},{title:'Сертификаты',amount:5000,image:'e11eb.svg',text:'Сертификаты для покупок на Wildberries.'},{title:'С возвратов',amount:12432,image:'69635.svg',text:'Деньги за возвращённые покупки.'}];
function AccountCarousel({ mode, hidden, open, shoppingAccounts = defaultShoppingAccounts }: { mode: Mode; hidden: boolean; open: (detail: Detail) => void; shoppingAccounts?: typeof defaultShoppingAccounts }) {
  const ref = useRef<HTMLDivElement>(null);
  const drag = useRef({ active: false, x: 0, scroll: 0, moved: false, lastX: 0, time: 0, velocity: 0 });
  const reduced = useReducedMotion();
  const isShopping = mode === 'shopping';
  const different = { title: isShopping ? 'С возвратов' : 'Счёт ВТБ', amount: isShopping ? 12432 : 40000, image: isShopping ? '778e9.svg' : '35a9c.svg', text: isShopping ? 'Деньги за возвращённые покупки. Их можно использовать для новых покупок на Wildberries.' : 'Подключённый счёт ВТБ. Баланс включён в общую сумму на счетах.' };
  return <div ref={ref} className="account-carousel" role="region" aria-label="Счета — листайте влево и вправо" tabIndex={0}
    onKeyDown={e => { if (e.key === 'ArrowRight' || e.key === 'ArrowLeft') { e.preventDefault(); ref.current?.scrollBy({ left: e.key === 'ArrowRight' ? 122 : -122, behavior: reduced ? 'instant' : 'smooth' }); } }}
    onPointerDown={e => { if (e.pointerType !== 'mouse' || e.button !== 0) return; drag.current = { active: true, x: e.clientX, scroll: e.currentTarget.scrollLeft, moved: false, lastX: e.clientX, time: performance.now(), velocity: 0 }; }}
    onPointerMove={e => { const d = drag.current; if (!d.active) return; const delta = e.clientX - d.x; if (Math.abs(delta) > 5) { d.moved = true; e.currentTarget.setPointerCapture(e.pointerId); e.currentTarget.classList.add('dragging'); } if (d.moved) { const now = performance.now(); d.velocity = (e.clientX - d.lastX) / Math.max(now - d.time, 1); d.lastX = e.clientX; d.time = now; e.currentTarget.scrollLeft = d.scroll - delta; } }}
    onPointerUp={e => { const d = drag.current; if (!d.active) return; d.active = false; e.currentTarget.classList.remove('dragging'); if (d.moved) { if (e.currentTarget.hasPointerCapture(e.pointerId)) e.currentTarget.releasePointerCapture(e.pointerId); const velocity = performance.now() - d.time < 80 ? d.velocity : 0; e.currentTarget.scrollBy({ left: -velocity * 100, behavior: reduced ? 'instant' : 'smooth' }); } }}
    onPointerCancel={e => { drag.current.active = false; e.currentTarget.classList.remove('dragging'); }}
    onClickCapture={e => { if (drag.current.moved) { e.preventDefault(); e.stopPropagation(); drag.current.moved = false; } }}>
    <div className="account-track">
      <div className="account-pair">
        <div className="account primary-account"><button className="card-hit" aria-label="Основной счёт" onClick={() => open({ title: 'Основной счёт', amount: 65775, text: 'Карта •• 3112. Счёт для ежедневных покупок и переводов.' })}><MiniCards/><strong><PrivacyNumber value="65 775 ₽" hidden={hidden}/></strong><span className="account-label">Основной счёт</span></button><button className="card-plus" aria-label="Пополнить основной счёт" onClick={() => open({ title: 'Пополнить счёт', text: 'Пополнение доступно через СБП или с карты другого банка. Это демонстрационный экран, реальные операции не выполняются.' })}><Asset name="card-add.svg"/></button></div>
        <button className="account cash-account" onClick={() => open({ title: 'WB Кэш', amount: 30000, image: '4183b.svg', text: 'Дополнительная сумма для покупок на Wildberries. Показана отдельно от ваших средств.' })}><Asset className="account-icon" name={unified ? "c869d.svg" : variant === 'original' ? "4183b.svg" : variant === 'compact' ? "cash-icon-compact.svg" : "cash-icon-v2.svg"}/><strong><PrivacyNumber value="30 000 ₽" hidden={hidden}/></strong><span className="account-label">WB Кэш</span></button>
      </div>
      {unified ? <>
        <motion.div className="mode-accounts-slot" initial={false} animate={{width:isShopping ? shoppingAccounts.length * 126 : 132}} transition={{duration:reduced ? 0 : .5,ease:[.4,0,.2,1]}}>
        <motion.div key="shopping-extras" className="shopping-extras" style={{width:shoppingAccounts.length * 126}} inert={!isShopping} aria-hidden={!isShopping}>
          {shoppingAccounts.map((account, index) => <motion.button initial={false} animate={{y:reduced || isShopping ? 0 : 115,opacity:reduced && !isShopping ? 0 : 1}} transition={{duration:reduced ? .15 : .4,delay:reduced ? 0 : isShopping ? .1 + index * .045 : index * .025,ease}} key={account.title} className="account" onClick={()=>open(account)}><Asset className="account-icon" name={account.image}/><strong><PrivacyNumber value={`${money(account.amount)} ₽`} hidden={hidden}/></strong><span className="account-label">{account.title}</span></motion.button>)}
        </motion.div>
        <div className="external-account-slot" inert={isShopping} aria-hidden={isShopping}>
        <motion.div className="external-account-content" initial={false} animate={{y:reduced ? 0 : isShopping ? 115 : 0,opacity:reduced && isShopping ? 0 : 1}} transition={{duration:reduced ? .15 : .4,delay:reduced || isShopping ? 0 : .1,ease}}>
        <span className="account-divider" aria-hidden="true"/>
        <button className="account external-account" onClick={()=>open({title:'Счёт ВТБ',amount:40000,text:'Подключённый счёт ВТБ. Не входит в общий баланс.'})}><Asset className="account-icon" name="35a9c.svg"/><strong><PrivacyNumber value="40 000 ₽" hidden={hidden}/></strong><span className="account-label">Счёт ВТБ</span></button>
        </motion.div></div></motion.div>
      </> : <div className="changing-slot"><AnimatePresence initial={false} mode="wait"><motion.button key={mode} className="account changing-account" initial={{ opacity: 0, y: reduced ? 0 : 10 }} animate={{ opacity: 1, y: 0, transition: { duration: .28, ease } }} exit={{ opacity: 0, y: reduced ? 0 : -6, transition: { duration: .16, ease } }} onClick={() => open(different)}><Asset className="account-icon" name={different.image}/><strong><PrivacyNumber value={`${money(different.amount)} ₽`} hidden={hidden}/></strong><span className="account-label">{different.title}</span></motion.button></AnimatePresence></div> }

      <button className="account add-account" onClick={() => open({ title: 'Открыть ещё', text: 'Подключите счёт другого банка, чтобы видеть все деньги в одном месте.' })}><span>Открыть ещё</span><span className="open-more-art"><Asset name="open-more-oct14.webp"/></span><span className="add-plus">+</span></button>
    </div>
  </div>;
}
function EmptyScreen({ title, close }: { title: string; close: () => void }) {
  const reduced = useReducedMotion();
  const back = useRef<HTMLButtonElement>(null);
  useEffect(() => { back.current?.focus({ preventScroll: true }); }, []);
  return <motion.section className="empty-screen" aria-label={`Экран ${title}`} initial={{ x: reduced ? 0 : '100%' }} animate={{ x: 0 }} exit={{ x: reduced ? 0 : '100%' }} transition={{ duration: reduced ? 0 : .32, ease }}>
    <button ref={back} className="back-button" aria-label="Назад" onClick={close}><svg width="24" height="24" viewBox="0 0 24 24" aria-hidden="true"><path d="M19 12H5m6-6-6 6 6 6" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/></svg></button>
  </motion.section>;
}
function App() {
  const [mode, setMode] = useState<Mode>(unified ? 'accounts' : 'shopping');
  const [hidden, setHidden] = useState(false);
  const [detail, updateDetail] = useState<Detail | null>(null);
  const [navigatingBack, setNavigatingBack] = useState(false);
  const origin = useRef<HTMLElement | null>(null);
  const scrollPosition = useRef(0);
  const navigationLock = useRef(false);
  function setDetail(next: Detail) {
    if (navigationLock.current) return;
    navigationLock.current = true;
    origin.current = document.activeElement as HTMLElement;
    scrollPosition.current = window.scrollY;
    history.pushState({ bankScreen: next.title }, '', '#screen');
    window.scrollTo({ top: 0, behavior: 'instant' });
    updateDetail(next);
  }
  function closeScreen() { history.back(); }
  useEffect(() => {
    // Each reload begins at home; subsequent push/pop entries remain browser navigable.
    history.replaceState({ bankHome: true }, '', location.pathname + location.search);
    const onPop = () => {
      if (history.state?.bankScreen) {
        navigationLock.current = true;
        updateDetail({ title: history.state.bankScreen, text: '' });
      } else {
        updateDetail(null); setNavigatingBack(true);
      }
    };
    window.addEventListener('popstate', onPop);
    return () => window.removeEventListener('popstate', onPop);
  }, []);
  const [query, setQuery] = useState('');
  const balance = unified ? 65775 + 30000 + (mode === 'shopping' ? 41054 + 5000 + 12432 : 0) : (mode === 'shopping' ? 78207 : 105775) + (variant !== 'original' ? 30000 : 0);
  const services: Detail[] = [{ title: 'Основной счёт', amount: 65775, text: 'Карта •• 3112' }, { title: 'WB Кэш', amount: 30000, text: 'Для покупок на Wildberries' }, { title: 'Счёт ВТБ', amount: 40000, text: 'Подключённый счёт' }, { title: 'Перевести', text: 'Перевод по номеру телефона. В прототипе реальные операции не выполняются.' }, { title: 'Пополнить', text: 'Пополнение по СБП. В прототипе реальные операции не выполняются.' }];
  const matches = services.filter(s => s.title.toLowerCase().includes(query.trim().toLowerCase()));
  return <main className={`phone variant-${variant}${unified ? ' unified' : ''}`} aria-label="WB Банк"><div className="home-screen" inert={!!detail || navigatingBack} aria-hidden={!!detail || navigatingBack}>
    <section className="bank-header" data-mode={mode}>
      <header className="toolbar"><button className="icon-button" aria-label="Профиль" onClick={() => setDetail({ title: 'Ваш профиль', text: 'Личный кабинет WB Банка. Демонстрационный интерфейс.' })}><Asset name="profile.svg"/></button><label className="search"><span className="search-icon" aria-hidden="true"><Asset name="search.svg"/></span><input aria-label="Поиск по приложению" value={query} onChange={e => setQuery(e.target.value)} placeholder="Поиск" type="search"/>{query && <button aria-label="Очистить поиск" onClick={() => setQuery('')}>×</button>}</label><div className="toolbar-actions"><button className="icon-button" aria-label="Уведомления" onClick={() => setDetail({ title: 'Уведомления', text: 'Новых уведомлений пока нет. Здесь появятся сообщения об операциях и предложениях банка.' })}><Asset name="bell.svg"/></button></div></header>
      <AnimatePresence>{query.trim() && <motion.div className="search-results" initial={{ opacity: 0, y: -6 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -6 }}>{matches.length ? matches.map(s => <button key={s.title} onClick={() => { setQuery(''); setDetail(s); }}>{s.title}<span>↗</span></button>) : <p>Ничего не найдено</p>}</motion.div>}</AnimatePresence>
      <PromoCards open={setDetail} hidden={hidden} active={!detail && !navigatingBack}/>
      <section className="balance-section" aria-label="Баланс">
        <div className="balance-tabs" role="tablist" aria-label="Вид баланса">{((unified ? ['accounts', 'shopping'] : ['shopping', 'accounts']) as Mode[]).map((item, i) => <button key={item} id={`tab-${item}`} role="tab" aria-selected={mode === item} aria-controls="balance-panel" tabIndex={mode === item ? 0 : -1} onKeyDown={e => { if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') { e.preventDefault(); const next = item === 'shopping' ? 'accounts' : 'shopping'; setMode(next); document.getElementById(`tab-${next}`)?.focus(); } }} className={`balance-tab ${mode === item ? 'selected' : ''}`} onClick={() => setMode(item)}>{mode === item && <motion.span className="tab-highlight" layoutId="active-tab" transition={{ type: 'spring', stiffness: 480, damping: 38 }}/>}<span>{unified ? (item === 'accounts' ? 'Для любых покупок' : <>На <Asset name="65840.svg"/></>) : i === 0 ? <>Для покупок на <Asset name="65840.svg"/></> : 'На счетах'}</span></button>)}</div>
        <div id="balance-panel" role="tabpanel" aria-labelledby={`tab-${mode}`}><div className="balance-line"><span className="balance-number" data-testid="balance" aria-label={hidden ? 'Баланс скрыт' : `${money(balance)} рублей`}><AnimatedAmountWidth value={`${money(balance)} ₽`}><PrivacyNumber value={`${money(balance)} ₽`} hidden={hidden} rolling={!location.pathname.startsWith('/wb-test-1')} animateValue={location.pathname.startsWith('/wb-test-1')}/></AnimatedAmountWidth></span><motion.button className="hide-balance" aria-label={hidden ? 'Показать баланс' : 'Скрыть баланс'} aria-pressed={hidden} onClick={() => setHidden(!hidden)}><Asset name={hidden ? "eye-on.svg" : "7470e.svg"}/></motion.button></div>{variant === 'original' && <div className="cash-total"><span><PrivacyNumber value={`${money(balance + 30000)} ₽`} hidden={hidden} animateValue/> с ВБ Кэш</span><Asset name="49330.svg"/></div>}</div>
      </section>
      <div id="accounts-panel"><AccountCarousel mode={mode} hidden={hidden} open={d => setDetail(hidden && d.amount ? { ...d, amount: undefined } : d)}/></div>
    </section>
    <nav className="quick-actions" aria-label="Быстрые действия">{[{ name: 'QR', icon: '22853.svg', text: 'Оплата по QR-коду. В этом прототипе сканирование и реальные платежи не выполняются.' }, { name: 'Пополнить', icon: 'dabda.svg', text: 'Пополните основной счёт через СБП или с карты другого банка. Демонстрационный экран.' }, { name: 'Перевести', icon: '1ca7e.svg', text: 'Перевод по номеру телефона или реквизитам. Демонстрационный экран.' }, { name: 'За границу', icon: '31c5f.svg', text: '' }].map(action => <button key={action.name} onClick={() => setDetail({ title: action.name === 'Тоня' ? 'Перевод Тоне' : action.name, text: action.text })}><span className={`action-icon ${action.name === 'Тоня' ? 'avatar' : ''}`}><Asset name={action.icon}/></span><span>{action.name}</span></button>)}</nav>
    {unified && <button className="operation-history" onClick={()=>setDetail({title:'История операций',text:''})}><span className="history-copy"><strong>История операций</strong><span>Траты в апреле <PrivacyNumber value="12 543 ₽" hidden={hidden}/></span></span><span className="history-chart history-chart-line" aria-hidden="true"><i/><i/><i/></span></button>}
    <BannerCarousel open={setDetail} active={!detail && !navigatingBack}/>
    {unified && <>
      <section className="product-grid" aria-label="Продукты банка">
        {[{title:'Накопления',description:'Вклады и инвестиции',amount:120000,icon:'product-safe.svg'},{title:'Частями',description:'До 6 месяцев без переплат',amount:100000,icon:'product-split.svg'},{title:'Кредиты',description:'До 500 000 ₽, под 12% годовых',amount:1345678,icon:'product-credit.svg'}].map(product=><button className="product-tile" key={product.title} onClick={()=>setDetail({title:product.title,text:product.description})}><span className="product-heading"><span><strong>{product.title}</strong><span className="product-description">{product.description}</span></span><span className="product-icon"><Asset name={product.icon}/></span></span><span className="product-amount"><PrivacyNumber value={`${money(product.amount)} ₽`} hidden={hidden}/></span></button>)}
        <button className="product-tile all-products" onClick={()=>setDetail({title:'Все продукты',text:''})}><strong>Все продукты</strong><span className="products-art"><Asset className="art-back" name="b0e68.webp"/><Asset className="art-shadow-middle" name="a2694.svg"/><Asset className="art-middle" name="fe3ed.webp"/><Asset className="art-shadow-front" name="f8172.svg"/><Asset className="art-front" name="44623.webp"/></span></button>
      </section>
      <nav className="bottom-navigation" aria-label="Основная навигация">{[{title:'Главная',icon:'43846.svg'},{title:'Каталог',icon:'13da4.svg'},{title:'Банк',icon:'4f242.svg'},{title:'Корзина',icon:'c12c0.svg'},{title:'Профиль',icon:'8eb01.svg'}].map(tab=><button key={tab.title} aria-label={tab.title === 'Корзина' ? 'Корзина, 1 товар' : tab.title} aria-current={tab.title === 'Банк' ? 'page' : undefined} onClick={()=>tab.title === 'Банк' ? window.scrollTo({top:0,behavior:'smooth'}) : setDetail({title:tab.title,text:''})}><span><Asset name={tab.icon}/>{tab.title === 'Корзина' && <span className="nav-counter">1</span>}</span></button>)}</nav>
    </>}

    </div>
    <AnimatePresence onExitComplete={() => {
      setNavigatingBack(false); navigationLock.current = false;
      requestAnimationFrame(() => { window.scrollTo({ top: scrollPosition.current, behavior: 'instant' }); origin.current?.focus({ preventScroll: true }); });
    }}>{detail && <EmptyScreen key="destination" title={detail.title} close={closeScreen}/>}</AnimatePresence>
  </main>;
}
createRoot(document.getElementById('root')!).render(<React.StrictMode><MotionConfig reducedMotion="user"><App/></MotionConfig></React.StrictMode>);
