<template>
  <v-responsive class="align-center fill-height">
    <v-alert class="mx-2 text-center" v-if="controller.activeSejour == null">
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
    <v-card v-else title="Bilan des ingrédients">
      <v-card-text>
        <v-row>
          <v-col cols="auto" align-self="center">
            <v-list>
              <v-list-subheader> Sélectionner les jours </v-list-subheader>
              <v-list-item
                v-for="day in dayItems"
                :key="day.offset"
                :title="formatDate(day.date)"
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
            </v-list>
          </v-col>
          <v-col cols="auto" align-self="center">
            <v-icon>mdi-chevron-right</v-icon>
          </v-col>
          <v-col cols="6" align-self="center">
            <v-btn
              v-if="compiledIngredients == null"
              :disabled="!selectedDaysList.length"
              @click="compileIngredients"
              >Calculer les ingrédients nécessaires</v-btn
            >
            <compiled-ingredients-list
              v-else
              :ingredients="compiledIngredients"
            ></compiled-ingredients-list>
          </v-col>
        </v-row>
      </v-card-text>
    </v-card>
  </v-responsive>
</template>

<script lang="ts" setup>
import CompiledIngredientsList from "@/components/order/CompiledIngredientsList.vue";
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

const compiledIngredients = ref<CompileIngredientsOut | null>(null);
async function compileIngredients() {
  const res = await controller.OrderCompileIngredients({
    IdSejour: controller.activeSejour!.Sejour.Id,
    DayOffsets: selectedDaysList.value,
  });
  if (res === undefined) return;
  compiledIngredients.value = res;
}
</script>
