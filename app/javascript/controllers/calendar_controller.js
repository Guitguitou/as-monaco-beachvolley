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
    const closures = JSON.parse(calendarEl.dataset.closures || '[]')
    const initialDate = calendarEl.dataset.initialDate

    const isMobile = window.matchMedia('(max-width: 640px)').matches
    const headerToolbar = isMobile
      ? { left: 'prev,next', center: 'title', right: 'listWeek,timeGridDay' }
      : { left: 'prev,next today', center: 'title', right: 'dayGridMonth,timeGridWeek,timeGridThreeDay,timeGridDay' }

    const calendar = new window.FullCalendar.Calendar(calendarEl, {
      // Sur 375 px de large, une semaine en grille laisse ~40 px par jour, et la
      // vue Jour laisse surtout du vide entre deux créneaux. L'agenda de la
      // semaine liste les sessions jour par jour, lisibles d'un coup d'œil.
      initialView: isMobile ? 'listWeek' : 'timeGridWeek',
      ...(initialDate ? { initialDate } : {}),
      firstDay: 1,
      headerToolbar,
      locale: 'fr',
      buttonText: { today: "Aujourd'hui", month: 'Mois', week: 'Semaine', day: 'Jour', list: 'Agenda', timeGridThreeDay: '3 jours' },
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
      events: [...sessions, ...closures],
      eventTimeFormat: { hour: "2-digit", minute: "2-digit", hour12: false },
      noEventsContent: 'Aucune session cette semaine.',
      eventContent: (arg) => {
        // Fermetures de terrain : rendu par défaut (titre sur le fond hachuré).
        if (arg.event.display === 'background') return true

        const props = arg.event.extendedProps
        const status = { text: props.statusText, tone: props.statusTone }

        // Vue liste (mobile) : le titre, le terrain et une pastille de statut.
        // Un vrai lien : le contenu personnalisé remplace celui de FullCalendar,
        // qui portait le <a href> de la ligne. Sans lui, la ligne n'est plus
        // cliquable (eventClick ne se déclenche pas en vue liste).
        if (arg.view.type.startsWith('list')) {
          const root = document.createElement('a')
          root.href = arg.event.url
          root.dataset.turbo = 'false'
          root.className = 'block'
          root.append(`${arg.event.title} `)
          const terrain = document.createElement('span')
          terrain.className = 'fc-brand-terrain text-[11px]'
          terrain.textContent = props.terrainShort || ''
          const pill = document.createElement('span')
          pill.className = `fc-brand-pill ${status.tone}`
          pill.textContent = status.text
          root.append(terrain, pill)
          if (props.coachName) {
            const coach = document.createElement('span')
            coach.className = 'block text-xs text-gray-500'
            coach.textContent = props.coachName
            root.appendChild(coach)
          }
          return { domNodes: [root] }
        }

        // Le titre abrégé n'a de sens que dans les colonnes étroites d'une vue
        // semaine sur mobile ; en vue Jour on a toute la largeur.
        const isNarrowColumn = window.matchMedia('(max-width: 640px)').matches && arg.view.type !== 'timeGridDay'
        const title = (isNarrowColumn ? (props.shortTitle || arg.event.title) : arg.event.title) || ''

        const root = document.createElement('div')
        root.className = 'fc-brand-card flex flex-col h-full overflow-hidden gap-0.5'

        const terrain = document.createElement('span')
        terrain.className = 'fc-brand-terrain mr-1'
        terrain.textContent = props.terrainShort || ''

        const titleEl = document.createElement('div')
        titleEl.className = 'fc-brand-title text-xs sm:text-[13px] font-semibold leading-tight line-clamp-2'
        titleEl.append(terrain, title)

        const statusEl = document.createElement('div')
        statusEl.className = 'text-[11px] font-medium opacity-90 truncate'
        statusEl.textContent = status.text

        // Dans une grille horaire, la position de l'événement donne déjà l'heure :
        // la répéter mangeait la moitié d'une colonne étroite. En vue mois, rien
        // d'autre ne situe l'heure, on la garde.
        if (!arg.view.type.startsWith('timeGrid')) {
          const time = document.createElement('div')
          time.className = 'text-[11px] opacity-90 tabular-nums'
          time.textContent = arg.timeText
          root.appendChild(time)
        }
        root.appendChild(titleEl)
        if (props.coachName) {
          const coachEl = document.createElement('div')
          coachEl.className = 'text-[11px] opacity-80 truncate'
          coachEl.textContent = props.coachName
          root.appendChild(coachEl)
        }
        root.appendChild(statusEl)

        // Jauge de remplissage : visible sans ouvrir la session.
        if (props.maxPlayers) {
          const fill = document.createElement('div')
          fill.className = `fc-brand-fill${status.tone === 'hot' ? ' is-hot' : ''}`
          const bar = document.createElement('span')
          bar.style.width = `${Math.min(100, Math.round((props.confirmedCount / props.maxPlayers) * 100))}%`
          fill.appendChild(bar)
          root.appendChild(fill)
        }

        return { domNodes: [root] }
      },
      eventClick: (info) => {
        // Le lien du titre (vue liste) porte data-turbo="false" : on empêche ici
        // la navigation du navigateur et on ouvre l'aperçu à la place.
        info.jsEvent.preventDefault()
        const id = info.event.id
        if (!id) return
        this.openPreview(id)
      },

      eventDidMount(info) {
        if (info.event.display === 'background') {
          info.el.title = info.event.title
          return
        }
        if (info.view.type.startsWith('list')) return

        const isMobile = window.matchMedia('(max-width: 640px)').matches
        info.el.style.borderRadius = '8px'
        info.el.style.padding = isMobile ? '3px 4px' : '5px 7px'
        info.el.style.overflow = 'hidden'
        info.el.style.minHeight = isMobile ? '40px' : '60px'
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
    this.closures = closures

    calendar.render()
    this.styleHeaderButtons(calendarEl)
    this.setupFilterTabsInteraction()
    this.applyFiltersFromUrl()
  }

  // URL d'une session qui garde le contexte du calendrier (semaine, filtres),
  // pour que « Retour » et les redirections après inscription y ramènent.
  sessionUrl(id, suffix = '') {
    const url = new URL(`/sessions/${id}${suffix}`, window.location.origin)
    const current = new URL(window.location.href)
    ;['date', 'terrain', 'for_me'].forEach((key) => {
      const v = current.searchParams.get(key)
      if (v) url.searchParams.set(key, v)
    })
    url.searchParams.set('view', 'calendar')
    return url.toString()
  }

  // Aperçu en modale (Turbo Frame chargé à la demande). Sans la modale sur la
  // page, on retombe sur la fiche complète.
  openPreview(id) {
    const wrapper = document.getElementById('session-preview')
    const dialog = wrapper?.querySelector('dialog')
    const frame = wrapper?.querySelector('turbo-frame#session_preview')
    if (!dialog || !frame) {
      window.Turbo?.visit ? window.Turbo.visit(this.sessionUrl(id)) : window.location.assign(this.sessionUrl(id))
      return
    }
    frame.innerHTML = '<p class="py-8 text-center text-sm text-gray-500">Chargement…</p>'
    frame.src = this.sessionUrl(id, '/preview')
    dialog.showModal()
  }

  styleHeaderButtons(_calendarEl) {
    // Styling is handled by CSS (application.css .fc .fc-button rules).
  }

  updateDateQueryParamAndLinks(dateObj) {
    // Masqué (mobile), le calendrier ne pilote pas l'URL : c'est l'agenda
    // mobile qui choisit le jour, et le ramener au lundi le perdrait.
    if (!this.element.offsetParent) return
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
          // Une pastille ne change que son propre filtre : son href, rendu au
          // chargement, ignore les filtres choisis depuis sans rechargement.
          const param = anchor.dataset.filterPill === 'audience' ? 'for_me' : 'terrain'
          const value = new URL(anchor.href, window.location.origin).searchParams.get(param)

          // Update URL (preserve date param already set by datesSet)
          const currentUrl = new URL(window.location.href)
          if (value) {
            currentUrl.searchParams.set(param, value)
          } else {
            currentUrl.searchParams.delete(param)
          }
          window.history.replaceState({}, '', currentUrl.toString())
          this.applyFiltersFromUrl()
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
      const terrainMatches = selectedTerrain ? String(eventData.terrain) === String(selectedTerrain) : true
      const forMeMatches = forMe ? Boolean(eventData.forMe) : true
      return terrainMatches && forMeMatches
    })
    this.filteredSessions = filteredEvents
    const closures = (this.closures || []).filter((c) => !selectedTerrain || String(c.terrain) === String(selectedTerrain))
    this.calendar.removeAllEvents()
    this.calendar.addEventSource([...filteredEvents, ...closures])

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
