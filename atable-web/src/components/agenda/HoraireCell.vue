<template>
  <div class="ma-1 text-center">
    <v-row no-gutters justify="stretch" style="height: 100%">
      <template v-for="(meal, index) in props.meals" :key="index">
        <v-col cols="auto" v-if="index != 0" class="bg-black mx-1">
          <div style="width: 1px"></div>
        </v-col>

        <v-col align-self="stretch">
          <HoraireCellMeal
            :meal="meal"
            :menu="props.menus[meal.Meal.Menu]"
            :groups="groupsM"
            :show-expanded="props.meals.length <= 3"
            @swap-meals="(m1, m2) => emit('swapMeals', m1, m2)"
            @set-menu="(menu) => emit('setMenu', menu, meal)"
          ></HoraireCellMeal>
        </v-col>
      </template>
    </v-row>
  </div>
</template>

<script lang="ts" setup>
import {
  MealExt,
  MenuExt,
  IdMenu,
  Group,
  IdMeal,
  ResourceHeader,
} from "@/logic/api_gen";
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
  (ev: "setMenu", menu: ResourceHeader, meal: MealExt): void;
}>();

const groupsM = computed(() => groupMap(props.groups));
</script>

<style scoped></style>
