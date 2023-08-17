<template>
  <div class="ma-1 text-center">
    <v-row no-gutters justify="space-evenly">
      <template v-for="(meal, index) in props.meals" :key="index">
        <v-col cols="auto" v-if="index != 0" class="bg-black">
          <div style="width: 1px"></div>
        </v-col>

        <v-col cols="auto" align-self="center">
          <HoraireCellMeal
            :meal="meal"
            :menu="props.menus[meal.Meal.Menu]"
            :groups="groupsM"
            :show-expanded="props.meals.length <= 3"
            @swap-meals="(m1, m2) => emit('swapMeals', m1, m2)"
          ></HoraireCellMeal>
        </v-col>
      </template>
    </v-row>
  </div>
</template>

<script lang="ts" setup>
import { MealExt, MenuExt, IdMenu, Group, IdMeal } from "@/logic/api_gen";
import { groupMap } from "@/logic/controller";
import { computed } from "vue";
import HoraireCellMeal from "./HoraireCellMeal.vue";

const props = defineProps<{
  meals: MealExt[];
  menus: { [key: IdMenu]: MenuExt };
  groups: Group[];
}>();

const emit = defineEmits<{
  (ev: "swapMeals", m1: IdMeal, m2: IdMeal): void;
}>();

const groupsM = computed(() => groupMap(props.groups));
</script>

<style scoped></style>
