/**
 * plugins/vuetify.ts
 *
 * Framework documentation: https://vuetifyjs.com`
 */

// Styles
import "@mdi/font/css/materialdesignicons.css";
import "vuetify/styles";

// Composables
import { createVuetify } from "vuetify";
import { fr } from "vuetify/locale";

// https://vuetifyjs.com/en/introduction/why-vuetify/#feature-guides
export default createVuetify({
  locale: { locale: "fr", messages: { fr } },
  theme: {
    themes: {
      light: {
        colors: {
          primary: "#f5e238",
          secondary: "#3c9fc9",
          accent: "#e8d52c",
        },
      },
    },
  },
});
