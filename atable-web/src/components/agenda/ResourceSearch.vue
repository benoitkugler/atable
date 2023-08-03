<template>
  <v-card class="fill-height">
    <v-card-text>
      <v-text-field
        class="mt-1"
        variant="outlined"
        density="comfortable"
        label="Rechercher un menu, une recette ou un ingrédient"
        v-model="pattern"
        @update:model-value="debounce.onType(pattern)"
        placeholder="Entrez au moins 2 charactères..."
        hint="Tapez :I, :R ou :M pour afficher tous les ingrédients, recettes ou menus."
        persistent-hint
      ></v-text-field>
      <v-list class="overflow-y-auto my-2" max-height="70vh">
        <i v-if="pattern.length >= 2 && isResEmpty">
          Aucun résultat ne correspond à votre recherche.
        </i>
        <!-- Menus -->
        <template v-if="resources.Menus?.length">
          <v-list-subheader>Menus favoris</v-list-subheader>
          <resource-result
            v-for="(item, index) in resources.Menus"
            :key="index"
            :title="item.Title"
            subtitle=""
            @on-drag="(ev) => dragStart(ev, item, DragKind.menu)"
          ></resource-result>
          <v-divider class="my-1"></v-divider>
        </template>
        <!-- Receipes -->
        <template v-if="resources.Receipes?.length">
          <v-list-subheader>Recettes</v-list-subheader>
          <resource-result
            v-for="(item, index) in resources.Receipes"
            :key="index"
            :title="item.Title"
            :subtitle="PlatKindLabels[item.Plat]"
            @on-drag="(ev) => dragStart(ev, item, DragKind.receipe)"
          ></resource-result>
          <v-divider class="my-1"></v-divider>
        </template>
        <!-- Ingredients -->
        <template v-if="resources.Ingredients?.length">
          <v-list-subheader>Ingrédients</v-list-subheader>
          <resource-result
            v-for="(item, index) in resources.Ingredients"
            :key="index"
            :title="item.Title"
            :subtitle="IngredientKindLabels[item.Kind]"
            @on-drag="(ev) => dragStart(ev, item, DragKind.ingredient)"
          ></resource-result>
          <v-divider class="my-1"></v-divider>
        </template>
      </v-list>
    </v-card-text>
  </v-card>
</template>

<script lang="ts" setup>
import {
  ResourceSearchOut,
  IngredientKindLabels,
  ResourceHeader,
  PlatKindLabels,
} from "@/logic/api_gen";
import {
  Debouncer,
  DragKind,
  ResourceDrag,
  controller,
} from "@/logic/controller";
import { computed } from "vue";
import { ref } from "vue";
import ResourceResult from "./ResourceResult.vue";

// const props = defineProps<{}>();

// const emit = defineEmits<{
//   (event: "select", item: ResourceHeader): void;
// }>();

const pattern = ref("");

const resources = ref<ResourceSearchOut>({
  Ingredients: [],
  Receipes: [],
  Menus: [],
});
const isResEmpty = computed(() => {
  const v = resources.value;
  return !v.Ingredients?.length && !v.Receipes?.length && !v.Menus?.length;
});

// debounce feature for text field
const debounce = new Debouncer(search);

async function search(pattern: string) {
  if (pattern.length < 2) return;
  const res = await controller.MealsSearch({ search: pattern });
  if (res === undefined) return;
  resources.value = res || [];
}

function dragStart(event: DragEvent, item: ResourceHeader, kind: DragKind) {
  const payload: ResourceDrag = { item, kind };
  event.dataTransfer?.setData("json/add-resource", JSON.stringify(payload));
  event.dataTransfer!.dropEffect = "copy";
  // special case menu
  if (kind == DragKind.menu) {
    console.log("setnin menu");

    event.dataTransfer?.setData("drag-menu", "true");
  }
}
</script>
