// Reserve decimal places before counting starts. Leading empty cells carry no
// text, so crossing a power of ten changes only a glyph, never the layout.
export function AmountDigits({ value, measurement = false, minimumDigits = 0 }: { value: string; measurement?: boolean; minimumDigits?: number }) {
  const missing = Math.max(0, minimumDigits - value.replace(/\D/g, '').length);
  return <span className="amount-digits">
    {Array.from({length: missing}, (_, index) => <span key={`reserved-${index}`} className="amount-digit-cell" aria-hidden="true"/>)}
    {Array.from(value).map((char, index) =>
      <span key={value.length - index} className={/\d/.test(char) ? 'amount-digit-cell' : 'amount-space-cell'} data-glyph={measurement ? char : undefined}>{measurement ? null : char}</span>
    )}
  </span>;
}
