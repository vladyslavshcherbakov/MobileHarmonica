export function element<T extends HTMLElement = HTMLElement>(id: string): T {
    const found = document.getElementById(id)
    if (found === null) throw new Error(`the page has no element called ${id}`)

    return found as T
}
