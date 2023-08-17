<template>
  <v-card class="fill-height">
    <v-card-text>
      <v-text-field
        class="mt-1"
        variant="outlined"
        density="compact"
        label="Rechercher une ressource"
        v-model="pattern"
        @update:model-value="debounce.onType(pattern)"
        placeholder="Entrez au moins 2 charactères..."
        hint="Tapez :I, :R ou :M pour afficher tous les ingrédients, recettes ou menus."
        persistent-hint
      ></v-text-field>
      <v-list class="overflow-y-auto my-2" max-height="70vh">
        <v-card v-if="pattern.length >= 2 && isResEmpty" color="grey-lighten-3">
          <v-card-text>
            Aucun résultat ne correspond à votre recherche.

            <v-row no-gutters justify="center" class="mt-2">
              <v-col cols="auto">
                <v-btn
                  class="my-2"
                  @click="emit('createIngredient', pattern)"
                  size="small"
                >
                  Ajouter un ingrédient
                  <template v-slot:prepend>
                    <v-icon color="green">mdi-plus</v-icon>
                  </template>
                </v-btn>
              </v-col>
            </v-row>
            <v-row no-gutters justify="center">
              <v-col cols="auto">
                <v-btn class="my-2" @click="emit('goToLibrary')" size="small">
                  Aller à la bibliothèque
                  <template v-slot:prepend>
                    <v-icon>mdi-notebook-heart-outline</v-icon>
                  </template>
                </v-btn>
              </v-col>
            </v-row>
          </v-card-text>
        </v-card>
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

const emit = defineEmits<{
  (event: "goToLibrary"): void;
  (event: "createIngredient", name: string): void;
}>();

const pattern = ref("");

defineExpose({ refreshSearch });

/** `refreshSearch` immediately launches the search with the current input */
function refreshSearch() {
  search(pattern.value);
}

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
    event.dataTransfer?.setData("drag-menu", "true");
  }
}
</script>
