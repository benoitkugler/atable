<template>
  <v-card
    elevation="0"
    title="Menus et recettes"
    subtitle="Retrouver vos menus favoris et vos recettes."
  >
    <v-dialog v-model="showImportCSV" max-width="1000px">
      <ImportCsvMain @import-done="onImportCSV"></ImportCsvMain>
    </v-dialog>

    <template v-slot:append>
      <v-menu>
        <template v-slot:activator="{ isActive, props }">
          <v-btn v-on="{ isActive }" v-bind="props">
            <template v-slot:prepend>
              <v-icon color="success">mdi-plus</v-icon>
            </template>
            Ajouter...</v-btn
          >
        </template>
        <v-list density="compact">
          <v-list-item title="Ajouter une recette" @click="createReceipe">
          </v-list-item>
          <v-list-item title="Ajouter un menu" @click="createMenu">
          </v-list-item>
        </v-list>
      </v-menu>
      <v-divider vertical></v-divider>
      <v-btn class="mx-2" @click="showImportCSV = true">
        <template v-slot:prepend>
          <v-icon>mdi-file-table-outline</v-icon>
        </template>
        Importer...</v-btn
      >
    </template>

    <v-card-text>
      <v-row>
        <v-col>
          <v-text-field
            class="mt-1"
            variant="outlined"
            density="comfortable"
            label="Rechercher un menu ou une recette"
            :model-value="props.searchPattern"
            @update:model-value="
              (p) => {
                emit('update:searchPattern', p);
                debounce.onType(p);
              }
            "
            placeholder="Entrez au moins 2 charactères..."
            hide-details
          ></v-text-field>
        </v-col>
      </v-row>
      <v-row no-gutters>
        <v-col>
          <v-list class="overflow-y-auto my-2" max-height="70vh">
            <i v-if="props.searchPattern.length >= 2 && resourcesLength == 0">
              Aucun résultat ne correspond à votre recherche.
            </i>
            <list-page
              :resources="currentPage"
              @update-menu="(m) => emit('updateMenu', m)"
              @update-receipe="(m) => emit('updateReceipe', m)"
            ></list-page>
          </v-list>
        </v-col>
      </v-row>
      <v-row no-gutters>
        <v-col>
          <v-pagination
            :model-value="props.pageIndex"
            @update:model-value="(p) => emit('update:pageIndex', p)"
            :length="Math.ceil(resourcesLength / pagination)"
          ></v-pagination> </v-col
      ></v-row>
    </v-card-text>
  </v-card>
</template>

<script lang="ts" setup>
import ListPage from "@/components/library/ListPage.vue";
import {
  ReceipeExt,
  ReceipeHeader,
  ResourceHeader,
  ResourceSearchOut,
} from "@/logic/api_gen";
import { Debouncer, controller } from "@/logic/controller";
import { onMounted } from "vue";
import { onActivated } from "vue";
import { computed } from "vue";
import { ref } from "vue";
import ImportCsvMain from "./ImportCsvMain.vue";

const props = defineProps<{
  pageIndex: number;
  searchPattern: string;
}>();

const emit = defineEmits<{
  (e: "update:pageIndex", m: number): void;
  (e: "update:searchPattern", m: string): void;
  (e: "updateMenu", m: ResourceHeader): void;
  (e: "updateReceipe", m: ReceipeHeader): void;
}>();

onMounted(() => search(props.searchPattern));
onActivated(() => search(props.searchPattern));

const debounce = new Debouncer(search);
const resources = ref<ResourceSearchOut>({
  Ingredients: [],
  Receipes: [],
  Menus: [],
});
const resourcesLength = computed(
  () =>
    (resources.value.Menus?.length || 0) +
    (resources.value.Receipes?.length || 0)
);

const pagination = 12;

const currentPage = computed<ResourceSearchOut>(() => {
  const menus = resources.value.Menus || [];
  const receipes = resources.value.Receipes || [];
  const start = (props.pageIndex - 1) * pagination;
  const end = start + pagination;

  const outMenus = menus.slice(start, end);
  let outReceipes: ReceipeHeader[] = [];
  if (end > menus.length) {
    outReceipes = receipes.slice(
      Math.max(start - menus.length, 0),
      end - menus.length
    );
  }
  return { Ingredients: [], Receipes: outReceipes, Menus: outMenus };
});

async function search(s: string) {
  const res = await controller.MealsSearch({ search: s });
  if (res === undefined) return;
  resources.value = res;
}

async function createMenu() {
  const res = await controller.LibraryCreateMenu();
  if (res === undefined) return;
  controller.showMessage("Menu favori ajouté avec succès.");

  // start edit
  emit("updateMenu", res);
}

async function createReceipe() {
  const res = await controller.LibraryCreateReceipe();
  if (res === undefined) return;
  controller.showMessage("Recette ajoutée avec succès.");

  // start edit
  emit("updateReceipe", res);
}

const showImportCSV = ref(false);
function onImportCSV(receipes: ReceipeExt[]) {
  showImportCSV.value = false;
  search(""); // refresh the main list
}
</script>