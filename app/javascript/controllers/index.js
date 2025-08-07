// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import SessionFormController from 'controllers/session_form_controller';
application.register('session-form', SessionFormController);
import CalendarController from "controllers/calendar_controller"
application.register("calendar", CalendarController)
import AdminSidebarController from "controllers/admin_sidebar_controller"
application.register("admin-sidebar", AdminSidebarController)
import SessionModalController from "controllers/session_modal_controller"
application.register("session-modal", SessionModalController)
import SidebarController from "controllers/sidebar_controller"
application.register("sidebar", SidebarController)
eagerLoadControllersFrom("controllers", application)
