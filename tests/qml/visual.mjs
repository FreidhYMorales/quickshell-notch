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

export function findHorizontalDivider(items) {
  for (const item of items) {
    if (
      item.visible && item.color !== undefined && item.height > 0 &&
      item.height <= 2 && item.width >= 8
    ) return item;
    const nested = findHorizontalDivider(childItems(item));
    if (nested) return nested;
  }
  return null;
}

// Texts visible in an item's subtree, as plain strings.
export function textsIn(item) {
  const found = [];
  for (const child of childItems(item)) {
    if (child.visible && typeof child.text === "string") found.push(child.text);
    for (const nested of textsIn(child)) found.push(nested);
  }
  return found;
}
