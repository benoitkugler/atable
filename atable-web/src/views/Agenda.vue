<template>
  <v-responsive
    class="align-center text-center fill-height"
    v-if="controller.activeSejour == null"
  >
    <v-alert class="mx-2">
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
  </v-responsive>
  <view-week
    v-else-if="viewKind == 'week'"
    @go-to="
      (of) => {
        dayOffset = of;
        viewKind = 'day';
      }
    "
  ></view-week>
  <view-day
    v-else
    :offset="dayOffset"
    @back="viewKind = 'week'"
    @previous-day="dayOffset = dayOffset - 1"
    @next-day="dayOffset = dayOffset + 1"
  ></view-day>
</template>

<script lang="ts" setup>
import ViewDay from "@/components/agenda/ViewDay.vue";
import ViewWeek from "@/components/agenda/ViewWeek.vue";
import { controller } from "@/logic/controller";
import { ref } from "vue";

const viewKind = ref<"week" | "day">("week");
const dayOffset = ref(0);
</script>
