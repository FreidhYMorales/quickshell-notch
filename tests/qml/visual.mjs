export function findText(items, text) {
  for (const item of items) {
    if (item.visible && item.text === text) return item;
    const nested = findText(item.children || [], text);
    if (nested) return nested;
  }
  return null;
}

export function findImage(items, source) {
  for (const item of items) {
    if (item.visible && item.source && String(item.source) === source) {
      return item;
    }
    const nested = findImage(item.children || [], source);
    if (nested) return nested;
  }
  return null;
}
