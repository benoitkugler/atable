<template>
  <v-list-item
    rounded
    class="bg-grey-lighten-5 my-2"
    @dragover="onDragover"
    @dragleave="acceptDrop = false"
    @drop="onDrop"
    :elevation="acceptDrop ? 2 : 0"
  >
    <v-row>
      <v-col cols="3" align-self="center">
        <v-row no-gutters>
          <v-col cols="12" class="my-1">
            <v-list-item-title>
              {{ formatHoraire(props.meal.Meal.Horaire) }}
            </v-list-item-title>
          </v-col>
          <v-col>
            <v-hover v-for="group in props.meal.Groups" :key="group.IdGroup">
              <template v-slot:default="{ isHovering, props: innerProps }">
                <GroupChip
                  v-bind="innerProps"
                  :is-hovering="isHovering"
                  style="cursor: grab"
                  :draggable="true"
                  @dragstart="(e) => onGroupDragStart(e, group.IdGroup)"
                  :is-mono-group="
                    Object.keys(props.groups || {}).length == 1 &&
                    props.meal.Groups?.length == 1
                  "
                  :small="false"
                  :group="props.groups![group.IdGroup]"
                ></GroupChip>
              </template>
            </v-hover>

            <add-people-chip
              :people="props.meal.Meal.AdditionalPeople"
              :small="false"
            ></add-people-chip>
          </v-col>
        </v-row>
      </v-col>

      <v-col align-self="center">
        <v-row no-gutters>
          <v-col
            cols="auto"
            v-for="(item, index) in sortedMenuContent"
            :key="index"
            class="px-1"
          >
            <v-hover>
              <template v-slot:default="{ isHovering, props }">
                <v-chip
                  label
                  v-bind="props"
                  :color="platColors[item.plat]"
                  :class="{ 'my-1': true, 'pr-0': isHovering }"
                  @[!item.isReceipe&&`click`]="
                    emit('updateMenuIngredient', item.id)
                  "
                >
                  <template v-slot:append>
                    <v-btn
                      class="my-2 ml-2 mr-1"
                      variant="tonal"
                      icon="mdi-close"
                      v-if="isHovering"
                      size="26"
                      @click.stop="emit('removeItem', item.id, item.isReceipe)"
                    ></v-btn>
                  </template>
                  {{ item.title }}
                </v-chip>
              </template>
            </v-hover>
          </v-col>
        </v-row>
      </v-col>

      <v-col cols="auto" align-self="center" class="my-1">
        <v-menu>
          <template v-slot:activator="{ isActive, props }">
            <v-btn
              flat
              icon="mdi-dots-vertical"
              size="small"
              v-on="{ isActive }"
              v-bind="props"
            ></v-btn>
          </template>
          <v-list>
            <v-list-item>
              <v-btn flat @click="emit('update')">
                <template v-slot:prepend>
                  <v-icon>mdi-pencil</v-icon>
                </template>
                Modifier
              </v-btn>
            </v-list-item>
            <v-divider></v-divider>
            <v-list-item>
              <v-btn flat>
                <template v-slot:prepend>
                  <v-icon>mdi-food-variant</v-icon>
                </template>
                Prévisualiser les quantités
              </v-btn>
            </v-list-item>
            <v-divider></v-divider>
            <v-list-item>
              <v-btn flat @click="emit('delete')">
                <template v-slot:prepend>
                  <v-icon color="red">mdi-delete</v-icon>
                </template>
                Supprimer ce repas
              </v-btn>
            </v-list-item>
          </v-list>
        </v-menu>
      </v-col>
    </v-row>
  </v-list-item>
</template>

<script lang="ts" setup>
import type { Groups, IdIngredient, MealExt, MenuExt } from "@/logic/api_gen";
import { PlatKind } from "@/logic/api_gen";
import {
  ResourceDrag,
  formatHoraire,
  platColors,
  sortMenuContent,
} from "@/logic/controller";
import GroupChip from "./GroupChip.vue";
import AddPeopleChip from "./AddPeopleChip.vue";
import { ref } from "vue";
import { computed } from "vue";

const props = defineProps<{
  meal: MealExt;
  groups: Groups;
  menu: MenuExt;
}>();

const emit = defineEmits<{
  (event: "delete"): void;
  (event: "update"): void;
  (event: "move", idGroup: number, from: number): void;
  (event: "addResource", payload: ResourceDrag): void;
  (event: "removeItem", id: number, isReceipe: boolean): void;
  (event: "updateMenuIngredient", id: IdIngredient): void;
}>();

function onGroupDragStart(event: DragEvent, idGroup: number) {
  event.dataTransfer?.setData(
    "json/move-group",
    JSON.stringify({ idGroup, from: props.meal.Meal.Id })
  );
  event.dataTransfer!.dropEffect = "move";
}

const acceptDrop = ref(false);

function onDragover(event: DragEvent) {
  event.preventDefault();
  acceptDrop.value = true;
}

function onDrop(event: DragEvent) {
  acceptDrop.value = false;
  event.preventDefault();

  const data = event.dataTransfer!;
  if (data.types.includes("json/move-group")) {
    const val: { idGroup: number; from: number } = JSON.parse(
      data.getData("json/move-group")
    );
    emit("move", val.idGroup, val.from);
  } else if (data.types.includes("json/add-resource")) {
    const val: ResourceDrag = JSON.parse(data.getData("json/add-resource"));
    emit("addResource", val);
  }
}

const sortedMenuContent = computed(() => sortMenuContent(props.menu));
</script>