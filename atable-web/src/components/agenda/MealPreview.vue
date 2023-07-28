<template>
  <v-card density="compact" subtitle="Contenu du repas">
    <v-card-text class="pa-1 pt-0">
      <v-row v-if="items == null" justify="center"
        ><v-col cols="auto" class="mb-2">
          <v-progress-circular indeterminate></v-progress-circular> </v-col
      ></v-row>
      <div v-else>
        <v-chip
          v-for="(item, index) in items"
          :key="index"
          label
          :color="platColors[item.plat]"
          class="ma-1"
        >
          {{ item.title }}
        </v-chip>
      </div>
    </v-card-text>
  </v-card>
</template>

<script lang="ts" setup>
import { MealHeader } from "@/logic/api_gen";
import {
  MenuItem,
  controller,
  platColors,
  sortMenuContent,
} from "@/logic/controller";
import { onMounted } from "vue";
import { watch } from "vue";
import { ref } from "vue";

const props = defineProps<{
  meal: MealHeader;
}>();

const items = ref<MenuItem[] | null>(null);

onMounted(() => (console.log("mounted"), fetch()));

watch(props, (old) => {
  if (old.meal.Meal.Id != props.meal.Meal.Id) fetch();
});

async function fetch() {
  const res = await controller.MealsPreview({ idMeal: props.meal.Meal.Id });
  if (res === undefined) return;
  items.value = sortMenuContent(res);
}
</script>
