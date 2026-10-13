// === ВСТАВЬ В КОНСОЛЬ CHROME НА chat.deepseek.com ===
// 1. Отправь сообщение (например "расскажи длинную историю")
// 2. ПОКА ИДЁТ ГЕНЕРАЦИЯ (кнопка Stop видна) — вставь это в консоль и нажми Enter

(() => {
  const btns = [...document.querySelectorAll('button')]
    .map(b => {
      const r = b.getBoundingClientRect()
      return {
        ariaLabel: b.getAttribute('aria-label'),
        title: b.getAttribute('title'),
        text: (b.innerText || '').trim().slice(0, 40),
        type: b.getAttribute('type'),
        disabled: b.disabled,
        visible: r.width > 0 && r.height > 0,
        className: typeof b.className === 'string' ? b.className.slice(0, 120) : undefined,
        svgPath: b.querySelector('svg path')?.getAttribute('d')?.slice(0, 60),
      }
    })
    .filter(b => b.visible)
  console.log('=== BUTTONS WHILE GENERATING ===')
  console.log(JSON.stringify(btns, null, 2))
  copy(JSON.stringify(btns, null, 2))
})()
