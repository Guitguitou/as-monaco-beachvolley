import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const waitForFullCalendar = () => {
      if (window.FullCalendar?.Calendar) {
        this.initializeCalendar()
      } else {
        setTimeout(waitForFullCalendar, 50)
      }
    }
    waitForFullCalendar()
  }

  initializeCalendar() {
    const calendarEl = this.element
    const sessions = JSON.parse(calendarEl.dataset.sessions)
    const initialDate = calendarEl.dataset.initialDate

    const isMobile = window.matchMedia('(max-width: 640px)').matches
    const headerToolbar = isMobile
      ? { left: 'prev,next', center: 'title', right: 'dayGridWeek,dayGridDay' }
      : { left: 'prev,next today', center: 'title', right: 'dayGridMonth,dayGridWeek,dayGridThreeDay,dayGridDay' }

    const calendar = new window.FullCalendar.Calendar(calendarEl, {
      initialView: isMobile ? 'dayGridWeek' : 'dayGridWeek',
      ...(initialDate ? { initialDate } : {}),
      firstDay: 1,
      headerToolbar,
      locale: 'fr',
      buttonText: {
        today: "Aujourd'hui",
        month: 'Mois',
        dayGridWeek: 'Semaine',
        dayGridDay: 'Jour',
        dayGridThreeDay: '3 jours'
      },
      views: {
        dayGridThreeDay: { type: 'dayGrid', duration: { days: 3 } }
      },
      allDaySlot: false,
      slotMinTime: '08:00:00',
      slotMaxTime: '23:00:00',
      slotDuration: '00:30:00',
      slotLabelFormat: { hour: 'numeric', minute: '2-digit', meridiem: false, hour12: false },
      height: isMobile ? 'auto' : 'calc(100vh - 200px)',
      nowIndicator: true,
      stickyHeaderDates: true,
      eventOverlap: true,
      scrollTime: isMobile ? '07:30:00' : '08:00:00',
      expandRows: true,
      dayMaxEvents: false,
      eventOrder: 'start,terrain',
      eventOrderStrict: true,
      slotLabelClassNames: ['text-sm', 'text-gray-600', 'font-medium'],
      eventDisplay: 'block',
      dayHeaderFormat: isMobile ? { weekday: 'short', day: 'numeric', month: 'numeric' } : undefined,
      events: sessions,
      eventTimeFormat: { hour: "2-digit", minute: "2-digit", hour12: false },
      eventContent(arg) {
        const isMobile = window.matchMedia('(max-width: 640px)').matches
        const timeText = arg.timeText
        const sessionType = arg.event.extendedProps.sessionTypeLabel || ''
        const groups = arg.event.extendedProps.groupsLabel || ''
        const coach = arg.event.extendedProps.coachName || ''

        const root = document.createElement('div')
        root.className = 'fc-asmbv-card'

        const time = document.createElement('div')
        time.className = 'fc-asmbv-time'
        time.textContent = timeText

        const typeEl = document.createElement('div')
        typeEl.className = 'fc-asmbv-type'
        typeEl.textContent = sessionType

        const groupsEl = document.createElement('div')
        groupsEl.className = 'fc-asmbv-groups'
        groupsEl.textContent = groups

        const coachEl = document.createElement('div')
        coachEl.className = 'fc-asmbv-coach'
        coachEl.textContent = coach

        root.appendChild(time)
        root.appendChild(typeEl)
        root.appendChild(groupsEl)
        root.appendChild(coachEl)
        return { domNodes: [root] }
      },
      eventDidMount: (info) => {
        const isMobile = window.matchMedia('(max-width: 640px)').matches
        const todayBackground = '#fff8f7'
        const baseBackground = info.event.extendedProps.backgroundColor
        info.el.style.backgroundColor = this.applyAlphaColor(baseBackground, 0.85)
        info.el.style.borderColor = todayBackground
        info.el.style.color = info.event.extendedProps.textColor

        // style "carte"
        info.el.style.borderRadius = '10px'
        info.el.style.padding = isMobile ? '4px' : '8px'
        info.el.style.boxShadow = '0 1px 0 rgba(0,0,0,0.06)'
        info.el.style.fontWeight = '500'
        info.el.style.whiteSpace = 'normal'
        info.el.style.overflow = isMobile ? 'hidden' : 'visible'
        info.el.style.display = 'block'
        // Sur mobile, s'assurer que le contenu ne dépasse pas
        if (isMobile) {
          info.el.style.width = '100%'
          info.el.style.boxSizing = 'border-box'
        }

        // typographies fines via classes utilitaires
        const card = info.el.querySelector('.fc-asmbv-card')
        if (card) {
          card.style.width = '100%'
          card.style.height = '100%'
          card.style.display = 'flex'
          card.style.flexDirection = 'column'
          card.style.overflow = 'hidden'
        }

        const time = info.el.querySelector('.fc-asmbv-time')
        const type = info.el.querySelector('.fc-asmbv-type')
        const groups = info.el.querySelector('.fc-asmbv-groups')
        const coach = info.el.querySelector('.fc-asmbv-coach')

        if (time) {
          time.style.fontSize = isMobile ? '10px' : '12px'
          time.style.opacity = '0.9'
          time.style.lineHeight = '1.1'
          time.style.flexShrink = '0'
          if (isMobile) {
            time.style.overflow = 'hidden'
            time.style.textOverflow = 'ellipsis'
            time.style.whiteSpace = 'nowrap'
          }
        }

        if (type) {
          type.style.fontSize = isMobile ? '11px' : '13px'
          type.style.fontWeight = '600'
          type.style.lineHeight = '1.2'
          type.style.flexShrink = '0'
          type.style.display = '-webkit-box'
          type.style.webkitLineClamp = '1'
          type.style.webkitBoxOrient = 'vertical'
          type.style.overflow = 'hidden'
          type.style.textOverflow = 'ellipsis'
        }

        if (groups) {
          groups.style.fontSize = isMobile ? '10px' : '12px'
          groups.style.opacity = '0.95'
          groups.style.lineHeight = '1.2'
          groups.style.flex = '1'
          groups.style.minHeight = '0'
          groups.style.display = '-webkit-box'
          groups.style.webkitLineClamp = isMobile ? '1' : '2'
          groups.style.webkitBoxOrient = 'vertical'
          groups.style.overflow = 'hidden'
          groups.style.textOverflow = 'ellipsis'
        }

        if (coach) {
          coach.style.fontSize = isMobile ? '9px' : '12px'
          coach.style.opacity = '0.9'
          coach.style.lineHeight = '1.1'
          coach.style.flexShrink = '0'
          if (isMobile) {
            coach.style.overflow = 'hidden'
            coach.style.textOverflow = 'ellipsis'
            coach.style.whiteSpace = 'nowrap'
            coach.style.maxWidth = '100%'
          }
        }

        // min height douce pour les events courts - ajusté pour mobile
        info.el.style.minHeight = isMobile ? '56px' : '80px'
        // Sur mobile, hauteur maximale pour éviter les débordements
        if (isMobile) {
          info.el.style.maxHeight = '100%'
        }
      },

      datesSet: (info) => {
        this.updateDateQueryParamAndLinks(info.start)
        this.styleHeaderButtons(calendarEl)
      },
      viewDidMount: () => this.styleHeaderButtons(calendarEl)
    })

    // Expose for later filtering
    this.calendar = calendar
    this.sessions = sessions

    calendar.render()
    this.styleHeaderButtons(calendarEl)
    this.setupTerrainTabsInteraction()
    this.applyTerrainFromUrl()
  }

  styleHeaderButtons(calendarEl) {
    const isMobile = window.matchMedia('(max-width: 640px)').matches
    const buttons = calendarEl.querySelectorAll('.fc .fc-toolbar-chunk .fc-button')
    buttons.forEach(btn => {
      btn.classList.add(
        'bg-asmbv-red', 'text-white', 'hover:bg-asmbv-red-dark',
        'border-0', 'rounded-md', 'font-semibold'
      )
      btn.classList.remove('fc-button-primary')
      // size adjustments
      btn.classList.add(isMobile ? 'px-2' : 'px-3')
      btn.classList.add(isMobile ? 'py-2' : 'py-1.5')
      btn.classList.add(isMobile ? 'text-sm' : 'text-sm')
    })

    // tighten toolbar spacing on mobile
    if (isMobile) {
      calendarEl.querySelectorAll('.fc .fc-toolbar-chunk').forEach(chunk => {
        chunk.classList.add('space-x-1')
      })
    }
  }

  updateDateQueryParamAndLinks(dateObj) {
    try {
      const ymd = this.formatDateToYMD(dateObj)
      const url = new URL(window.location.href)
      url.searchParams.set('date', ymd)
      window.history.replaceState({}, '', url.toString())
      this.syncTerrainLinksDate(ymd)
    } catch (_) {
      // noop if URL API not available
    }
  }

  formatDateToYMD(date) {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  syncTerrainLinksDate(ymd) {
    try {
      const container = document.getElementById('terrain-tabs')
      if (!container) return
      const anchors = container.querySelectorAll('a[href]')
      anchors.forEach((a) => {
        const url = new URL(a.href, window.location.origin)
        url.searchParams.set('date', ymd)
        a.href = url.toString()
      })
    } catch (_) {
      // ignore
    }
  }

  setupTerrainTabsInteraction() {
    const container = document.getElementById('terrain-tabs')
    if (!container) return

    // Intercept clicks to avoid full page reload and keep calendar week
    container.addEventListener('click', (event) => {
      const anchor = event.target.closest('a')
      if (!anchor) return
      event.preventDefault()
      try {
        const url = new URL(anchor.href, window.location.origin)
        const selectedTerrain = url.searchParams.get('terrain') || ''
        this.applyTerrain(selectedTerrain)

        // Update URL (preserve date param already set by datesSet)
        const currentUrl = new URL(window.location.href)
        if (selectedTerrain) {
          currentUrl.searchParams.set('terrain', selectedTerrain)
        } else {
          currentUrl.searchParams.delete('terrain')
        }
        window.history.replaceState({}, '', currentUrl.toString())
      } catch (_) {
        // ignore
      }
    })

    // Keep in sync when navigating browser history
    window.addEventListener('popstate', () => this.applyTerrainFromUrl())
  }

  applyAlphaColor(color, alpha) {
    if (!color) return color
    const trimmed = color.trim()

    if (trimmed.startsWith("#")) {
      const hex = trimmed.replace("#", "")
      if (hex.length === 3) {
        const r = parseInt(hex[0] + hex[0], 16)
        const g = parseInt(hex[1] + hex[1], 16)
        const b = parseInt(hex[2] + hex[2], 16)
        return `rgba(${r}, ${g}, ${b}, ${alpha})`
      }
      if (hex.length === 6) {
        const r = parseInt(hex.slice(0, 2), 16)
        const g = parseInt(hex.slice(2, 4), 16)
        const b = parseInt(hex.slice(4, 6), 16)
        return `rgba(${r}, ${g}, ${b}, ${alpha})`
      }
    }

    const rgbMatch = trimmed.match(/^rgba?\((.+)\)$/i)
    if (rgbMatch) {
      const parts = rgbMatch[1].split(",").map(part => part.trim())
      const [r, g, b] = parts
      return `rgba(${r}, ${g}, ${b}, ${alpha})`
    }

    return color
  }

  applyTerrainFromUrl() {
    try {
      const url = new URL(window.location.href)
      const selectedTerrain = url.searchParams.get('terrain') || ''
      this.applyTerrain(selectedTerrain)
    } catch (_) {
      // ignore
    }
  }

  applyTerrain(selectedTerrain) {
    if (!this.calendar || !this.sessions) return

    // Update active tab classes
    const container = document.getElementById('terrain-tabs')
    if (container) {
      const anchors = Array.from(container.querySelectorAll('a'))
      anchors.forEach((a) => {
        const url = new URL(a.href, window.location.origin)
        const terrain = url.searchParams.get('terrain') || ''
        const isActive = terrain === (selectedTerrain || '')

        a.classList.toggle('text-asmbv-red', isActive)
        a.classList.toggle('border-asmbv-red', isActive)
        a.classList.toggle('text-gray-500', !isActive)
        a.classList.toggle('border-transparent', !isActive)
      })
    }

    // Filter events
    const filteredEvents = selectedTerrain
      ? this.sessions.filter(e => e.terrain === selectedTerrain)
      : this.sessions
    this.calendar.removeAllEvents()
    this.calendar.addEventSource(filteredEvents)
  }
}
