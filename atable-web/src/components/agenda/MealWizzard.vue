<template>
  <v-card class="py-1">
    <v-card-title>Assistant de créations de repas</v-card-title>
    <v-card-subtitle>
      Créez rapidement les repas du séjour
      <b>{{ props.sejour.Sejour.Name }}</b
      >. Les groupes marqués en sortie auront un repas à part.
    </v-card-subtitle>
    <v-card-text>
      <v-row justify="space-between">
        <v-col align-self="center" cols="3">
          <v-text-field
            variant="outlined"
            density="compact"
            min="1"
            hide-details
            label="Durée du séjour"
            type="number"
            v-model.number="args.DaysNumber"
            suffix="jours"
          ></v-text-field>
        </v-col>
        <v-col cols="auto" align-self="center">
          <v-switch
            v-model="args.WithGouter"
            label="Inclure un goûter"
            color="primary"
            hide-details
          ></v-switch>
        </v-col>
        <v-col align-self="center" cols="5">
          <v-select
            variant="outlined"
            density="compact"
            hide-details
            multiple
            chips
            :items="groupItems"
            label="Groupes pour le cinquième"
            v-model="args.GroupsForCinquieme"
          ></v-select>
        </v-col>
      </v-row>
      <v-row no-gutters class="mt-4" v-if="groupItems.length >= 2">
        <v-col>
          <v-card subtitle="Groupes en sortie" elevation="0">
            <v-slide-group show-arrows>
              <v-slide-group-item v-for="i in args.DaysNumber" :key="i">
                <v-card
                  :subtitle="dayForIndex(i - 1)"
                  width="200px"
                  class="ma-1"
                >
                  <v-card-text
                    class="text-center pb-1"
                    @click="editExcursionIndex = i - 1"
                  >
                    <v-select
                      @blur="editExcursionIndex = -1"
                      :variant="
                        editExcursionIndex == i - 1 ? 'outlined' : 'plain'
                      "
                      :menu-icon="editExcursionIndex == i - 1 ? undefined : ''"
                      :label="
                        editExcursionIndex == i - 1
                          ? 'Groupes en sortie'
                          : excursionForIndex(i - 1).length
                          ? ''
                          : 'Aucune sortie'
                      "
                      density="compact"
                      hide-details
                      multiple
                      chips
                      :items="groupItems"
                      :model-value="excursionForIndex(i - 1)"
                      @update:model-value="
                        (l) => setExcursionForIndex(l, i - 1)
                      "
                    ></v-select>
                  </v-card-text>
                </v-card>
              </v-slide-group-item>
            </v-slide-group>
          </v-card>
        </v-col>
      </v-row>
    </v-card-text>
    <v-card-actions>
      <v-spacer></v-spacer>

      <v-btn
        v-if="props.mealsNumber > 0"
        color="orange"
        @click="
          args.DeleteExisting = true;
          emit('create', args);
        "
      >
        Remplacer les repas actuels
      </v-btn>
      <v-btn
        color="success"
        @click="
          args.DeleteExisting = false;
          emit('create', args);
        "
      >
        Ajouter ces nouveaux repas
      </v-btn>
    </v-card-actions>
  </v-card>
</template>

<script lang="ts" setup>
import { AssistantMealsIn, SejourExt } from "@/logic/api_gen";
import { addDays, formatDate } from "@/logic/controller";
import { computed } from "vue";
import { watch } from "vue";
import { ref } from "vue";

const props = defineProps<{
  sejour: SejourExt;
  mealsNumber: number;
}>();

const emit = defineEmits<{
  (event: "create", v: AssistantMealsIn): void;
}>();

watch(props, () => (args.value = defaultArgs()));

function defaultArgs() {
  return {
    IdSejour: props.sejour.Sejour.Id,
    DaysNumber: 7,
    Excursions: {},
    WithGouter: true,
    GroupsForCinquieme: [],
    DeleteExisting: true,
  };
}

const args = ref<AssistantMealsIn>(defaultArgs());

const groupItems = computed(() =>
  (props.sejour.Groups || []).map((gr) => ({
    title: gr.Name || "Groupe par défaut",
    value: gr.Id,
  }))
);

function dayForIndex(i: number) {
  const date = addDays(new Date(props.sejour.Sejour.Start), i);
  return formatDate(date);
}

function excursionForIndex(i: number) {
  return (args.value.Excursions || {})[i] || [];
}
function setExcursionForIndex(ids: number[], i: number) {
  const m = args.value.Excursions || {};
  m[i] = ids;
  args.value.Excursions = m;
}

const editExcursionIndex = ref(-1);
</script>
