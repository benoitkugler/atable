<template>
  <v-responsive class="align-center text-center fill-height">
    <v-alert v-if="controller.activeSejour == null" class="mx-2">
      <v-row>
        <v-col align-self="center">
          Merci de sélectionner (ou de créer) un séjour
        </v-col>
        <v-col>
          <v-btn class="my-2" :to="{ name: 'sejours' }"
            >Aller aux séjours</v-btn
          >
        </v-col>
      </v-row>
    </v-alert>
    <week-view
      v-else-if="viewKind == 'week'"
      @go-to="
        (of) => {
          viewKind = 'day';
          dayOffset = of;
        }
      "
    ></week-view>
    <day-view v-else :offset="dayOffset" @back="viewKind = 'week'"></day-view>
  </v-responsive>
</template>

<script lang="ts" setup>
import DayView from "@/components/agenda/DayView.vue";
import WeekView from "@/components/agenda/WeekView.vue";
import { controller } from "@/logic/controller";
import { ref } from "vue";

const viewKind = ref<"week" | "day">("week");
const dayOffset = ref(0);
</script>
