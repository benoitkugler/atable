// Composables
import { createRouter, createWebHistory } from "vue-router";

import Sejours from "@/views/Sejours.vue";
import Agenda from "@/views/Agenda.vue";
import Library from "@/views/Library.vue";
import Order from "@/views/Order.vue";
import Settings from "@/views/Settings.vue";

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
  {
    path: "/order",
    name: "order",
    component: Order,
  },
  {
    path: "/library",
    name: "library",
    component: Library,
  },
  {
    path: "/settings",
    name: "settings",
    component: Settings,
  },
];

const router = createRouter({
  history: createWebHistory(process.env.BASE_URL),
  routes,
});

export default router;
