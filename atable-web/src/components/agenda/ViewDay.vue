<template>
  <v-card class="mx-2 py-2 fill-height" elevation="0">
    <v-dialog
      max-width="600px"
      :model-value="mealToUpdate != null"
      @update:model-value="mealToUpdate = null"
    >
      <v-card title="Modifier le repas" v-if="mealToUpdate != null">
        <v-card-text>
          <v-form>
            <v-select
              :items="horairesItems"
              variant="outlined"
              density="compact"
              label="Horaire"
              v-model="mealToUpdate.Horaire"
            >
            </v-select>
            <v-text-field
              variant="outlined"
              density="compact"
              v-model.number="mealToUpdate.AdditionalPeople"
              type="number"
              label="Personnes supplémentaires"
              hint="Ce nombre s'ajoute aux groupes déjà prévus, et peut être négatif."
              persistent-hint
            ></v-text-field>
          </v-form>
        </v-card-text>
        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn flat color="success" @click="updateMeal">Enregistrer</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!--  -->

    <v-dialog
      max-width="600px"
      :model-value="mealToDelete != null"
      @update:model-value="mealToDelete = null"
    >
      <v-card title="Confirmer la suppression">
        <v-card-text>
          Confirmez vous la suppression de ce repas ? <br />

          Cette opération est irréversible.
        </v-card-text>
        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn flat color="red" @click="deleteMeal(mealToDelete!)"
            >Supprimer</v-btn
          >
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!--  -->

    <v-dialog
      max-width="700px"
      :model-value="menuIngToUpdate != null"
      @update:model-value="menuIngToUpdate = null"
    >
      <menu-ingredient-form
        v-if="menuIngToUpdate != null"
        v-model="menuIngToUpdate"
        @update:model-value="updateIngredient"
      ></menu-ingredient-form>
    </v-dialog>

    <!--  -->

    <v-dialog
      max-width="700px"
      :model-value="ingToCreate != null"
      @update:model-value="ingToCreate = null"
    >
      <IngredientEditor
        v-if="ingToCreate != null"
        :ingredient="ingToCreate"
        @update="(ing) => createIngredient(ing)"
      ></IngredientEditor>
    </v-dialog>
    <!--  -->

    <v-dialog
      max-width="700px"
      :model-value="previewQuantities != null"
      @update:model-value="previewQuantities = null"
    >
      <v-card
        v-if="previewQuantities != null"
        title="Quantités nécessaires"
        :subtitle="`${previewQuantities.NbPeople} personnes`"
      >
        <v-card-text>
          <v-list>
            <v-list-item
              v-for="ingredient in previewQuantities.Quantities"
              :key="ingredient.Ingredient.Id"
            >
              <template v-slot:append>
                {{ formatQuantities(ingredient.Quantities || []) }}
              </template>
              <v-list-item-title>{{
                ingredient.Ingredient.Name
              }}</v-list-item-title>
              <v-list-item-subtitle>{{
                IngredientKindLabels[ingredient.Ingredient.Kind]
              }}</v-list-item-subtitle>
            </v-list-item>
          </v-list>
        </v-card-text>
      </v-card>
    </v-dialog>

    <!--  -->

    <v-card-text class="fill-height">
      <v-row class="fill-height">
        <v-col>
          <v-row justify="space-between">
            <v-col cols="auto" align-self="center">
              <v-btn class="ma-1" flat @click="emit('back')">
                <template v-slot:prepend>
                  <v-icon>mdi-arrow-left</v-icon>
                </template>
                Retour à la semaine</v-btn
              >
            </v-col>
            <v-col cols="auto" align-self="center">
              <v-btn
                size="small"
                flat
                class="mx-2 my-1"
                icon="mdi-arrow-left"
                @click="emit('previousDay')"
              ></v-btn>
              <b>
                {{ formatDate(day) }}
              </b>
              <v-btn
                size="small"
                flat
                class="mx-2 my-1"
                icon="mdi-arrow-right"
                @click="emit('nextDay')"
              ></v-btn>
            </v-col>
            <v-col cols="auto" align-self="center">
              <v-menu>
                <template v-slot:activator="{ isActive, props: innerProps }">
                  <v-btn v-on="{ isActive }" v-bind="innerProps">
                    <template v-slot:prepend>
                      <v-icon color="success">mdi-plus</v-icon>
                    </template>
                    Ajouter un repas...</v-btn
                  >
                </template>
                <v-list>
                  <v-list-item
                    v-for="(horaire, index) in horairesItems"
                    :key="index"
                    @click="createMeal(horaire.value)"
                  >
                    <v-list-item-title>{{ horaire.title }}</v-list-item-title>
                  </v-list-item>
                </v-list>
              </v-menu>
            </v-col>
          </v-row>

          <v-list class="overflow-y-auto" style="max-height: 78vh">
            <meal-ext-row
              v-for="meal in sortedMeals"
              :key="meal.Meal.Id"
              :meal="meal"
              :menu="(data.Menus || {})[meal.Meal.Menu]"
              :groups="groups"
              @delete="
                isMenuEmpty(meal.Meal.Menu)
                  ? deleteMeal(meal)
                  : (mealToDelete = meal)
              "
              @update="mealToUpdate = copy(meal.Meal)"
              @move="(g, from) => moveGroup(g, from, meal.Meal.Id)"
              @add-resource="(payload) => addResource(payload, meal.Meal)"
              @remove-item="(id, isR) => removeItem(id, isR, meal.Meal)"
              @update-menu-ingredient="
                (id) => startUpdateIngredient(id, meal.Meal.Menu)
              "
              @mark-favorite="
                markMenuFavorite((data.Menus || {})[meal.Meal.Menu])
              "
              @preview-quantities="() => showPreviewQuantities(meal.Meal.Id)"
              @go-to-menu="goToMenu(meal.Meal.Menu)"
              @go-to-receipe="goToReceipe"
            ></meal-ext-row>
          </v-list>
        </v-col>
        <v-col cols="3">
          <resource-search
            @go-to-library="goToLibrary"
            @create-ingredient="showCreateIngredient"
            ref="resourceSearch"
          ></resource-search>
        </v-col>
      </v-row>
    </v-card-text>
  </v-card>
</template>

<script lang="ts" setup>
import {
  type Horaire,
  type IdGroup,
  type IdIngredient,
  type IdMeal,
  type IdMenu,
  type IdReceipe,
  type Meal,
  type MealExt,
  type MealsLoadOut,
  type MenuIngredient,
  type PreviewQuantitiesOut,
  type Quantity,
  IngredientKindLabels,
  UniteLabels,
  MenuExt,
  type Ingredient,
  IngredientKind,
  Time,
  Int,
  IdUser,
} from "@/logic/api_gen";
import ResourceSearch from "./ResourceSearch.vue";
import IngredientEditor from "@/components/IngredientEditor.vue";
import { computed } from "vue";
import {
  DragKind,
  ResourceDrag,
  addDays,
  controller,
  copy,
  formatDate,
  groupMap,
  horairesItems,
} from "@/logic/controller";
import { ref } from "vue";
import { onMounted } from "vue";
import { onActivated } from "vue";
import MealExtRow from "./MealExtRow.vue";
import MenuIngredientForm from "./MenuIngredientForm.vue";
import { useRouter } from "vue-router";
import { reactive } from "vue";
import { watch } from "vue";

const props = defineProps<{
  offset: Int;
}>();

const emit = defineEmits<{
  (event: "back"): void;
  (e: "previousDay"): void;
  (e: "nextDay"): void;
}>();

onMounted(fetchMeals);
onActivated(fetchMeals);
watch(
  () => props.offset,
  (newV, oldV) => {
    if (newV != oldV) fetchMeals();
  }
);

const sortedMeals = computed(() => {
  const out = (data.Meals || []).map((m) => m);
  out.sort((a, b) => a.Meal.Horaire - b.Meal.Horaire);
  return out;
});

const day = computed(() =>
  addDays(new Date(sejour.value.Sejour.Start), props.offset)
);

const sejour = computed(() => controller.activeSejour!);
const groups = computed(() => groupMap(sejour.value.Groups));
const data = reactive<MealsLoadOut>({ Meals: [], Menus: {} });

async function fetchMeals() {
  const res = await controller.MealsLoadDay({
    idSejour: sejour.value.Sejour.Id,
    day: props.offset,
  });
  if (res === undefined) return;
  data.Menus = res.Menus;
  data.Meals = res.Meals;
}

async function createMeal(horaire: Horaire) {
  const res = await controller.MealsCreate({
    IdSejour: sejour.value.Sejour.Id,
    Day: props.offset,
    Horaire: horaire,
  });
  if (res === undefined) return;
  controller.showMessage("Repas ajouté avec succès.");
  data.Meals = (data.Meals || []).concat(res);
  // register the new empty menu
  const m = data.Menus || {};
  m[res.Meal.Menu] = {
    Menu: {
      Id: res.Meal.Menu,
      Owner: controller.idUser!,
      IsFavorite: false,
      IsPublished: false,
      Updated: "" as Time,
    },
    Ingredients: [],
    Receipes: [],
    OwnerPseudo: "",
  };
  data.Menus = m;
}

function isMenuEmpty(id: IdMenu) {
  const menu = data.Menus![id];
  return !menu.Ingredients?.length && !menu.Receipes?.length;
}

const mealToDelete = ref<MealExt | null>(null);
async function deleteMeal(meal: MealExt) {
  mealToDelete.value = null; // close potential confirm dialog

  const res = await controller.MealsDelete({ idMeal: meal.Meal.Id });
  if (res === undefined) return;
  controller.showMessage("Repas supprimé avec succès.");
  data.Meals = (data.Meals || []).filter((m) => m.Meal.Id != meal.Meal.Id);
}

const mealToUpdate = ref<Meal | null>(null);
async function updateMeal() {
  const newMeal = mealToUpdate.value!;
  const res = await controller.MealsUpdate(newMeal);
  if (res === undefined) return;

  controller.showMessage("Repas modifié avec succès.");
  const m = data.Meals?.find((m) => m.Meal.Id == newMeal.Id)!;
  m.Meal = newMeal;
  mealToUpdate.value = null;
}

async function moveGroup(idGroup: IdGroup, from: IdMeal, to: IdMeal) {
  if (from == to) return;

  const res = await controller.MealsMoveGroup({
    Group: idGroup,
    From: from,
    To: to,
  });
  if (res === undefined) return;
  controller.showMessage("Groupe déplacé avec succès.");

  const mFrom = data.Meals?.find((m) => m.Meal.Id == from)!;
  const mTo = data.Meals?.find((m) => m.Meal.Id == to)!;

  mFrom.Groups = res[0] || [];
  mTo.Groups = res[1] || [];
}

function addResource(payload: ResourceDrag, target: Meal) {
  switch (payload.kind) {
    case DragKind.ingredient:
      return addIngredient(payload.item.ID as IdIngredient, target);
    case DragKind.receipe:
      return addReceipe(payload.item.ID as IdReceipe, target);
    case DragKind.menu:
      return setMenu(payload.item.ID as IdMenu, target);
  }
}

async function addIngredient(id: IdIngredient, target: Meal) {
  const res = await controller.MealsAddIngredient({
    IdSejour: target.Sejour,
    IdIngredient: id,
    IdMenu: target.Menu,
  });
  if (res === undefined) return;
  controller.showMessage("Menu mis à jour avec succès");
  data.Menus![target.Menu] = res;

  startUpdateIngredient(id, target.Menu);
}

async function addReceipe(id: IdReceipe, target: Meal) {
  const res = await controller.MealsAddReceipe({
    IdReceipe: id,
    IdMenu: target.Menu,
  });
  if (res === undefined) return;
  controller.showMessage("Menu mis à jour avec succès");
  data.Menus![target.Menu] = res;
}

async function setMenu(id: IdMenu, target: Meal) {
  const res = await controller.MealsSetMenu({
    IdMeal: target.Id,
    IdMenu: id,
  });
  if (res === undefined) return;
  controller.showMessage("Menu remplacé avec succès");
  data.Menus![id] = res;
  // redirect the meal to the updated menu
  const m = data.Meals?.find((ml) => ml.Meal.Id == target.Id)!;
  m.Meal.Menu = id;
}

async function removeItem(id: Int, isReceipe: boolean, from: Meal) {
  const res = await controller.MealsRemoveItem({
    IdMenu: from.Menu,
    ID: id,
    IsReceipe: isReceipe,
  });
  if (res === undefined) return;
  controller.showMessage("Menu modifié avec succès.");
  const m = data.Menus || {};
  m[from.Menu] = res;
  data.Menus = m;
}

const menuIngToUpdate = ref<MenuIngredient | null>(null);
function startUpdateIngredient(id: IdIngredient, menu: IdMenu) {
  const ings = (data?.Menus || {})[menu].Ingredients || [];

  menuIngToUpdate.value = ings.find((link) => link.IdIngredient == id)!;
}

async function updateIngredient() {
  const newV = menuIngToUpdate.value!;
  const res = await controller.MealsUpdateMenuIngredient(newV);
  if (res === undefined) return;
  controller.showMessage("Ingrédient mis à jour avec succès.");
  const m = data.Menus || {};
  m[newV.IdMenu] = res;
  data.Menus = m;

  menuIngToUpdate.value = null; // close dialog
}

async function markMenuFavorite(menu: MenuExt) {
  const payload = menu.Menu;
  payload.IsFavorite = true;
  const res = controller.LibraryUpdateMenu(payload);
  if (res === undefined) return;

  controller.showMessage("Menu enregistré dans la bibliothèque.");
  data.Menus![payload.Id].Menu = payload;
}

const previewQuantities = ref<PreviewQuantitiesOut | null>(null);
async function showPreviewQuantities(idMeal: IdMeal) {
  const res = await controller.MealsPreviewQuantities({ idMeal });
  if (res === undefined) return;
  previewQuantities.value = res;
}

function formatQuantities(qus: Quantity[]) {
  return qus
    .map((item) => `${item.Val} ${UniteLabels[item.Unite]}`)
    .join(" et ");
}

const resourceSearch = ref<InstanceType<typeof ResourceSearch> | null>(null);
const ingToCreate = ref<Ingredient | null>(null);
function showCreateIngredient(name: string) {
  ingToCreate.value = {
    Name: name,
    Id: -1 as IdIngredient,
    Kind: IngredientKind.I_Empty,
    Owner: -1 as IdUser,
  };
}
async function createIngredient(ing: Ingredient) {
  ingToCreate.value = null;
  const res = await controller.LibraryCreateIngredient(ing);
  if (res === undefined) return;
  controller.showMessage("Ingrédient ajouté avec succès.");
  resourceSearch.value?.refreshSearch();
}

const router = useRouter();
function goToMenu(menu: IdMenu) {
  router.push({ name: "library", query: { "id-menu": menu } });
}
function goToReceipe(rec: IdReceipe) {
  router.push({ name: "library", query: { "id-receipe": rec } });
}
function goToLibrary() {
  router.push({ name: "library" });
}
</script>
