<template>
  <v-responsive class="align-center fill-height">
    <v-dialog v-model="showSuppliers" max-width="1000px">
      <ProfilesList></ProfilesList>
    </v-dialog>

    <v-dialog v-model="showExportExcel" max-width="1200px">
      <ExportExcel
        v-if="compiledIngredients != null"
        :compiledIngredients="compiledIngredients"
        :days="selectedDaysList"
        @done="showExportExcel = false"
      ></ExportExcel>
    </v-dialog>

    <v-card
      title="Bilan des ingrédients"
      subtitle="Fiches de cuisine et commandes"
    >
      <template v-slot:append>
        <v-btn @click="showSuppliers = true">
          <template v-slot:prepend>
            <v-icon>mdi-view-list</v-icon>
          </template>
          Fournisseurs
        </v-btn>
      </template>
      <v-card-text>
        <v-alert
          class="mx-2 text-center"
          v-if="controller.activeSejour == null"
        >
          <v-row>
            <v-col align-self="center">
              Merci de sélectionner (ou de créer) un séjour
            </v-col>
            <v-col>
              <v-btn class="my-2" :to="{ name: 'sejours' }"
                >Aller aux séjours</v-btn
              >
            </v-col>
          </v-row>
        </v-alert>
        <v-row v-else justify="space-between">
          <v-col cols="auto" align-self="center">
            <v-list>
              <v-list-subheader> Sélectionner les jours </v-list-subheader>
              <div class="overflow-y-auto" style="max-height: 66vh">
                <v-list-item
                  title="Tout sélectionner"
                  class="pl-1"
                  @click="onSelectAll(allDaysSelected != true)"
                >
                  <template v-slot:prepend="">
                    <v-list-item-action start>
                      <v-checkbox-btn
                        :indeterminate="allDaysSelected == null"
                        :model-value="allDaysSelected"
                        @update:model-value="onSelectAll"
                        color="secondary"
                      ></v-checkbox-btn>
                    </v-list-item-action>
                  </template>
                </v-list-item>
                <v-list-item
                  v-for="day in dayItems"
                  :key="day.offset"
                  :title="formatDate(day.date)"
                  class="pl-1"
                  @click="
                    selectedDays[day.offset] = !selectedDays[day.offset];
                    compiledIngredients = null;
                  "
                >
                  <template v-slot:prepend="">
                    <v-list-item-action start>
                      <v-checkbox-btn
                        v-model="selectedDays[day.offset]"
                        @update:model-value="compiledIngredients = null"
                        color="secondary"
                      ></v-checkbox-btn>
                    </v-list-item-action>
                  </template>
                </v-list-item>
              </div>
            </v-list>
          </v-col>
          <v-col cols="auto" align-self="center">
            <v-icon>mdi-chevron-right</v-icon>
          </v-col>
          <v-col
            :cols="compiledIngredients != null ? 4 : 9"
            align-self="center"
          >
            <div class="text-center" v-if="compiledIngredients == null">
              <v-row no-gutters>
                <v-col cols="12">
                  <v-btn
                    :disabled="!selectedDaysList.length"
                    @click="compileIngredients"
                    >Exporter les ingrédients nécessaires</v-btn
                  >
                </v-col>
              </v-row>
            </div>
            <compiled-ingredients-list
              v-else
              :ingredients="compiledIngredients"
            ></compiled-ingredients-list>
          </v-col>
          <v-col
            cols="auto"
            align-self="center"
            v-if="compiledIngredients != null"
          >
            <v-icon>mdi-chevron-right</v-icon>
          </v-col>
          <v-col
            align-self="center"
            cols="auto"
            v-if="compiledIngredients != null"
          >
            <v-card>
              <v-card-text>
                <v-row justify="center">
                  <v-col cols="12">
                    <v-list-item
                      title="Exporter les fiches de cuisine"
                      subtitle="Fichier PDF, une page par repas"
                      class="bg-secondary-lighten"
                      prepend-icon="mdi-file-pdf-box"
                      elevation="4"
                      link
                      rounded
                      @click="downloadCookbook"
                    >
                    </v-list-item>
                  </v-col>
                </v-row>

                <v-row justify="center">
                  <v-col cols="12">
                    <v-list-item
                      title="Exporter un tableau de courses"
                      subtitle="Fichier Excel, tri par fournisseurs"
                      class="bg-secondary-lighten"
                      prepend-icon="mdi-file-excel-box"
                      elevation="4"
                      link
                      rounded
                      @click="showExportExcel = true"
                    >
                    </v-list-item>
                  </v-col>
                </v-row>
              </v-card-text>
            </v-card>
          </v-col>
        </v-row>
      </v-card-text>
    </v-card>
  </v-responsive>
</template>

<script lang="ts" setup>
import CompiledIngredientsList from "@/components/order/CompiledIngredientsList.vue";
import ExportExcel from "@/components/order/ExportExcel.vue";
import ProfilesList from "@/components/order/ProfilesList.vue";
import { CompileIngredientsOut, Int } from "@/logic/api_gen";
import {
  addDays,
  controller,
  formatDate,
  saveBlobAsFile,
} from "@/logic/controller";
import { computed } from "vue";
import { onMounted } from "vue";
import { ref } from "vue";

onMounted(fetchDays);

const dayItems = ref<{ date: Date; offset: number }[]>([]);
async function fetchDays() {
  const sejour = controller.activeSejour;
  if (sejour == null) return;
  const res = await controller.OrderGetDays({
    idSejour: sejour.Sejour.Id,
  });
  if (res === undefined) return;
  dayItems.value = (res || []).map((offset) => ({
    offset,
    date: addDays(new Date(sejour.Sejour.Start), offset),
  }));
}

const selectedDays = ref<{ [key: number]: boolean }>({});
const selectedDaysList = computed(() =>
  Object.entries(selectedDays.value)
    .filter((l) => l[1])
    .map((v) => Number(v[0]) as Int)
);

const allDaysSelected = computed(() => {
  if (selectedDaysList.value.length == dayItems.value.length) return true;
  if (selectedDaysList.value.length == 0) return false;
  return null;
});
function onSelectAll(b: boolean | null) {
  dayItems.value.forEach((d) => (selectedDays.value[d.offset] = b || false));
  compiledIngredients.value = null;
}

const compiledIngredients = ref<CompileIngredientsOut | null>(null);
async function compileIngredients() {
  const res = await controller.OrderCompileIngredients({
    IdSejour: controller.activeSejour!.Sejour.Id,
    DayOffsets: selectedDaysList.value,
  });
  if (res === undefined) return;
  compiledIngredients.value = res;
}

const showSuppliers = ref(false);

async function downloadCookbook() {
  const res = await controller.MealsExportCookbook({
    IdSejour: controller.activeSejour!.Sejour.Id,
    Days: selectedDaysList.value,
  });
  if (res === undefined) return;

  controller.showMessage("Fiches cuisines téléchargées avec succès.");

  saveBlobAsFile(res.blob, res.filename);
}

const showExportExcel = ref(false);
</script>
