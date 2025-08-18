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
      ? { left: 'prev,next today', center: 'title', right: 'timeGridDay,timeGridWeek,dayGridMonth' }
      : { left: 'prev,next today', center: 'title', right: 'dayGridMonth,timeGridWeek,timeGridDay' }

    const calendar = new window.FullCalendar.Calendar(calendarEl, {
      initialView: 'timeGridWeek',
      firstDay: 1,
      headerToolbar,
      locale: 'fr',
      allDaySlot: false,
      slotMinTime: '08:00:00',
      slotMaxTime: '23:00:00',
      slotLabelFormat: { hour: 'numeric', minute: '2-digit', meridiem: false, hour12: false },
      height: '100%',
      expandRows: true,
      dayMaxEvents: true,
      slotLabelClassNames: ['text-xs', 'text-gray-400'],
      eventDisplay: 'block',
      events: sessions,
      eventTimeFormat: { hour: "2-digit", minute: "2-digit", hour12: false },

      eventDidMount: function(info) {
        // couleurs injectées depuis Rails
        info.el.style.backgroundColor = info.event.extendedProps.backgroundColor
        info.el.style.borderColor     = info.event.extendedProps.borderColor
        info.el.style.color           = info.event.extendedProps.textColor
        info.el.style.borderRadius    = '6px'
        info.el.style.fontWeight      = '500'
        info.el.style.padding         = '4px'
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
    const buttons = calendarEl.querySelectorAll('.fc .fc-toolbar-chunk .fc-button')
    buttons.forEach(btn => {
      btn.classList.add(
        'bg-asmbv-red', 'text-white', 'hover:bg-asmbv-red-dark',
        'border-0', 'rounded-md', 'px-3', 'py-1.5', 'text-sm', 'font-semibold'
      )
    })
  }
}
