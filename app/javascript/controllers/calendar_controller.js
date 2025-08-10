import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Stimulus controller calendar connecté ✅")

    const waitForFullCalendar = () => {
      if (window.FullCalendar && window.FullCalendar.Calendar) {
        this.initializeCalendar()
      } else {
        setTimeout(waitForFullCalendar, 50)
      }
    }

    waitForFullCalendar()
  }

  initializeCalendar() {
    console.log("Initialisation du calendrier ✅")
    const calendarEl = this.element

    // Sessions data
    const sessions = JSON.parse(calendarEl.dataset.sessions)

    // Responsive header & view
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
      slotLabelFormat: {
        hour: 'numeric',
        minute: '2-digit',
        meridiem: false,
        hour12: false
      },
      height: '100%',
      contentHeight: 'auto',
      expandRows: true,
      dayMaxEvents: true,
      slotLabelClassNames: ['text-xs', 'text-gray-400'],
      eventDisplay: 'block',
      events: sessions,
      dayHeaderContent: function(arg) {
        const isToday = arg.date.toDateString() === new Date().toDateString()
        return {
          html: `
            <div class="flex flex-col items-center justify-center">
              <span class="text-xs uppercase tracking-wide">${arg.date.toLocaleDateString('fr-FR', { weekday: 'short' })}</span>
              <span class="text-lg font-bold ${isToday ? 'text-white bg-asmbv-red rounded-full px-2' : ''}">
                ${arg.date.getDate()}
              </span>
            </div>
          `
        }
      },
      eventTimeFormat: {
        hour: "2-digit",
        minute: "2-digit",
        hour12: false
      },
      eventDidMount: function(info) {
        info.el.style.backgroundColor = '#fee2e2'
        info.el.style.borderColor = '#ef4444'
        info.el.style.color = '#991b1b'
        info.el.style.borderRadius = '6px'
        info.el.style.fontWeight = '500'
        info.el.style.padding = '4px'
      },
      datesSet: () => this.styleHeaderButtons(calendarEl),
      viewDidMount: () => this.styleHeaderButtons(calendarEl)
    });

    // Terrain filtering (if present)
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
        'bg-asmbv-red',
        'text-white',
        'hover:bg-asmbv-red-dark',
        'border-0',
        'rounded-md',
        'px-3',
        'py-1.5',
        'text-sm',
        'font-semibold'
      )
    })

    // Resize title
    const titleEl = calendarEl.querySelector('.fc-toolbar-title')
    if (titleEl) {
      titleEl.classList.add('text-base', 'sm:text-lg')
    }

    const todayBtn = calendarEl.querySelector('.fc-today-button')
    if (todayBtn) {
      todayBtn.classList.add('bg-asmbv-red')
    }
  }
}
