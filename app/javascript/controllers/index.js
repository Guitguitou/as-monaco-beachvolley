// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import SessionFormController from 'controllers/session_form_controller';
application.register('session-form', SessionFormController);
eagerLoadControllersFrom("controllers", application)
