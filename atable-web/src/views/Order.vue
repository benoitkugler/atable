<template>
  <v-responsive class="align-center fill-height">
    <v-dialog v-model="showSuppliers" max-width="1000px">
      <ProfilesList></ProfilesList>
    </v-dialog>

    <v-card title="Bilan des ingrédients">
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
        <v-row v-else>
          <v-col cols="auto" align-self="center">
            <v-list>
              <v-list-subheader> Sélectionner les jours </v-list-subheader>
              <div class="overflow-y-auto" style="max-height: 70vh">
                <v-list-item title="Tout sélectionner" class="pl-1">
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
          <v-col cols="5" align-self="center">
            <div class="text-center" v-if="compiledIngredients == null">
              <v-btn
                :disabled="!selectedDaysList.length"
                @click="compileIngredients"
                >Calculer les ingrédients nécessaires</v-btn
              >
            </div>
            <compiled-ingredients-list
              v-else
              :ingredients="compiledIngredients"
            ></compiled-ingredients-list>
          </v-col>
          <v-col cols="auto" align-self="center">
            <v-icon>mdi-chevron-right</v-icon>
          </v-col>
          <v-col align-self="center">
            <ExportMappingCard
              v-if="compiledIngredients != null"
              :compiledIngredients="compiledIngredients"
            ></ExportMappingCard>
          </v-col>
        </v-row>
      </v-card-text>
    </v-card>
  </v-responsive>
</template>

<script lang="ts" setup>
import CompiledIngredientsList from "@/components/order/CompiledIngredientsList.vue";
import ExportMappingCard from "@/components/order/ExportMappingCard.vue";
import ProfilesList from "@/components/order/ProfilesList.vue";
import { CompileIngredientsOut } from "@/logic/api_gen";
import { addDays, controller, formatDate } from "@/logic/controller";
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
    .map((v) => Number(v[0]))
);

const allDaysSelected = computed(() => {
  if (selectedDaysList.value.length == dayItems.value.length) return true;
  if (selectedDaysList.value.length == 0) return false;
  return null;
});
function onSelectAll(b: boolean) {
  dayItems.value.forEach((d) => (selectedDays.value[d.offset] = b));
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
</script>
