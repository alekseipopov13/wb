import {useEffect,useLayoutEffect,useRef,useState} from 'react';
import {motion,useReducedMotion} from 'motion/react';
const A=`${import.meta.env.BASE_URL}assets/`;
const titles=['Выберите категории кешбэка на сентябрь','Открылись 3 новые категории кешбэка','Вы выбрали все категории кешбэка'];
export function CategorySlider({active,open}:{active:boolean;open:(title:string)=>void}){
 const reduced=useReducedMotion();
 const [slide,setSlide]=useState({index:0,previous:0,direction:1,serial:0});
 const [touching,setTouching]=useState(false);
 const [visible,setVisible]=useState(!document.hidden);
 const busy=useRef(false);
 const layers=useRef<(HTMLSpanElement|null)[]>([]);
 useLayoutEffect(()=>{
  if(!slide.serial)return;
  const layer=layers.current[slide.index];if(!layer)return;
  // Keep every slide mounted: the outgoing image stays on the same composited layer.
  const animation=layer.animate(reduced?[{opacity:0},{opacity:1}]:[{transform:`translate3d(0,${slide.direction*100}%,0)`},{transform:"translate3d(0,0,0)"}],{duration:reduced?150:550,easing:"cubic-bezier(.22,1,.36,1)"});
  animation.onfinish=()=>{busy.current=false;};
  return()=>animation.cancel();
 },[slide.serial,slide.index,slide.direction,reduced]);
 const pointer=useRef<{x:number;y:number;id:number}|null>(null);
 const moved=useRef(false);
 const advance=(direction:number)=>{if(busy.current)return;busy.current=true;setSlide(s=>({index:(s.index+direction+3)%3,previous:s.index,direction,serial:s.serial+1}));};
 useEffect(()=>{const change=()=>setVisible(!document.hidden);document.addEventListener('visibilitychange',change);return()=>document.removeEventListener('visibilitychange',change);},[]);
 useEffect(()=>{if(!active||!visible||touching)return;const timer=window.setTimeout(()=>advance(1),20000);return()=>clearTimeout(timer);},[slide.serial,active,visible,touching]);
 useEffect(()=>{for(const name of ['categories-mailbox.webp','categories-new.webp']){const img=new Image();img.src=A+name;}},[]);
 const content=(index:number)=><><span className="category-title">{titles[index]}</span>{index===0&&<span className="category-mailbox-frame"><img className="category-mailbox" src={A+'categories-mailbox.webp'} alt="" draggable={false}/></span>} {index===1&&<><img className="category-photo" src={A+'categories-new.webp'} alt="" draggable={false}/><span className="category-shade"/></>}{index===2&&<span className="category-chosen-icons">{['balloon.svg','scissors.svg','pill.svg'].map(name=><span key={name}><img src={A+name} alt=""/></span>)}</span>}<span className="category-cta">{index===2?'Потратить':<img src={A+'category-arrow-oct26.svg'} alt=""/>}</span></>;
 return <><motion.button className="promo cashback category-slider" aria-label={`${titles[slide.index]}. Баннер ${slide.index+1} из ${titles.length}`} aria-roledescription="карусель" data-slide={slide.index} initial={{opacity:0,y:reduced?0:12}} animate={{opacity:1,y:0}} transition={{duration:.4,delay:.06}}
 onPointerDown={e=>{if(e.pointerType==='mouse'&&e.button!==0)return;pointer.current={x:e.clientX,y:e.clientY,id:e.pointerId};moved.current=false;setTouching(true);e.currentTarget.setPointerCapture(e.pointerId);}}
 onPointerMove={e=>{if(pointer.current&&Math.abs(e.clientY-pointer.current.y)>8)moved.current=true;}}
 onPointerUp={e=>{const start=pointer.current;pointer.current=null;setTouching(false);if(e.currentTarget.hasPointerCapture(e.pointerId))e.currentTarget.releasePointerCapture(e.pointerId);if(start){const dy=e.clientY-start.y;if(Math.abs(dy)>24&&Math.abs(dy)>Math.abs(e.clientX-start.x))advance(dy<0?1:-1);}}}
 onPointerCancel={()=>{pointer.current=null;moved.current=true;setTouching(false);}}
 onKeyDown={e=>{if(e.key==='ArrowDown'||e.key==='ArrowUp'){e.preventDefault();advance(e.key==='ArrowDown'?1:-1);}}}
 onClick={()=>{if(moved.current){moved.current=false;return;}open(titles[slide.index]);}}>
 {titles.map((_,index)=><span key={index} ref={node=>{layers.current[index]=node;}} className={`category-layer category-slide-${index}`} aria-hidden="true" style={{zIndex:index===slide.index?1:0,visibility:index===slide.index||index===slide.previous?'visible':'hidden'}}>{content(index)}</span>)}
 </motion.button>
 <motion.span className="category-pagination" aria-hidden="true" initial={{opacity:0}} animate={{opacity:1}} transition={{duration:.4,delay:.06}}>
  {titles.map((_,index)=><span key={index} className="category-page-dot" data-active={index===slide.index}/>)}
 </motion.span></>;
}
