export function forceTouchCanBeRead(): boolean {
    return 'WEBKIT_FORCE_AT_MOUSE_DOWN' in MouseEvent && window.matchMedia('(pointer: fine)').matches
}
