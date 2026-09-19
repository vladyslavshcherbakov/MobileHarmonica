export interface Contact {
    readonly x: number
    readonly y: number
}

export interface TouchHandlers {
    readonly changed: (contacts: readonly Contact[]) => void
    readonly pinched?: (magnification: number) => void
}

export class TouchArea {
    private readonly contacts = new Map<number, Contact>()
    private bounds: DOMRect
    private spread: number | null = null

    constructor(
        private readonly element: HTMLElement,
        private readonly handlers: TouchHandlers
    ) {
        this.bounds = element.getBoundingClientRect()
        element.addEventListener('pointerdown', event => this.began(event))
        element.addEventListener('pointermove', event => this.moved(event))
        element.addEventListener('pointerup', event => this.ended(event))
        element.addEventListener('pointercancel', event => this.ended(event))
    }

    refreshBounds(): void {
        this.bounds = this.element.getBoundingClientRect()
    }

    private began(event: PointerEvent): void {
        event.preventDefault()
        this.refreshBounds()
        this.element.setPointerCapture(event.pointerId)
        this.contacts.set(event.pointerId, this.contactAt(event))
        this.spread = null
        this.report()
    }

    private moved(event: PointerEvent): void {
        if (!this.contacts.has(event.pointerId)) return

        event.preventDefault()
        this.contacts.set(event.pointerId, this.contactAt(event))
        this.reportPinch()
        this.report()
    }

    private ended(event: PointerEvent): void {
        if (!this.contacts.delete(event.pointerId)) return

        this.spread = null
        this.report()
    }

    private contactAt(event: PointerEvent): Contact {
        return { x: event.clientX - this.bounds.left, y: event.clientY - this.bounds.top }
    }

    private reportPinch(): void {
        const pinched = this.handlers.pinched
        const spread = this.spreadBetweenTheFirstTwo()
        if (pinched === undefined || spread === null) return

        const previous = this.spread
        this.spread = spread
        if (previous === null || previous === 0) return

        pinched(spread / previous)
    }

    private spreadBetweenTheFirstTwo(): number | null {
        const [one, other] = [...this.contacts.values()]
        if (one === undefined || other === undefined) return null

        return Math.hypot(one.x - other.x, one.y - other.y)
    }

    private report(): void {
        this.handlers.changed([...this.contacts.values()])
    }
}
