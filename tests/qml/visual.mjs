// QML objects expose `children` with different shapes: visual items and plain
// QObjects return lists, but types such as QsMenuOpener return a single menu
// object instead. Only list-like children are worth walking.
function childItems(item) {
  const children = item.children;
  return children && typeof children.length === "number" ? children : [];
}

export function findText(items, text) {
  for (const item of items) {
    if (item.visible && item.text === text) return item;
    const nested = findText(childItems(item), text);
    if (nested) return nested;
  }
  return null;
}

export function findImage(items, source) {
  for (const item of items) {
    if (item.visible && item.source && String(item.source) === source) {
      return item;
    }
    const nested = findImage(childItems(item), source);
    if (nested) return nested;
  }
  return null;
}

export function findVerticalDivider(items) {
  for (const item of items) {
    if (
      item.visible && item.color !== undefined && item.width > 0 &&
      item.width <= 2 && item.height >= 8
    ) return item;
    const nested = findVerticalDivider(childItems(item));
    if (nested) return nested;
  }
  return null;
}
