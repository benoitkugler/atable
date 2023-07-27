<template>
  <v-card @click="emit('goTo')">
    <v-row justify="start" no-gutters class="pa-0 my-2">
      <v-col cols="auto">
        <v-card-title>{{ formatDate(props.date) }}</v-card-title>
      </v-col>
    </v-row>
    <v-card-text class="pa-0 mb-">
      <v-row no-gutters>
        <v-col v-if="!meals.length" class="my-2">
          <i>Aucun repas.</i>
        </v-col>
        <v-col
          cols="12"
          v-for="(meal, index) in meals"
          :key="index"
          class="pa-0 my-1"
        >
          <MealCard :meal="meal" :sejour-groups="props.sejourGroups"></MealCard>
        </v-col>
      </v-row>
    </v-card-text>
  </v-card>
</template>

<script lang="ts" setup>
import { Group, MealHeader } from "@/logic/api_gen";
import MealCard from "./MealCard.vue";
import { copy, formatDate } from "@/logic/controller";
import { computed } from "vue";

const props = defineProps<{
  date: Date;
  meals: MealHeader[];
  sejourGroups: Group[];
}>();

const emit = defineEmits<{
  (event: "goTo"): void;
}>();

const meals = computed(() => {
  const out = copy(props.meals);
  out.sort((a, b) => a.Meal.Horaire - b.Meal.Horaire);
  return out;
});
</script>
