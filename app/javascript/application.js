// Entry point for the build script. Imports Turbo and Stimulus controllers.
import "@hotwired/turbo-rails"
import "controllers"
import * as ActiveStorage from "@rails/activestorage"

ActiveStorage.start()
