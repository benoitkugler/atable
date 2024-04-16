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
    :view-group-index="viewGroupIndex"
    @set-group-index="(v) => (viewGroupIndex = v)"
    @go-to="goToDay"
  ></view-week>
  <view-day
    v-else
    :offset="dayOffset"
    @back="goToWeek"
    @previous-day="goToDay(dayOffset - 1)"
    @next-day="goToDay(dayOffset + 1)"
  ></view-day>
</template>

<script lang="ts" setup>
import ViewDay from "@/components/agenda/ViewDay.vue";
import ViewWeek from "@/components/agenda/ViewWeek.vue";
import { Int } from "@/logic/api_gen";
import { controller } from "@/logic/controller";
import { onMounted } from "vue";
import { computed } from "vue";
import { ref } from "vue";
import { useRouter } from "vue-router";

const viewKind = computed<"week" | "day">(() =>
  router.currentRoute.value.query["dayOffset"] ? "day" : "week"
);
const dayOffset = computed(
  () => (Number(router.currentRoute.value.query["dayOffset"]) || 0) as Int
);
const viewGroupIndex = ref(-1);

// for mono group select the group, else the overall view
onMounted(() => {
  viewGroupIndex.value = controller.activeSejour?.Groups?.length == 1 ? 0 : -1;
});

const router = useRouter();
function goToDay(offset: number) {
  router.push({ name: "agenda", query: { dayOffset: offset } });
}
function goToWeek() {
  router.push({ name: "agenda" });
}
</script>
