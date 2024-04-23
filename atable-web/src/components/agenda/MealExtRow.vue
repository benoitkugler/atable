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
                    props.groups.size == 1 && props.meal.Groups?.length == 1
                  "
                  :small="true"
                  :group="props.groups.get(group.IdGroup)!"
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
            align-self="center"
          >
            <v-card
              label
              :color="platColors[item.plat]"
              :variant="props.menu.Menu.IsFavorite ? 'text' : 'tonal'"
              class="my-1 pr-2"
              @click="
                item.isReceipe
                  ? emit('goToReceipe', item.id)
                  : emit('updateMenuIngredient', item.id)
              "
              :disabled="props.menu.Menu.IsFavorite"
            >
              <v-row no-gutters>
                <v-col align-self="center" class="px-2 py-1">
                  <v-row no-gutters>
                    <v-col cols="12">
                      {{ item.title }}
                    </v-col>
                    <v-col>
                      <small v-if="item.quantity != null">
                        {{ item.quantity.Val }}
                        {{ UniteLabels[item.quantity.Unite] }}
                        (pour {{ item.quantity.For_ }} per.)
                      </small>
                    </v-col>
                  </v-row>
                </v-col>
                <v-col cols="auto" align-self="center">
                  <v-btn
                    v-if="!props.menu.Menu.IsFavorite"
                    class="my-1 mr-0"
                    variant="plain"
                    icon="mdi-close"
                    size="x-small"
                    @click.stop="emit('removeItem', item.id, item.isReceipe)"
                  ></v-btn>
                </v-col>
              </v-row>
            </v-card>
          </v-col>
        </v-row>
      </v-col>

      <v-col cols="auto" v-if="props.menu.Menu.IsFavorite" align-self="center">
        <v-chip
          prepend-icon="mdi-heart"
          color="secondary"
          @click="emit('goToMenu')"
          >Menu favori</v-chip
        >
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
                  <v-icon>mdi-cog</v-icon>
                </template>
                Détails
              </v-btn>
            </v-list-item>
            <v-divider></v-divider>
            <v-list-item>
              <v-btn flat @click="emit('previewQuantities')">
                <template v-slot:prepend>
                  <v-icon>mdi-food-variant</v-icon>
                </template>
                Prévisualiser les quantités
              </v-btn>
            </v-list-item>
            <v-divider></v-divider>
            <v-list-item>
              <v-btn
                flat
                @click="emit('markFavorite')"
                :disabled="props.menu.Menu.IsFavorite"
              >
                <template v-slot:prepend>
                  <v-icon>mdi-heart</v-icon>
                </template>
                Enregistrer comme favori
              </v-btn>
            </v-list-item>
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
import {
  UniteLabels,
  type IdIngredient,
  type IdReceipe,
  type MealExt,
  type MenuExt,
  type IdGroup,
  type Group,
  Int,
  IdMeal,
} from "@/logic/api_gen";
import {
  DragKind,
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
  groups: Map<IdGroup, Group>;
  menu: MenuExt;
}>();

const emit = defineEmits<{
  (event: "delete"): void;
  (event: "update"): void;
  (event: "move", idGroup: IdGroup, from: IdMeal): void;
  (event: "addResource", payload: ResourceDrag): void;
  (event: "removeItem", id: Int, isReceipe: boolean): void;
  (event: "updateMenuIngredient", id: IdIngredient): void;
  (event: "markFavorite"): void;
  (event: "goToMenu"): void;
  (event: "goToReceipe", id: IdReceipe): void;
  (event: "previewQuantities"): void;
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
  const data = event.dataTransfer!;
  // we want to prevent modification of favorite menu
  if (data.types.includes("json/add-resource")) {
    if (!data.types.includes("private/is-menu") && props.menu.Menu.IsFavorite) {
      return;
    }
  }

  // accept the drop
  event.preventDefault();
  acceptDrop.value = true;
}

function onDrop(event: DragEvent) {
  acceptDrop.value = false;
  event.preventDefault();

  const data = event.dataTransfer!;
  if (data.types.includes("json/move-group")) {
    const val: { idGroup: IdGroup; from: IdMeal } = JSON.parse(
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
