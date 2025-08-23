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
      ? { left: 'prev,next today', center: 'title', right: 'dayGridMonth,timeGridWeek,timeGridDay' }
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
      slotLabelFormat: { hour: 'numeric', minute: '2-digit', meridiem: false, hour12: false },
      height: isMobile ? 'auto' : '100%',
      nowIndicator: true,
      stickyHeaderDates: true,
      scrollTime: isMobile ? '07:30:00' : '08:00:00',
      expandRows: true,
      dayMaxEvents: true,
      slotLabelClassNames: ['text-xs', 'text-gray-400'],
      eventDisplay: 'block',
      dayHeaderFormat: isMobile ? { weekday: 'short', day: 'numeric', month: 'numeric' } : undefined,
      events: sessions,
      eventTimeFormat: { hour: "2-digit", minute: "2-digit", hour12: false },

      eventDidMount: function(info) {
        // couleurs injectées depuis Rails
        info.el.style.backgroundColor = info.event.extendedProps.backgroundColor
        info.el.style.borderColor     = info.event.extendedProps.borderColor
        info.el.style.color           = info.event.extendedProps.textColor
        info.el.style.borderRadius    = '6px'
        info.el.style.fontWeight      = '500'
        info.el.style.padding         = isMobile ? '2px' : '4px'
        info.el.style.fontSize        = isMobile ? '0.75rem' : '0.875rem'
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
