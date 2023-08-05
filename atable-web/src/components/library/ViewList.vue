<template>
  <v-card
    elevation="0"
    title="Menus et recettes"
    subtitle="Retrouver vos menus favoris et vos recettes."
  >
    <v-dialog v-model="showImportCSV" max-width="1000px">
      <ImportCsvMain @import-done="onImportCSV"></ImportCsvMain>
    </v-dialog>

    <v-dialog
      :model-value="menuToDelete != null"
      @update:model-value="menuToDelete = null"
      max-width="600px"
    >
      <v-card title="Confirmer la suppression">
        <v-card-text v-if="menuToDelete != null">
          Confirmer vous la suppression du menu
          <i> {{ menuToDelete.Title }} </i> ?
          <br />
          <br />

          Cette opération est irréversible.
        </v-card-text>
        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn color="red" flat @click="deleteMenu"> Supprimer </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog
      :model-value="receipeToDelete != null"
      @update:model-value="receipeToDelete = null"
      max-width="600px"
    >
      <v-card title="Confirmer la suppression">
        <v-card-text v-if="receipeToDelete != null">
          Confirmer vous la suppression de la recette
          <i> {{ receipeToDelete.Title }} </i> ?
          <br />
          <br />

          Cette opération est irréversible.
        </v-card-text>
        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn color="red" flat @click="deleteReceipe"> Supprimer </v-btn>
        </v-card-actions>
      </v-card>
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

      <v-menu>
        <template v-slot:activator="{ isActive, props }">
          <v-btn
            class="mx-2"
            icon
            v-on="{ isActive }"
            v-bind="props"
            size="small"
          >
            <v-icon>mdi-swap-vertical</v-icon>
          </v-btn>
        </template>
        <v-list density="compact">
          <v-list-item
            title="Importer des recettes"
            subtitle="au format .CSV"
            @click="showImportCSV = true"
            prepend-icon="mdi-file-import-outline"
          >
          </v-list-item>
          <v-list-item
            title="Exporter mes recettes"
            subtitle="personnelles, au format .CSV"
            link
            :href="controller.receipesExportURL()"
            prepend-icon="mdi-file-export-outline"
          >
          </v-list-item>
        </v-list>
      </v-menu>
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
              @delete-menu="(m) => (menuToDelete = m)"
              @delete-receipe="(m) => (receipeToDelete = m)"
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

const menuToDelete = ref<ResourceHeader | null>(null);
async function deleteMenu() {
  const toDelete = menuToDelete.value!.ID;
  const res = await controller.LibraryDeleteMenu({
    idMenu: toDelete,
  });
  menuToDelete.value = null;
  if (res === undefined) return;
  controller.showMessage("Menu supprimé avec succès.");
  resources.value.Menus = (resources.value.Menus || []).filter(
    (m) => m.ID != toDelete
  );
}

async function createReceipe() {
  const res = await controller.LibraryCreateReceipe();
  if (res === undefined) return;
  controller.showMessage("Recette ajoutée avec succès.");

  // start edit
  emit("updateReceipe", res);
}

const receipeToDelete = ref<ReceipeHeader | null>(null);
async function deleteReceipe() {
  const toDelete = receipeToDelete.value!.ID;
  const res = await controller.LibraryDeleteReceipe({
    idReceipe: toDelete,
  });
  receipeToDelete.value = null;
  if (res === undefined) return;
  controller.showMessage("Recette supprimée avec succès.");
  resources.value.Receipes = (resources.value.Receipes || []).filter(
    (m) => m.ID != toDelete
  );
}

const showImportCSV = ref(false);
function onImportCSV(receipes: ReceipeExt[]) {
  showImportCSV.value = false;
  search(""); // refresh the main list
}
</script>
