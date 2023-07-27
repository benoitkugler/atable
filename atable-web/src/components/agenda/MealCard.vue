<template>
  <v-card
    elevation="0"
    variant="outlined"
    :color="props.meal.IsMenuEmpty ? 'grey' : 'secondary'"
    rounded
    class="mx-1 py-1"
  >
    <v-row no-gutters class="my-0" justify="space-between">
      <v-col cols="6" align-self="center" class="px-0">
        <v-card-subtitle class="mx-1">
          {{ formatHoraire(props.meal.Meal.Horaire) }}
        </v-card-subtitle>
      </v-col>
      <v-col cols="6" align-self="center" class="pl-0 pr-1">
        <v-chip
          size="small"
          v-if="
            props.sejourGroups.length == 1 && props.meal.Groups?.length == 1
          "
        >
          Tous
        </v-chip>
        <template v-else>
          <group-chip
            :group="group"
            v-for="(group, index) in props.meal.Groups"
            :key="index"
          ></group-chip>
        </template>
        <v-chip v-if="props.meal.Meal.AdditionalPeople != 0" size="small">
          {{ props.meal.Meal.AdditionalPeople >= 0 ? "+" : "" }}
          {{ props.meal.Meal.AdditionalPeople }}
        </v-chip>
      </v-col>
    </v-row>
  </v-card>
</template>

<script lang="ts" setup>
import { Group, MealHeader } from "@/logic/api_gen";
import { formatHoraire } from "@/logic/controller";
import GroupChip from "./GroupChip.vue";

const props = defineProps<{
  sejourGroups: Group[];
  meal: MealHeader;
}>();

const emit = defineEmits<{
  (event: "update:model-value", v: string): void;
}>();
</script>
