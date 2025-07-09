<template>
  <v-card
    title="Importer des recettes"
    :subtitle="
      [
        'Importez plusieurs recettes depuis un fichier .CSV',
        'Vérifiez la correspondance des ingrédients.',
        'Conclure l\'import',
      ][step]
    "
  >
    <template v-slot:append>
      <TimelineSteps
        :steps="['Fichier', 'Ingrédients', 'Recettes']"
        :current-step="step"
        class="mb-2"
      ></TimelineSteps>
    </template>
    <ImportCsv1
      v-if="step == steps.importFile"
      @start-import="startImport"
    ></ImportCsv1>
    <ImportCsv2
      v-else-if="step == steps.mapIngredients"
      :receipes="receipesToMap"
      :ingredients="DB"
      @back="step = steps.importFile"
      @show-receipes="
        (m) => {
          receipesToMap.Map = m;
          step = steps.importReceipes;
        }
      "
    ></ImportCsv2>
    <ImportCsv3
      v-else-if="step == steps.importReceipes"
      :receipes="receipesToMap"
      @back="step = steps.mapIngredients"
      @import="concludeImport"
    ></ImportCsv3>
  </v-card>
</template>

<script setup lang="ts">
import { ref } from "vue";
import ImportCsv1 from "./ImportCsv1.vue";
import ImportCsv2 from "./ImportCsv2.vue";
import { MenuResource, controller, resourcesToList } from "@/logic/controller";
import { ImportReceipes1Out, ReceipeExt } from "@/logic/api_gen";
import { onMounted } from "vue";
import TimelineSteps from "../TimelineSteps.vue";
import ImportCsv3 from "./ImportCsv3.vue";

// const props = defineProps<{}>();

const emit = defineEmits<{
  (e: "importDone", receipes: ReceipeExt[]): void;
}>();

onMounted(fetchDB);

const DB = ref<MenuResource[]>([]);

async function fetchDB() {
  const res = await controller.LibraryLoadIngredients();
  if (res === undefined) return;
  DB.value = resourcesToList(res, {});
}

enum steps {
  importFile,
  mapIngredients,
  importReceipes,
}

const step = ref<steps>(steps.importFile);
const receipesToMap = ref<ImportReceipes1Out>({ Map: {}, Receipes: [] });
async function startImport(file: File) {
  const res = await controller.LibraryImportReceipes1(file);
  if (res === undefined) return;

  receipesToMap.value = res;
  step.value = steps.mapIngredients;
}

async function concludeImport() {
  const res = await controller.LibraryImportReceipes2(receipesToMap.value);
  if (res === undefined) return;
  controller.showMessage("Recettes importées avec succès");
  emit("importDone", res || []);
}
</script>
