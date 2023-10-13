<template>
  <v-card
    height="100%"
    :elevation="isDraggingOver ? 2 : 0"
    color="transparent"
    class="px-2 py-1 text-body-2"
    style="cursor: grab"
    :draggable="true"
    @dragstart="(ev) => onDragstart(ev)"
    @dragover="onDragover"
    @dragleave="isDraggingOver = false"
    @drop="(ev) => onDrop(ev)"
  >
    <v-tooltip
      location="bottom"
      content-class="ma-0 pa-0 rounded-lg"
      :disabled="props.groups.size <= 1"
    >
      <template v-slot:activator="{ isActive, props: innerProps }">
        <div v-on="{ isActive }" v-bind="innerProps">
          <!-- visually optimize common cases -->
          <template v-if="props.showExpanded">
            <small v-if="!content.length" class="text-grey">Menu vide.</small>
            <div v-for="(item, indexI) in content" :key="indexI">
              {{ item.title }}
            </div>
          </template>
          <!-- too many meals : use a compact view -->
          <template v-else> Repas {{ props.meal.Meal.Id }} </template>
        </div>
      </template>
      <v-card class="pa-0 ma-0" rounded="lg">
        <v-card-text class="pa-1 ma-0">
          <i v-if="!props.meal.Groups?.length">Aucun groupe</i>
          <GroupChip
            v-for="group in props.meal.Groups"
            :key="group.IdGroup"
            :group="props.groups.get(group.IdGroup)!"
            :is-mono-group="false"
            :is-hovering="false"
            :small="false"
          >
          </GroupChip>
        </v-card-text>
      </v-card>
    </v-tooltip>
  </v-card>
</template>

<script lang="ts" setup>
import type {
  Group,
  IdGroup,
  IdMeal,
  MealExt,
  MenuExt,
  ResourceHeader,
} from "@/logic/api_gen";
import { sortMenuContent } from "@/logic/controller";
import { computed } from "vue";
import GroupChip from "./GroupChip.vue";
import { ref } from "vue";

const props = defineProps<{
  meal: MealExt;
  menu: MenuExt;
  showExpanded: boolean;
  groups: Map<IdGroup, Group>;
}>();

const emit = defineEmits<{
  (ev: "swapMeals", m1: IdMeal, m2: IdMeal): void;
  (ev: "setMenu", menu: ResourceHeader): void;
}>();

const content = computed(() => sortMenuContent(props.menu));

function onDragstart(event: DragEvent) {
  event.dataTransfer?.setData(
    "json/swap-meals",
    JSON.stringify(props.meal.Meal.Id)
  );
}

const isDraggingOver = ref(false);
function onDragover(event: DragEvent) {
  const types = event.dataTransfer?.types;
  if (types?.includes("json/swap-meals") || types?.includes("json/add-menu")) {
    event.preventDefault();
    event.dataTransfer!.dropEffect = "move";
    isDraggingOver.value = true;
  }
}

function onDrop(event: DragEvent) {
  isDraggingOver.value = false;

  const types = event.dataTransfer?.types;
  if (types?.includes("json/swap-meals")) {
    const idSource = JSON.parse(
      event.dataTransfer?.getData("json/swap-meals") || ""
    ) as number;
    const idTarget = props.meal.Meal.Id;
    if (idSource == idTarget) return;
    emit("swapMeals", idSource, idTarget);
  } else {
    const menu: ResourceHeader = JSON.parse(
      event.dataTransfer?.getData("json/add-menu") || ""
    );
    emit("setMenu", menu);
  }
}
</script>
