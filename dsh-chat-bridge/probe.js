// === ВСТАВЬ ЭТО В КОНСОЛЬ CHROME (F12 → Console) НА chat.deepseek.com ===
// Перед запуском: отправь любое сообщение и дождись завершения ответа.

(async () => {
  const result = {}

  // 1. Поле ввода
  const possibleInputs = [
    '#chat-input',
    'textarea',
    '[contenteditable="true"]',
    '[role="textbox"]',
  ]
  result.inputs = possibleInputs.map(sel => {
    const el = document.querySelector(sel)
    return {
      selector: sel,
      found: !!el,
      tag: el?.tagName,
      id: el?.id,
      className: typeof el?.className === 'string' ? el.className.slice(0, 100) : undefined,
      placeholder: el?.getAttribute('placeholder'),
      ariaLabel: el?.getAttribute('aria-label'),
    }
  }).filter(x => x.found)

  // 2. Все видимые кнопки (ищем Stop / Send)
  result.buttons = [...document.querySelectorAll('button')]
    .map(b => {
      const r = b.getBoundingClientRect()
      return {
        ariaLabel: b.getAttribute('aria-label'),
        title: b.getAttribute('title'),
        text: (b.innerText || b.textContent || '').trim().slice(0, 40),
        type: b.getAttribute('type'),
        disabled: b.disabled,
        visible: r.width > 0 && r.height > 0,
        className: typeof b.className === 'string' ? b.className.slice(0, 80) : undefined,
      }
    })
    .filter(b => b.visible && (b.ariaLabel || b.text || b.title))

  // 3. Контейнеры AI-ответа
  result.assistantContainers = {
    dsMarkdown: [...document.querySelectorAll('.ds-markdown')].length,
    byRoleAssistant: [...document.querySelectorAll('[data-message-author-role="assistant"]')].length,
    byRoleArticle: [...document.querySelectorAll('[role="article"]')].length,
    thinking: [...document.querySelectorAll('[class*="thinking"], [class*="reason"]')].length,
  }

  // 4. Последний AI-ответ: класс + родитель
  const lastMd = [...document.querySelectorAll('.ds-markdown')].at(-1)
  if (lastMd) {
    result.lastAssistant = {
      tag: lastMd.tagName,
      className: typeof lastMd.className === 'string' ? lastMd.className.slice(0, 150) : undefined,
      textPreview: (lastMd.innerText || '').trim().slice(0, 200),
      parentTag: lastMd.parentElement?.tagName,
      parentClass: typeof lastMd.parentElement?.className === 'string'
        ? lastMd.parentElement.className.slice(0, 150)
        : undefined,
      grandParentClass: typeof lastMd.parentElement?.parentElement?.className === 'string'
        ? lastMd.parentElement.parentElement.className.slice(0, 150)
        : undefined,
    }
  }

  // 5. Кнопки рядом с последним сообщением (Copy / Regenerate / Like)
  if (lastMd) {
    const container = lastMd.closest('[class*="message"], [role="article"], [class*="chat"]') || lastMd.parentElement
    if (container) {
      result.nearbyButtons = [...container.querySelectorAll('button')].map(b => ({
        ariaLabel: b.getAttribute('aria-label'),
        title: b.getAttribute('title'),
        text: (b.innerText || '').trim().slice(0, 30),
      })).filter(b => b.ariaLabel || b.text || b.title)
    }
  }

  // 6. Общий список сообщений (контейнер, где всё лежит)
  const allContainers = [...document.querySelectorAll('div')]
    .filter(d => d.children.length > 2 && d.querySelectorAll('.ds-markdown').length > 0)
    .slice(0, 5)
    .map(d => ({
      tag: d.tagName,
      id: d.id,
      className: typeof d.className === 'string' ? d.className.slice(0, 150) : undefined,
      childCount: d.children.length,
      mdCount: d.querySelectorAll('.ds-markdown').length,
    }))
  result.messageListCandidates = allContainers

  console.log('=== PROBE RESULT ===')
  console.log(JSON.stringify(result, null, 2))
  copy(JSON.stringify(result, null, 2))  // автоматически скопирует в буфер обмена
  console.log('=== Скопировано в буфер. Вставь мне сюда. ===')
})()
