export function findText(items, text) {
  for (const item of items) {
    if (item.visible && item.text === text) return item;
    const nested = findText(item.children || [], text);
    if (nested) return nested;
  }
  return null;
}
