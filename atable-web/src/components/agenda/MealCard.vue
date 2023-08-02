<template>
  <v-card
    elevation="0"
    :color="props.meal.IsMenuEmpty ? 'orange-lighten-4' : undefined"
    rounded
    class="mx-1"
  >
    <v-row no-gutters class="my-0" justify="space-between">
      <v-tooltip content-class="px-1" :eager="false" open-delay="100">
        <template v-slot:activator="{ isActive, props: innerProps }">
          <v-col
            v-on="{ isActive }"
            v-bind="innerProps"
            cols="5"
            align-self="center"
            :class="
              'text-center px-0  py-1 rounded bg-' +
              horaireColors[props.meal.Meal.Horaire]
            "
          >
            <v-card-subtitle class="mx-1 px-1">
              {{ formatHoraire(props.meal.Meal.Horaire) }}
            </v-card-subtitle>
          </v-col>
        </template>
        <MealPreview :meal="meal"></MealPreview>
      </v-tooltip>

      <v-col cols="7" align-self="center" class="pl-0 pr-1 text-right">
        <group-chip
          :is-mono-group="
            props.sejourGroups.length == 1 && props.meal.Groups?.length == 1
          "
          small
          :group="group"
          v-for="(group, index) in props.meal.Groups"
          :key="index"
        ></group-chip>
        <add-people-chip
          :people="props.meal.Meal.AdditionalPeople"
          small
        ></add-people-chip>
      </v-col>
    </v-row>
  </v-card>
</template>

<script lang="ts" setup>
import { Group, MealHeader } from "@/logic/api_gen";
import { formatHoraire, horaireColors } from "@/logic/controller";
import GroupChip from "./GroupChip.vue";
import AddPeopleChip from "./AddPeopleChip.vue";
import MealPreview from "./MealPreview.vue";

const props = defineProps<{
  sejourGroups: Group[];
  meal: MealHeader;
}>();

const emit = defineEmits<{
  (event: "update:model-value", v: string): void;
}>();
</script>
