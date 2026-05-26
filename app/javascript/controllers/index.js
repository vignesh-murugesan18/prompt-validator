import { application } from "controllers/application"
import AnalysisPollController from "controllers/analysis_poll_controller"
import PromptFormController from "controllers/prompt_form_controller"

application.register("analysis-poll", AnalysisPollController)
application.register("prompt-form", PromptFormController)
