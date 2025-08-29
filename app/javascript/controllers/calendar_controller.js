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

    const isMobile = window.matchMedia('(max-width: 640px)').matches
    const headerToolbar = isMobile
      ? { left: 'prev,next', center: 'title', right: 'timeGridWeek,timeGridDay' }
      : { left: 'prev,next today', center: 'title', right: 'dayGridMonth,timeGridWeek,timeGridThreeDay,timeGridDay' }

    const calendar = new window.FullCalendar.Calendar(calendarEl, {
      initialView: isMobile ? 'timeGridWeek' : 'timeGridWeek',
      firstDay: 1,
      headerToolbar,
      locale: 'fr',
      buttonText: { today: "Aujourd'hui", month: 'Mois', week: 'Semaine', day: 'Jour', timeGridThreeDay: '3 jours' },
      views: {
        timeGridThreeDay: { type: 'timeGrid', duration: { days: 3 } }
      },
      allDaySlot: false,
      slotMinTime: '08:00:00',
      slotMaxTime: '23:00:00',
      slotDuration: '00:30:00',
      slotLabelFormat: { hour: 'numeric', minute: '2-digit', meridiem: false, hour12: false },
      height: isMobile ? 'auto' : '100%',
      nowIndicator: true,
      stickyHeaderDates: true,
      eventOverlap: true,
      scrollTime: isMobile ? '07:30:00' : '08:00:00',
      expandRows: true,
      dayMaxEvents: true,
      slotLabelClassNames: ['text-xs', 'text-gray-400'],
      eventDisplay: 'block',
      dayHeaderFormat: isMobile ? { weekday: 'short', day: 'numeric', month: 'numeric' } : undefined,
      events: sessions,
      eventTimeFormat: { hour: "2-digit", minute: "2-digit", hour12: false },
      eventContent(arg) {
        const isMobile = window.matchMedia('(max-width: 640px)').matches
        const timeText = arg.timeText
        const title = (isMobile ? (arg.event.extendedProps.shortTitle || arg.event.title) : arg.event.title) || ''
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
      eventDidMount(info) {
        const isMobile = window.matchMedia('(max-width: 640px)').matches
        info.el.style.backgroundColor = info.event.extendedProps.backgroundColor
        info.el.style.borderColor = info.event.extendedProps.borderColor
        info.el.style.color = info.event.extendedProps.textColor

        // style "carte"
        info.el.style.borderRadius = '10px'
        info.el.style.padding = isMobile ? '6px' : '8px'
        info.el.style.boxShadow = '0 1px 0 rgba(0,0,0,0.06)'
        info.el.style.fontWeight = '500'
        info.el.style.whiteSpace = 'normal'
        info.el.style.overflow = 'visible'
        info.el.style.display = 'block'

        // typographies fines via classes utilitaires
        const card = info.el.querySelector('.fc-asmbv-card')
        const time = info.el.querySelector('.fc-asmbv-time')
        const title = info.el.querySelector('.fc-asmbv-title')
        const coach = info.el.querySelector('.fc-asmbv-coach')

        time.style.fontSize = isMobile ? '11px' : '12px'
        time.style.opacity = '0.9'
        time.style.lineHeight = '1.1'

        title.style.fontSize = isMobile ? '12px' : '13px'
        title.style.fontWeight = '600'
        title.style.lineHeight = '1.2'
        // line-clamp 2
        title.style.display = '-webkit-box'
        title.style.webkitLineClamp = '2'
        title.style.webkitBoxOrient = 'vertical'
        title.style.overflow = 'hidden'

        coach.style.fontSize = isMobile ? '11px' : '12px'
        coach.style.opacity = '0.9'
        coach.style.lineHeight = '1.1'

        // min height douce pour les events courts
        info.el.style.minHeight = isMobile ? '44px' : '48px'
      },

      datesSet: () => this.styleHeaderButtons(calendarEl),
      viewDidMount: () => this.styleHeaderButtons(calendarEl)
    })

    // Filtrage terrain
    const filterSelect = document.getElementById('terrain-filter')
    if (filterSelect) {
      filterSelect.addEventListener('change', (event) => {
        const selectedTerrain = event.target.value
        calendar.removeAllEvents()
        const filteredEvents = selectedTerrain
          ? sessions.filter(e => e.terrain === selectedTerrain)
          : sessions
        calendar.addEventSource(filteredEvents)
      })
    }

    calendar.render()
    this.styleHeaderButtons(calendarEl)
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
}
