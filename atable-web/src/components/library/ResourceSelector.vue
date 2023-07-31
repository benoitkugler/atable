<template>
  <v-dialog
    :model-value="newIngredient != null"
    @update:model-value="newIngredient = null"
    max-width="700px"
  >
    <ingredient-editor
      v-if="newIngredient != null"
      :ingredient="newIngredient"
      @update="
        (ing) => {
          newIngredient = null;
          emit('createIngredient', ing);
        }
      "
    ></ingredient-editor>
  </v-dialog>
  <v-autocomplete
    class="my-2 mx-2"
    density="compact"
    variant="underlined"
    menu-icon=""
    auto-select-first
    :label="label"
    append-inner-icon="mdi-magnify"
    hint="Appuyer sur Tab ou Entrée pour valider rapidement."
    persistent-hint
    :custom-filter="customFilter"
    :items="props.items"
    @update:model-value="onAdd"
    v-model:search="search"
    v-model="item"
    item-title="Title"
    item-value="Id"
    return-object
    autofocus
  >
    <template v-slot:no-data>
      <v-row no-gutters class="px-2">
        <v-col align-self="center"><i>Aucun résultat.</i></v-col>
        <v-col cols="auto">
          <v-btn flat @click="startCreateIngredient">
            Ajouter un ingrédient
          </v-btn>
        </v-col>
      </v-row>
    </template>
  </v-autocomplete>
</template>

<script setup lang="ts">
import { Ingredient, IngredientKind } from "@/logic/api_gen";
import { MenuResource, upperFirst } from "@/logic/controller";
import { nextTick } from "vue";
import { ref } from "vue";
import IngredientEditor from "./IngredientEditor.vue";

const props = defineProps<{
  items: MenuResource[];
  label: string;
}>();

const emit = defineEmits<{
  (e: "selected", item: MenuResource): void;
  (e: "createIngredient", item: Ingredient): void;
}>();

const search = ref("");
const item = ref<MenuResource | null>(null);

function customFilter(itemTitle: string, queryText: string) {
  queryText = queryText
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase();
  itemTitle = itemTitle
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase();
  const index = itemTitle.indexOf(queryText);
  return index == -1 ? false : index;
}

function onAdd(v: MenuResource | null) {
  if (v == null) return;
  emit("selected", v);
  // clear the selector
  nextTick(() => {
    search.value = "";
    item.value = null;
  });
}

const newIngredient = ref<Ingredient | null>(null);
function startCreateIngredient() {
  newIngredient.value = {
    Id: 0,
    Name: upperFirst(search.value),
    Kind: IngredientKind.I_Empty,
  };
  // clear the selector
  nextTick(() => {
    search.value = "";
    item.value = null;
  });
}
</script>
