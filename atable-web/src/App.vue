<template>
  <v-app>
    <v-navigation-drawer rail expand-on-hover v-if="rc.idUser != null">
      <v-list>
        <v-list-item
          :prepend-avatar="logo"
          :title="rc.pseudo"
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
        <v-tooltip text="Bibliothèque de menus et recettes">
          <template v-slot:activator="{ isActive, props }">
            <v-list-item
              v-on="{ isActive }"
              v-bind="props"
              color="secondary"
              title="Bibliothèque"
              prepend-icon="mdi-notebook-heart-outline"
              :to="{ name: 'library' }"
            >
            </v-list-item>
          </template>
        </v-tooltip>
        <v-tooltip text="Ingrédients requis et commandes.">
          <template v-slot:activator="{ isActive, props }">
            <v-list-item
              v-on="{ isActive }"
              v-bind="props"
              color="secondary"
              title="Commandes"
              prepend-icon="mdi-cart"
              :to="{ name: 'order' }"
            >
            </v-list-item>
          </template>
        </v-tooltip>
        <v-divider></v-divider>
        <v-list-item
          color="secondary"
          title="Se déconnecter"
          prepend-icon="mdi-logout"
          @click="rc.idUser = null"
        >
        </v-list-item>
      </v-list>
    </v-navigation-drawer>

    <v-app-bar color="primary" density="comfortable">
      <v-app-bar-title>
        {{ title }}
      </v-app-bar-title>
    </v-app-bar>

    <v-main v-if="rc.idUser != null">
      <router-view />

      <success-snackbar
        :messages="messages.messages"
        @close="messages.clearMessages()"
      ></success-snackbar>
      <error-snackbar :error="error"></error-snackbar>
    </v-main>
    <v-main v-else>
      <loggin @loggin="onLoggin"></loggin>
    </v-main>
  </v-app>
</template>

<script lang="ts" setup>
import logo from "@/assets/logo.svg";
import { computed } from "vue";
import { useRoute } from "vue-router";

import { Error, Messages, controller } from "@/logic/controller";
import SuccessSnackbar from "./components/SuccessSnackbar.vue";
import ErrorSnackbar from "./components/ErrorSnackbar.vue";
import { ref } from "vue";
import { reactive } from "vue";
import Loggin from "./views/Loggin.vue";
import { IdUser } from "./logic/api_gen";

const version = process.env.VERSION;

const rc = reactive(controller);
const navSubtitle = computed(() => `À table - Version ${version || ""}`);

const route = useRoute();

const error = ref<Error>({ Kind: "", HTML: "" });

const title = computed(() => {
  if (rc.idUser == null) return "À table";
  switch (route.name) {
    case "sejours":
      return "Séjours et groupes";
    case "agenda": {
      const sejour = controller.activeSejour;
      if (sejour == null) return "Organisation d'un séjour";
      return `Organisation du séjour courant : ${sejour.Sejour.Name}`;
    }
    case "order": {
      const sejour = controller.activeSejour;
      if (sejour == null) return "Bilan des ingrédients et commandes";
      return `Bilan des ingrédients et commandes pour le séjour courant : ${sejour.Sejour.Name}`;
    }
    case "library":
      return "Bibliothèque de menus favoris et recettes";
    default:
      return "";
  }
});

function onLoggin(idUser: IdUser, token: string, pseudo: string) {
  rc.setLog(idUser, token, pseudo);
  rc.showMessage(`Bon retour parmi nous, ${pseudo}`);
}

// setup notifications callbacks
const messages = ref(new Messages());

controller.onError = (k, m) => (error.value = { Kind: k, HTML: m });
controller.showMessage = (m) => messages.value.addMessage(m);
</script>
