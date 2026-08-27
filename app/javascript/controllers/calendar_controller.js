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

  // Fenêtre horaire affichée par la grille.
  //
  // Elle était figée sur 08:00–23:00 alors que les sessions se jouent en fin de
  // journée : on ouvrait sur dix heures de créneaux vides, et sur mobile
  // (height: 'auto', donc pas de scroll interne) même `scrollTime` n'y changeait
  // rien — il fallait scroller la page pour trouver quoi que ce soit.
  //
  // On calcule donc la fenêtre à partir des sessions réellement visibles dans la
  // plage affichée. Un jour sans session affiche une grille courte plutôt que
  // quinze heures de vide.
  slotWindowFor(events, rangeStart, rangeEnd) {
    const hours = (events || []).reduce((acc, event) => {
      const start = new Date(event.start)
      const end = new Date(event.end || event.start)
      if (rangeStart && end <= rangeStart) return acc
      if (rangeEnd && start >= rangeEnd) return acc

      acc.push(start.getHours())
      // Une session qui finit pile à l'heure ne doit pas ajouter un créneau vide.
      acc.push(end.getMinutes() > 0 ? end.getHours() + 1 : end.getHours())
      return acc
    }, [])

    if (hours.length === 0) return { min: '17:00:00', max: '22:00:00' }

    const min = Math.max(Math.min(...hours) - 1, 0)
    const max = Math.min(Math.max(...hours) + 1, 24)
    return { min: `${String(min).padStart(2, '0')}:00:00`, max: `${String(max).padStart(2, '0')}:00:00` }
  }

  applySlotWindow(calendar, info) {
    const { min, max } = this.slotWindowFor(this.visibleEvents(), info.start, info.end)
    if (calendar.getOption('slotMinTime') !== min) calendar.setOption('slotMinTime', min)
    if (calendar.getOption('slotMaxTime') !== max) calendar.setOption('slotMaxTime', max)
  }

  // Les sessions actuellement retenues par les filtres, ou toutes au premier rendu.
  visibleEvents() {
    return this.filteredSessions || this.sessions || []
  }

  initializeCalendar() {
    const calendarEl = this.element
    const sessions = JSON.parse(calendarEl.dataset.sessions)
    const initialDate = calendarEl.dataset.initialDate

    const isMobile = window.matchMedia('(max-width: 640px)').matches
    const headerToolbar = isMobile
      ? { left: 'prev,next', center: 'title', right: 'timeGridDay,timeGridWeek' }
      : { left: 'prev,next today', center: 'title', right: 'dayGridMonth,timeGridWeek,timeGridThreeDay,timeGridDay' }

    const calendar = new window.FullCalendar.Calendar(calendarEl, {
      // Sur 375 px de large, une semaine laisse ~40 px par jour : les sessions y
      // sont illisibles. La vue Jour est la seule utilisable au bord du terrain.
      initialView: isMobile ? 'timeGridDay' : 'timeGridWeek',
      ...(initialDate ? { initialDate } : {}),
      firstDay: 1,
      headerToolbar,
      locale: 'fr',
      buttonText: { today: "Aujourd'hui", month: 'Mois', week: 'Semaine', day: 'Jour', timeGridThreeDay: '3 jours' },
      views: {
        timeGridThreeDay: { type: 'timeGrid', duration: { days: 3 } }
      },
      allDaySlot: false,
      // Recalculés à chaque changement de plage par applySlotWindow().
      slotMinTime: '17:00:00',
      slotMaxTime: '22:00:00',
      slotDuration: '00:30:00',
      slotLabelFormat: { hour: 'numeric', minute: '2-digit', meridiem: false, hour12: false },
      height: isMobile ? 'auto' : 'calc(100vh - 280px)',
      nowIndicator: true,
      stickyHeaderDates: true,
      eventOverlap: true,
      // Trois sessions simultanées ne tiennent pas dans une colonne d'1/7e de
      // semaine, quelle que soit la façon de les empiler. On les met côte à côte
      // plutôt que superposées, et on rend l'en-tête du jour cliquable : un clic
      // ouvre la vue Jour, où elles sont pleinement lisibles.
      slotEventOverlap: false,
      navLinks: true,
      scrollTime: '17:00:00',
      expandRows: true,
      dayMaxEvents: false,
      slotLabelClassNames: ['text-sm', 'text-gray-600', 'font-medium'],
      eventDisplay: 'block',
      dayHeaderFormat: isMobile ? { weekday: 'short', day: 'numeric', month: 'numeric' } : undefined,
      events: sessions,
      eventTimeFormat: { hour: "2-digit", minute: "2-digit", hour12: false },
      eventContent(arg) {
        const timeText = arg.timeText
        // Le titre abrégé n'a de sens que dans les colonnes étroites d'une vue
        // semaine sur mobile ; en vue Jour on a toute la largeur.
        const isNarrowColumn = window.matchMedia('(max-width: 640px)').matches && arg.view.type !== 'timeGridDay'
        const title = (isNarrowColumn ? (arg.event.extendedProps.shortTitle || arg.event.title) : arg.event.title) || ''
        const coach = arg.event.extendedProps.coachName || ''

        const root = document.createElement('div')
        root.className = 'fc-asmbv-card'

        const time = document.createElement('div')
        time.className = 'fc-asmbv-time'
        time.textContent = timeText

        const titleEl = document.createElement('div')
        titleEl.className = 'fc-asmbv-title'
        titleEl.textContent = title

        const coachEl = document.createElement('div')
        coachEl.className = 'fc-asmbv-coach'
        coachEl.textContent = coach

        root.appendChild(time)
        root.appendChild(titleEl)
        root.appendChild(coachEl)
        return { domNodes: [root] }
      },
      eventClick: (info) => {
        info.jsEvent.preventDefault()
        const id = info.event.id
        const url = new URL(`/sessions/${id}`, window.location.origin)
        const current = new URL(window.location.href)
        ;["view", "date", "terrain", "for_me"].forEach((key) => {
          const v = current.searchParams.get(key)
          if (v) url.searchParams.set(key, v)
        })
        url.searchParams.set("view", "calendar")
        if (window.Turbo?.visit) {
          window.Turbo.visit(url.toString())
        } else {
          window.location.assign(url.toString())
        }
      },

      eventDidMount(info) {
        const isMobile = window.matchMedia('(max-width: 640px)').matches

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
        const title = info.el.querySelector('.fc-asmbv-title')
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

        if (title) {
          title.style.fontSize = isMobile ? '11px' : '13px'
          title.style.fontWeight = '600'
          title.style.lineHeight = '1.2'
          title.style.flex = '1'
          title.style.minHeight = '0'
          // line-clamp 2 sur desktop, 1 sur mobile pour économiser l'espace
          title.style.display = '-webkit-box'
          title.style.webkitLineClamp = isMobile ? '1' : '2'
          title.style.webkitBoxOrient = 'vertical'
          title.style.overflow = 'hidden'
          title.style.textOverflow = 'ellipsis'
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
        info.el.style.minHeight = isMobile ? '40px' : '60px'
        // Sur mobile, hauteur maximale pour éviter les débordements
        if (isMobile) {
          info.el.style.maxHeight = '100%'
        }
      },

      datesSet: (info) => {
        this.updateDateQueryParamAndLinks(info.start)
        this.applySlotWindow(info.view.calendar, info)
        this.styleHeaderButtons(calendarEl)
      },
      viewDidMount: () => this.styleHeaderButtons(calendarEl)
    })

    // Expose for later filtering
    this.calendar = calendar
    this.sessions = sessions

    calendar.render()
    this.styleHeaderButtons(calendarEl)
    this.setupFilterTabsInteraction()
    this.applyFiltersFromUrl()
  }

  styleHeaderButtons(_calendarEl) {
    // Styling is handled by CSS (application.css .fc .fc-button rules).
  }

  updateDateQueryParamAndLinks(dateObj) {
    try {
      const ymd = this.formatDateToYMD(dateObj)
      const url = new URL(window.location.href)
      url.searchParams.set('date', ymd)
      url.searchParams.set('view', 'calendar')
      window.history.replaceState({}, '', url.toString())
      this.syncFilterLinksDate(ymd)
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

  syncFilterLinksDate(ymd) {
    try {
      ;['terrain-tabs', 'audience-tabs'].forEach((containerId) => {
        const container = document.getElementById(containerId)
        if (!container) return
        const anchors = container.querySelectorAll('a[href]')
        anchors.forEach((a) => {
          const url = new URL(a.href, window.location.origin)
          url.searchParams.set('date', ymd)
          a.href = url.toString()
        })
      })
    } catch (_) {
      // ignore
    }
  }

  setupFilterTabsInteraction() {
    const containers = ['terrain-tabs', 'audience-tabs']
      .map((id) => document.getElementById(id))
      .filter(Boolean)
    if (containers.length === 0) return

    containers.forEach((container) => {
      // Intercept clicks to avoid full page reload and keep calendar week
      container.addEventListener('click', (event) => {
        const anchor = event.target.closest('a')
        if (!anchor) return
        event.preventDefault()
        try {
          const url = new URL(anchor.href, window.location.origin)
          const selectedTerrain = url.searchParams.get('terrain') || ''
          const forMe = url.searchParams.get('for_me') === '1'
          this.applyFilters({ selectedTerrain, forMe })

          // Update URL (preserve date param already set by datesSet)
          const currentUrl = new URL(window.location.href)
          if (selectedTerrain) {
            currentUrl.searchParams.set('terrain', selectedTerrain)
          } else {
            currentUrl.searchParams.delete('terrain')
          }
          if (forMe) {
            currentUrl.searchParams.set('for_me', '1')
          } else {
            currentUrl.searchParams.delete('for_me')
          }
          window.history.replaceState({}, '', currentUrl.toString())
        } catch (_) {
          // ignore
        }
      })
    })

    // Keep in sync when navigating browser history
    window.addEventListener('popstate', () => this.applyFiltersFromUrl())
  }

  applyFiltersFromUrl() {
    try {
      const url = new URL(window.location.href)
      const selectedTerrain = url.searchParams.get('terrain') || ''
      const forMe = url.searchParams.get('for_me') === '1'
      this.applyFilters({ selectedTerrain, forMe })
    } catch (_) {
      // ignore
    }
  }

  applyFilters({ selectedTerrain, forMe }) {
    if (!this.calendar || !this.sessions) return

    // Filter events
    const filteredEvents = this.sessions.filter((eventData) => {
      const terrainMatches = selectedTerrain ? eventData.terrain === selectedTerrain : true
      const forMeMatches = forMe ? Boolean(eventData.forMe) : true
      return terrainMatches && forMeMatches
    })
    this.filteredSessions = filteredEvents
    this.calendar.removeAllEvents()
    this.calendar.addEventSource(filteredEvents)

    // La fenêtre horaire suit le filtrage : ne filtrer que le terrain 2 ne doit
    // pas laisser la grille ouverte sur les heures du terrain 1.
    const view = this.calendar.view
    this.applySlotWindow(this.calendar, { start: view.activeStart, end: view.activeEnd })

    // L'apparence des pastilles est entièrement pilotée par `aria-pressed`
    // (cf. _terrain_filter.html.erb et tailwind/application.css). On ne touche
    // pas aux classes ici : la variante rendue par le serveur resterait
    // appliquée à l'ancienne pastille active, et deux pastilles paraîtraient
    // sélectionnées en même temps.
    this.markPressed('terrain-tabs', (url) => (url.searchParams.get('terrain') || '') === (selectedTerrain || ''))
    this.markPressed('audience-tabs', (url) => (url.searchParams.get('for_me') === '1') === forMe)
  }

  markPressed(containerId, isActive) {
    const container = document.getElementById(containerId)
    if (!container) return

    container.querySelectorAll('a[data-filter-pill]').forEach((anchor) => {
      const url = new URL(anchor.href, window.location.origin)
      anchor.setAttribute('aria-pressed', String(isActive(url)))
    })
  }
}
