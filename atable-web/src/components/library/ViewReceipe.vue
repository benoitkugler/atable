<template>
  <v-card>
    <v-card class="mb-1" elevation="0" variant="tonal" :color="titleColor">
      <v-row no-gutters>
        <v-col align-self="center">
          <v-btn flat @click="emit('back')" class="mx-2">
            <template v-slot:prepend>
              <v-icon>mdi-arrow-left</v-icon>
              Retour à la liste
            </template>
          </v-btn>
        </v-col>
        <v-col align-self="center">
          <v-card-title>
            Détails de la recette

            <v-tooltip v-if="isReadonly && inner != null">
              <template v-slot:activator="{ props }">
                <v-icon v-bind="props" size="small">mdi-lock</v-icon>
              </template>
              Cette recette appartient à <b>{{ inner.OwnerPseudo }}</b>
            </v-tooltip>
          </v-card-title>
        </v-col>
        <v-col cols="3" align-self="center" class="text-right px-2">
          <small v-if="inner != null">
            modifiée le {{ formatTime(new Date(inner.Receipe.Updated)) }}</small
          >
        </v-col>
      </v-row>
    </v-card>

    <v-card-text v-if="inner != null">
      <v-row>
        <v-col cols="12" md="4">
          <v-form>
            <v-row>
              <v-col>
                <v-text-field
                  v-model="tmpName"
                  variant="outlined"
                  density="compact"
                  label="Nom de la recette"
                  hide-details
                  @blur="saveName"
                  @focus="$event.target.select()"
                  :readonly="isReadonly"
                >
                </v-text-field>
              </v-col>
            </v-row>
            <v-row>
              <v-col>
                <plat-select
                  v-model="inner.Receipe.Plat"
                  @update:model-value="save"
                  :readonly="isReadonly"
                ></plat-select>
              </v-col>
            </v-row>
            <v-row>
              <v-col>
                <v-textarea
                  v-model="inner.Receipe.Description"
                  variant="outlined"
                  density="compact"
                  label="Description (optionnelle)"
                  hide-details
                  @blur="save"
                  :readonly="isReadonly"
                >
                </v-textarea>
              </v-col>
            </v-row>

            <v-row v-if="!isReadonly">
              <v-col>
                <v-checkbox
                  label="Publier"
                  density="compact"
                  hint="Rendre la recette visible aux autres utilisateurs, en lecture seule."
                  persistent-hint
                  v-model="inner.Receipe.IsPublished"
                  @update:model-value="save"
                >
                </v-checkbox>
              </v-col>
            </v-row>
          </v-form>
        </v-col>
        <v-col>
          <v-card
            title="Ingrédients"
            :subtitle="
              hasSameForPeople ? ` Pour ${hasSameForPeople} personnes` : ''
            "
          >
            <template v-slot:append v-if="!isReadonly">
              <ResourceSelector
                :items="DB"
                label="Ajouter un ingrédient"
                @selected="(item) => addIngredient(item.Id as IdIngredient)"
                @create-ingredient="createAndAddIngredient"
              ></ResourceSelector>
            </template>
            <v-card-text>
              <div v-if="!inner.Ingredients?.length" class="text-center">
                <i>La recette est vide.</i>
              </div>
              <v-list density="compact" style="column-count: 2">
                <v-row
                  style="break-inside: avoid-column"
                  class="mb-2 mx-1 pa-2 bg-grey-lighten-4 rounded"
                  no-gutters
                  v-for="ingredient in sortedIngredients"
                  :key="ingredient.Id"
                  justify="space-between"
                >
                  <v-col align-self="center" class="pl-1">
                    <v-list-item-title>
                      {{ ingredient.Name }}
                    </v-list-item-title>
                    <v-list-item-subtitle>
                      {{ IngredientKindLabels[ingredient.Kind] }}
                    </v-list-item-subtitle>
                  </v-col>
                  <v-col align-self="center" cols="auto">
                    <QuantityChip
                      :quantity="ingredient.Quantity"
                      :show-for="hasSameForPeople == null"
                      :disabled="isReadonly"
                      @update="(qu) => updateIngredient(ingredient.Id, qu)"
                    ></QuantityChip>
                  </v-col>
                  <v-col
                    cols="auto"
                    align-self="center"
                    class="pl-4"
                    v-if="!isReadonly"
                  >
                    <v-btn
                      icon
                      size="x-small"
                      @click="deleteIngredient(ingredient.Id)"
                    >
                      <v-icon color="red">mdi-delete</v-icon>
                    </v-btn>
                  </v-col>
                </v-row>
              </v-list>
            </v-card-text>
          </v-card>
        </v-col>
      </v-row>
    </v-card-text>
    <v-card-text v-else>
      <v-progress-linear indeterminate></v-progress-linear>
    </v-card-text>
  </v-card>
</template>

<script setup lang="ts">
import {
  type ReceipeExt,
  type IdIngredient,
  IngredientKindLabels,
  QuantityR,
  PlatKind,
  IdReceipe,
  Ingredient,
  Int,
} from "@/logic/api_gen";
import {
  MenuResource,
  controller,
  formatTime,
  platColors,
  resourcesToList,
} from "@/logic/controller";
import { onMounted } from "vue";
import { ref } from "vue";
import PlatSelect from "@/components/PlatSelect.vue";
import ResourceSelector from "./ResourceSelector.vue";
import { computed } from "vue";
import QuantityChip from "./QuantityChip.vue";

interface Props {
  receipe: IdReceipe;
}

const props = defineProps<Props>();

const emit = defineEmits<{
  (event: "back"): void;
}>();

onMounted(fetch);

const inner = ref<ReceipeExt | null>(null);
const DB = ref<MenuResource[]>([]);

const sortedIngredients = computed(() => {
  const out = inner.value?.Ingredients || [];
  out.sort((a, b) => a.Name.localeCompare(b.Name));
  return out;
});

const titleColor = computed(
  () => platColors[inner.value?.Receipe.Plat || PlatKind.P_Empty]
);

const isReadonly = computed(
  () => inner.value?.Receipe.Owner != controller.idUser
);

async function fetch() {
  await fetchReceipe();
  tmpName.value = inner.value!.Receipe.Name;

  const ings = await controller.LibraryLoadIngredients();
  if (ings === undefined) return;
  DB.value = resourcesToList(ings, {});
}

async function fetchReceipe() {
  const res = await controller.LibraryLoadReceipe({
    idReceipe: props.receipe,
  });
  if (res === undefined) return;
  inner.value = res;
}

const tmpName = ref("");
function saveName() {
  // avoid useless calls
  if (inner.value?.Receipe.Name == tmpName.value) return;
  inner.value!.Receipe.Name = tmpName.value;
  save();
}

async function save() {
  if (inner.value == null || isReadonly.value) return;
  const res = await controller.LibraryUpdateReceipe(inner.value.Receipe);
  if (res === undefined) return;

  controller.showMessage("Recette modifiée avec succès.");

  fetchReceipe();
}

async function addIngredient(idIngredient: IdIngredient) {
  if (
    inner.value?.Ingredients?.find((ing) => ing.Id == idIngredient) != undefined
  )
    return;

  const for_ = hasSameForPeople.value;
  const res = await controller.LibraryAddReceipeIngredient({
    IdReceipe: props.receipe,
    IdIngredient: idIngredient,
    InitialFor: for_ == null ? (0 as Int) : for_,
  });
  if (res == undefined) return;

  controller.showMessage("Ingrédient ajouté avec succès.");
  inner.value!.Ingredients = (inner.value?.Ingredients || []).concat(res);

  fetchReceipe();
}

async function createAndAddIngredient(ingredient: Ingredient) {
  const res = await controller.LibraryCreateIngredient(ingredient);
  if (res === undefined) return;
  controller.showMessage("Ingrédient créé avec succès.");
  // update the local DB
  DB.value.push({ Id: res.Id, Title: res.Name, Kind: "ingredient" });

  addIngredient(res.Id);
}

const hasSameForPeople = computed(() => {
  const s = new Set(inner.value?.Ingredients?.map((ing) => ing.Quantity.For_));
  return s.size == 1 ? Array.from(s.keys())[0] : null;
});

async function updateIngredient(id: IdIngredient, qu: QuantityR) {
  const res = await controller.LibraryUpdateReceipeIngredient({
    IdIngredient: id,
    IdReceipe: props.receipe,
    Quantity: qu,
  });
  if (res === undefined) return;
  controller.showMessage("Quantité modifiée avec succès.");
  const item = inner.value?.Ingredients?.find((ing) => ing.Id == id)!;
  item.Quantity = qu;

  fetchReceipe();
}

async function deleteIngredient(id: IdIngredient) {
  const res = await controller.LibraryDeleteReceipeIngredient({
    idReceipe: props.receipe,
    idIngredient: id,
  });
  if (res === undefined) return;
  controller.showMessage("Ingrédient retiré avec succès.");
  inner.value!.Ingredients = (inner.value?.Ingredients || []).filter(
    (ing) => ing.Id != id
  );

  fetchReceipe();
}
</script>
