<template>
  <div class="ma-2">
    <v-dialog v-model="showAssistant">
      <MealWizzard
        :sejour="sejour"
        :meals-number="meals.length"
        @create="wizzardCreate"
      ></MealWizzard>
    </v-dialog>

    <v-row justify="space-between" class="my-2">
      <v-col cols="auto">
        <v-btn flat icon @click="offset -= 1">
          <v-icon>mdi-chevron-left</v-icon>
        </v-btn>
        <v-chip
          v-if="emtpyMealsNb > 0"
          label
          prepend-icon="mdi-alert-box-outline"
          color="orange-lighten-2"
        >
          {{ emtpyMealsNb }} repas vide{{ emtpyMealsNb > 1 ? "s" : "" }}
        </v-chip>
        <v-chip v-else color="secondary" label>
          {{ meals.length }} repas
        </v-chip>

        <v-btn flat icon @click="offset += 1">
          <v-icon>mdi-chevron-right</v-icon>
        </v-btn>
      </v-col>

      <v-col cols="auto" align-self="center">
        <v-menu>
          <template v-slot:activator="{ isActive, props: innerProps }">
            <v-btn flat v-on="{ isActive }" v-bind="innerProps">
              <template v-slot:prepend>
                <v-icon>mdi-view-list</v-icon>
              </template>
              {{
                props.viewGroupIndex == -1
                  ? "Vue d'ensemble"
                  : groups[props.viewGroupIndex].Name || "Tous"
              }}
            </v-btn>
          </template>
          <v-list>
            <v-list-item @click="emit('setGroupIndex', -1)"
              >Vue d'ensemble</v-list-item
            >
            <v-list-item
              v-for="(group, index) in groups"
              :key="index"
              @click="emit('setGroupIndex', index)"
            >
              {{ group.Name || "Tous (Groupe par défaut)" }}
            </v-list-item>
          </v-list>
        </v-menu>
      </v-col>

      <v-col cols="auto" align-self="center">
        <v-btn @click="showAssistant = true">
          <template v-slot:prepend>
            <v-icon color="success">mdi-plus-box-multiple-outline</v-icon>
          </template>
          Ajouter plusieurs repas...</v-btn
        >
      </v-col>
    </v-row>
    <table width="100%" v-if="props.viewGroupIndex == -1">
      <tr>
        <td
          v-for="i in 7"
          :key="i"
          style="max-width: 250px; vertical-align: top"
        >
          <DayCard
            :date="dayForCol(i - 1)"
            :meals="mealsForCol(i - 1)"
            :sejour-groups="sejour.Groups || []"
            @go-to="emit('goTo', totalOffset(i - 1))"
          ></DayCard>
        </td>
      </tr>
    </table>
    <GroupTable
      :group="groups[props.viewGroupIndex]"
      :offset-first-day="offset"
      v-else
      @go-to="(v) => emit('goTo', v)"
    ></GroupTable>
  </div>
</template>

<script lang="ts" setup>
import { ref } from "vue";
import DayCard from "./DayCard.vue";
import { controller, addDays } from "@/logic/controller";
import { computed } from "vue";
import { AssistantMealsIn, MealHeader } from "@/logic/api_gen";
import { onMounted } from "vue";
import { onActivated } from "vue";
import MealWizzard from "./MealWizzard.vue";
import GroupTable from "./GroupTable.vue";

const props = defineProps<{
  viewGroupIndex: number; // -1 for all
}>();

const emit = defineEmits<{
  (event: "goTo", offset: number): void;
  (event: "setGroupIndex", index: number): void;
}>();

onMounted(fetchMeals);
onActivated(fetchMeals);

const meals = ref<MealHeader[]>([]);
const emtpyMealsNb = computed(
  () => meals.value.filter((m) => m.IsMenuEmpty).length
);

const groups = computed(() => sejour.value.Groups || []);

async function fetchMeals() {
  const res = await controller.MealsGet({
    "id-sejour": controller.activeSejour!.Sejour.Id,
  });
  if (res == undefined) return;
  meals.value = res || [];

  sejour.value = controller.activeSejour!;
}

// offset of the first day displayed
const offset = ref(0);

const sejour = ref(controller.activeSejour!);

const firstDay = computed(() => new Date(sejour.value.Sejour.Start));

const totalOffset = (col: number) => offset.value + col;

function mealsForCol(col: number) {
  const of = totalOffset(col);
  return meals.value.filter((ml) => ml.Meal.Jour == of);
}

function dayForCol(col: number) {
  return addDays(firstDay.value, totalOffset(col));
}

const showAssistant = ref(false);
async function wizzardCreate(params: AssistantMealsIn) {
  const res = await controller.MealsWizzard(params);
  if (res === undefined) return;
  controller.showMessage("Repas générés avec succès");
  showAssistant.value = false;
  meals.value = res || [];
}
</script>
