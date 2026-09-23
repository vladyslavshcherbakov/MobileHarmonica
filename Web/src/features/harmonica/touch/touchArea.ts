import type { Contact } from './contact.js'

export interface TouchHandlers {
    readonly changed: (contacts: readonly Contact[]) => void
    readonly pinched?: (magnification: number) => void
}

export class TouchArea {
    private readonly contacts = new Map<number, Contact>()
    private bounds: DOMRect
    private spread: number | null = null
    private mousePointerId: number | null = null

    constructor(
        private readonly element: HTMLElement,
        private readonly handlers: TouchHandlers
    ) {
        this.bounds = element.getBoundingClientRect()
        element.addEventListener('pointerdown', event => this.began(event))
        element.addEventListener('pointermove', event => this.moved(event))
        element.addEventListener('pointerup', event => this.ended(event))
        element.addEventListener('pointercancel', event => this.ended(event))
        element.addEventListener('webkitmouseforcewillbegin', event => event.preventDefault())
        window.addEventListener('webkitmouseforcechanged', event => this.followThePress(event as MouseEvent))
    }

    refreshBounds(): void {
        this.bounds = this.element.getBoundingClientRect()
    }

    private began(event: PointerEvent): void {
        event.preventDefault()
        this.refreshBounds()
        this.element.setPointerCapture(event.pointerId)
        if (event.pointerType === 'mouse') this.mousePointerId = event.pointerId
        this.contacts.set(event.pointerId, this.contactAt(event, null))
        this.spread = null
        this.report()
    }

    private moved(event: PointerEvent): void {
        const previous = this.contacts.get(event.pointerId)
        if (previous === undefined) return

        event.preventDefault()
        this.contacts.set(event.pointerId, this.contactAt(event, previous.force))
        this.reportPinch()
        this.report()
    }

    private ended(event: PointerEvent): void {
        if (!this.contacts.delete(event.pointerId)) return

        if (event.pointerId === this.mousePointerId) this.mousePointerId = null
        this.spread = null
        this.report()
    }

    private followThePress(event: MouseEvent): void {
        const pressingPointerId = this.mousePointerId
        const pressedContact = pressingPointerId === null ? undefined : this.contacts.get(pressingPointerId)
        if (pressingPointerId === null || pressedContact === undefined) return

        this.contacts.set(pressingPointerId, { ...pressedContact, force: forceOf(event) ?? pressedContact.force })
        this.report()
    }

    private contactAt(event: PointerEvent, force: number | null): Contact {
        return { x: event.clientX - this.bounds.left, y: event.clientY - this.bounds.top, force }
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

function forceOf(event: MouseEvent): number | null {
    const force = (event as ForceTouchMouseEvent).webkitForce
    return typeof force === 'number' ? force : null
}

interface ForceTouchMouseEvent extends MouseEvent {
    readonly webkitForce?: number
}
