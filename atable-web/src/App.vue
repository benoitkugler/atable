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
              v-on="isActive"
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
              v-on="isActive"
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
    </v-main>
  </v-app>
</template>

<script lang="ts" setup>
import logo from "@/assets/logo.png";
import { computed } from "vue";
import { useRoute } from "vue-router";

import { controller } from "@/logic/controller";

const version = process.env.VERSION;

const navSubtitle = computed(() => `Version ${version || ""}`);

const route = useRoute();

const title = computed(() => {
  switch (route.name) {
    case "sejours":
      return "Séjours et groupes";
    case "agenda":
      return `Organisation du séjour courant: ${controller.sejourCourant}`;
    default:
      return "";
  }
});
</script>
