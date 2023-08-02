<template>
  <v-progress-linear v-if="data == null"></v-progress-linear>
  <table width="100%" v-else>
    <tr>
      <th v-for="i in 7" :key="i" style="border-bottom: 1px solid grey">
        <v-card elevation="0" @click="emit('goTo', totalOffset(i - 1))">
          {{ formatDate(dayForCol(i - 1)) }}
        </v-card>
      </th>
    </tr>
    <tr
      v-for="horaire in horairesItems"
      :key="horaire.value"
      :class="'bg-' + horaireColors[horaire.value]"
    >
      <td v-for="i in 7" :key="i">
        <v-card
          elevation="0"
          @click="emit('goTo', totalOffset(i - 1))"
          color="transparent"
        >
          <GroupHoraireCell
            :day-offset="totalOffset(i - 1)"
            :group="props.group"
            :menu="menuFor(horaire.value, i - 1)"
          ></GroupHoraireCell>
        </v-card>
      </td>
    </tr>
  </table>
</template>

<script lang="ts" setup>
import { Group, MealsForGroupOut, Horaire } from "@/logic/api_gen";
import {
  addDays,
  controller,
  formatDate,
  horaireColors,
  horairesItems,
} from "@/logic/controller";
import { computed } from "vue";
import { ref } from "vue";
import GroupHoraireCell from "./GroupHoraireCell.vue";
import { onMounted } from "vue";
import { watch } from "vue";

const props = defineProps<{
  offsetFirstDay: number;
  group: Group;
}>();

const emit = defineEmits<{
  (ev: "goTo", offset: number): void;
}>();

onMounted(loadMealsContent);
watch(() => props.group, loadMealsContent);

const sejour = ref(controller.activeSejour!);
const firstDay = computed(() => new Date(sejour.value.Sejour.Start));

const data = ref<MealsForGroupOut | null>(null);
async function loadMealsContent() {
  const res = await controller.MealsLoadForGroup({ idGroup: props.group.Id });
  if (res === undefined) return;
  data.value = res;
}

function totalOffset(i: number) {
  return props.offsetFirstDay + i;
}

function dayForCol(col: number) {
  return addDays(firstDay.value, totalOffset(col));
}

function menuFor(horaire: Horaire, colOffset: number) {
  const dayOffset = totalOffset(colOffset);
  const meal = Object.values(data.value?.Meals || {}).find(
    (meal) => meal.Horaire == horaire && meal.Jour == dayOffset
  );
  if (meal === undefined) return null;
  return (data.value?.Menus || {})[meal.Menu];
}
</script>

<style scoped></style>
