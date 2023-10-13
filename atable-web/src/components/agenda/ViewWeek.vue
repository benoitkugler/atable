<template>
  <div class="ma-2">
    <v-dialog v-model="showAssistant">
      <MealWizzard
        :sejour="sejour"
        :meals-number="meals.Meals?.length || 0"
        @create="wizzardCreate"
      ></MealWizzard>
    </v-dialog>

    <v-row justify="space-between" class="mt-2">
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
          {{ emtpyMealsNb }} menus vide{{ emtpyMealsNb > 1 ? "s" : "" }}
        </v-chip>
        <v-chip v-else color="secondary" label>
          {{ (meals.Meals || []).length }} repas
        </v-chip>

        <v-btn flat icon @click="offset += 1">
          <v-icon>mdi-chevron-right</v-icon>
        </v-btn>
      </v-col>

      <v-col cols="auto" align-self="center" v-if="groups.length >= 2">
        <v-menu>
          <template v-slot:activator="{ isActive, props: innerProps }">
            <v-btn flat v-on="{ isActive }" v-bind="innerProps">
              <template v-slot:prepend>
                <v-icon>mdi-view-list</v-icon>
              </template>
              {{
                props.viewGroupIndex == -1
                  ? "Tous les groupes"
                  : groups[props.viewGroupIndex].Name
              }}
            </v-btn>
          </template>
          <v-list>
            <v-list-item @click="emit('setGroupIndex', -1)"
              >Tous les groupes</v-list-item
            >
            <v-list-item
              v-for="(group, index) in groups"
              :key="index"
              @click="emit('setGroupIndex', index)"
            >
              {{ group.Name || "Tous les groupes" }}
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

    <v-card class="my-2" elevation="4">
      <v-row class="mx-1">
        <v-col cols="3" align-self="center">
          <v-text-field
            variant="outlined"
            density="compact"
            hide-details
            label="Rechercher et ajouter un menu"
            v-model="menuSearch"
            @update:model-value="debounce.onType(menuSearch)"
          ></v-text-field>
        </v-col>
        <v-col align-self="center">
          <v-row
            no-gutters
            style="height: 13vh"
            class="overflow-y-auto"
            density="compact"
          >
            <v-col cols="4" v-for="(menu, index) in menus" :key="index">
              <v-list-item
                style="cursor: grab"
                rounded
                :title="menu.Title"
                density="compact"
                class="bg-grey-lighten-4 my-1 mx-1"
                :draggable="true"
                @dragstart="(ev: DragEvent) => onDragMenu(ev, menu)"
              >
                <template v-slot:prepend>
                  <v-icon class="ml-0 mr-1 px-0"> mdi-drag-vertical </v-icon>
                </template>
              </v-list-item>
            </v-col>
          </v-row>
        </v-col>
      </v-row>
    </v-card>

    <table width="100%">
      <tr>
        <th v-for="i in 7" :key="i" style="border-bottom: 1px solid grey">
          <v-card
            elevation="0"
            @click="emit('goTo', totalOffset(i - 1))"
            class="py-2"
          >
            {{ formatDate(dayForCol(i - 1)) }}
          </v-card>
        </th>
      </tr>
      <tr v-for="horaire in horairesItems" :key="horaire.value">
        <td
          v-for="i in 7"
          :key="i"
          :class="'rounded bg-' + colorForCell(horaire.value, i - 1)"
        >
          <HoraireCell
            :meals="mealsForCell(horaire.value, i - 1)"
            :menus="meals.Menus || {}"
            :groups="groups"
            @swap-meals="swapMeals"
            @set-menu="setMenu"
          ></HoraireCell>
        </td>
      </tr>
    </table>
  </div>
</template>

<script lang="ts" setup>
import { ref } from "vue";
import {
  controller,
  addDays,
  formatDate,
  horairesItems,
  horaireColors,
  Debouncer,
} from "@/logic/controller";
import { computed } from "vue";
import {
  AssistantMealsIn,
  Horaire,
  IdMeal,
  MealExt,
  MealsLoadOut,
  ResourceHeader,
} from "@/logic/api_gen";
import { onMounted } from "vue";
import { onActivated } from "vue";
import MealWizzard from "./MealWizzard.vue";
import HoraireCell from "./HoraireCell.vue";
import { reactive } from "vue";

const props = defineProps<{
  viewGroupIndex: number; // -1 for all
}>();

const emit = defineEmits<{
  (event: "goTo", offset: number): void;
  (event: "setGroupIndex", index: number): void;
}>();

onMounted(fetchMeals);
onActivated(fetchMeals);

const meals = reactive<MealsLoadOut>({ Meals: [], Menus: {} });
const emtpyMealsNb = computed(
  () =>
    (meals.Meals || [])
      .map((meal) => (meals.Menus || {})[meal.Meal.Menu])
      .filter((m) => !m.Ingredients?.length && !m.Receipes?.length).length
);

const groups = computed(() => sejour.value.Groups || []);

async function fetchMeals() {
  const res = await controller.MealsLoadAll({
    idSejour: controller.activeSejour!.Sejour.Id,
  });
  if (res == undefined) return;
  meals.Meals = res.Meals || [];
  meals.Menus = res.Menus || {};

  sejour.value = controller.activeSejour!;

  search("");
}

// offset of the first day displayed
const offset = ref(0);

const sejour = ref(controller.activeSejour!);

const firstDay = computed(() => new Date(sejour.value.Sejour.Start));

const totalOffset = (col: number) => offset.value + col;

function mealsForCell(horaire: Horaire, col: number) {
  const of = totalOffset(col);
  const out = (meals.Meals || []).filter(
    (ml) =>
      ml.Meal.Jour == of &&
      ml.Meal.Horaire == horaire &&
      (props.viewGroupIndex == -1 ||
        ml.Groups?.find(
          (g) => g.IdGroup == groups.value[props.viewGroupIndex].Id
        ) !== undefined)
  );
  out.sort((a, b) => a.Meal.Id - b.Meal.Id);
  return out;
}

function colorForCell(horaire: Horaire, col: number) {
  if (!mealsForCell(horaire, col).length) return "white";
  return horaireColors[horaire];
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
  meals.Meals = res.Meals || [];
  meals.Menus = res.Menus || {};
}

async function swapMeals(m1: IdMeal, m2: IdMeal) {
  const res = await controller.MealsSwapMenus({ IdMeal1: m1, IdMeal2: m2 });
  if (res === undefined) return;

  controller.showMessage("Menus permutés avec succès");
  const meal1 = meals.Meals?.find((m) => m.Meal.Id == m1)!;
  const meal2 = meals.Meals?.find((m) => m.Meal.Id == m2)!;
  const tmp = meal1.Meal.Menu;
  meal1.Meal.Menu = meal2.Meal.Menu;
  meal2.Meal.Menu = tmp;
}

const menuSearch = ref("");
// debounce feature for text field
const debounce = new Debouncer(search);
const menus = ref<ResourceHeader[]>([]);
async function search(pattern: string) {
  const res = await controller.MealsSearch({ search: pattern });
  if (res === undefined) return;
  menus.value = res.Menus || [];
}

function onDragMenu(event: DragEvent, menu: ResourceHeader) {
  event.dataTransfer!.dropEffect = "move";
  event.dataTransfer?.setData("json/add-menu", JSON.stringify(menu));
}

async function setMenu(menu: ResourceHeader, meal: MealExt) {
  const res = await controller.MealsSetMenu({
    IdMeal: meal.Meal.Id,
    IdMenu: menu.ID,
  });
  if (res === undefined) return;
  controller.showMessage("Menu mis en place avec succès");

  meals.Menus![menu.ID] = res;
  // redirect the meal to the updated menu
  const m = meals.Meals?.find((ml) => ml.Meal.Id == meal.Meal.Id)!;
  m.Meal.Menu = menu.ID;
}
</script>
