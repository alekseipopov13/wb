#!/usr/bin/env python3
"""Check the published handoff, relative links and live-parameter manifest."""
from pathlib import Path
import json, re, sys, subprocess
ROOT=Path(__file__).resolve().parents[1]
DOCS=ROOT/'docs/favourites'
errors=[]
required=['Зачем','Как запускается','Пример и последовательность','Параметры и их смысл','Повторное действие и прерывание','Уменьшение движения и доступность','Как проверить','Где находится реализация']
pages=sorted((DOCS/'animations').glob('*.md'))
if len(pages)!=9:errors.append(f'Expected 9 animation pages, found {len(pages)}')
for p in list(DOCS.rglob('*.md'))+[ROOT/'docs/templates/motion-spec.md']:
 text=p.read_text()
 if p.parent.name=='animations':
  for title in required:
   if '## '+title not in text:errors.append(f'{p.name}: missing section {title}')
 for target in re.findall(r'\]\(([^)]+)\)',text):
  target=target.strip('<>').split('#',1)[0]
  if not target or re.match(r'^[a-z]+:',target):continue
  if not (p.parent/target).resolve().exists():errors.append(f'{p.relative_to(ROOT)}: broken link {target}')
 if re.search(r'\b(TODO|TBD|FIXME)\b',text):errors.append(f'{p.name}: unresolved placeholder')
examples=(ROOT/'WBSandbox/Model/FavouritesAnimationExample.swift').read_text()
if 'case amount' in examples or 'case rowInsertion' in examples:errors.append('Removed animation is back in catalog')
if not (DOCS/'validation.json').exists():errors.append('Missing validation record')
reference=json.loads((DOCS/'motion-reference.json').read_text())
expected={'schema_version':1,'sample_rate_hz':60}
for key,value in expected.items():
 if reference.get(key)!=value:errors.append(f'Motion reference {key} mismatch')
for name in ['reminder','grid_insertion','neighbour_travel','removal','promotion']:
 samples=reference[name]['samples']
 if not samples or samples[0]['time_ms']!=0:errors.append(f'{name}: missing first sample')
 if any(a['time_ms']>=b['time_ms'] for a,b in zip(samples,samples[1:])):errors.append(f'{name}: time must increase')
if reference['deck_gesture']!={'arm_distance':72,'disarm_distance':54}:errors.append('Gesture thresholds mismatch')
manifest=json.loads((DOCS/'media/manifest.json').read_text())
if len(manifest)!=9:errors.append('Expected 9 recorded examples')
for item in manifest:
 slug=item['id']
 for suffix in ['.gif','.mp4','-frames.jpg']:
  p=DOCS/'media'/f'{slug}{suffix}'
  if not p.exists() or p.stat().st_size==0:errors.append(f'Missing media: {p.name}')
if errors:
 print('\n'.join(errors),file=sys.stderr);sys.exit(1)
print('Handoff docs: 9 pages, shared template, relative links, media and parameter manifest passed')
