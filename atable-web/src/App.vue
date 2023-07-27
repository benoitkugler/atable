<template>
  <v-app>
    <v-navigation-drawer rail expand-on-hover>
      <v-list>
        <v-list-item
          :prepend-avatar="logo"
          title="À table - Intendance"
          :subtitle="navSubtitle"
        ></v-list-item>
      </v-list>

      <v-divider></v-divider>

      <v-list>
        <v-tooltip text="Vue d'ensemble des séjours et des groupes.">
          <template v-slot:activator="{ isActive, props }">
            <v-list-item
              v-on="{ isActive }"
              v-bind="props"
              title="Séjours"
              prepend-icon="mdi-account-group"
              color="secondary"
              :to="{ name: 'sejours' }"
            >
            </v-list-item>
          </template>
        </v-tooltip>
        <v-tooltip text="Organisation du séjour courant.">
          <template v-slot:activator="{ isActive, props }">
            <v-list-item
              v-on="{ isActive }"
              v-bind="props"
              color="secondary"
              title="Agenda"
              prepend-icon="mdi-calendar-month"
              :to="{ name: 'agenda' }"
            >
            </v-list-item>
          </template>
        </v-tooltip>
      </v-list>
    </v-navigation-drawer>

    <v-app-bar color="primary" density="comfortable">
      <v-app-bar-title>
        {{ title }}
      </v-app-bar-title>
    </v-app-bar>

    <v-main>
      <router-view />

      <success-snackbar
        :messages="messages.messages"
        @close="messages.clearMessages()"
      ></success-snackbar>
      <error-snackbar :error="error"></error-snackbar>
    </v-main>
  </v-app>
</template>

<script lang="ts" setup>
import logo from "@/assets/logo.png";
import { computed } from "vue";
import { useRoute } from "vue-router";

import { Error, Messages, controller } from "@/logic/controller";
import SuccessSnackbar from "./components/SuccessSnackbar.vue";
import ErrorSnackbar from "./components/ErrorSnackbar.vue";
import { ref } from "vue";

const version = process.env.VERSION;

const navSubtitle = computed(() => `Version ${version || ""}`);

const route = useRoute();

const error = ref<Error>({ Kind: "", HTML: "" });

const title = computed(() => {
  switch (route.name) {
    case "sejours":
      return "Séjours et groupes";
    case "agenda": {
      const sejour = controller.activeSejour;
      if (sejour == null) return "Organisation d'un séjour";
      return `Organisation du séjour courant : ${sejour.Sejour.Name}`;
    }
    default:
      return "";
  }
});

// setup notifications callbacks
const messages = ref(new Messages());

controller.onError = (k, m) => (error.value = { Kind: k, HTML: m });
controller.showMessage = (m) => messages.value.addMessage(m);
</script>
