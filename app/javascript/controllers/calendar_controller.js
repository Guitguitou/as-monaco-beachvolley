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

    const calendar = new window.FullCalendar.Calendar(calendarEl, {
      initialView: "timeGridWeek",
      firstDay: 1,
      headerToolbar: {
        left: "prev,next today",
        center: "title",
        right: "dayGridMonth,timeGridWeek,timeGridDay"
      },
      locale: "fr",
      allDaySlot: false,
      slotMinTime: "08:00:00",
      slotMaxTime: "23:00:00",
      slotLabelFormat: {
        hour: 'numeric',
        minute: '2-digit',
        meridiem: false,
        hour12: false
      },
      height: "100%",
      contentHeight: "auto",
      expandRows: true,
      // slotDuration: "00:30:00",
      slotLabelClassNames: ["text-xs", "text-gray-400"],
      eventDisplay: "block",
      events: JSON.parse(calendarEl.dataset.sessions),
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
        info.el.style.backgroundColor = '#fee2e2'; // rouge très clair
        info.el.style.borderColor = '#ef4444';     // rouge principal
        info.el.style.color = '#991b1b';           // rouge foncé pour texte
        info.el.style.borderRadius = '6px';
        info.el.style.fontWeight = '500';
        info.el.style.padding = '4px';
      }
    });

    
const filterSelect = document.getElementById("terrain-filter")
if (filterSelect) {
  filterSelect.addEventListener("change", (event) => {
    const selectedTerrain = event.target.value
    calendar.removeAllEvents()

    const filteredEvents = selectedTerrain
      ? sessions.filter(e => e.terrain === selectedTerrain)
      : sessions

    calendar.addEventSource(filteredEvents)
  })
}

    calendar.render()
  }
}
