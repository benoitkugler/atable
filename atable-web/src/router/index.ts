// Composables
import { createRouter, createWebHistory } from "vue-router";

import Sejours from "@/views/Sejours.vue";
import Agenda from "@/views/Agenda.vue";

const routes = [
  {
    path: "/",
    name: "sejours",
    component: Sejours,
  },
  {
    path: "/agenda",
    name: "agenda",
    component: Agenda,
  },
];

const router = createRouter({
  history: createWebHistory(process.env.BASE_URL),
  routes,
});

export default router;
